"""Business logic for the unified member "Other Fees" page.

Every non-installment fee lives here: fixed amounts resolved from Fee
Settings (`fee_<key>_amount` versions), variable amounts entered by the
member (donation, extra, and any newly configured type without a rate), and
the special per-head picnic calculation. Installment fees are excluded by
the `fee_settings.fee_category` flag, never by a hard-coded name list.
"""

from datetime import date
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import func, literal, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.fee_payment import FeePayment
from app.models.fee_settings import FeeSetting, FeeType
from app.models.member import Member
from app.models.picnic_payment import PicnicPayment
from app.services.fee_calculation import (
    PICNIC_MAX_ADDITIONAL_HEADS,
    calculate_picnic_fee,
    resolve_picnic_rates,
)
from app.services.fee_catalog import CALC_FIXED, CALC_VARIABLE, CATEGORY_OTHER

SETTING_PREFIX = "fee_"
SETTING_SUFFIX = "_amount"
ADMISSION_FEE_KEY = "admission_fee"
INSTALLMENT_FEE_TYPE = "installment"

# Code-defined types offered even when no rate version exists (the member
# then enters the amount themselves). Everything else is discovered from
# active `fee_<key>_amount` settings, so committee-added types need no code.
ALWAYS_VARIABLE_TYPES = ("donation", "extra")

HISTORY_DEFAULT_PAGE_SIZE = 20
HISTORY_MAX_PAGE_SIZE = 100

MAX_VARIABLE_AMOUNT = Decimal("10000000")


def _humanize(key: str) -> str:
    return key.replace("_", " ").strip().title()


async def _active_setting(db: AsyncSession, key: str, on_date: date) -> FeeSetting | None:
    result = await db.execute(
        select(FeeSetting)
        .where(
            FeeSetting.key == key,
            FeeSetting.start_date <= on_date,
            or_(FeeSetting.end_date.is_(None), FeeSetting.end_date >= on_date),
        )
        .order_by(FeeSetting.start_date.desc(), FeeSetting.id.desc())
        .limit(1)
    )
    return result.scalar_one_or_none()


async def _variable_bounds(
    db: AsyncSession, fee_key: str, on_date: date
) -> tuple[Decimal | None, Decimal | None]:
    """Optional min/max bounds configured for a variable fee type (its version
    rows under `<key>_min` / `<key>_max`)."""
    minimum = await _active_setting(db, f"{fee_key}_min", on_date)
    maximum = await _active_setting(db, f"{fee_key}_max", on_date)
    return (
        Decimal(str(minimum.value)) if minimum is not None else None,
        Decimal(str(maximum.value)) if maximum is not None else None,
    )


async def resolve_other_fee_types(
    db: AsyncSession, on_date: date, member: Member | None = None
) -> list[dict]:
    """The payable catalog for the Other Fees page, rates resolved as of
    `on_date`. `member` (when given) marks pay-once types already settled."""
    types: dict[str, dict] = {}

    # Fixed types straight from Fee Settings - config-driven, so a newly
    # added `fee_<key>_amount` version appears without any code change.
    result = await db.execute(
        select(FeeSetting)
        .where(
            FeeSetting.key.like(f"{SETTING_PREFIX}%{SETTING_SUFFIX}"),
            FeeSetting.fee_category == "other",
            FeeSetting.start_date <= on_date,
            or_(FeeSetting.end_date.is_(None), FeeSetting.end_date >= on_date),
        )
        .order_by(FeeSetting.start_date.desc(), FeeSetting.id.desc())
    )
    seen: set[str] = set()
    for row in result.scalars():
        if row.key in seen:  # newest start_date already won for this key
            continue
        seen.add(row.key)
        key = row.key[len(SETTING_PREFIX) : -len(SETTING_SUFFIX)]
        if key == "picnic" or key == INSTALLMENT_FEE_TYPE:
            continue  # picnic is assembled from its two rate keys below
        types[key] = {
            "key": key,
            "label": _humanize(key),
            "calculation": "fixed",
            "amount": float(row.value),
            "unit": row.unit,
            "pay_once": False,
            "already_paid": None,
        }

    for key in ALWAYS_VARIABLE_TYPES:
        if key not in types:
            types[key] = {
                "key": key,
                "label": _humanize(key),
                "calculation": "variable",
                "amount": None,
                "unit": None,
                "pay_once": False,
                "already_paid": None,
            }

    # Fee-type catalog entries (Fee Settings "New Fee Type") - config-driven,
    # so a fee type the committee adds appears here without any code change.
    # head_additional types are skipped: per-head quoting is picnic-specific
    # and assembled from its two rate keys below.
    catalog = await db.execute(
        select(FeeType).where(FeeType.is_active.is_(True), FeeType.fee_category == CATEGORY_OTHER)
    )
    for fee_type in catalog.scalars():
        if fee_type.key in types or fee_type.calculation_type not in (CALC_FIXED, CALC_VARIABLE):
            continue
        if fee_type.calculation_type == CALC_VARIABLE:
            types[fee_type.key] = {
                "key": fee_type.key,
                "label": fee_type.label_bn,
                "calculation": "variable",
                "amount": None,
                "unit": fee_type.unit,
                "pay_once": fee_type.is_pay_once,
                "already_paid": None,
            }
            continue
        setting = await _active_setting(db, fee_type.key, on_date)
        if setting is None:
            continue  # no active version yet - not payable
        types[fee_type.key] = {
            "key": fee_type.key,
            "label": fee_type.label_bn,
            "calculation": "fixed",
            "amount": float(setting.value),
            "unit": setting.unit or fee_type.unit,
            "pay_once": fee_type.is_pay_once,
            "already_paid": None,
        }

    # Admission fee: fixed, pay-once, settled at registration for every
    # approved member - shown as a paid status card rather than a form.
    admission = await _active_setting(db, ADMISSION_FEE_KEY, on_date)
    types["admission"] = {
        "key": "admission",
        "label": _humanize("admission_fee"),
        "calculation": "fixed",
        "amount": float(admission.value) if admission is not None else None,
        "unit": admission.unit if admission is not None else None,
        "pay_once": True,
        "already_paid": member.admission_fee is not None if member is not None else None,
    }

    rates = await resolve_picnic_rates(db, on_date)
    types["picnic"] = {
        "key": "picnic",
        "label": _humanize("picnic"),
        "calculation": "picnic",
        "amount": None,
        "unit": rates["unit"] if rates else None,
        "pay_once": False,
        "already_paid": None,
        "head_fee": float(rates["head_fee"]) if rates else None,
        "additional_head_fee": float(rates["additional_head_fee"]) if rates else None,
    }

    return [types[key] for key in sorted(types)]


