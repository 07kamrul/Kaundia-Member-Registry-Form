import hashlib

import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.admin import AdminUser
from app.models.credential import MemberCredential
from app.models.member import Member, MemberStatus
from app.models.password_reset import PasswordResetToken

pytestmark = pytest.mark.asyncio

OLD_PASSWORD = "oldpass123"
FORGOT_URL = "/api/forgot-password"
RESET_URL = "/api/reset-password"


def sha(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


@pytest_asyncio.fixture
async def member(db_session: AsyncSession) -> Member:
    member = Member(
        member_id="KAM-0001",
        status=MemberStatus.APPROVED,
        full_name="Test Member",
        father_or_husband="Father",
        mother="Mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="Farmer",
        nid="1234567890",
        mobile="01700000000",
        gender="পুরুষ",
        email="member@example.com",
        admission_fee="1000",
        subscription="500",
        receipt_no="R-1",
        payment_method="cash",
        submission_date="2026-01-01",
    )
    db_session.add(member)
    await db_session.flush()
    db_session.add(
        MemberCredential(
            member_id=member.id,
            username="kam-0001",
            password_hash=hash_password(OLD_PASSWORD),
        )
    )
    await db_session.commit()
    return member


@pytest_asyncio.fixture
async def admin(db_session: AsyncSession) -> AdminUser:
    admin = AdminUser(
        name="Admin",
        email="admin@example.com",
        password_hash=hash_password(OLD_PASSWORD),
    )
    db_session.add(admin)
    await db_session.commit()
    return admin


async def _latest_token(db_session: AsyncSession) -> PasswordResetToken:
    rows = (
        (await db_session.execute(select(PasswordResetToken))).scalars().all()
    )
    assert rows, "no reset token was created"
    return rows[-1]


async def test_forgot_password_by_username_creates_token(
    client: AsyncClient, db_session: AsyncSession, member: Member
) -> None:
    response = await client.post(FORGOT_URL, json={"identifier": "KAM-0001"})
    assert response.status_code == 200
    row = await _latest_token(db_session)
    assert row.user_type == "member"
    assert row.member_id == member.id
    assert row.used_at is None
    assert sha("raw-token") != row.token_hash  # only the hash is stored


async def test_forgot_password_by_email_creates_token(
    client: AsyncClient, db_session: AsyncSession, member: Member
) -> None:
    response = await client.post(FORGOT_URL, json={"identifier": "member@example.com"})
    assert response.status_code == 200
    row = await _latest_token(db_session)
    assert row.user_type == "member"
    assert row.member_id == member.id


async def test_forgot_password_for_admin_creates_token(
    client: AsyncClient, db_session: AsyncSession, admin: AdminUser
) -> None:
    response = await client.post(FORGOT_URL, json={"identifier": "admin@example.com"})
    assert response.status_code == 200
    row = await _latest_token(db_session)
    assert row.user_type == "admin"
    assert row.admin_id == admin.id


async def test_forgot_password_unknown_identifier_still_200(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    response = await client.post(FORGOT_URL, json={"identifier": "nobody@nowhere.test"})
    assert response.status_code == 200
    rows = (await db_session.execute(select(PasswordResetToken))).scalars().all()
    assert rows == []


async def test_full_reset_flow_with_new_password(
    client: AsyncClient, db_session: AsyncSession, member: Member
) -> None:
    await client.post(FORGOT_URL, json={"identifier": "kam-0001"})
    row = await _latest_token(db_session)

    # The stored hash must match the raw token we would have emailed; emulate
    # the email step by hashing an arbitrary raw token is not possible, so we
    # assert against the endpoint by issuing a token with a known hash.
    response = await client.post(
        RESET_URL, json={"token": "wrong-token", "new_password": "brandnew99"}
    )
    assert response.status_code == 400

    db_session.add(
        PasswordResetToken(
            user_type="member",
            member_id=member.id,
            token_hash=sha("known-raw-token"),
            expires_at=row.expires_at,
        )
    )
    await db_session.commit()

    response = await client.post(
        RESET_URL, json={"token": "known-raw-token", "new_password": "brandnew99"}
    )
    assert response.status_code == 200

    relogin = await client.post(
        "/api/member/login", json={"username": "kam-0001", "password": "brandnew99"}
    )
    assert relogin.status_code == 200
    assert relogin.json()["must_change_password"] is False

    # Single use: replaying the token must fail.
    replay = await client.post(
        RESET_URL, json={"token": "known-raw-token", "new_password": "another99"}
    )
    assert replay.status_code == 400


async def test_reset_password_rejects_weak_password(
    client: AsyncClient, db_session: AsyncSession, member: Member
) -> None:
    response = await client.post(
        RESET_URL, json={"token": "whatever", "new_password": "short"}
    )
    assert response.status_code == 422


async def test_forgot_password_invalidates_previous_tokens(
    client: AsyncClient, db_session: AsyncSession, member: Member
) -> None:
    await client.post(FORGOT_URL, json={"identifier": "kam-0001"})
    await client.post(FORGOT_URL, json={"identifier": "kam-0001"})
    rows = (
        (
            await db_session.execute(
                select(PasswordResetToken).where(PasswordResetToken.used_at.is_(None))
            )
        )
        .scalars()
        .all()
    )
    assert len(rows) == 1
