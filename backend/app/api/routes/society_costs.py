"""Society costs: recording, optional member splitting, payment collection.

Admin endpoints are gated on `manage_costs`; members see only their own
shares via /member/cost-shares.
"""
import re
from datetime import date, datetime, timezone
from decimal import Decimal, InvalidOperation

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import case, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.deps import get_current_member
from app.core.permissions import require_permission
from app.db.session import get_db
from app.models.config_list_item import ConfigListItem
from app.models.member import Member, MemberStatus
from app.models.property import Property
from app.models.society_cost import (
    CostSplit,
    CostSplitShare,
    SocietyCost,
)
from app.schemas.society_cost import (
    CostSplitCreate,
    CostSplitOut,
    CostSplitShareOut,
    CostSummaryOut,
    SocietyCostCreate,
    SocietyCostOut,
    SocietyCostUpdate,
    SharePaymentUpdate,
    SplitPreviewRow,
)
from app.services.audit import record_audit
from app.services.storage import save_upload_file

router = APIRouter(tags=["society-costs"])

_TWO_PLACES = Decimal("0.01")


def _member_label(member: Member) -> str:
    return member.full_name or ""


def _decorate_share(share: CostSplitShare, out: CostSplitShareOut) -> CostSplitShareOut:
    if share.member is not None:
        out.member_name = _member_label(share.member)
        out.member_display_id = share.member.member_id
    cost = share.split.cost if share.split is not None else None
    if cost is not None:
        out.cost_title = cost.title
        out.cost_incurred_date = cost.incurred_date
        out.cost_category = cost.category.label if cost.category is not None else None
    return out


async def _load_cost(db: AsyncSession, cost_id: int) -> SocietyCost:
    result = await db.execute(select(SocietyCost).where(SocietyCost.id == cost_id))
    cost = result.scalar_one_or_none()
    if cost is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cost not found")
    return cost


def _cost_out(cost: SocietyCost) -> SocietyCostOut:
    out = SocietyCostOut.model_validate(cost)
    if cost.category is not None:
        out.category_label = cost.category.label
    if cost.split is not None:
        for share, share_out in zip(cost.split.shares, out.split.shares, strict=False):
            share_out.member_name = _member_label(share.member) if share.member else None
            share_out.member_display_id = share.member.member_id if share.member else None
            share_out.payment_method_label = (
                share.payment_method.label if share.payment_method else None
            )
    return out


def _parse_land_quantity(raw: str | None) -> Decimal:
    """Extract the first numeric value from a free-text land quantity field
    (e.g. '1.5 একর', '৩ শতক'). Bengali digits are transliterated first."""
    if not raw:
        return Decimal("0")
    bn_digits = str.maketrans("০১২৩৪৫৬৭৮৯", "0123456789")
    match = re.search(r"\d+(?:\.\d+)?", raw.translate(bn_digits))
    if match is None:
        return Decimal("0")
    try:
        return Decimal(match.group())
    except InvalidOperation:
        return Decimal("0")


async def _active_members_with_land(db: AsyncSession) -> list[tuple[Member, Decimal]]:
    result = await db.execute(
        select(Member, Property.land_quantity)
        .outerjoin(Property, Property.member_id == Member.id)
        .where(Member.status == MemberStatus.APPROVED)
    )
    weights: dict[int, tuple[Member, Decimal]] = {}
    for member, land_quantity in result.all():
        entry = weights.setdefault(member.id, (member, Decimal("0")))
        weights[member.id] = (entry[0], entry[1] + _parse_land_quantity(land_quantity))
    return list(weights.values())


def _reconciled_amounts(
    total: Decimal, weights: list[Decimal]
) -> list[Decimal]:
    """Proportional split rounded to 2 places with the remainder cents
    distributed to the first shares so the sum always equals `total` exactly."""
    weight_sum = sum(weights, Decimal("0"))
    if weight_sum <= 0:
        # No usable land data: fall back to an equal split rather than
        # putting the whole cost on the first member.
        weights = [Decimal("1")] * len(weights)
        weight_sum = Decimal(len(weights))
    amounts = [(total * w / weight_sum).quantize(_TWO_PLACES) for w in weights]
    drift = total - sum(amounts, Decimal("0"))
    i = 0
    cent = Decimal("0.01")
    while drift != 0 and i < len(amounts):
        if drift > 0:
            amounts[i] += cent
            drift -= cent
        else:
            amounts[i] -= cent
            drift += cent
        i += 1
    return amounts


