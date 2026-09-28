from datetime import date
from decimal import Decimal

import pytest
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.fee_settings import FeeSetting
from app.services.fee_calculation import calculate_monthly_subscription


async def _seed_tier(
    db_session: AsyncSession,
    *,
    base: str = "100",
    rate: str = "10",
    threshold: str = "1",
    start_date: date = date(2000, 1, 1),
    end_date: date | None = None,
) -> None:
    db_session.add_all(
        [
            FeeSetting(
                key="monthly_subscription_base_amount",
                value=base,
                start_date=start_date,
                end_date=end_date,
            ),
            FeeSetting(
                key="monthly_subscription_additional_rate",
                value=rate,
                start_date=start_date,
                end_date=end_date,
            ),
            FeeSetting(
                key="monthly_subscription_base_threshold",
                value=threshold,
                start_date=start_date,
                end_date=end_date,
            ),
        ]
    )
    await db_session.commit()


@pytest.mark.parametrize(
    "land_size,expected_total",
    [
        ("0.33", "100"),
        ("0.5", "100"),
        ("1", "100"),
        ("3", "120"),
        ("10", "190"),
        ("0", "100"),
        ("1.0001", "100.001"),
    ],
)
@pytest.mark.asyncio
async def test_calculate_monthly_subscription_examples(
    db_session: AsyncSession, land_size: str, expected_total: str
) -> None:
    await _seed_tier(db_session)

    breakdown = await calculate_monthly_subscription(db_session, Decimal(land_size), date(2026, 1, 1))

    assert breakdown.total == Decimal(expected_total)


@pytest.mark.asyncio
async def test_calculate_monthly_subscription_rejects_negative_size(db_session: AsyncSession) -> None:
    await _seed_tier(db_session)

    with pytest.raises(HTTPException) as exc_info:
        await calculate_monthly_subscription(db_session, Decimal("-1"), date(2026, 1, 1))

    assert exc_info.value.status_code == 422


@pytest.mark.asyncio
async def test_calculate_monthly_subscription_returns_breakdown(db_session: AsyncSession) -> None:
    await _seed_tier(db_session)

    breakdown = await calculate_monthly_subscription(db_session, Decimal("3"), date(2026, 1, 1))

    assert breakdown.base == Decimal("100")
    assert breakdown.extra_decimals == Decimal("2")
    assert breakdown.extra_amount == Decimal("20")
    assert breakdown.total == Decimal("120")


@pytest.mark.asyncio
async def test_calculate_monthly_subscription_uses_rate_effective_on_billing_date(
    db_session: AsyncSession,
) -> None:
    # Old rate covers Jan-Jun; a mid-year change raises the additional rate from Jul onward.
    await _seed_tier(
        db_session, rate="10", start_date=date(2026, 1, 1), end_date=date(2026, 6, 30)
    )
    await _seed_tier(db_session, rate="20", start_date=date(2026, 7, 1))

    before_change = await calculate_monthly_subscription(db_session, Decimal("3"), date(2026, 3, 1))
    after_change = await calculate_monthly_subscription(db_session, Decimal("3"), date(2026, 8, 1))

    assert before_change.total == Decimal("120")
    assert after_change.total == Decimal("140")


@pytest.mark.asyncio
async def test_calculate_monthly_subscription_requires_configured_fee(db_session: AsyncSession) -> None:
    # The autouse fixture seeds default subscription rates for every test;
    # remove them here to exercise the "not configured" path specifically.
    from sqlalchemy import delete

    from app.models.fee_settings import FeeSetting
    from app.services.fee_calculation import MONTHLY_SUBSCRIPTION_FEE_KEYS

    await db_session.execute(
        delete(FeeSetting).where(FeeSetting.key.in_(MONTHLY_SUBSCRIPTION_FEE_KEYS))
    )
    await db_session.commit()

    with pytest.raises(HTTPException) as exc_info:
        await calculate_monthly_subscription(db_session, Decimal("1"), date(2026, 1, 1))

    assert exc_info.value.status_code == 409
