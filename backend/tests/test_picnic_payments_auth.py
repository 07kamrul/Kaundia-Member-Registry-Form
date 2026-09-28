from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.admin import AdminRole, AdminUser
from app.models.fee_settings import FeeSetting
from app.models.member import Member
from app.models.picnic_payment import PicnicPayment

pytestmark = pytest.mark.asyncio


async def _seed_picnic_rates(db_session: AsyncSession) -> None:
    db_session.add_all(
        [
            FeeSetting(
                key="picnic_head_fee", value=500, unit="taka", start_date=date(2000, 1, 1)
            ),
            FeeSetting(
                key="picnic_additional_head_fee",
                value=300,
                unit="taka",
                start_date=date(2000, 1, 1),
            ),
        ]
    )
    await db_session.commit()


async def _seed_member(db_session: AsyncSession, email: str, full_name: str) -> Member:
    member = Member(
        status="approved",
        full_name=full_name,
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


def _auth_header(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


async def test_member_sees_only_own_payments(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_picnic_rates(db_session)
    mine = await _seed_member(db_session, "mine@example.com", "Mine")
    other = await _seed_member(db_session, "other@example.com", "Other")
    db_session.add_all(
        [
            PicnicPayment(
                member_id=mine.id,
                head_price=500,
                additional_price=300,
                additional_count=2,
                total=1100,
                payment_date=date(2026, 1, 10),
            ),
            PicnicPayment(
                member_id=other.id,
                head_price=500,
                additional_price=300,
                additional_count=0,
                total=500,
                payment_date=date(2026, 1, 11),
            ),
        ]
    )
    await db_session.commit()

    response = await client.get(
        "/api/member/picnic-payments",
        headers=_auth_header(create_access_token(str(mine.id), "member")),
    )

    assert response.status_code == 200
    rows = response.json()
    assert len(rows) == 1
    assert rows[0]["additional_count"] == 2


@pytest.mark.parametrize(
    "role,email",
    [
        (AdminRole.SUPER_ADMIN, "super@example.com"),
        (AdminRole.EXECUTIVE_COMMITTEE, "committee@example.com"),
        (AdminRole.ADMINISTRATOR, "administrator@example.com"),
    ],
)
async def test_admin_tier_roles_cannot_use_member_payment_history(
    client: AsyncClient, db_session: AsyncSession, role: AdminRole, email: str
) -> None:
    """Fee managers configure/review payments elsewhere (Fee Settings and
    GET /admin/picnic-payments); the member history endpoint rejects them."""
    await _seed_picnic_rates(db_session)
    payer = await _seed_member(db_session, "payer@example.com", "Payer")
    db_session.add(
        PicnicPayment(
            member_id=payer.id,
            head_price=500,
            additional_price=300,
            additional_count=0,
            total=500,
            payment_date=date(2026, 1, 10),
        )
    )
    await db_session.commit()
    admin = await _seed_admin(db_session, role, email)

    response = await client.get(
        "/api/member/picnic-payments", headers=_auth_header(create_access_token(str(admin.id), role.value))
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Fee managers cannot make member payments."


async def test_unauthenticated_picnic_payments_is_unauthorized(client: AsyncClient) -> None:
    response = await client.get("/api/member/picnic-payments")
    assert response.status_code == 401


async def test_unlinked_member_account_gets_clear_error(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_picnic_rates(db_session)
    admin = await _seed_admin(db_session, AdminRole.EXECUTIVE_COMMITTEE, "linked@example.com")

    # A token claiming role=member for an id with no member profile.
    response = await client.get(
        "/api/member/picnic-payments",
        headers=_auth_header(create_access_token(str(admin.id), "member")),
    )

    assert response.status_code == 403
    assert "not linked to a member profile" in response.json()["detail"]


async def test_member_can_create_payment_and_sees_snapshot(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_picnic_rates(db_session)
    member = await _seed_member(db_session, "creator@example.com", "Creator")

    response = await client.post(
        "/api/member/picnic-payments",
        headers=_auth_header(create_access_token(str(member.id), "member")),
        json={
            "additional_heads": 2,
            "additional_people": [{"name": "Wife", "relation": "spouse"}, {"name": "Kid", "relation": "child"}],
            "payment_date": "2026-01-15",
        },
    )

    assert response.status_code == 201
    body = response.json()
    # Snapshot from configured rates, ignoring anything the client claimed.
    assert float(body["head_price"]) == 500
    assert float(body["additional_price"]) == 300
    assert body["additional_count"] == 2
    assert float(body["total"]) == 1100


async def test_admin_tier_account_cannot_create_payment(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_picnic_rates(db_session)
    admin = await _seed_admin(db_session, AdminRole.ADMINISTRATOR, "no-profile@example.com")

    response = await client.post(
        "/api/member/picnic-payments",
        headers=_auth_header(create_access_token(str(admin.id), "administrator")),
        json={"additional_heads": 1, "payment_date": "2026-01-15"},
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Fee managers cannot make member payments."


async def test_super_admin_cannot_create_payment(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_picnic_rates(db_session)
    admin = await _seed_admin(db_session, AdminRole.SUPER_ADMIN, "super-payer@example.com")

    response = await client.post(
        "/api/member/picnic-payments",
        headers=_auth_header(create_access_token(str(admin.id), "super_admin")),
        json={"additional_heads": 1, "payment_date": "2026-01-15"},
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Fee managers cannot make member payments."


async def test_picnic_rates_readable_by_member_and_admin(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_picnic_rates(db_session)
    member = await _seed_member(db_session, "rates-member@example.com", "RM")
    admin = await _seed_admin(db_session, AdminRole.EXECUTIVE_COMMITTEE, "rates-admin@example.com")

    member_response = await client.get(
        "/api/member/picnic-rates",
        headers=_auth_header(create_access_token(str(member.id), "member")),
    )
    admin_response = await client.get(
        "/api/member/picnic-rates",
        headers=_auth_header(create_access_token(str(admin.id), "executive_committee")),
    )

    assert member_response.status_code == 200
    assert admin_response.status_code == 200
    for body in (member_response.json(), admin_response.json()):
        assert body["head_fee"] == 500
        assert body["additional_head_fee"] == 300
        assert body["unit"] == "taka"


async def test_picnic_rates_404_with_code_when_not_configured(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    member = await _seed_member(db_session, "no-rates@example.com", "NR")

    response = await client.get(
        "/api/member/picnic-rates",
        headers=_auth_header(create_access_token(str(member.id), "member")),
    )

    assert response.status_code == 404
    assert response.json()["detail"]["code"] == "PICNIC_RATES_NOT_CONFIGURED"


async def test_admin_picnic_payments_requires_permission(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    admin = await _seed_admin(db_session, AdminRole.SUPER_ADMIN, "viewall@example.com")

    response = await client.get(
        "/api/admin/picnic-payments",
        headers=_auth_header(create_access_token(str(admin.id), "super_admin")),
    )

    assert response.status_code == 200