async def create_other_fee_payment(
    db: AsyncSession, member: Member, payload
) -> FeePayment | PicnicPayment:
    """Validate + persist one other-fee payment. Fixed and picnic totals are
    always recomputed server-side; only variable types accept a client
    amount, and even that is validated against the sanity cap."""
    if payload.fee_type == INSTALLMENT_FEE_TYPE:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "code": "INSTALLMENT_NOT_PAYABLE_HERE",
                "message": "Installment payments are recorded on the Installments page.",
            },
        )

    if payload.payment_date > date.today():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Payment date cannot be in the future.",
        )

    if payload.fee_type == "picnic":
        heads = payload.additional_heads if payload.additional_heads is not None else 0
        breakdown = await calculate_picnic_fee(db, heads, payload.payment_date)
        people = payload.additional_people or None
        return PicnicPayment(
            member_id=member.id,
            head_price=breakdown.head_price,
            additional_price=breakdown.additional_price,
            additional_count=breakdown.additional_count,
            total=breakdown.total,
            additional_heads=people,
            payment_date=payload.payment_date,
            receipt_no=payload.receipt_no,
            payment_method=payload.payment_method,
        )

    if payload.fee_type == "admission":
        if member.admission_fee is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "code": "ADMISSION_FEE_ALREADY_PAID",
                    "message": "The admission fee was already paid at registration.",
                },
            )
        setting = await _active_setting(db, ADMISSION_FEE_KEY, payload.payment_date)
        if setting is None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "code": "RATE_NOT_CONFIGURED",
                    "message": "This fee has no active rate configured. Please contact the committee.",
                },
            )
        return FeePayment(
            member_id=member.id,
            fee_type="admission",
            amount=Decimal(str(setting.value)),
            payment_date=payload.payment_date,
            receipt_no=payload.receipt_no,
            payment_method=payload.payment_method,
            note=payload.note,
        )

    # Every other type: fixed when a rate version covers the payment date,
    # variable otherwise. The client-sent amount is only ever consulted for
    # the variable case (validated against the optional `<key>_min` /
    # `<key>_max` fee-setting bounds when configured). Rates are resolved
    # first from the fee-type catalog key (new fee types), then the legacy
    # `fee_<key>_amount` alias.
    catalog_result = await db.execute(select(FeeType).where(FeeType.key == payload.fee_type))
    fee_type_def = catalog_result.scalar_one_or_none()
    setting = None
    for candidate in (
        (payload.fee_type,)
        if fee_type_def is not None
        else (f"{SETTING_PREFIX}{payload.fee_type}{SETTING_SUFFIX}",)
    ):
        setting = await _active_setting(db, candidate, payload.payment_date)
        if setting is not None:
            break
    if setting is None and fee_type_def is not None and fee_type_def.calculation_type == CALC_FIXED:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "RATE_NOT_CONFIGURED",
                "message": "This fee has no active rate configured. Please contact the committee.",
            },
        )
    if setting is not None:
        amount = Decimal(str(setting.value))
    else:
        if payload.amount is None or payload.amount <= 0:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail={
                    "code": "AMOUNT_REQUIRED",
                    "message": "This fee type has no configured rate - a positive amount is required.",
                },
            )
        if payload.amount > MAX_VARIABLE_AMOUNT:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail={
                    "code": "AMOUNT_TOO_LARGE",
                    "message": "Amount is unreasonably large.",
                },
            )
        amount = payload.amount
        minimum, maximum = await _variable_bounds(db, payload.fee_type, payload.payment_date)
        if minimum is not None and amount < minimum:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail={
                    "code": "AMOUNT_BELOW_MINIMUM",
                    "message": f"Amount is below the configured minimum ({minimum}).",
                },
            )
        if maximum is not None and amount > maximum:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail={
                    "code": "AMOUNT_ABOVE_MAXIMUM",
                    "message": f"Amount is above the configured maximum ({maximum}).",
                },
            )

    return FeePayment(
        member_id=member.id,
        fee_type=payload.fee_type,
        amount=amount,
        payment_date=payload.payment_date,
        receipt_no=payload.receipt_no,
        payment_method=payload.payment_method,
        note=payload.note,
    )


