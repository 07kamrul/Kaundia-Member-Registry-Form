"""Tests for the unified member "Other Fees" endpoints.

Covers the config-driven catalog (installment excluded by fee_category),
server-side recomputation per calculation mode, pay-once admission
enforcement, and the combined history (picnic + fee_payments rows, own
records only, installments never).
"""

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.admin import AdminRole, AdminUser
from app.models.fee_payment import FeePayment
from app.models.fee_settings import FeeSetting
from app.models.member import Member
from app.models.picnic_payment import PicnicPayment

pytestmark = pytest.mark.asyncio


async def _seed_rates(db_session: AsyncSession) -> None:
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
            FeeSetting(
                key="admission_fee", value=2000, unit="taka", start_date=date(2000, 1, 1)
            ),
            FeeSetting(
                key="fee_maintenance_amount",
                value=250,
                unit="taka",
                start_date=date(2000, 1, 1),
            ),
            FeeSetting(
                key="fee_installment_amount",
                value=1000,
                unit="taka",
                start_date=date(2000, 1, 1),
                fee_category="installment",
            ),
        ]
    )
    await db_session.commit()


async def _seed_member(db_session: AsyncSession, email: str, **overrides) -> Member:
    member = Member(
        status="approved",
        full_name=overrides.pop("full_name", email.split("@")[0].title()),
        father_or_husband="father",
        mother="mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="job",
        nid=str(abs(hash(email)) % 10**10),
        mobile="0170000000",
        gender="male",
        email=email,
        admission_fee=overrides.pop("admission_fee", "2000"),
        subscription="100",
        receipt_no="r",
        payment_method="cash",
        submission_date="2026-01-01",
        **overrides,
    )
    db_session.add(member)
    await db_session.commit()
    await db_session.refresh(member)
    return member


def _auth(member: Member) -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(str(member.id), 'member')}"}


