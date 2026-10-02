"""Submission validation, duplicate-NID rules, re-approval, and approve/reject
audit rows.

The duplicate-safety net is the partial unique indexes from migration
d4e6f8a0b2c4 (one per identifier, scoped to non-REJECTED rows). The ORM
models don't declare them, so these tests create the same indexes on the
in-memory SQLite database to exercise the real constraint, not just the
route-level pre-check.
"""

import json

import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy import select, text
from sqlalchemy.exc import IntegrityError

from app.api.routes import admin as admin_routes
from app.api.routes.submissions import _BLOCKING_STATUSES
from app.core.security import hash_password
from app.models.admin import AdminRole, AdminUser
from app.models.credential import MemberCredential
from app.models.member import Member, MemberStatus
from tests.test_submission_flow import _submission_payload

pytestmark = pytest.mark.asyncio

# SQLite equivalent of the Postgres partial unique indexes; the enum is
# stored as its Python name ('REJECTED') in both dialects.
_PARTIAL_INDEX_DDL = [
    "CREATE UNIQUE INDEX ix_members_nid_active ON members (nid) WHERE status <> 'REJECTED'",
    "CREATE UNIQUE INDEX ix_members_mobile_active ON members (mobile) WHERE status <> 'REJECTED'",
    "CREATE UNIQUE INDEX ix_members_email_active ON members (email) WHERE status <> 'REJECTED'",
]


@pytest_asyncio.fixture
async def db_with_partial_indexes(db_session):
    for ddl in _PARTIAL_INDEX_DDL:
        await db_session.execute(text(ddl))
    await db_session.commit()
    return db_session


