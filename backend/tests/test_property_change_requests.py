"""Property change request workflow: member submits add/edit/delete requests,
admin approves (applies to `properties`) or cancels with a reason."""

import json

import pytest
from httpx import AsyncClient
from sqlalchemy import select

from app.core.security import create_access_token
from app.models.member import Member, MemberStatus
from app.models.property import ApplicableDoc, CoOwner, Property
from app.models.property_change_request import PropertyChangeRequest

pytestmark = pytest.mark.asyncio


async def _approved_member(db_session, *, email="props@example.com") -> Member:
    member = Member(
        status=MemberStatus.APPROVED,
        full_name="Md. Property Owner",
        father_or_husband="Father",
        mother="Mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="Job",
        nid="1234567890",
        mobile="01758290421",
        gender="পুরুষ",
        email=email,
        admission_fee="500",
        subscription="100",
        receipt_no="R-1",
        payment_method="Cash",
        submission_date="2026-01-01",
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


def _add_payload() -> dict:
    return {
        "property_type": ["জায়গা"],
        "khatian_no": "2025-100801",
        "dag_no_cs": "2214",
        "land_quantity": "6",
        "my_share_quantity": "1",
        "ownership": "বটিয়া",
        "co_owners": [{"owner_name": "Co Owner", "owner_phone": "01711111111"}],
        "docs": [{"doc_type": "খাজনা/কর রশিদ"}],
    }


async def _create_request(client, member, action="add", *, payload=None, property_id=None):
    data = payload if payload is not None else _add_payload()
    form = {"action": action, "payload": json.dumps(data)}
    files = []
    for doc in data.get("docs", []):
        if doc.get("keep_path") is None:
            files.append(
                ("doc_files", ("doc.png", b"\x89PNG fake bytes", "image/png"))
            )
    if property_id is not None:
        form["property_id"] = str(property_id)
    return await client.post(
        "/api/member/property-requests",
        data=form,
        files=files or None,
        headers=_member_headers(member),
    )


async def test_add_request_full_cycle(
    client: AsyncClient, db_session, admin_user
) -> None:
    member = await _approved_member(db_session)
    admin_headers = await _admin_headers(client)

    created = await _create_request(client, member)
    assert created.status_code == 201
    request_id = created.json()["id"]
    assert created.json()["status"] == "pending"

    # Admin list shows the request with member context.
    listed = await client.get(
        "/api/admin/property-requests?status=pending", headers=admin_headers
    )
    assert listed.status_code == 200
    entry = next(r for r in listed.json() if r["id"] == request_id)
    assert entry["member_name"] == member.full_name

    approved = await client.post(
        f"/api/admin/property-requests/{request_id}/approve", headers=admin_headers
    )
    assert approved.status_code == 200
    assert approved.json()["status"] == "approved"

    property_ = (
        await db_session.execute(select(Property).where(Property.member_id == member.id))
    ).scalar_one()
    assert property_.khatian_no == "2025-100801"
    co_owners = (
        await db_session.execute(select(CoOwner).where(CoOwner.property_id == property_.id))
    ).scalars().all()
    assert len(co_owners) == 1

    # The approved request is no longer in the pending queue.
    still_pending = await client.get(
        "/api/admin/property-requests?status=pending", headers=admin_headers
    )
    assert all(r["id"] != request_id for r in still_pending.json())

    # Approving twice is rejected.
    again = await client.post(
        f"/api/admin/property-requests/{request_id}/approve", headers=admin_headers
    )
    assert again.status_code == 409


async def test_edit_request_applies_and_second_pending_conflicts(
    client: AsyncClient, db_session, admin_user
) -> None:
    member = await _approved_member(db_session)
    admin_headers = await _admin_headers(client)
    property_ = Property(
        member_id=member.id, property_type=[], khatian_no="100", land_quantity="5"
    )
    db_session.add(property_)
    await db_session.flush()
    db_session.add(CoOwner(property_id=property_.id, owner_name="Old", owner_phone="01700000000"))
    await db_session.commit()

    payload = _add_payload() | {"khatian_no": "999"}
    created = await _create_request(client, member, "edit", payload=payload, property_id=property_.id)
    assert created.status_code == 201

    # A second pending request for the same property is blocked.
    duplicate = await _create_request(client, member, "edit", payload=payload, property_id=property_.id)
    assert duplicate.status_code == 409

    approved = await client.post(
        f"/api/admin/property-requests/{created.json()['id']}/approve", headers=admin_headers
    )
    assert approved.status_code == 200
    await db_session.refresh(property_)
    assert property_.khatian_no == "999"
    co_owners = (
        await db_session.execute(select(CoOwner).where(CoOwner.property_id == property_.id))
    ).scalars().all()
    assert [co.owner_name for co in co_owners] == ["Co Owner"]


async def test_cancel_records_reason_and_delete_snapshot(
    client: AsyncClient, db_session, admin_user
) -> None:
    member = await _approved_member(db_session)
    admin_headers = await _admin_headers(client)
    property_ = Property(member_id=member.id, property_type=[], khatian_no="555")
    db_session.add(property_)
    await db_session.flush()
    db_session.add(
        ApplicableDoc(property_id=property_.id, doc_type="খাজনা/কর রশিদ", file_path="documents/member_x/khajna/a.jpg")
    )
    await db_session.commit()

    created = await _create_request(client, member, "delete", payload={}, property_id=property_.id)
    assert created.status_code == 201
    request_id = created.json()["id"]

    cancelled = await client.post(
        f"/api/admin/property-requests/{request_id}/cancel",
        json={"reason": "Khatian number mismatch"}, headers=admin_headers,
    )
    assert cancelled.status_code == 200
    assert cancelled.json()["status"] == "cancelled"
    assert cancelled.json()["cancel_reason"] == "Khatian number mismatch"

    # Property untouched, request row keeps the delete snapshot.
    await db_session.refresh(property_)
    assert property_.khatian_no == "555"
    request = await db_session.get(PropertyChangeRequest, request_id)
    assert request.payload["khatian_no"] == "555"
    assert request.payload["docs"][0]["doc_type"] == "খাজনা/কর রশিদ"

    # Member sees the cancelled status and reason.
    listed = await client.get("/api/member/property-requests", headers=_member_headers(member))
    entry = next(r for r in listed.json() if r["id"] == request_id)
    assert entry["status"] == "cancelled"
    assert entry["cancel_reason"] == "Khatian number mismatch"

    # Cancelling an already-decided request is rejected.
    again = await client.post(
        f"/api/admin/property-requests/{request_id}/cancel",
        json={"reason": "x"}, headers=admin_headers,
    )
    assert again.status_code == 409


async def test_member_can_withdraw_pending_request(
    client: AsyncClient, db_session, admin_user
) -> None:
    member = await _approved_member(db_session)
    created = await _create_request(client, member)
    request_id = created.json()["id"]

    withdrawn = await client.post(
        f"/api/member/property-requests/{request_id}/withdraw", headers=_member_headers(member)
    )
    assert withdrawn.status_code == 200
    assert withdrawn.json()["status"] == "cancelled"

    # Admin approves are now blocked on the withdrawn request.
    admin_headers = await _admin_headers(client)
    blocked = await client.post(
        f"/api/admin/property-requests/{request_id}/approve", headers=admin_headers
    )
    assert blocked.status_code == 409


async def test_delete_request_for_foreign_property_is_404(
    client: AsyncClient, db_session, admin_user
) -> None:
    member = await _approved_member(db_session)
    other = await _approved_member(db_session, email="other@example.com")
    property_ = Property(member_id=other.id, property_type=[])
    db_session.add(property_)
    await db_session.commit()
    await db_session.refresh(property_)

    response = await _create_request(client, member, "delete", payload={}, property_id=property_.id)
    assert response.status_code == 404
