"""Online Resolution Book: atomic meeting creation, role gating, vote/attendance
validation, notices, audit trail, search and the minutes PDF export."""

import pytest
from httpx import AsyncClient
from sqlalchemy import select as sa_select

from app.core.security import create_access_token, hash_password
from app.models.admin import AdminRole, AdminUser
from app.models.audit_log import AuditLog
from app.models.member import Member, MemberStatus
from app.models.notice import Notice

pytestmark = pytest.mark.asyncio


def _headers(account_id: int | str, role: str) -> dict:
    return {"Authorization": f"Bearer {create_access_token(str(account_id), role)}"}


async def _member(db_session, name: str = "সদস্য", email: str = "rb-member@x.com") -> Member:
    member = Member(
        status=MemberStatus.APPROVED,
        member_id=f"UKAMKS-{abs(hash(email)) % 10000:04d}",
        full_name=name,
        father_or_husband="Father",
        mother="Mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="Job",
        nid="1234567899",
        mobile="01758290499",
        gender="পুরুষ",
        email=email,
        admission_fee="500",
        subscription="100",
        receipt_no="R-9",
        payment_method="Cash",
        submission_date="2026-01-01",
    )
    db_session.add(member)
    await db_session.commit()
    await db_session.refresh(member)
    return member


async def _committee_headers(db_session) -> dict:
    admin = AdminUser(
        email="rb-committee@x.com",
        password_hash=hash_password("pass12345"),
        name="Committee",
        role=AdminRole.EXECUTIVE_COMMITTEE,
    )
    db_session.add(admin)
    await db_session.commit()
    await db_session.refresh(admin)
    return _headers(admin.id, admin.role.value)


def _meeting_payload(member_ids: list[int], **extra) -> dict:
    return {
        "date": "2026-10-08",
        "time": "20:30",
        "meeting_type": "online",
        "chairperson": "সভাপতির নাম",
        "agenda": "বার্ষিক সাধারণ সভার এজেন্ডা",
        "summary": "সভা সফলভাবে সম্পন্ন হয়েছে।",
        "attendance": [{"member_id": mid, "status": "present"} for mid in member_ids],
        "resolutions": [
            {
                "decision": "রাস্তার সংস্কার অনুমোদন",
                "vote_for": len(member_ids) - 1,
                "vote_against": 1,
                "vote_neutral": 0,
                "task": "ঠিকাদার নির্বাচন",
                "due_date": "2026-11-30",
            }
        ],
        **extra,
    }


async def _create_meeting(client: AsyncClient, headers: dict, member_ids: list[int], **extra) -> dict:
    response = await client.post(
        "/api/resolution-book/meetings",
        json=_meeting_payload(member_ids, **extra),
        headers=headers,
    )
    assert response.status_code == 201, response.text
    return response.json()


async def test_meetings_require_login(client: AsyncClient):
    assert (await client.get("/api/resolution-book/meetings")).status_code == 401
    assert (await client.get("/api/resolution-book/summary")).status_code == 401


async def test_committee_creates_meeting_atomically(client: AsyncClient, db_session):
    member = await _member(db_session)
    member2 = await _member(db_session, name="সদস্য ২", email="rb-member2@x.com")
    headers = await _committee_headers(db_session)

    body = await _create_meeting(client, headers, [member.id, member2.id])
    assert body["meeting_no"] == "SVA-2026-001"
    assert body["attendance_present"] == 2
    assert body["attendance_percent"] == 100
    assert len(body["resolutions"]) == 1
    assert body["resolutions"][0]["resolution_no"] == 1

    # Notice published through the existing notices table.
    notices = (await db_session.execute(sa_select(Notice))).scalars().all()
    assert any("নতুন সভার রেকর্ড" in n.title for n in notices)
    # Audit trail entry.
    audits = (await db_session.execute(sa_select(AuditLog))).scalars().all()
    assert any(a.action == "meeting.create" for a in audits)


async def test_duplicate_meeting_no_rejected(client: AsyncClient, db_session):
    member = await _member(db_session)
    headers = await _committee_headers(db_session)
    await _create_meeting(client, headers, [member.id], meeting_no="SVA-2026-001")
    response = await client.post(
        "/api/resolution-book/meetings",
        json=_meeting_payload([member.id], meeting_no="sva-2026-001"),
        headers=headers,
    )
    assert response.status_code == 409


async def test_member_is_read_only(client: AsyncClient, db_session):
    member = await _member(db_session)
    headers = await _committee_headers(db_session)
    body = await _create_meeting(client, headers, [member.id])

    member_headers = _headers(member.id, "member")
    assert (
        await client.get("/api/resolution-book/meetings", headers=member_headers)
    ).status_code == 200
    assert (
        await client.get(f"/api/resolution-book/meetings/{body['id']}", headers=member_headers)
    ).status_code == 200
    # Direct-URL write attempts are rejected server-side.
    assert (
        await client.put(
            f"/api/resolution-book/meetings/{body['id']}",
            json={"summary": "tampered"},
            headers=member_headers,
        )
    ).status_code == 403
    assert (
        await client.post(
            f"/api/resolution-book/meetings/{body['id']}/attendance",
            json={"entries": [{"member_id": member.id, "status": "present"}]},
            headers=member_headers,
        )
    ).status_code == 403