async def test_types_excludes_installment_and_marks_admission_paid(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_rates(db_session)
    member = await _seed_member(db_session, "types@example.com")

    response = await client.get(
        "/api/member/other-fees/types", headers=_auth(member)
    )

    assert response.status_code == 200
    types = {row["key"]: row for row in response.json()}
    assert "installment" not in types
    # Config-driven fixed type straight from Fee Settings.
    assert types["maintenance"]["calculation"] == "fixed"
    assert types["maintenance"]["amount"] == 250
    # Variable types are offered even without a configured rate.
    assert types["donation"]["calculation"] == "variable"
    assert types["donation"]["amount"] is None
    # Admission is pay-once and already settled at registration.
    assert types["admission"]["pay_once"] is True
    assert types["admission"]["already_paid"] is True
    assert types["admission"]["amount"] == 2000
    # Picnic carries both rate keys.
    assert types["picnic"]["calculation"] == "picnic"
    assert types["picnic"]["head_fee"] == 500
    assert types["picnic"]["additional_head_fee"] == 300


async def test_fixed_payment_recomputes_and_ignores_client_amount(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_rates(db_session)
    member = await _seed_member(db_session, "fixed@example.com")

    response = await client.post(
        "/api/member/other-fees/payments",
        headers=_auth(member),
        json={
            "fee_type": "maintenance",
            "payment_date": "2026-02-01",
            "amount": "1",
            "payment_method": "Cash",
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["fee_type"] == "maintenance"
    assert float(body["amount"]) == 250  # server rate, not the client's 1
    assert body["source"] == "fee_payment"


async def test_variable_type_requires_positive_amount(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_rates(db_session)
    member = await _seed_member(db_session, "donor@example.com")

    missing = await client.post(
        "/api/member/other-fees/payments",
        headers=_auth(member),
        json={"fee_type": "donation", "payment_date": "2026-02-01"},
    )
    assert missing.status_code == 422
    assert missing.json()["detail"]["code"] == "AMOUNT_REQUIRED"

    ok = await client.post(
        "/api/member/other-fees/payments",
        headers=_auth(member),
        json={
            "fee_type": "donation",
            "payment_date": "2026-02-01",
            "amount": "1500.50",
            "payment_method": "bKash",
        },
    )
    assert ok.status_code == 201
    assert float(ok.json()["amount"]) == 1500.5


async def test_admission_pay_once_blocks_second_payment(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_rates(db_session)
    member = await _seed_member(db_session, "admitted@example.com")

    response = await client.post(
        "/api/member/other-fees/payments",
        headers=_auth(member),
        json={"fee_type": "admission", "payment_date": "2026-02-01"},
    )
    assert response.status_code == 409
    assert response.json()["detail"]["code"] == "ADMISSION_FEE_ALREADY_PAID"


async def test_picnic_via_other_fees_recomputes_total(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_rates(db_session)
    member = await _seed_member(db_session, "picnicer@example.com")

    response = await client.post(
        "/api/member/other-fees/payments",
        headers=_auth(member),
        json={
            "fee_type": "picnic",
            "payment_date": "2026-02-01",
            "additional_heads": 2,
            "payment_method": "Cash",
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["source"] == "picnic_payment"
    assert body["fee_type"] == "picnic"
    assert float(body["amount"]) == 500 + 2 * 300
    assert body["additional_heads"] == 2


async def test_installment_fee_type_rejected_even_when_called_directly(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_rates(db_session)
    member = await _seed_member(db_session, "installment@example.com")

    response = await client.post(
        "/api/member/other-fees/payments",
        headers=_auth(member),
        json={"fee_type": "installment", "payment_date": "2026-02-01", "amount": "100"},
    )
    assert response.status_code == 422
    assert response.json()["detail"]["code"] == "INSTALLMENT_NOT_PAYABLE_HERE"


async def test_history_unions_picnic_and_fee_payments_scoped_and_filtered(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_rates(db_session)
    mine = await _seed_member(db_session, "histmine@example.com")
    other = await _seed_member(db_session, "histother@example.com")
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
            FeePayment(
                member_id=mine.id,
                fee_type="maintenance",
                amount=250,
                payment_date=date(2026, 1, 20),
            ),
            # Must never surface on the Other Fees page.
            FeePayment(
                member_id=mine.id,
                fee_type="installment",
                amount=99999,
                payment_date=date(2026, 1, 25),
            ),
        ]
    )
    await db_session.commit()

    all_rows = await client.get("/api/member/other-fees/payments", headers=_auth(mine))
    assert all_rows.status_code == 200
    page = all_rows.json()
    assert page["total"] == 2  # own picnic + maintenance; installment excluded
    assert {row["fee_type"] for row in page["items"]} == {"picnic", "maintenance"}
    assert page["items"][0]["payment_date"] == "2026-01-20"  # newest first
    assert page["summary"]["total_paid"] == pytest.approx(1350)
    assert page["summary"]["by_type"]["picnic"] == pytest.approx(1100)

    picnic_only = await client.get(
        "/api/member/other-fees/payments?fee_type=picnic", headers=_auth(mine)
    )
    assert picnic_only.status_code == 200
    rows = picnic_only.json()["items"]
    assert len(rows) == 1
    assert rows[0]["additional_heads"] == 2

    # Ownership: the other member's rows never leak.
    theirs = await client.get("/api/member/other-fees/payments", headers=_auth(other))
    assert theirs.json()["total"] == 1


async def test_admin_other_fees_ledger_requires_permission_and_filters(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_rates(db_session)
    payer = await _seed_member(db_session, "ledger@example.com")
    db_session.add_all(
        [
            PicnicPayment(
                member_id=payer.id,
                head_price=500,
                additional_price=300,
                additional_count=1,
                total=800,
                payment_date=date(2026, 3, 1),
            ),
            FeePayment(
                member_id=payer.id,
                fee_type="donation",
                amount=700,
                payment_date=date(2026, 3, 5),
            ),
        ]
    )
    await db_session.commit()
    admin = AdminUser(
        email="ledger-admin@example.com",
        password_hash="x",
        name="Ledger Admin",
        role=AdminRole.SUPER_ADMIN,
    )
    db_session.add(admin)
    await db_session.commit()
    await db_session.refresh(admin)
    headers = {
        "Authorization": f"Bearer {create_access_token(str(admin.id), 'super_admin')}"
    }

    response = await client.get("/api/admin/other-fees/payments", headers=headers)
    assert response.status_code == 200
    page = response.json()
    assert page["total"] == 2
    assert all(row["member_name"] == payer.full_name for row in page["items"])
    assert page["summary"]["total_paid"] == pytest.approx(1500)

    filtered = await client.get(
        "/api/admin/other-fees/payments?fee_type=picnic", headers=headers
    )
    assert filtered.json()["total"] == 1

    unprivileged = await client.get(
        "/api/admin/other-fees/payments",
        headers=_auth(payer),  # member token, not an admin
    )
    assert unprivileged.status_code in (401, 403)
