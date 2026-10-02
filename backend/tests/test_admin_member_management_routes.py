"""Admin member-management routes: pagination, not-found paths,
installment CRUD, member deletion, and the resend-notification endpoint."""

import json
from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy import select, text

from app.core.security import hash_password
from app.models.credential import MemberCredential
from app.models.installment import Installment, InstallmentStatus
from app.models.member import Member, MemberStatus
from tests.test_submission_flow import _submission_payload

pytestmark = pytest.mark.asyncio


async def _admin_headers(client: AsyncClient) -> dict:
    response = await client.post(
        "/api/admin/login", json={"email": "admin@example.com", "password": "adminpass123"}
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


_SEQ = {"n": 0}


async def _submit(client: AsyncClient) -> dict:
    """Each call submits a fresh applicant (unique NID/mobile/email)."""
    _SEQ["n"] += 1
    n = _SEQ["n"]
    payload = _submission_payload()
    payload.update(
        full_name=f"Applicant {n}",
        nid=f"123456789{n}",
        mobile=f"0170000000{n}",
        email=f"applicant{n}@example.com",
    )
    response = await client.post("/api/submissions", data={"payload": json.dumps(payload)})
    assert response.status_code == 201, response.text
    return response.json()


async def test_submissions_list_limit_and_offset(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    await _submit(client)
    await _submit(client)
    headers = await _admin_headers(client)

    all_rows = await client.get("/api/admin/submissions", headers=headers)
    assert all_rows.status_code == 200
    assert len(all_rows.json()) == 2

    paged = await client.get(
        "/api/admin/submissions", params={"limit": 1, "offset": 1}, headers=headers
    )
    assert paged.status_code == 200
    assert len(paged.json()) == 1


async def test_get_missing_submission_returns_404(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    headers = await _admin_headers(client)
    response = await client.get("/api/admin/submissions/424242", headers=headers)
    assert response.status_code == 404


async def test_installment_crud_round_trip(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    submission = await _submit(client)
    member_pk = submission["id"]
    headers = await _admin_headers(client)

    missing_member = await client.get(
        f"/api/admin/members/{member_pk}/installments", headers=headers
    )
    # A pending submission IS a member row, so this must succeed and be empty.
    assert missing_member.status_code == 200
    assert missing_member.json() == []

    not_found = await client.get("/api/admin/members/424242/installments", headers=headers)
    assert not_found.status_code == 404

    created = await client.post(
        f"/api/admin/members/{member_pk}/installments",
        json={"year": 2026, "month": 1, "amount": 250},
        headers=headers,
    )
    assert created.status_code == 201, created.text
    installment_id = created.json()["id"]
    assert created.json()["status"] == "due"

    marked = await client.patch(
        f"/api/admin/installments/{installment_id}",
        json={"status": "paid"},
        headers=headers,
    )
    assert marked.status_code == 200
    assert marked.json()["status"] == "paid"
    assert marked.json()["paid_at"] is not None

    unpaid = await client.patch(
        f"/api/admin/installments/{installment_id}",
        json={"status": "due"},
        headers=headers,
    )
    assert unpaid.status_code == 200
    assert unpaid.json()["paid_at"] is None

    missing_installment = await client.patch(
        "/api/admin/installments/424242", json={"status": "paid"}, headers=headers
    )
    assert missing_installment.status_code == 404

    rows = (await db_session.execute(select(Installment))).scalars().all()
    assert len(rows) == 1


async def test_delete_member_removes_the_whole_graph(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    """The set-based delete must remove properties, docs, nominees,
    credential, installments and the member itself without FK errors."""
    submission = await _submit(client)
    member_pk = submission["id"]
    headers = await _admin_headers(client)
    # Approve so a credential exists too.
    await client.post(f"/api/admin/submissions/{member_pk}/approve", headers=headers)
    db_session.add(Installment(member_id=member_pk, year=2026, month=1, amount=100))
    await db_session.commit()

    response = await client.delete(f"/api/admin/members/{member_pk}", headers=headers)
    assert response.status_code == 204

    assert (await db_session.execute(text("SELECT count(*) FROM members"))).scalar() == 0
    assert (await db_session.execute(text("SELECT count(*) FROM properties"))).scalar() == 0
    assert (await db_session.execute(text("SELECT count(*) FROM applicable_docs"))).scalar() == 0
    assert (await db_session.execute(text("SELECT count(*) FROM nominees"))).scalar() == 0
    assert (await db_session.execute(text("SELECT count(*) FROM member_credentials"))).scalar() == 0
    assert (await db_session.execute(text("SELECT count(*) FROM installments"))).scalar() == 0

    gone = await client.delete(f"/api/admin/members/{member_pk}", headers=headers)
    assert gone.status_code == 404


async def test_resend_rejection_notification_success_and_conflict(
    client: AsyncClient, db_session, admin_user: AdminUser, monkeypatch: pytest.MonkeyPatch
) -> None:
    from app.api.routes import admin as admin_routes

    calls: list[str] = []

    async def fake_send_email(to: str, subject: str, html_body: str) -> bool:
        calls.append(subject)
        return True

    monkeypatch.setattr(admin_routes, "send_email", fake_send_email)

    submission = await _submit(client)
    member_pk = submission["id"]
    headers = await _admin_headers(client)

    rejected = await client.post(
        f"/api/admin/submissions/{member_pk}/reject",
        json={"reason": "documents unclear"},
        headers=headers,
    )
    assert rejected.status_code == 200
    assert rejected.json()["email_sent"] is True
    assert len(calls) == 1

    # Nothing failed -> nothing to resend.
    conflict = await client.post(
        f"/api/admin/submissions/{member_pk}/resend-notification", headers=headers
    )
    assert conflict.status_code == 409
    assert len(calls) == 1

    # Simulate a failed notification on a rejected member, then resend.
    member = await db_session.get(Member, member_pk)
    assert member.status == MemberStatus.REJECTED
    member.notification_status = "failed"
    await db_session.commit()

    resent = await client.post(
        f"/api/admin/submissions/{member_pk}/resend-notification", headers=headers
    )
    assert resent.status_code == 200
    assert resent.json()["email_sent"] is True
    assert len(calls) == 2


async def test_members_list_pagination_and_due_counts(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    submission = await _submit(client)
    member_pk = submission["id"]
    headers = await _admin_headers(client)
    await client.post(f"/api/admin/submissions/{member_pk}/approve", headers=headers)
    db_session.add(Installment(member_id=member_pk, year=2026, month=1, amount=100))
    await db_session.commit()

    response = await client.get("/api/admin/members", params={"limit": 10}, headers=headers)
    assert response.status_code == 200
    rows = response.json()
    assert len(rows) == 1
    assert rows[0]["due_installments"] == 1

    empty_page = await client.get(
        "/api/admin/members", params={"offset": 50, "limit": 10}, headers=headers
    )
    assert empty_page.json() == []
