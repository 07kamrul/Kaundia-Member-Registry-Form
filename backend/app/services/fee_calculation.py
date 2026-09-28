from dataclasses import dataclass
from datetime import date
from decimal import ROUND_CEILING, Decimal

from fastapi import HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.fee_settings import FeeSetting

MONTHLY_SUBSCRIPTION_BASE_AMOUNT_KEY = "monthly_subscription_base_amount"
MONTHLY_SUBSCRIPTION_ADDITIONAL_RATE_KEY = "monthly_subscription_additional_rate"
MONTHLY_SUBSCRIPTION_BASE_THRESHOLD_KEY = "monthly_subscription_base_threshold"

MONTHLY_SUBSCRIPTION_FEE_KEYS = (
    MONTHLY_SUBSCRIPTION_BASE_AMOUNT_KEY,
    MONTHLY_SUBSCRIPTION_ADDITIONAL_RATE_KEY,
    MONTHLY_SUBSCRIPTION_BASE_THRESHOLD_KEY,
)

PICNIC_HEAD_FEE_KEY = "picnic_head_fee"
PICNIC_ADDITIONAL_HEAD_FEE_KEY = "picnic_additional_head_fee"

PICNIC_FEE_KEYS = (PICNIC_HEAD_FEE_KEY, PICNIC_ADDITIONAL_HEAD_FEE_KEY)

PICNIC_MAX_ADDITIONAL_HEADS = 20


@dataclass(frozen=True)
class MonthlySubscriptionBreakdown:
    base: Decimal
    extra_units: int
    extra_rate: Decimal
    extra_amount: Decimal
    total: Decimal
    unit: str = "taka"
    effective_from: date | None = None


async def resolve_active_fee_versions(
    db: AsyncSession, keys: tuple[str, ...], on_date: date
) -> dict[str, FeeSetting] | None:
    """The FeeSetting rows active on `on_date` for every key in `keys`, or
    None when any key has no active version. Shared by the calculators so the
    quote endpoint and the stored amounts always agree on which version won."""
    result = await db.execute(
        select(FeeSetting).where(
            FeeSetting.key.in_(keys),
            FeeSetting.start_date <= on_date,
            or_(FeeSetting.end_date.is_(None), FeeSetting.end_date >= on_date),
        )
    )
    versions = {row.key: row for row in result.scalars().all()}
    if any(key not in versions for key in keys):
        return None
    return versions


async def resolve_active_fee_decimal(db: AsyncSession, key: str, on_date: date) -> Decimal:
    """Fee-setting value active on `on_date`, as a Decimal. Resolved against the
    version effective on that date rather than the latest one, so historical
    calculations (e.g. past invoices) stay correct after a rate change."""
    result = await db.execute(
        select(FeeSetting.value).where(
            FeeSetting.key == key,
            FeeSetting.start_date <= on_date,
            or_(FeeSetting.end_date.is_(None), FeeSetting.end_date >= on_date),
        )
    )
    value = result.scalar_one_or_none()
    if value is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"No active fee setting configured for '{key}'",
        )
    return Decimal(str(value))


@dataclass(frozen=True)
class PicnicFeeBreakdown:
    head_price: Decimal
    additional_price: Decimal
    additional_count: int
    additional_amount: Decimal
    total: Decimal


async def resolve_picnic_rates(db: AsyncSession, on_date: date) -> dict | None:
    """The picnic rate versions effective on `on_date`, or None when either
    key has no active version - surfaced as PICNIC_RATES_NOT_CONFIGURED
    instead of a generic failure."""
    result = await db.execute(
        select(FeeSetting).where(
            FeeSetting.key.in_(PICNIC_FEE_KEYS),
            FeeSetting.start_date <= on_date,
            or_(FeeSetting.end_date.is_(None), FeeSetting.end_date >= on_date),
        )
    )
    versions = {row.key: row for row in result.scalars().all()}
    head = versions.get(PICNIC_HEAD_FEE_KEY)
    additional = versions.get(PICNIC_ADDITIONAL_HEAD_FEE_KEY)
    if head is None or additional is None:
        return None
    return {
        "head_fee": head.value,
        "additional_head_fee": additional.value,
        "unit": head.unit or additional.unit or "taka",
        "effective_from": max(head.start_date, additional.start_date),
    }


async def calculate_picnic_fee(
    db: AsyncSession, additional_heads: int, payment_date: date
) -> PicnicFeeBreakdown:
    """Picnic fee for one member seat plus `additional_heads` extra seats
    (spouse, children, guests), using the rate versions effective on
    `payment_date`. The total is always recomputed here; the client-sent
    amount is never trusted."""
    if isinstance(additional_heads, bool) or not isinstance(additional_heads, int):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Additional heads must be a whole number",
        )
    if additional_heads < 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Additional heads must not be negative",
        )
    if additional_heads > PICNIC_MAX_ADDITIONAL_HEADS:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Additional heads must not exceed {PICNIC_MAX_ADDITIONAL_HEADS}",
        )

    head_price = await resolve_active_fee_decimal(db, PICNIC_HEAD_FEE_KEY, payment_date)
    additional_price = await resolve_active_fee_decimal(
        db, PICNIC_ADDITIONAL_HEAD_FEE_KEY, payment_date
    )

    additional_amount = additional_price * additional_heads
    return PicnicFeeBreakdown(
        head_price=head_price,
        additional_price=additional_price,
        additional_count=additional_heads,
        additional_amount=additional_amount,
        total=head_price + additional_amount,
    )


async def calculate_monthly_subscription(
    db: AsyncSession, land_size_decimal: Decimal, billing_date: date
) -> MonthlySubscriptionBreakdown:
    """Tiered monthly subscription fee for a land size (in decimal, the land
    area unit): `base_amount` covers up to `base_threshold` decimals, and every
    decimal beyond that - including any partial fraction of a decimal - is
    charged in full at `additional_rate`, rounded up to the next whole decimal.
    """
    versions = await resolve_active_fee_versions(
        db, MONTHLY_SUBSCRIPTION_FEE_KEYS, billing_date
    )
    if versions is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "SUBSCRIPTION_RATES_NOT_CONFIGURED",
                    "message": "Monthly subscription rates are not configured"},
        )

    base_amount = Decimal(str(versions[MONTHLY_SUBSCRIPTION_BASE_AMOUNT_KEY].value))
    additional_rate = Decimal(str(versions[MONTHLY_SUBSCRIPTION_ADDITIONAL_RATE_KEY].value))
    base_threshold = Decimal(str(versions[MONTHLY_SUBSCRIPTION_BASE_THRESHOLD_KEY].value))
    effective_from = max(row.start_date for row in versions.values())
    unit = versions[MONTHLY_SUBSCRIPTION_BASE_AMOUNT_KEY].unit or "taka"

    if land_size_decimal <= 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Land size must be greater than zero",
        )

    if land_size_decimal <= base_threshold:
        return MonthlySubscriptionBreakdown(
            base=base_amount,
            extra_units=0,
            extra_rate=additional_rate,
            extra_amount=Decimal("0"),
            total=base_amount,
            unit=unit,
            effective_from=effective_from,
        )

    extra_units = int(
        (land_size_decimal - base_threshold).to_integral_value(rounding=ROUND_CEILING)
    )
    extra_amount = extra_units * additional_rate
    return MonthlySubscriptionBreakdown(
        base=base_amount,
        extra_units=extra_units,
        extra_rate=additional_rate,
        extra_amount=extra_amount,
        total=base_amount + extra_amount,
        unit=unit,
        effective_from=effective_from,
    )
