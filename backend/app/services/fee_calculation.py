from dataclasses import dataclass
from datetime import date
from decimal import Decimal

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


@dataclass(frozen=True)
class MonthlySubscriptionBreakdown:
    base: Decimal
    extra_decimals: Decimal
    extra_amount: Decimal
    total: Decimal


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


async def calculate_monthly_subscription(
    db: AsyncSession, land_size_decimal: Decimal, billing_date: date
) -> MonthlySubscriptionBreakdown:
    """Tiered monthly subscription fee for a land size (in decimal, the land
    area unit): `base_amount` covers up to `base_threshold` decimals, and each
    decimal beyond that costs `additional_rate`, proportionally for fractions.
    """
    if land_size_decimal < 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Land size must not be negative",
        )

    base_amount = await resolve_active_fee_decimal(db, MONTHLY_SUBSCRIPTION_BASE_AMOUNT_KEY, billing_date)
    additional_rate = await resolve_active_fee_decimal(
        db, MONTHLY_SUBSCRIPTION_ADDITIONAL_RATE_KEY, billing_date
    )
    base_threshold = await resolve_active_fee_decimal(
        db, MONTHLY_SUBSCRIPTION_BASE_THRESHOLD_KEY, billing_date
    )

    if land_size_decimal <= base_threshold:
        return MonthlySubscriptionBreakdown(
            base=base_amount,
            extra_decimals=Decimal("0"),
            extra_amount=Decimal("0"),
            total=base_amount,
        )

    extra_decimals = land_size_decimal - base_threshold
    extra_amount = extra_decimals * additional_rate
    return MonthlySubscriptionBreakdown(
        base=base_amount,
        extra_decimals=extra_decimals,
        extra_amount=extra_amount,
        total=base_amount + extra_amount,
    )
