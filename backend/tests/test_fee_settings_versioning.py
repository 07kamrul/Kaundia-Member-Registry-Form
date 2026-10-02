"""Fee-settings versioning: one active row per key, history semantics, and
the public endpoint's view of the current rates.

The partial unique index `ux_fee_settings_active_key` (migration
d4e5f6a7b8c9) lives only in migrations, so these tests recreate it on the
in-memory SQLite DB to exercise the real constraint.
"""

from datetime import date, timedelta

import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy import select, text
from sqlalchemy.exc import IntegrityError

from app.models.admin import AdminUser
from app.models.fee_settings import FeeSetting

pytestmark = pytest.mark.asyncio


@pytest_asyncio.fixture
async def db_with_unique_active_index(db_session):
    await db_session.execute(
        text("CREATE UNIQUE INDEX ux_fee_settings_active_key ON fee_settings (key) WHERE status = 1")
    )
    await db_session.commit()
    return db_session


async def _admin_headers(client: AsyncClient) -> dict:
    response = await client.post(
        "/api/admin/login", json={"email": "admin@example.com", "password": "adminpass123"}
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


async def _add_version(client: AsyncClient, headers: dict, key: str, value: float, **kwargs) -> dict:
    response = await client.post(
        "/api/admin/fee-settings",
        json={"key": key, "value": value, **kwargs},
        headers=headers,
    )
    assert response.status_code == 201, response.text
    return response.json()


async def test_new_version_closes_previous_row(
    client: AsyncClient, db_with_unique_active_index, admin_user: AdminUser
) -> None:
    headers = await _admin_headers(client)
    first = await _add_version(client, headers, "admission_fee", 600)
    second = await _add_version(client, headers, "admission_fee", 700)

    rows = {
        row.id: row
        for row in (
            await db_with_unique_active_index.execute(
                select(FeeSetting).where(FeeSetting.key == "admission_fee")
            )
        )
        .scalars()
        .all()
    }
    # The conftest seed also has an admission_fee row (id 1, closed by the
    # first route call); assert on the two route-created rows.
    assert (rows[first["id"]].value, rows[first["id"]].status) == (600, 0)
    assert (rows[second["id"]].value, rows[second["id"]].status) == (700, 1)
    # The superseded row is closed at the transaction boundary, not left open.
    assert rows[first["id"]].end_date == date.today()
    assert rows[second["id"]].end_date is None
    # The seeded row was the one closed by the first route call.
    assert rows[min(rows)].status == 0

    admin_list = await client.get("/api/admin/fee-settings", headers=headers)
    active_rows = [r for r in admin_list.json() if r["key"] == "admission_fee"]
    assert len(active_rows) == 1
    assert active_rows[0]["value"] == 700


async def test_two_active_rows_for_same_key_violate_unique_index(
    db_with_unique_active_index,
) -> None:
    """Even if two add-version writes raced past the ORM pre-check, the
    partial unique index must make the second commit impossible."""
    db_with_unique_active_index.add_all(
        [
            FeeSetting(key="picnic_head_fee", value=200, start_date=date(2000, 1, 1), status=0),
            FeeSetting(key="picnic_head_fee", value=250, start_date=date(2026, 1, 1), status=1),
        ]
    )
    await db_with_unique_active_index.commit()
    db_with_unique_active_index.add(
        FeeSetting(key="picnic_head_fee", value=300, start_date=date(2026, 10, 2), status=1)
    )
    with pytest.raises(IntegrityError):
        await db_with_unique_active_index.commit()


async def test_public_fee_settings_returns_current_value_per_key(
    client: AsyncClient, db_with_unique_active_index, admin_user: AdminUser
) -> None:
    """After a version change, /api/public/fee-settings must reflect the NEW
    value. The superseded row keeps end_date = today (it was active until the
    change), so it still satisfies a plain date-window filter on the change
    day — the endpoint has to prefer the newest start_date per key."""
    headers = await _admin_headers(client)
    await _add_version(client, headers, "admission_fee", 600)
    await _add_version(client, headers, "admission_fee", 700)

    response = await client.get("/api/public/fee-settings")
    assert response.status_code == 200
    body = response.json()
    assert body["admission_fee"] == 700


async def test_subscription_quote_as_of_past_date_uses_that_versions_rate(
    client: AsyncClient, admin_user: AdminUser
) -> None:
    """Historical lookup: a quote billed before the rate change uses the old
    rate, one billed after uses the new one."""
    headers = await _admin_headers(client)
    # A rate bump effective tomorrow; quotes dated before/after must differ.
    tomorrow = date.today() + timedelta(days=1)
    await _add_version(
        client,
        headers,
        "monthly_subscription_additional_rate",
        20,
        start_date=tomorrow.isoformat(),
    )
    # The previous version (from the conftest seed, start 2000-01-01, rate 10)
    # stays active until tomorrow.

    before = await client.post(
        "/api/public/registration/subscription-quote",
        json={"land_size_decimal": "3", "billing_date": date.today().isoformat()},
    )
    after = await client.post(
        "/api/public/registration/subscription-quote",
        json={"land_size_decimal": "3", "billing_date": tomorrow.isoformat()},
    )
    assert before.status_code == 200
    assert after.status_code == 200
    assert float(before.json()["extra_rate"]) == 10
    assert float(before.json()["total"]) == 120
    assert float(after.json()["extra_rate"]) == 20
    assert float(after.json()["total"]) == 140