async def _assert_split_replacable(cost: SocietyCost, db: AsyncSession) -> None:
    if cost.split is None:
        return
    paid = any(share.amount_paid > 0 for share in cost.split.shares)
    if paid:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cannot re-split: some members have already paid this cost. "
            "Record refunds or adjust shares manually instead.",
        )


# ---------------------------------------------------------------------------
# Admin: costs CRUD
# ---------------------------------------------------------------------------


@router.get("/admin/society-costs", response_model=list[SocietyCostOut])
async def list_society_costs(
    category_id: int | None = Query(default=None),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
    payment_source: str | None = Query(default=None, pattern="^(society_fund|member_billed)$"),
    billed: bool | None = Query(default=None),
    search: str | None = Query(default=None, max_length=255),
    limit: int | None = Query(default=None, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin=Depends(require_permission("manage_costs")),
) -> list[SocietyCostOut]:
    query = select(SocietyCost).order_by(SocietyCost.incurred_date.desc(), SocietyCost.id.desc())
    if category_id is not None:
        query = query.where(SocietyCost.category_id == category_id)
    if date_from is not None:
        query = query.where(SocietyCost.incurred_date >= date_from)
    if date_to is not None:
        query = query.where(SocietyCost.incurred_date <= date_to)
    if payment_source is not None:
        query = query.where(SocietyCost.payment_source == payment_source)
    if billed is True:
        query = query.where(SocietyCost.split.has())
    elif billed is False:
        query = query.where(~SocietyCost.split.has())
    if search:
        query = query.where(SocietyCost.title.ilike(f"%{search}%"))
    if limit is not None:
        query = query.limit(limit).offset(offset)
    result = await db.execute(query)
    return [_cost_out(cost) for cost in result.scalars().unique()]


@router.post(
    "/admin/society-costs", response_model=SocietyCostOut, status_code=status.HTTP_201_CREATED
)
async def create_society_cost(
    payload: SocietyCostCreate,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_costs")),
) -> SocietyCostOut:
    cost = SocietyCost(
        **payload.model_dump(),
        created_by=admin.id,
    )
    db.add(cost)
    await db.flush()
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="society_cost.create",
        entity_type="society_cost",
        entity_id=str(cost.id),
        detail=f"{cost.title}: ৳{cost.total_amount} ({cost.payment_source})",
    )
    await db.commit()
    await db.refresh(cost)
    return _cost_out(cost)


@router.patch("/admin/society-costs/{cost_id}", response_model=SocietyCostOut)
async def update_society_cost(
    cost_id: int,
    payload: SocietyCostUpdate,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_costs")),
) -> SocietyCostOut:
    cost = await _load_cost(db, cost_id)
    changes = payload.model_dump(exclude_unset=True)
    if cost.split is not None and any(s.amount_paid > 0 for s in cost.split.shares):
        if "total_amount" in changes and changes["total_amount"] != cost.total_amount:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Cannot change the amount: members have already paid this cost.",
            )
        if "payment_source" in changes and changes["payment_source"] != cost.payment_source:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Cannot change the payment source: members have already paid this cost.",
            )
    if not changes:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update")
    for field, value in changes.items():
        setattr(cost, field, value)
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="society_cost.update",
        entity_type="society_cost",
        entity_id=str(cost.id),
        detail=", ".join(sorted(changes)),
    )
    await db.commit()
    await db.refresh(cost)
    return _cost_out(cost)


@router.delete("/admin/society-costs/{cost_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_society_cost(
    cost_id: int,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_costs")),
) -> None:
    cost = await _load_cost(db, cost_id)
    if cost.split is not None and any(s.amount_paid > 0 for s in cost.split.shares):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cannot delete: members have already paid this cost.",
        )
    title = cost.title
    await db.delete(cost)
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="society_cost.delete",
        entity_type="society_cost",
        entity_id=str(cost_id),
        detail=f"deleted '{title}'",
    )
    await db.commit()


