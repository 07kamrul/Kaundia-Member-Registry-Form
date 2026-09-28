from datetime import date

import pytest
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.fee_settings import FeeSetting
from app.services.fee_calculation import (
    PICNIC_ADDITIONAL_HEAD_FEE_KEY,
    PICNIC_HEAD_FEE_KEY,
    PICNIC_MAX_ADDITIONAL_HEADS,
    calculate_picnic_fee,
)


async def _seed_picnic_rates(
    db_session: AsyncSession,
    *,
    head: str = "500",
    additional: str = "300",
    start_date: date = date(2000, 1, 1),
    end_date: date | None = None,
) -> None:
    db_session.add_all(
        [
            FeeSetting(
                key=PICNIC_HEAD_FEE_KEY,
                value=head,
                unit="taka",
                start_date=start_date,
                end_date=end_date,
            ),
            FeeSetting(
                key=PICNIC_ADDITIONAL_HEAD_FEE_KEY,
                value=additional,
                unit="taka",
                start_date=start_date,
                end_date=end_date,
            ),
        ]
    )
    await db_session.commit()


@pytest.mark.parametrize(
    "additional_heads,expected_total",
    [
        (0, "500"),
        (1, "800"),
        (2, "1100"),
        (4, "1700"),
    ],
)
@pytest.mark.asyncio
async def test_calculate_picnic_fee_examples(
    db_session: AsyncSession, additional_heads: int, expected_total: str
) -> None:
    await _seed_picnic_rates(db_session)

    breakdown = await calculate_picnic_fee(db_session, additional_heads, date(2026, 1, 1))

    assert breakdown.head_price == 500
    assert breakdown.additional_price == 300
    assert breakdown.additional_count == additional_heads
    assert breakdown.additional_amount == 300 * additional_heads
    assert breakdown.total == int(expected_total)


@pytest.mark.asyncio
async def test_calculate_picnic_fee_zero_additional_is_member_only(db_session: AsyncSession) -> None:
    await _seed_picnic_rates(db_session)

    breakdown = await calculate_picnic_fee(db_session, 0, date(2026, 1, 1))

    assert breakdown.additional_amount == 0
    assert breakdown.total == breakdown.head_price


@pytest.mark.asyncio
async def test_calculate_picnic_fee_rejects_negative_heads(db_session: AsyncSession) -> None:
    await _seed_picnic_rates(db_session)

    with pytest.raises(HTTPException) as exc_info:
        await calculate_picnic_fee(db_session, -1, date(2026, 1, 1))

    assert exc_info.value.status_code == 422


@pytest.mark.asyncio
async def test_calculate_picnic_fee_rejects_non_integer_heads(db_session: AsyncSession) -> None:
    await _seed_picnic_rates(db_session)

    with pytest.raises(HTTPException) as exc_info:
        await calculate_picnic_fee(db_session, 1.5, date(2026, 1, 1))

    assert exc_info.value.status_code == 422


@pytest.mark.asyncio
async def test_calculate_picnic_fee_rejects_heads_above_cap(db_session: AsyncSession) -> None:
    await _seed_picnic_rates(db_session)

    with pytest.raises(HTTPException) as exc_info:
        await calculate_picnic_fee(db_session, PICNIC_MAX_ADDITIONAL_HEADS + 1, date(2026, 1, 1))

    assert exc_info.value.status_code == 422


@pytest.mark.asyncio
async def test_calculate_picnic_fee_uses_rates_effective_on_payment_date(
    db_session: AsyncSession,
) -> None:
    # A rate change on Jul 1: additional head goes from 300 to 400.
    await _seed_picnic_rates(
        db_session, start_date=date(2026, 1, 1), end_date=date(2026, 6, 30)
    )
    await _seed_picnic_rates(
        db_session, head="500", additional="400", start_date=date(2026, 7, 1)
    )

    before_change = await calculate_picnic_fee(db_session, 2, date(2026, 3, 1))
    after_change = await calculate_picnic_fee(db_session, 2, date(2026, 8, 1))

    assert before_change.total == 1100
    assert after_change.additional_price == 400
    assert after_change.total == 1300


@pytest.mark.asyncio
async def test_calculate_picnic_fee_requires_configured_fees(db_session: AsyncSession) -> None:
    with pytest.raises(HTTPException) as exc_info:
        await calculate_picnic_fee(db_session, 1, date(2026, 1, 1))

    assert exc_info.value.status_code == 409
