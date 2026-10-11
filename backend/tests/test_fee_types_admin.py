"""Admin fee-type catalog endpoints: CRUD, versioned rates, calculator, and
the merged admin fee-payments list (picnic ledger folded in)."""

from datetime import date

import pytest
import pytest_asyncio
from httpx import AsyncClient

from app.models.admin import AdminUser
from app.models.fee_settings import FeeType

pytestmark = pytest.mark.asyncio


@pytest_asyncio.fixture
async def seeded_fee_types(db_session) -> None:
    db_session.add_all(
        [
            FeeType(
                key="monthly_subscription",
                label_bn="মাসিক সাবস্ক্রিপশন ফি",
                label_en="Monthly Subscription Rate",
                calculation_type="tiered",
                fee_category="installment",
                sort_order=0,
            ),
            FeeType(
                key="admission_fee",
                label_bn="ভর্তি ফি",
                label_en="Admission Fee",
                calculation_type="fixed",
                is_pay_once=True,
                sort_order=1,
            ),
            FeeType(
                key="picnic_fee",
                label_bn="পিকনিক ফি",
                label_en="Picnic Fee",
                calculation_type="head_additional",
                head_setting_key="picnic_head_fee",
                additional_setting_key="picnic_additional_head_fee",
                sort_order=2,
            ),
        ]
    )
    await db_session.commit()


