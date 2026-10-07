"""Society costs: CRUD, exact-reconciliation splits, payment recording,
summary accuracy and member isolation."""

from decimal import Decimal

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token
from app.models.member import Member, MemberStatus
from app.models.property import Property

pytestmark = pytest.mark.asyncio


async def _approved_member(db_session, *, email, land_quantity=None, member_id=None) -> Member:
    member = Member(
        status=MemberStatus.APPROVED,
        member_id=member_id,
        full_name=f"Member {email}",
        father_or_husband="Father",
        mother="Mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="Job",
        nid=f"123456789{abs(hash(email)) % 10}",
        mobile=f"017582904{abs(hash(email)) % 100:02d}",
        gender="পুরুষ",
        email=email,
        admission_fee="500",
        subscription="100",
        receipt_no="R-1",
        payment_method="Cash",
        submission_date="2026-01-01",
    )
    if land_quantity is not None:
        member.properties.append(
            Property(property_type=["জমি"], land_quantity=land_quantity, ownership="একক")
        )
    db_session.add(member)
    await db_session.commit()
    await db_session.refresh(member)
    return member


def _member_headers(member: Member) -> dict:
    return {"Authorization": f"Bearer {create_access_token(str(member.id), 'member')}"}


async def _admin_headers(client: AsyncClient) -> dict:
    response = await client.post(
        "/api/admin/login", json={"email": "admin@example.com", "password": "adminpass123"}
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _cost_payload(**overrides) -> dict:
    payload = {
        "title": "রাস্তার মেরামত",
        "total_amount": "1000.00",
        "incurred_date": "2026-10-01",
        "payment_source": "member_billed",
    }
    payload.update(overrides)
    return payload


async def _create_cost(client, admin_headers, **overrides) -> dict:
    response = await client.post(
        "/api/admin/society-costs", json=_cost_payload(**overrides), headers=admin_headers
    )
    assert response.status_code == 201, response.text
    return response.json()


async def test_equal_split_reconciles_exactly(client, db_session, admin_user):
    headers = await _admin_headers(client)
    m1 = await _approved_member(db_session, email="a@x.com", member_id="UKAMKS-1")
    m2 = await _approved_member(db_session, email="b@x.com", member_id="UKAMKS-2")
    m3 = await _approved_member(db_session, email="c@x.com", member_id="UKAMKS-3")
    cost = await _create_cost(client, headers, total_amount="100.00")

    response = await client.post(
        f"/api/admin/society-costs/{cost['id']}/split",
        json={"split_method": "equal"},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    shares = response.json()["split"]["shares"]
    assert len(shares) == 3
    amounts = sorted(Decimal(s["amount_due"]) for s in shares)
    assert sum(amounts) == Decimal("100.00")
    # 100 / 3 = 33.33 each, +0.01 remainder to the first share(s)
    assert amounts == [Decimal("33.33"), Decimal("33.33"), Decimal("33.34")]


async def test_land_quantity_split_reconciles_exactly(client, db_session, admin_user):
    headers = await _admin_headers(client)
    await _approved_member(db_session, email="a@x.com", land_quantity="2")
    await _approved_member(db_session, email="b@x.com", land_quantity="1")
    await _approved_member(db_session, email="c@x.com", land_quantity="১")  # Bengali digit
    cost = await _create_cost(client, headers, total_amount="100.00")

    response = await client.post(
        f"/api/admin/society-costs/{cost['id']}/split",
        json={"split_method": "by_land_quantity"},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    shares = response.json()["split"]["shares"]
    # weights 2:1:1 over 100 -> 50 / 25 / 25
    by_member = {s["member_name"]: Decimal(s["amount_due"]) for s in shares}
    assert sum(by_member.values()) == Decimal("100.00")
    assert sorted(by_member.values()) == [Decimal("25.00"), Decimal("25.00"), Decimal("50.00")]


async def test_manual_split_mismatch_blocked_and_overridable(client, db_session, admin_user):
    headers = await _admin_headers(client)
    m1 = await _approved_member(db_session, email="a@x.com")
    m2 = await _approved_member(db_session, email="b@x.com")
    cost = await _create_cost(client, headers, total_amount="100.00")

    body = {
        "split_method": "manual",
        "manual_shares": [
            {"member_id": m1.id, "amount_due": "60.00"},
            {"member_id": m2.id, "amount_due": "30.00"},
        ],
    }
    response = await client.post(
        f"/api/admin/society-costs/{cost['id']}/split", json=body, headers=headers
    )
    assert response.status_code == 422

    body["allow_mismatch"] = True
    response = await client.post(
        f"/api/admin/society-costs/{cost['id']}/split", json=body, headers=headers
    )
    assert response.status_code == 200
    assert len(response.json()["split"]["shares"]) == 2


async def test_resplit_blocked_after_payment(client, db_session, admin_user):
    headers = await _admin_headers(client)
    await _approved_member(db_session, email="a@x.com")
    cost = await _create_cost(client, headers, total_amount="100.00")

    response = await client.post(
        f"/api/admin/society-costs/{cost['id']}/split",
        json={"split_method": "equal"},
        headers=headers,
    )
    share_id = response.json()["split"]["shares"][0]["id"]

    payment = await client.patch(
        f"/api/admin/cost-split-shares/{share_id}",
        json={"amount_paid": "10.00"},
        headers=headers,
    )
    assert payment.status_code == 200
    assert payment.json()["status"] == "partial"

    response = await client.post(
        f"/api/admin/society-costs/{cost['id']}/split",
        json={"split_method": "equal"},
        headers=headers,
    )
    assert response.status_code == 409


async def test_payment_overpay_blocked_and_full_payment_marks_paid(client, db_session, admin_user):
    headers = await _admin_headers(client)
    await _approved_member(db_session, email="a@x.com")
    cost = await _create_cost(client, headers, total_amount="100.00")
    response = await client.post(
        f"/api/admin/society-costs/{cost['id']}/split",
        json={"split_method": "equal"},
        headers=headers,
    )
    share_id = response.json()["split"]["shares"][0]["id"]

    overpay = await client.patch(
        f"/api/admin/cost-split-shares/{share_id}",
        json={"amount_paid": "999.00"},
        headers=headers,
    )
    assert overpay.status_code == 400

    paid = await client.patch(
        f"/api/admin/cost-split-shares/{share_id}",
        json={"amount_paid": "100.00", "receipt_no": "RC-1"},
        headers=headers,
    )
    assert paid.status_code == 200
    body = paid.json()
    assert body["status"] == "paid"
    assert body["paid_at"] is not None


async def test_society_fund_cost_never_reaches_member_view(client, db_session, admin_user):
    headers = await _admin_headers(client)
    member = await _approved_member(db_session, email="a@x.com")
    await _create_cost(client, headers, payment_source="society_fund")

    billed_cost = await _create_cost(
        client, headers, title="বিল করা খরচ", payment_source="member_billed"
    )
    await client.post(
        f"/api/admin/society-costs/{billed_cost['id']}/split",
        json={"split_method": "equal"},
        headers=headers,
    )

    response = await client.get("/api/member/cost-shares", headers=_member_headers(member))
    assert response.status_code == 200
    shares = response.json()
    assert len(shares) == 1
    assert shares[0]["cost_title"] == "বিল করা খরচ"


async def test_member_endpoint_isolated_to_own_shares(client, db_session, admin_user):
    headers = await _admin_headers(client)
    m1 = await _approved_member(db_session, email="a@x.com", member_id="UKAMKS-1")
    m2 = await _approved_member(db_session, email="b@x.com", member_id="UKAMKS-2")
    cost = await _create_cost(client, headers)
    await client.post(
        f"/api/admin/society-costs/{cost['id']}/split",
        json={"split_method": "equal"},
        headers=headers,
    )

    r1 = await client.get("/api/member/cost-shares", headers=_member_headers(m1))
    r2 = await client.get("/api/member/cost-shares", headers=_member_headers(m2))
    assert {s["member_id"] for s in r1.json()} == {m1.id}
    assert {s["member_id"] for s in r2.json()} == {m2.id}


async def test_summary_matches_underlying_rows(client, db_session, admin_user):
    headers = await _admin_headers(client)
    member = await _approved_member(db_session, email="a@x.com")
    await _create_cost(
        client, headers, title="ফান্ড", total_amount="500.00", payment_source="society_fund"
    )
    billed = await _create_cost(client, headers, total_amount="300.00")
    response = await client.post(
        f"/api/admin/society-costs/{billed['id']}/split",
        json={"split_method": "equal"},
        headers=headers,
    )
    share_id = response.json()["split"]["shares"][0]["id"]
    await client.patch(
        f"/api/admin/cost-split-shares/{share_id}",
        json={"amount_paid": "100.00"},
        headers=headers,
    )

    summary = await client.get("/api/admin/society-costs/summary", headers=headers)
    assert summary.status_code == 200
    body = summary.json()
    assert Decimal(body["total_amount"]) == Decimal("800.00")
    assert Decimal(body["society_fund_total"]) == Decimal("500.00")
    assert Decimal(body["member_billed_total"]) == Decimal("300.00")
    assert Decimal(body["outstanding_total"]) == Decimal("200.00")
    assert Decimal(body["collected_total"]) == Decimal("100.00")


async def test_audit_logged_for_create_split_payment(client, db_session, admin_user):
    from sqlalchemy import select

    from app.models.audit_log import AuditLog

    headers = await _admin_headers(client)
    member = await _approved_member(db_session, email="a@x.com")
    cost = await _create_cost(client, headers)
    response = await client.post(
        f"/api/admin/society-costs/{cost['id']}/split",
        json={"split_method": "equal"},
        headers=headers,
    )
    share_id = response.json()["split"]["shares"][0]["id"]
    await client.patch(
        f"/api/admin/cost-split-shares/{share_id}",
        json={"amount_paid": "1000.00"},
        headers=headers,
    )

    actions = set(
        await db_session.scalars(
            select(AuditLog.action).where(AuditLog.entity_type.in_(["society_cost", "cost_split_share"]))
        )
    )
    assert {"society_cost.create", "society_cost.split", "society_cost.payment"} <= actions


async def test_cost_delete_blocked_after_payment(client, db_session, admin_user):
    headers = await _admin_headers(client)
    await _approved_member(db_session, email="a@x.com")
    cost = await _create_cost(client, headers)
    response = await client.post(
        f"/api/admin/society-costs/{cost['id']}/split",
        json={"split_method": "equal"},
        headers=headers,
    )
    share_id = response.json()["split"]["shares"][0]["id"]
    await client.patch(
        f"/api/admin/cost-split-shares/{share_id}",
        json={"amount_paid": "1.00"},
        headers=headers,
    )
    blocked = await client.delete(f"/api/admin/society-costs/{cost['id']}", headers=headers)
    assert blocked.status_code == 409
