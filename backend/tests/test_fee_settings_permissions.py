"""Fee Settings authorization: super_admin must be able to manage fee versions
exactly like the committee/administrator tiers, while plain members are
rejected on the write endpoints."""

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.admin import AdminRole, AdminUser
from app.models.audit_log import AuditLog
from app.models.member import Member
from sqlalchemy import select

pytestmark = pytest.mark.asyncio


async def _seed_admin(db_session: AsyncSession, role: AdminRole, email: str) -> AdminUser:
    from app.core.security import hash_password

    admin = AdminUser(
        email=email,
        password_hash=hash_password("pass12345"),
        name=email,
        role=role,
    )
    db_session.add(admin)
    await db_session.commit()
    await db_session.refresh(admin)
    return admin


async def _seed_member(db_session: AsyncSession, email: str) -> Member:
    member = Member(
        status="approved",
        full_name="Member",
        father_or_husband="father",
        mother="mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="job",
        nid=str(abs(hash(email)) % 10**10),
        mobile="0170000000",
        gender="male",
        email=email,
        admission_fee="500",
        subscription="100",
        receipt_no="r",
        payment_method="cash",
        submission_date="2026-01-01",
    )
    db_session.add(member)
    await db_session.commit()
    await db_session.refresh(member)
    return member


def _auth_header(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


async def test_super_admin_can_create_picnic_fee_versions_and_read_history(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    admin = await _seed_admin(db_session, AdminRole.SUPER_ADMIN, "superfee@example.com")
    headers = _auth_header(create_access_token(str(admin.id), AdminRole.SUPER_ADMIN.value))

    head = await client.post(
        "/api/admin/fee-settings",
        headers=headers,
        json={"key": "picnic_head_fee", "value": 500, "unit": "taka", "start_date": "2026-01-01"},
    )
    additional = await client.post(
        "/api/admin/fee-settings",
        headers=headers,
        json={
            "key": "picnic_additional_head_fee",
            "value": 300,
            "unit": "taka",
            "start_date": "2026-01-01",
        },
    )

    assert head.status_code == 201
    assert additional.status_code == 201

    history = await client.get(
        "/api/admin/fee-settings/picnic_head_fee/history", headers=headers
    )
    assert history.status_code == 200
    assert len(history.json()) == 1

    active = await client.get("/api/admin/fee-settings", headers=headers)
    assert active.status_code == 200
    keys = {row["key"] for row in active.json()}
    assert {"picnic_head_fee", "picnic_additional_head_fee"} <= keys


async def test_super_admin_fee_change_is_audited_with_role(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    admin = await _seed_admin(db_session, AdminRole.SUPER_ADMIN, "superaudit@example.com")
    headers = _auth_header(create_access_token(str(admin.id), AdminRole.SUPER_ADMIN.value))

    response = await client.post(
        "/api/admin/fee-settings",
        headers=headers,
        json={"key": "picnic_head_fee", "value": 500, "unit": "taka"},
    )
    assert response.status_code == 201

    result = await db_session.execute(select(AuditLog).where(AuditLog.action == "fee_settings.new_version"))
    entry = result.scalar_one()
    assert entry.actor_admin_id == admin.id
    assert "role=super_admin" in entry.detail
    assert "value=500" in entry.detail


@pytest.mark.parametrize(
    "role,email",
    [
        (AdminRole.EXECUTIVE_COMMITTEE, "committee-fee@example.com"),
        (AdminRole.ADMINISTRATOR, "administrator-fee@example.com"),
    ],
)
async def test_other_admin_roles_can_still_create_fee_versions(
    client: AsyncClient, db_session: AsyncSession, role: AdminRole, email: str
) -> None:
    admin = await _seed_admin(db_session, role, email)
    response = await client.post(
        "/api/admin/fee-settings",
        headers=_auth_header(create_access_token(str(admin.id), role.value)),
        json={"key": "picnic_head_fee", "value": 500, "unit": "taka"},
    )
    assert response.status_code == 201


async def test_member_cannot_create_fee_version(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    member = await _seed_member(db_session, "plain-member@example.com")
    response = await client.post(
        "/api/admin/fee-settings",
        headers=_auth_header(create_access_token(str(member.id), "member")),
        json={"key": "picnic_head_fee", "value": 500, "unit": "taka"},
    )
    assert response.status_code == 403


@pytest.mark.parametrize(
    "role_value",
    ["SuperAdmin", "SUPER_ADMIN", "super-admin"],
)
async def test_role_claim_normalization_still_grants_super_admin(
    client: AsyncClient, db_session: AsyncSession, role_value: str
) -> None:
    """Tokens whose role claim uses a different casing/separator still resolve
    to the super_admin path (rates readable, payments listable)."""
    admin = await _seed_admin(db_session, AdminRole.SUPER_ADMIN, "normalized@example.com")
    headers = _auth_header(create_access_token(str(admin.id), role_value))

    rates = await client.get("/api/member/picnic-rates", headers=headers)
    assert rates.status_code == 404  # not configured, but authenticated + authorized

    payments = await client.get("/api/member/picnic-payments", headers=headers)
    assert payments.status_code == 403
    assert payments.json()["detail"] == "Fee managers cannot make member payments."
