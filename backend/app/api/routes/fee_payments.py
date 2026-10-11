from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import AccountActor, get_account_actor
from app.core.security import ADMIN_ROLES
from app.core.permissions import require_permission
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.fee_payment import FeePayment
from app.models.picnic_payment import PicnicPayment
from app.schemas.fee_payment import FeePaymentIn, FeePaymentOut, FeeTypeOut
from app.services.fee_calculation import resolve_active_fee_versions
from app.services.fee_catalog import FEE_TYPES

router = APIRouter(tags=["fee-payments"])

FEE_MANAGER_PAYMENT_MESSAGE = "Fee managers cannot make member payments."


def _reject_fee_manager(actor: AccountActor) -> None:
    """Same split as picnic/installment payments: admin-tier accounts review
    the ledger, they never pay as members."""
    if actor.admin is not None and actor.role in ADMIN_ROLES:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=FEE_MANAGER_PAYMENT_MESSAGE,
        )


def _require_paying_member(actor: AccountActor):
    if actor.member is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only accounts linked to a member profile can record fee payments.",
        )
    return actor.member


async def _fee_type_catalog(db: AsyncSession, on_date: date) -> list[FeeTypeOut]:
    """Suggested amounts for every fee type, resolved in one query against the
    FeeSetting versions effective on `on_date`; unconfigured types return a
    null amount instead of failing the whole catalog."""
    keys = tuple(ft.setting_key for ft in FEE_TYPES if ft.setting_key is not None)
    versions = await resolve_active_fee_versions(db, keys, on_date) if keys else None
    catalog: list[FeeTypeOut] = []
    for fee_type in FEE_TYPES:
        amount = None
        unit = None
        if fee_type.setting_key and versions and fee_type.setting_key in versions:
            row = versions[fee_type.setting_key]
            amount = float(row.value)
            unit = row.unit or "taka"
        catalog.append(FeeTypeOut(key=fee_type.key, default_amount=amount, unit=unit))
    return catalog


@router.get("/member/fee-types", response_model=list[FeeTypeOut])
async def list_fee_types(
    payment_date: date | None = Query(default=None),
    _actor: AccountActor = Depends(get_account_actor),
    db: AsyncSession = Depends(get_db),
) -> list[FeeTypeOut]:
    """Members and committee/admin accounts can all read the catalog; the
    suggested amounts are only ever changed through Fee Settings."""
    return await _fee_type_catalog(db, payment_date or date.today())


@router.get("/member/fee-payments", response_model=list[FeePaymentOut])
async def list_my_fee_payments(
    actor: AccountActor = Depends(get_account_actor),
    db: AsyncSession = Depends(get_db),
) -> list[FeePayment]:
    _reject_fee_manager(actor)
    member = _require_paying_member(actor)
    result = await db.execute(
        select(FeePayment)
        .where(FeePayment.member_id == member.id)
        .order_by(FeePayment.payment_date.desc(), FeePayment.id.desc())
    )
    return list(result.scalars().all())


@router.post(
    "/member/fee-payments",
    response_model=FeePaymentOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_fee_payment(
    payload: FeePaymentIn,
    actor: AccountActor = Depends(get_account_actor),
    db: AsyncSession = Depends(get_db),
) -> FeePayment:
    _reject_fee_manager(actor)
    member = _require_paying_member(actor)
    if payload.payment_date > date.today():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Payment date cannot be in the future.",
        )
    payment = FeePayment(
        member_id=member.id,
        fee_type=payload.fee_type,
        amount=payload.amount,
        payment_date=payload.payment_date,
        receipt_no=payload.receipt_no,
        payment_method=payload.payment_method,
        note=payload.note,
    )
    db.add(payment)
    await db.commit()
    await db.refresh(payment)
    return payment


@router.get("/admin/fee-payments")
async def list_fee_payments(
    member_id: int | None = Query(default=None),
    fee_type: str | None = Query(default=None),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
    _admin: AdminUser = Depends(require_permission("member.view_all")),
    db: AsyncSession = Depends(get_db),
) -> dict:
    conditions = [
        condition
        for condition in (
            FeePayment.member_id == member_id if member_id is not None else None,
            FeePayment.fee_type == fee_type if fee_type is not None else None,
            FeePayment.payment_date >= date_from if date_from is not None else None,
            FeePayment.payment_date <= date_to if date_to is not None else None,
        )
        if condition is not None
    ]
    result = await db.execute(
        select(FeePayment)
        .where(*conditions)
        .order_by(FeePayment.payment_date.desc(), FeePayment.id.desc())
    )
    payments = result.scalars().all()
    items = [
        {
            **FeePaymentOut.model_validate(payment).model_dump(mode="json"),
            "member_name": payment.member.full_name if payment.member else None,
            "source": "fee_payment",
        }
        for payment in payments
    ]

    # The structured picnic ledger (per-head breakdown rows) is merged in so
    # this single endpoint replaces the old standalone Picnic Payments page.
    include_picnic = fee_type is None or fee_type == "picnic"
    if include_picnic:
        picnic_conditions = [
            condition
            for condition in (
                PicnicPayment.member_id == member_id if member_id is not None else None,
                PicnicPayment.payment_date >= date_from if date_from is not None else None,
                PicnicPayment.payment_date <= date_to if date_to is not None else None,
            )
            if condition is not None
        ]
        picnic_result = await db.execute(
            select(PicnicPayment)
            .where(*picnic_conditions)
            .order_by(PicnicPayment.payment_date.desc(), PicnicPayment.id.desc())
        )
        for row in picnic_result.scalars():
            items.append(
                {
                    # Negative ids keep picnic-ledger rows from colliding with
                    # fee_payments ids in the client's trackBy keys.
                    "id": -row.id,
                    "member_id": row.member_id,
                    "fee_type": "picnic",
                    "amount": row.total,
                    "payment_date": row.payment_date,
                    "receipt_no": row.receipt_no,
                    "payment_method": row.payment_method,
                    "note": (
                        f"Head ৳{row.head_price:g} + {row.additional_count}"
                        f" additional × ৳{row.additional_price:g}"
                    ),
                    "created_at": row.created_at,
                    "member_name": row.member.full_name if row.member else None,
                    "additional_heads": row.additional_count,
                    "source": "picnic_payment",
                }
            )
        # payment_date is a string on fee_payment rows (JSON schema dump) and a
        # date on picnic rows; ISO strings and dates sort identically.
        items.sort(key=lambda item: (str(item["payment_date"]), item["id"]), reverse=True)
        count = len(items)
        total_collected = sum(float(item["amount"] or 0) for item in items)
    else:
        summary_query = select(
            func.count(FeePayment.id), func.coalesce(func.sum(FeePayment.amount), 0)
        ).where(*conditions)
        count, total_collected = (await db.execute(summary_query)).one()

    return {
        "items": items,
        "total_collected": float(total_collected),
        "count": count,
    }
