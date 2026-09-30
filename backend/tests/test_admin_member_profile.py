"""GET /api/admin/members/{id}: full member profile for the admin detail drawer."""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.admin import AdminRole, AdminUser
from app.models.installment import Installment, InstallmentStatus
from app.models.member import Member

pytestmark = pytest.mark.asyncio


async def _admin(db: AsyncSession, role: AdminRole, email: str) -> dict[str, str]:
    user = AdminUser(email=email, password_hash=hash_password("pass12345"), name=email, role=role)
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return {"Authorization": f"Bearer {create_access_token(str(user.id), role.value)}"}


async def _member(db: AsyncSession, email: str, reviewed_by: int | None = None) -> Member:
    member = Member(
        status="approved",
        member_id="KAM-2026-0001",
        full_name="Md. Kamrul Hasan",
        father_or_husband="father",
        mother="mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="job",
        nid="1234567890",
        mobile="01758290421",
        gender="male",
        email=email,
        admission_fee="500",
        subscription="100",
        receipt_no="r",
        payment_method="cash",
        submission_date="2026-01-01",
        reviewed_by=reviewed_by,
    )
    db.add(member)
    await db.commit()
    await db.refresh(member)
    return member


async def test_returns_full_profile_with_fee_summary(client: AsyncClient, db_session: AsyncSession) -> None:
    headers = await _admin(db_session, AdminRole.EXECUTIVE_COMMITTEE, "ec@example.com")
    member = await _member(db_session, "m1@example.com", reviewed_by=1)
    db_session.add_all(
        [
            Installment(member_id=member.id, year=2026, month=1, amount=100, status=InstallmentStatus.PAID),
            Installment(member_id=member.id, year=2026, month=2, amount=100, status=InstallmentStatus.DUE),
        ]
    )
    await db_session.commit()

    res = await client.get(f"/api/admin/members/{member.id}", headers=headers)

    assert res.status_code == 200
    body = res.json()
    assert body["member_id"] == "KAM-2026-0001"
    assert body["reviewed_by_name"] == "ec@example.com"
    assert body["fee_summary"] == {"due_count": 1, "paid_count": 1, "due_total": 100.0, "paid_total": 100.0}
    assert [i["month"] for i in body["installments"]] == [2, 1]
    assert "password_hash" not in body


async def test_unknown_member_returns_404(client: AsyncClient, db_session: AsyncSession) -> None:
    headers = await _admin(db_session, AdminRole.EXECUTIVE_COMMITTEE, "ec2@example.com")
    assert (await client.get("/api/admin/members/9999", headers=headers)).status_code == 404


async def test_administrator_without_view_all_gets_403(client: AsyncClient, db_session: AsyncSession) -> None:
    headers = await _admin(db_session, AdminRole.ADMINISTRATOR, "adm@example.com")
    member = await _member(db_session, "m2@example.com")
    assert (await client.get(f"/api/admin/members/{member.id}", headers=headers)).status_code == 403


async def test_member_token_and_anonymous_are_rejected(client: AsyncClient, db_session: AsyncSession) -> None:
    member = await _member(db_session, "m3@example.com")
    member_headers = {"Authorization": f"Bearer {create_access_token(str(member.id), 'member')}"}
    assert (await client.get(f"/api/admin/members/{member.id}", headers=member_headers)).status_code in (401, 403)
    assert (await client.get(f"/api/admin/members/{member.id}")).status_code in (401, 403)