def other_fee_payment_out(payment: FeePayment | PicnicPayment) -> dict:
    """Row shape shared by the member history, the member create response and
    the admin ledger - picnic rows are tagged fee_type='picnic'."""
    if isinstance(payment, PicnicPayment):
        return {
            "id": payment.id,
            "source": "picnic_payment",
            "fee_type": "picnic",
            "amount": payment.total,
            "payment_date": payment.payment_date,
            "additional_heads": payment.additional_count,
            "receipt_no": payment.receipt_no,
            "payment_method": payment.payment_method,
            "note": None,
            "created_at": payment.created_at,
        }
    return {
        "id": payment.id,
        "source": "fee_payment",
        "fee_type": payment.fee_type,
        "amount": payment.amount,
        "payment_date": payment.payment_date,
        "additional_heads": None,
        "receipt_no": payment.receipt_no,
        "payment_method": payment.payment_method,
        "note": payment.note,
        "created_at": payment.created_at,
    }


async def other_fee_history(
    db: AsyncSession,
    *,
    member_id: int | None = None,
    fee_type: str | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
    page: int = 1,
    page_size: int = HISTORY_DEFAULT_PAGE_SIZE,
) -> dict:
    """Combined paginated history across all non-installment fee types -
    `fee_payments` rows plus the legacy picnic ledger, newest first.
    Installment-tagged rows are excluded even if the filter is abused."""
    page = max(1, page)
    page_size = min(max(1, page_size), HISTORY_MAX_PAGE_SIZE)

    fee_conditions = [FeePayment.fee_type != INSTALLMENT_FEE_TYPE]
    picnic_conditions = []
    if member_id is not None:
        fee_conditions.append(FeePayment.member_id == member_id)
        picnic_conditions.append(PicnicPayment.member_id == member_id)
    if fee_type is not None and fee_type != INSTALLMENT_FEE_TYPE:
        fee_conditions.append(FeePayment.fee_type == fee_type)
        if fee_type == "picnic":
            picnic_conditions.append(literal(True))
        else:
            picnic_conditions.append(literal(False))
    if date_from is not None:
        fee_conditions.append(FeePayment.payment_date >= date_from)
        picnic_conditions.append(PicnicPayment.payment_date >= date_from)
    if date_to is not None:
        fee_conditions.append(FeePayment.payment_date <= date_to)
        picnic_conditions.append(PicnicPayment.payment_date <= date_to)

    fee_side = select(
        FeePayment.id.label("id"),
        literal("fee_payment").label("source"),
        FeePayment.member_id.label("member_id"),
        FeePayment.fee_type.label("fee_type"),
        FeePayment.amount.label("amount"),
        FeePayment.payment_date.label("payment_date"),
        literal(None).label("additional_heads"),
        FeePayment.receipt_no.label("receipt_no"),
        FeePayment.payment_method.label("payment_method"),
        FeePayment.note.label("note"),
        FeePayment.created_at.label("created_at"),
    ).where(*fee_conditions)

    picnic_side = select(
        PicnicPayment.id.label("id"),
        literal("picnic_payment").label("source"),
        PicnicPayment.member_id.label("member_id"),
        literal("picnic").label("fee_type"),
        PicnicPayment.total.label("amount"),
        PicnicPayment.payment_date.label("payment_date"),
        PicnicPayment.additional_count.label("additional_heads"),
        PicnicPayment.receipt_no.label("receipt_no"),
        PicnicPayment.payment_method.label("payment_method"),
        literal(None).label("note"),
        PicnicPayment.created_at.label("created_at"),
    ).where(*picnic_conditions)

    union = fee_side.union_all(picnic_side).subquery()
    total = (
        await db.execute(select(func.count()).select_from(union))
    ).scalar_one()

    rows = (
        await db.execute(
            select(union)
            .order_by(union.c.payment_date.desc(), union.c.source, union.c.id.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
    ).mappings().all()

    summary_query = select(
        func.coalesce(func.sum(union.c.amount), 0), union.c.fee_type
    ).group_by(union.c.fee_type)
    by_type: dict[str, float] = {}
    total_paid = 0.0
    for amount_sum, row_fee_type in (await db.execute(summary_query)).all():
        by_type[row_fee_type] = float(amount_sum)
        total_paid += float(amount_sum)

    return {
        "items": [dict(row) for row in rows],
        "total": total,
        "page": page,
        "page_size": page_size,
        "summary": {"total_paid": total_paid, "by_type": by_type},
    }