@router.put(
    "/admin/society-costs/{cost_id}/receipt", response_model=SocietyCostOut
)
async def upload_cost_receipt(
    cost_id: int,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_costs")),
) -> SocietyCostOut:
    cost = await _load_cost(db, cost_id)
    path = await save_upload_file(file, f"cost_receipts/cost_{cost.id}")
    cost.receipt_file_url = path
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="society_cost.receipt_upload",
        entity_type="society_cost",
        entity_id=str(cost.id),
        detail=path,
    )
    await db.commit()
    await db.refresh(cost)
    return _cost_out(cost)


# ---------------------------------------------------------------------------
# Admin: splitting & shares
# ---------------------------------------------------------------------------


@router.post(
    "/admin/society-costs/{cost_id}/split",
    response_model=SocietyCostOut | list[SplitPreviewRow],
)
async def split_society_cost(
    cost_id: int,
    payload: CostSplitCreate,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_costs")),
) -> SocietyCostOut:
    cost = await _load_cost(db, cost_id)
    await _assert_split_replacable(cost, db)

    members_with_land = await _active_members_with_land(db)
    if not members_with_land:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No active members to split this cost across.",
        )

    if payload.split_method == "manual":
        if not payload.manual_shares:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Manual split requires per-member amounts.",
            )
        member_map = {member.id: weight for member, weight in members_with_land}
        by_member: dict[int, Decimal] = {}
        for entry in payload.manual_shares:
            if entry.member_id not in member_map:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Member {entry.member_id} is not an active member.",
                )
            if entry.member_id in by_member:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Member {entry.member_id} appears more than once.",
                )
            by_member[entry.member_id] = entry.amount_due
        manual_total = sum(by_member.values(), Decimal("0"))
        if manual_total != cost.total_amount and not payload.allow_mismatch:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Manual amounts total ৳{manual_total}, but the cost is "
                f"৳{cost.total_amount}. Adjust the amounts or confirm the override.",
            )
        rows = [
            (member, amount) for member, _ in members_with_land if (amount := by_member.get(member.id)) is not None
        ]
    else:
        weights = [weight for _, weight in members_with_land]
        amounts = _reconciled_amounts(cost.total_amount, weights)
        rows = [
            (member, amount)
            for (member, _), amount in zip(members_with_land, amounts, strict=True)
        ]

    if payload.dry_run:
        return [
            SplitPreviewRow(member_id=member.id, member_name=_member_label(member), amount_due=amount)
            for member, amount in rows
        ]

    # Nothing paid yet (checked above), so replacing the draft split is safe.
    if cost.split is not None:
        await db.delete(cost.split)
        await db.flush()

    split = CostSplit(
        society_cost_id=cost.id,
        split_method=payload.split_method,
        created_by=admin.id,
        shares=[
            CostSplitShare(member_id=member.id, amount_due=amount) for member, amount in rows
        ],
    )
    db.add(split)
    cost.payment_source = "member_billed"
    await db.flush()
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="society_cost.split",
        entity_type="society_cost",
        entity_id=str(cost.id),
        detail=f"৳{cost.total_amount} across {len(rows)} members ({payload.split_method})",
    )
    await db.commit()
    await db.refresh(cost)
    return _cost_out(cost)


@router.get("/admin/society-costs/{cost_id}/shares", response_model=list[CostSplitShareOut])
async def list_cost_shares(
    cost_id: int,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(require_permission("manage_costs")),
):
    cost = await _load_cost(db, cost_id)
    if cost.split is None:
        return []
    return [_decorate_share(share, CostSplitShareOut.model_validate(share)) for share in cost.split.shares]


def _share_status(amount_due: Decimal, amount_paid: Decimal) -> str:
    if amount_paid <= 0:
        return "unpaid"
    if amount_paid < amount_due:
        return "partial"
    return "paid"


