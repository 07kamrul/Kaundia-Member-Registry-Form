"""The চাঁদা paid with the registration form is recorded as a PAID installment
on first approval so it appears in the member's চাঁদার ইতিহাস."""

from datetime import datetime, timezone
from types import SimpleNamespace

import pytest
from httpx import AsyncClient
from sqlalchemy import select

from app.models.admin import AdminUser
from app.models.installment import Installment, InstallmentStatus
from app.services.registration_installment import (
    build_registration_installment,
    parse_registration_paid_at,
)
from tests.test_admin_member_management_routes import _admin_headers, _submit


def _member(subscription: str = "100", submission_date: str = "2026-09-15"):
    return SimpleNamespace(
        id=7,
        subscription=subscription,
        submission_date=submission_date,
        reviewed_at=datetime(2026, 10, 2, tzinfo=timezone.utc),
    )


def test_builds_paid_installment_for_submission_month() -> None:
    installment = build_registration_installment(_member())

    assert installment is not None
    assert (installment.member_id, installment.year, installment.month) == (7, 2026, 9)
    assert float(installment.amount) == 100.0
    assert installment.status == InstallmentStatus.PAID
    assert installment.paid_at == datetime(2026, 9, 15, tzinfo=timezone.utc)


@pytest.mark.parametrize("amount", ["0", "-5", "abc", ""])
def test_returns_none_for_unusable_amount(amount: str) -> None:
    assert build_registration_installment(_member(subscription=amount)) is None


def test_falls_back_to_reviewed_at_for_unparseable_date() -> None:
    assert parse_registration_paid_at(_member(submission_date="not a date")) == (
        datetime(2026, 10, 2, tzinfo=timezone.utc)
    )


@pytest.mark.asyncio
async def test_first_approval_records_registration_installment(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    member_pk = (await _submit(client))["id"]
    headers = await _admin_headers(client)

    response = await client.post(f"/api/admin/submissions/{member_pk}/approve", headers=headers)
    assert response.status_code == 200

    rows = (
        await db_session.execute(select(Installment).where(Installment.member_id == member_pk))
    ).scalars().all()
    assert len(rows) == 1
    assert (rows[0].year, rows[0].month) == (2026, 9)
    assert rows[0].status == InstallmentStatus.PAID


@pytest.mark.asyncio
async def test_approval_does_not_duplicate_existing_month(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    member_pk = (await _submit(client))["id"]
    headers = await _admin_headers(client)
    db_session.add(Installment(member_id=member_pk, year=2026, month=9, amount=100))
    await db_session.commit()

    await client.post(f"/api/admin/submissions/{member_pk}/approve", headers=headers)

    rows = (
        await db_session.execute(select(Installment).where(Installment.member_id == member_pk))
    ).scalars().all()
    assert len(rows) == 1
