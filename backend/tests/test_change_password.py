import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.credential import MemberCredential
from app.models.member import Member, MemberStatus

pytestmark = pytest.mark.asyncio

CURRENT_PASSWORD = "oldpass123"
URL = "/api/member/change-password"


@pytest_asyncio.fixture
async def member_headers(db_session: AsyncSession) -> dict[str, str]:
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
            password_hash=hash_password(CURRENT_PASSWORD),
        )
    )
    await db_session.commit()
    return {"Authorization": f"Bearer {create_access_token(str(member.id), 'member')}"}


async def test_change_password_succeeds_with_valid_input(
    client: AsyncClient, member_headers: dict[str, str]
) -> None:
    response = await client.post(
        URL,
        json={"current_password": CURRENT_PASSWORD, "new_password": "brandnew99"},
        headers=member_headers,
    )
    assert response.status_code == 204

    relogin = await client.post(
        "/api/member/login", json={"username": "kam-0001", "password": "brandnew99"}
    )
    assert relogin.status_code == 200


async def test_wrong_current_password_returns_field_error(
    client: AsyncClient, member_headers: dict[str, str]
) -> None:
    response = await client.post(
        URL,
        json={"current_password": "not-the-password1", "new_password": "brandnew99"},
        headers=member_headers,
    )
    assert response.status_code == 422
    assert response.json()["detail"]["errors"] == {
        "current_password": "Current password is incorrect"
    }


@pytest.mark.parametrize("weak", ["short1", "nodigitshere"])
async def test_weak_new_password_returns_policy_message(
    client: AsyncClient, member_headers: dict[str, str], weak: str
) -> None:
    response = await client.post(
        URL,
        json={"current_password": CURRENT_PASSWORD, "new_password": weak},
        headers=member_headers,
    )
    assert response.status_code == 422
    assert "at least 8 characters and include a number" in response.json()["detail"]["errors"]["new_password"]


async def test_new_password_must_differ_from_current(
    client: AsyncClient, member_headers: dict[str, str]
) -> None:
    response = await client.post(
        URL,
        json={"current_password": CURRENT_PASSWORD, "new_password": CURRENT_PASSWORD},
        headers=member_headers,
    )
    assert response.status_code == 422
    assert "different" in response.json()["detail"]["errors"]["new_password"]