@router.patch("/admin/cost-split-shares/{share_id}", response_model=CostSplitShareOut)
async def record_share_payment(
    share_id: int,
    payload: SharePaymentUpdate,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_costs")),
):
    result = await db.execute(
        select(CostSplitShare).where(CostSplitShare.id == share_id)
    )
    share = result.scalar_one_or_none()
    if share is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Share not found")
    if payload.amount_paid > share.amount_due:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Paid amount cannot exceed the due amount (৳{share.amount_due}).",
        )
    share.amount_paid = payload.amount_paid
    share.status = _share_status(share.amount_due, payload.amount_paid)
    share.paid_at = datetime.now(timezone.utc) if payload.amount_paid > 0 else None
    share.payment_method_id = payload.payment_method_id
    share.receipt_no = payload.receipt_no
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="society_cost.payment",
        entity_type="cost_split_share",
        entity_id=str(share.id),
        detail=f"৳{payload.amount_paid} paid of ৳{share.amount_due} (status: {share.status})",
    )
    await db.commit()
    await db.refresh(share)
    return _decorate_share(share, CostSplitShareOut.model_validate(share))


@router.get("/admin/society-costs/summary", response_model=CostSummaryOut)
async def society_cost_summary(
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
    _admin=Depends(require_permission("manage_costs")),
) -> CostSummaryOut:
    range_filter = [
        SocietyCost.incurred_date >= date_from if date_from else None,
        SocietyCost.incurred_date <= date_to if date_to else None,
    ]
    conditions = [c for c in range_filter if c is not None]

    total_row = await db.execute(
        select(
            func.coalesce(func.sum(SocietyCost.total_amount), 0),
            func.coalesce(
                func.sum(
                    case(
                        (SocietyCost.payment_source == "society_fund", SocietyCost.total_amount),
                        else_=0,
                    )
                ),
                0,
            ),
            func.coalesce(
                func.sum(
                    case(
                        (SocietyCost.payment_source == "member_billed", SocietyCost.total_amount),
                        else_=0,
                    )
                ),
                0,
            ),
        ).where(*conditions)
    )
    total, society_fund_total, member_billed_total = total_row.one()

    share_row = await db.execute(
        select(
            func.coalesce(func.sum(CostSplitShare.amount_due), 0),
            func.coalesce(func.sum(CostSplitShare.amount_paid), 0),
        ).join(CostSplit, CostSplit.id == CostSplitShare.cost_split_id).join(
            SocietyCost, SocietyCost.id == CostSplit.society_cost_id
        ).where(*conditions)
    )
    due_total, paid_total = share_row.one()

    category_rows = await db.execute(
        select(
            ConfigListItem.label,
            func.coalesce(func.sum(SocietyCost.total_amount), 0),
        )
        .select_from(SocietyCost)
        .outerjoin(ConfigListItem, ConfigListItem.id == SocietyCost.category_id)
        .where(*conditions)
        .group_by(ConfigListItem.label)
    )

    return CostSummaryOut(
        total_amount=total,
        society_fund_total=society_fund_total,
        member_billed_total=member_billed_total,
        outstanding_total=due_total - paid_total,
        collected_total=paid_total,
        by_category=[
            {"category": label or "Uncategorised", "total": str(total)}
            for label, total in category_rows.all()
        ],
    )


# ---------------------------------------------------------------------------
# Member: own shares
# ---------------------------------------------------------------------------


@router.get("/member/cost-shares", response_model=list[CostSplitShareOut])
async def my_cost_shares(
    db: AsyncSession = Depends(get_db),
    member: Member = Depends(get_current_member),
) -> list[CostSplitShareOut]:
    result = await db.execute(
        select(CostSplitShare)
        .join(CostSplit, CostSplit.id == CostSplitShare.cost_split_id)
        .join(SocietyCost, SocietyCost.id == CostSplit.society_cost_id)
        .where(CostSplitShare.member_id == member.id)
        .order_by(SocietyCost.incurred_date.desc(), SocietyCost.id.desc())
    )
    out: list[CostSplitShareOut] = []
    for share in result.scalars().unique():
        out.append(_decorate_share(share, CostSplitShareOut.model_validate(share)))
    return out
