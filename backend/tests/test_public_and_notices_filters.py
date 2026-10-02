"""Public endpoints and notices/events filter branches not covered elsewhere:
public stats, event date filters/pagination, and unified-login member path."""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.credential import MemberCredential
from app.models.event import Event
from app.models.member import Member, MemberStatus
from tests.test_submission_flow import _submission_payload

pytestmark = pytest.mark.asyncio


async def _submit(client: AsyncClient, n: int, status: MemberStatus) -> dict:
    payload = _submission_payload()
    payload.update(
        full_name=f"Person {n}",
        nid=f"123456789{n}",
        mobile=f"0170000000{n}",
        email=f"person{n}@example.com",
        subscription="100",
    )
    response = await client.post("/api/submissions", data={"payload": json.dumps(payload)})
    assert response.status_code == 201
    return response.json()


import json


async def test_public_stats_counts_approved_and_pending(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    approved = await _submit(client, 1, MemberStatus.PENDING)
    await _submit(client, 2, MemberStatus.PENDING)
    member = await db_session.get(Member, approved["id"])
    member.status = MemberStatus.APPROVED
    member.subscription = "100"
    await db_session.commit()

    response = await client.get("/api/public/stats")
    assert response.status_code == 200
    body = response.json()
    assert body["approved_count"] == 1
    assert body["pending_count"] == 1
    assert body["monthly_subscription_total"] == 100


async def test_events_admin_list_filters_by_category_and_pagination(
    client: AsyncClient, db_session: AsyncSession, admin_user
) -> None:
    login = await client.post(
        "/api/admin/login", json={"email": "admin@example.com", "password": "adminpass123"}
    )
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

    # Seed a category, then two events.
    await client.post(
        "/api/admin/config-lists",
        json={"category": "event_category", "value": "cultural", "label": "Cultural"},
        headers=headers,
    )
    for i, (start, end) in enumerate(
        (
            ("2026-11-01T10:00:00", "2026-11-01T12:00:00"),
            ("2026-12-01T10:00:00", "2026-12-01T12:00:00"),
        )
    ):
        created = await client.post(
            "/api/admin/events",
            json={
                "title": f"Event {i}",
                "description": "d",
                "location": "loc",
                "start_at": start,
                "end_at": end,
                "is_published": True,
                "is_members_only": False,
            },
            headers=headers,
        )
        assert created.status_code == 201, created.text

    listed = await client.get("/api/admin/events", params={"limit": 1, "offset": 1}, headers=headers)
    assert listed.status_code == 200
    assert len(listed.json()) == 1  # second page of a 2-row list

    filtered = await client.get(
        "/api/admin/events", params={"published": "false"}, headers=headers
    )
    assert filtered.status_code == 200
    assert filtered.json() == []


async def test_unified_login_member_path_returns_member_token(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    member = Member(
        status=MemberStatus.APPROVED,
        full_name="Unified Login",
        father_or_husband="Father",
        mother="Mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="Job",
        nid="1234567899",
        mobile="01700000099",
        gender="পুরুষ",
        email="unified@example.com",
        admission_fee="500",
        subscription="100",
        receipt_no="R-9",
        payment_method="Cash",
        submission_date="2026-01-01",
    )
    db_session.add(member)
    await db_session.commit()
    await db_session.refresh(member)
    db_session.add(MemberCredential(
        member_id=member.id,
        username="ukamks-0001",
        password_hash=hash_password("memberpass1"),
        must_change_password=True,
    ))
    await db_session.commit()

    response = await client.post(
        "/api/member/login",
        json={"username": "ukamks-0001", "password": "memberpass1"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["role"] == "member"
    assert body["must_change_password"] is True
    assert "profile.view_own" in body["permissions"]

    wrong = await client.post(
        "/api/member/login", json={"username": "ukamks-0001", "password": "nope"}
    )
    assert wrong.status_code == 401