async def _login_admin(client: AsyncClient, email: str = "admin@example.com") -> dict:
    response = await client.post(
        "/api/admin/login", json={"email": email, "password": "adminpass123"}
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


async def _submit(client: AsyncClient, **overrides) -> dict:
    payload = _submission_payload()
    payload.update(overrides)
    response = await client.post("/api/submissions", data={"payload": json.dumps(payload)})
    assert response.status_code == 201, response.text
    return response.json()


async def test_create_submission_missing_required_field_is_422(client: AsyncClient) -> None:
    payload = _submission_payload()
    del payload["nid"]
    response = await client.post("/api/submissions", data={"payload": json.dumps(payload)})
    assert response.status_code == 422


async def test_missing_submitted_field_reports_which_field(client: AsyncClient) -> None:
    """The 422 must name the missing field so the applicant can fix it."""
    payload = _submission_payload()
    del payload["full_name"]
    response = await client.post("/api/submissions", data={"payload": json.dumps(payload)})
    assert response.status_code == 422
    assert "full_name" in response.text


async def test_duplicate_nid_against_approved_member_blocked_by_partial_index(
    client: AsyncClient, db_with_partial_indexes
) -> None:
    submission = await _submit(client)
    member = await db_with_partial_indexes.get(Member, submission["id"])
    member.status = MemberStatus.APPROVED
    await db_with_partial_indexes.commit()

    response = await client.post(
        "/api/submissions", data={"payload": json.dumps(_submission_payload())}
    )
    assert response.status_code == 409


def _member_row(i: int, status: MemberStatus, nid: str) -> Member:
    return Member(
        status=status,
        full_name=f"Dup {i}",
        father_or_husband="Father",
        mother="Mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="Farmer",
        nid=nid,
        mobile=f"0170000000{i}",
        gender="পুরুষ",
        email=f"dup{i}@example.com",
        admission_fee="500",
        subscription="100",
        receipt_no=f"R-{i}",
        payment_method="Cash",
        submission_date="2026-09-15",
    )


async def test_two_active_members_with_same_nid_violate_index(
    db_with_partial_indexes,
) -> None:
    """The DB constraint itself: even if the route pre-check raced, two
    non-rejected rows with the same NID cannot be committed."""
    db_with_partial_indexes.add(_member_row(0, MemberStatus.PENDING, "9998887776"))
    db_with_partial_indexes.add(_member_row(1, MemberStatus.APPROVED, "9998887776"))
    with pytest.raises(IntegrityError):
        await db_with_partial_indexes.commit()


async def test_rejected_member_does_not_block_nid_at_db_level(
    db_with_partial_indexes,
) -> None:
    """The partial index predicate mirrors _BLOCKING_STATUSES: a REJECTED row
    is outside the index, so its NID is free again."""
    rejected = _member_row(0, MemberStatus.REJECTED, "1112223334")
    rejected.mobile = "01600000001"
    rejected.email = "rejected@example.com"
    fresh = _member_row(1, MemberStatus.PENDING, "1112223334")
    fresh.mobile = "01600000002"
    fresh.email = "fresh@example.com"
    db_with_partial_indexes.add_all([rejected, fresh])
    await db_with_partial_indexes.commit()
    statuses = set(
        (
            await db_with_partial_indexes.execute(
                select(Member.status).where(Member.nid == "1112223334")
            )
        ).scalars()
    )
    assert statuses == {MemberStatus.REJECTED, MemberStatus.PENDING}


async def test_blocking_statuses_exclude_rejected() -> None:
    """Guard the invariant the partial-index predicate depends on."""
    assert MemberStatus.REJECTED not in _BLOCKING_STATUSES
    assert MemberStatus.PENDING in _BLOCKING_STATUSES
    assert MemberStatus.APPROVED in _BLOCKING_STATUSES


async def test_reapproval_reuses_credential_and_sends_reapproved_email(
    client: AsyncClient, db_session, admin_user: AdminUser, monkeypatch: pytest.MonkeyPatch
) -> None:
    sent_emails: list[dict] = []

    async def fake_send_email(to: str, subject: str, html_body: str) -> bool:
        sent_emails.append({"to": to, "subject": subject, "html_body": html_body})
        return True

    monkeypatch.setattr(admin_routes, "send_email", fake_send_email)

    submission = await _submit(client)
    member_pk = submission["id"]
    headers = await _login_admin(client)

    approve = await client.post(f"/api/admin/submissions/{member_pk}/approve", headers=headers)
    assert approve.status_code == 200
    first_member_id = approve.json()["member_id"]
    assert len(sent_emails) == 1
    assert "Temporary password" in sent_emails[0]["html_body"]

    # Simulate the member editing a core field, which re-queues the member to
    # PENDING while keeping their credential (see the re-approval workflow).
    member = await db_session.get(Member, member_pk)
    member.status = MemberStatus.PENDING
    await db_session.commit()

    reapprove = await client.post(f"/api/admin/submissions/{member_pk}/approve", headers=headers)
    assert reapprove.status_code == 200, reapprove.text
    assert reapprove.json()["member_id"] == first_member_id

    # Credential reused, not recreated.
    credentials = (
        (
            await db_session.execute(
                select(MemberCredential).where(MemberCredential.member_id == member_pk)
            )
        )
        .scalars()
        .all()
    )
    assert len(credentials) == 1
    assert credentials[0].username == first_member_id.lower()

    # Re-approval email tells the member their login is unchanged; it must
    # never carry a (stale) temp password.
    assert len(sent_emails) == 2
    assert "Re-approved" in sent_emails[1]["subject"]
    assert "Temporary password" not in sent_emails[1]["html_body"]

    # Exactly one approve + one reapprove audit row for this member.
    rows = (
        (
            await db_session.execute(
                text(
                    "SELECT action FROM audit_logs WHERE entity_type='member' "
                    "AND entity_id=:eid ORDER BY id"
                ),
                {"eid": str(member_pk)},
            )
        )
        .scalars()
        .all()
    )
    assert rows == ["member.approve", "member.reapprove"]


async def test_reject_writes_exactly_one_audit_row(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    submission = await _submit(client)
    headers = await _login_admin(client)
    reject = await client.post(
        f"/api/admin/submissions/{submission['id']}/reject",
        json={"reason": "photo unreadable"},
        headers=headers,
    )
    assert reject.status_code == 200

    rows = (
        (
            await db_session.execute(
                text(
                    "SELECT action, actor_admin_id FROM audit_logs "
                    "WHERE entity_type='member' AND entity_id=:eid"
                ),
                {"eid": str(submission["id"])},
            )
        )
        .all()
    )
    assert rows == [("member.reject", admin_user.id)]