async def test_votes_cannot_exceed_attendance(client: AsyncClient, db_session):
    member = await _member(db_session)
    headers = await _committee_headers(db_session)
    # 1 member present, but 3 votes cast.
    payload = _meeting_payload([member.id])
    payload["resolutions"][0]["vote_for"] = 3
    response = await client.post(
        "/api/resolution-book/meetings", json=payload, headers=headers
    )
    assert response.status_code == 422
    assert "উপস্থিত" in response.json()["detail"]
    # No partial meeting left behind (atomic).
    from app.models.resolution_book import Meeting

    remaining = (await db_session.execute(sa_select(Meeting))).scalars().all()
    assert remaining == []


async def test_attendance_shrink_revalidates_existing_votes(client: AsyncClient, db_session):
    member = await _member(db_session)
    member2 = await _member(db_session, name="সদস্য ২", email="rb-member2@x.com")
    headers = await _committee_headers(db_session)
    body = await _create_meeting(client, headers, [member.id, member2.id])
    # Mark one member absent -> existing votes (2 for + 1 against = 3) exceed presence (1).
    response = await client.post(
        f"/api/resolution-book/meetings/{body['id']}/attendance",
        json={"entries": [{"member_id": member.id, "status": "present"}]},
        headers=headers,
    )
    assert response.status_code == 422


async def test_resolution_status_update_audited_and_noticed(client: AsyncClient, db_session):
    member = await _member(db_session)
    headers = await _committee_headers(db_session)
    body = await _create_meeting(client, headers, [member.id])
    resolution = body["resolutions"][0]
    response = await client.put(
        f"/api/resolution-book/resolutions/{resolution['id']}",
        json={"status": "done"},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    assert response.json()["resolution"]["status"] == "done"
    audits = (
        await db_session.execute(sa_select(AuditLog).where(AuditLog.action == "resolution.update"))
    ).scalars().all()
    assert audits
    notices = (await db_session.execute(sa_select(Notice))).scalars().all()
    assert any("সিদ্ধান্ত বাস্তবায়িত" in n.title for n in notices)


async def test_search_matches_resolution_text(client: AsyncClient, db_session):
    member = await _member(db_session)
    headers = await _committee_headers(db_session)
    await _create_meeting(client, headers, [member.id])

    member_headers = _headers(member.id, "member")
    response = await client.get(
        "/api/resolution-book/search", params={"q": "রাস্তার"}, headers=member_headers
    )
    assert response.status_code == 200
    body = response.json()
    assert body["total"] == 1
    assert body["matched_resolutions"]
    assert body["matched_resolutions"][str(body["items"][0]["id"])][0]["decision"].startswith("রাস্তার")

    response = await client.get(
        "/api/resolution-book/search", params={"q": "কোনোম্যাচনেই"}, headers=member_headers
    )
    assert response.json()["total"] == 0


async def test_dashboard_summary(client: AsyncClient, db_session):
    member = await _member(db_session)
    headers = await _committee_headers(db_session)
    await _create_meeting(
        client, headers, [member.id], next_meeting_date="2026-12-15"
    )
    member_headers = _headers(member.id, "member")
    response = await client.get("/api/resolution-book/summary", headers=member_headers)
    assert response.status_code == 200
    body = response.json()
    assert body["total_meetings"] == 1
    assert body["meetings_this_year"] == 1
    assert body["average_attendance_percent"] == 100
    assert body["open_action_items"] == 1
    assert body["upcoming_meeting_date"] == "2026-12-15"


async def test_minutes_pdf_export(client: AsyncClient, db_session):
    member = await _member(db_session)
    headers = await _committee_headers(db_session)
    body = await _create_meeting(client, headers, [member.id])
    member_headers = _headers(member.id, "member")
    response = await client.get(
        f"/api/resolution-book/meetings/{body['id']}/export.pdf", headers=member_headers
    )
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert response.content[:5] == b"%PDF-"


async def test_suggested_meeting_no_skips_taken(client: AsyncClient, db_session):
    member = await _member(db_session)
    headers = await _committee_headers(db_session)
    response = await client.get(
        "/api/resolution-book/meetings/suggest-no", params={"for_date": "2026-10-01"}, headers=headers
    )
    assert response.status_code == 200
    assert response.json() == {"meeting_no": "SVA-2026-001", "available": True}
    await _create_meeting(client, headers, [member.id])
    response = await client.get(
        "/api/resolution-book/meetings/suggest-no", params={"for_date": "2026-10-01"}, headers=headers
    )
    assert response.json()["meeting_no"] == "SVA-2026-002"
