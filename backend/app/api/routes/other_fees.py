"""Member "Other Fees" endpoints plus the generalized admin ledger.

Replaces the picnic-only page: one catalog of non-installment fee types
(driven by fee_settings.fee_category), one server-recomputed payment
endpoint, and one combined history. The picnic payment path reuses the
existing per-head calculation and table unchanged.
"""

from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import AccountActor, get_account_actor
from app.core.security import ADMIN_ROLES
from app.core.permissions import require_permission
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.member import Member
from app.schemas.other_fees import (
    AdminOtherFeeHistoryPage,
    OtherFeeHistoryPage,
    OtherFeePaymentIn,
    OtherFeeTypeOut,
)
from app.services.other_fees import (
    create_other_fee_payment as create_other_fee_payment_record,
    other_fee_history,
    other_fee_payment_out,
    resolve_other_fee_types,
)

router = APIRouter(tags=["other-fees"])


def _reject_fee_manager(actor: AccountActor) -> None:
    """Same split as picnic/installment payments: admin-tier accounts review
    the ledger, they never pay as members."""
    if actor.admin is not None and actor.role in ADMIN_ROLES:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Fee managers cannot make member payments.",
        )


def _require_paying_member(actor: AccountActor) -> Member:
    if actor.member is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only accounts linked to a member profile can record fee payments.",
        )
    return actor.member


@router.get("/member/other-fees/types", response_model=list[OtherFeeTypeOut])
async def list_other_fee_types(
    payment_date: date | None = Query(default=None),
    actor: AccountActor = Depends(get_account_actor),
    db: AsyncSession = Depends(get_db),
) -> list[OtherFeeTypeOut]:
    """Non-installment fee types with their current rates. Members get the
    pay-once flags resolved against their own record; committee/admin
    accounts see the same catalog with `already_paid` left null."""
    types = await resolve_other_fee_types(
        db, payment_date or date.today(), member=actor.member
    )
    return [OtherFeeTypeOut(**fee_type) for fee_type in types]


@router.get("/member/other-fees/payments", response_model=OtherFeeHistoryPage)
async def list_my_other_fee_payments(
    fee_type: str | None = Query(default=None),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    actor: AccountActor = Depends(get_account_actor),
    db: AsyncSession = Depends(get_db),
) -> OtherFeeHistoryPage:
    """The caller's own combined history across every non-installment fee
    type (picnic rows included, installments never)."""
    _reject_fee_manager(actor)
    member = _require_paying_member(actor)
    result = await other_fee_history(
        db,
        member_id=member.id,
        fee_type=fee_type,
        date_from=date_from,
        date_to=date_to,
        page=page,
        page_size=page_size,
    )
    return OtherFeeHistoryPage(**result)


@router.post(
    "/member/other-fees/payments",
    status_code=status.HTTP_201_CREATED,
)
async def create_other_fee_payment(
    payload: OtherFeePaymentIn,
    actor: AccountActor = Depends(get_account_actor),
    db: AsyncSession = Depends(get_db),
) -> dict:
    _reject_fee_manager(actor)
    member = _require_paying_member(actor)
    payment = await create_other_fee_payment_record(db, member, payload)
    db.add(payment)
    await db.commit()
    await db.refresh(payment)
    return other_fee_payment_out(payment)


@router.get("/admin/other-fees/payments", response_model=AdminOtherFeeHistoryPage)
async def list_all_other_fee_payments(
    member_id: int | None = Query(default=None),
    fee_type: str | None = Query(default=None),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    _admin: AdminUser = Depends(require_permission("member.view_all")),
    db: AsyncSession = Depends(get_db),
) -> AdminOtherFeeHistoryPage:
    """All members' non-installment payments with filters, pagination and a
    collection summary - the picnic ledger generalized to every fee type."""
    result = await other_fee_history(
        db,
        member_id=member_id,
        fee_type=fee_type,
        date_from=date_from,
        date_to=date_to,
        page=page,
        page_size=page_size,
    )
    # Batch-resolve display names for the page's rows only.
    row_member_ids = {row["member_id"] for row in result["items"]}
    names: dict[int, str] = {}
    if row_member_ids:
        rows = await db.execute(
            select(Member.id, Member.full_name).where(Member.id.in_(row_member_ids))
        )
        names = {row_id: full_name for row_id, full_name in rows.all()}
    result["items"] = [
        {**row, "member_name": names.get(row["member_id"])} for row in result["items"]
    ]
    return AdminOtherFeeHistoryPage(**result)