async def _admin_headers(client: AsyncClient) -> dict:
    response = await client.post(
        "/api/admin/login", json={"email": "admin@example.com", "password": "adminpass123"}
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


async def test_list_fee_types_includes_current_versions_and_counts(
    client: AsyncClient, admin_user: AdminUser, seeded_fee_types: None
) -> None:
    headers = await _admin_headers(client)
    response = await client.get("/api/admin/fee-types", headers=headers)
    assert response.status_code == 200
    by_key = {row["key"]: row for row in response.json()}

    # Admission (conftest seeds a 500 version) shows its version and grouping.
    assert by_key["admission_fee"]["calculation_type"] == "fixed"
    assert by_key["admission_fee"]["fee_category"] == "other"
    assert by_key["admission_fee"]["current_version"]["values"]["admission_fee"] == 500

    # Tiered fee collapses the three settings rows into one snapshot.
    tiered = by_key["monthly_subscription"]["current_version"]["values"]
    assert tiered["monthly_subscription_base_amount"] == 100
    assert tiered["monthly_subscription_additional_rate"] == 10
    assert tiered["monthly_subscription_base_threshold"] == 1

    # Picnic has no active versions in this DB -> visible "no version" gap.
    assert by_key["picnic_fee"]["current_version"] is None


async def test_create_fee_type_then_version_then_calculate(
    client: AsyncClient, admin_user: AdminUser, seeded_fee_types: None
) -> None:
    headers = await _admin_headers(client)

    created = await client.post(
        "/api/admin/fee-types",
        json={
            "key": "development_fee",
            "label_bn": "উন্নয়ন ফি",
            "label_en": "Development Fee",
            "calculation_type": "fixed",
            "fee_category": "other",
            "is_pay_once": True,
        },
        headers=headers,
    )
    assert created.status_code == 201, created.text
    assert created.json()["key"] == "development_fee"

    duplicate = await client.post(
        "/api/admin/fee-types",
        json={
            "key": "development_fee",
            "label_bn": "x",
            "label_en": "x",
            "calculation_type": "fixed",
        },
        headers=headers,
    )
    assert duplicate.status_code == 409

    invalid_key = await client.post(
        "/api/admin/fee-types",
        json={
            "key": "Bad Key!",
            "label_bn": "x",
            "label_en": "x",
            "calculation_type": "fixed",
        },
        headers=headers,
    )
    assert invalid_key.status_code == 422

    version = await client.post(
        "/api/admin/fee-types/development_fee/versions",
        json={"value": 750, "start_date": date.today().isoformat()},
        headers=headers,
    )
    assert version.status_code == 201, version.text
    assert version.json()[0]["values"]["development_fee"] == 750

    calc = await client.post(
        "/api/admin/fee-types/development_fee/calculate", json={}, headers=headers
    )
    assert calc.status_code == 200
    assert calc.json()["total"] == 750


async def test_tiered_version_and_calculator_match_subscription_service(
    client: AsyncClient, admin_user: AdminUser, seeded_fee_types: None
) -> None:
    headers = await _admin_headers(client)
    response = await client.post(
        "/api/admin/fee-types/monthly_subscription/versions",
        json={"base_amount": 100, "additional_rate": 10, "base_threshold": 1},
        headers=headers,
    )
    assert response.status_code == 201, response.text

    calc = await client.post(
        "/api/admin/fee-types/monthly_subscription/calculate",
        json={"land_size": 3},
        headers=headers,
    )
    assert calc.status_code == 200
    body = calc.json()
    # base 100 + ceil(3-1)=2 extra decimals x 10
    assert body["total"] == 120
    assert body["breakdown"]["extra_units"] == 2


async def test_head_additional_version_uses_legacy_picnic_keys(
    client: AsyncClient, admin_user: AdminUser, seeded_fee_types: None, db_session
) -> None:
    from app.models.fee_settings import FeeSetting

    db_session.add_all(
        [
            FeeSetting(key="picnic_head_fee", value=500, start_date=date(2000, 1, 1)),
            FeeSetting(
                key="picnic_additional_head_fee", value=300, start_date=date(2000, 1, 1)
            ),
        ]
    )
    await db_session.commit()

    headers = await _admin_headers(client)
    calc = await client.post(
        "/api/admin/fee-types/picnic_fee/calculate",
        json={"additional_heads": 2},
        headers=headers,
    )
    assert calc.status_code == 200
    body = calc.json()
    assert body["total"] == 1100
    assert body["breakdown"]["additional_heads"] == 2

    # A new version writes through to the legacy keys.
    version = await client.post(
        "/api/admin/fee-types/picnic_fee/versions",
        json={"head_fee": 600, "additional_head_fee": 350},
        headers=headers,
    )
    assert version.status_code == 201
    latest = version.json()[0]
    assert latest["values"]["picnic_head_fee"] == 600
    assert latest["values"]["picnic_additional_head_fee"] == 350

    recalc = await client.post(
        "/api/admin/fee-types/picnic_fee/calculate",
        json={"additional_heads": 1},
        headers=headers,
    )
    assert recalc.json()["total"] == 950


async def test_update_fee_type_edits_settings_not_versions(
    client: AsyncClient, admin_user: AdminUser, seeded_fee_types: None
) -> None:
    headers = await _admin_headers(client)
    response = await client.put(
        "/api/admin/fee-types/admission_fee",
        json={"label_en": "Admission Fee (updated)", "is_active": False},
        headers=headers,
    )
    assert response.status_code == 200
    body = response.json()
    assert body["label_en"] == "Admission Fee (updated)"
    assert body["is_active"] is False
    # Rate untouched.
    assert body["current_version"]["values"]["admission_fee"] == 500


async def test_variable_fee_version_requires_bounds(
    client: AsyncClient, admin_user: AdminUser, seeded_fee_types: None
) -> None:
    headers = await _admin_headers(client)
    await client.post(
        "/api/admin/fee-types",
        json={
            "key": "donation",
            "label_bn": "দান",
            "label_en": "Donation",
            "calculation_type": "variable",
        },
        headers=headers,
    )
    missing = await client.post(
        "/api/admin/fee-types/donation/versions", json={}, headers=headers
    )
    assert missing.status_code == 422

    ok = await client.post(
        "/api/admin/fee-types/donation/versions",
        json={"min_amount": 100, "max_amount": 50000},
        headers=headers,
    )
    assert ok.status_code == 201
    values = ok.json()[0]["values"]
    assert values["donation_min"] == 100
    assert values["donation_max"] == 50000

    below = await client.post(
        "/api/admin/fee-types/donation/calculate",
        json={"amount": 50},
        headers=headers,
    )
    assert below.status_code == 422

    valid = await client.post(
        "/api/admin/fee-types/donation/calculate",
        json={"amount": 500},
        headers=headers,
    )
    assert valid.status_code == 200
    assert valid.json()["total"] == 500


async def test_admin_fee_payments_merges_picnic_ledger(
    client: AsyncClient, admin_user: AdminUser, seeded_fee_types: None, db_session
) -> None:
    from datetime import datetime, timezone

    from app.models.fee_payment import FeePayment
    from app.models.member import Member
    from app.models.picnic_payment import PicnicPayment

    member = Member(
        status="approved",
        full_name="Test Member",
        father_or_husband="father",
        mother="mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="job",
        nid="1234567890",
        mobile="0170000000",
        gender="male",
        email="testmember@example.com",
        admission_fee="2000",
        subscription="100",
        receipt_no="r",
        payment_method="cash",
        submission_date="2026-01-01",
    )
    db_session.add(member)
    await db_session.flush()
    db_session.add_all(
        [
            FeePayment(
                member_id=member.id,
                fee_type="maintenance",
                amount=200,
                payment_date=date(2026, 10, 1),
            ),
            PicnicPayment(
                member_id=member.id,
                head_price=500,
                additional_price=300,
                additional_count=1,
                total=800,
                payment_date=date(2026, 10, 5),
            ),
        ]
    )
    await db_session.commit()

    headers = await _admin_headers(client)
    response = await client.get("/api/admin/fee-payments", headers=headers)
    assert response.status_code == 200
    body = response.json()
    assert body["count"] == 2
    assert body["total_collected"] == 1000

    picnic_rows = [row for row in body["items"] if row["source"] == "picnic_payment"]
    assert len(picnic_rows) == 1
    assert picnic_rows[0]["fee_type"] == "picnic"
    assert float(picnic_rows[0]["amount"]) == 800
    assert "Head" in picnic_rows[0]["note"]

    # Filtering to another type excludes the picnic ledger.
    filtered = await client.get(
        "/api/admin/fee-payments", params={"fee_type": "maintenance"}, headers=headers
    )
    assert filtered.json()["count"] == 1
    assert all(row["source"] == "fee_payment" for row in filtered.json()["items"])

    # Picnic filter keeps only picnic rows (from either table).
    picnic_only = await client.get(
        "/api/admin/fee-payments", params={"fee_type": "picnic"}, headers=headers
    )
    assert picnic_only.json()["count"] == 1


async def test_fee_type_endpoints_require_permission(
    client: AsyncClient, seeded_fee_types: None
) -> None:
    response = await client.get("/api/admin/fee-types")
    assert response.status_code in (401, 403)
