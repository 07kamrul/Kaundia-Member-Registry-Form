"""Society roadmap: member read view with per-timeframe completion, committee
CRUD/status/move/reorder/archive, permission gating, notices integration,
audit trail and the PDF handout."""

import pytest
from httpx import AsyncClient
from sqlalchemy import select as sa_select

from app.core.security import create_access_token, hash_password
from app.models.admin import AdminRole, AdminUser
from app.models.audit_log import AuditLog
from app.models.member import Member, MemberStatus
from app.models.notice import Notice
from app.services.roadmap import completion_percent

pytestmark = pytest.mark.asyncio


def _headers(account_id: int | str, role: str) -> dict:
    return {"Authorization": f"Bearer {create_access_token(str(account_id), role)}"}


async def _member(db_session) -> Member:
    member = Member(
        status=MemberStatus.APPROVED,
        member_id="UKAMKS-77",
        full_name="সদস্য",
        father_or_husband="Father",
        mother="Mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="Job",
        nid="1234567899",
        mobile="01758290499",
        gender="পুরুষ",
        email="roadmap-member@x.com",
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


async def _admin_headers(db_session) -> dict:
    admin = AdminUser(
        email="roadmap-admin@x.com",
        password_hash=hash_password("pass12345"),
        name="Committee",
        role=AdminRole.EXECUTIVE_COMMITTEE,
    )
    db_session.add(admin)
    await db_session.commit()
    await db_session.refresh(admin)
    return _headers(admin.id, admin.role.value)


async def _timeframes(client: AsyncClient, headers: dict) -> dict[str, dict]:
    response = await client.get("/api/roadmap", headers=headers)
    assert response.status_code == 200
    return {tf["key"]: tf for tf in response.json()["timeframes"]}


async def _create(client, headers, timeframe_id, text, **extra) -> dict:
    response = await client.post(
        "/api/admin/roadmap/items",
        json={"timeframe_id": timeframe_id, "text": text, **extra},
        headers=headers,
    )
    assert response.status_code == 201, response.text
    return response.json()


def _section(payload: dict, key: str) -> dict:
    return next(tf for tf in payload["timeframes"] if tf["key"] == key)


async def test_completion_percent_rounds_and_handles_empty():
    assert completion_percent(0, 0) == 0
    assert completion_percent(3, 8) == 38
    assert completion_percent(8, 8) == 100


async def test_roadmap_requires_login(client: AsyncClient):
    assert (await client.get("/api/roadmap")).status_code == 401


async def test_member_sees_three_ordered_timeframes(client: AsyncClient, db_session):
    member = await _member(db_session)
    response = await client.get("/api/roadmap", headers=_headers(member.id, "member"))
    assert response.status_code == 200
    body = response.json()
    assert [tf["key"] for tf in body["timeframes"]] == ["short", "mid", "long"]
    assert body["totals"] == {"total": 0, "done": 0, "in_progress": 0, "planned": 0, "percent": 0}


async def test_member_cannot_manage_roadmap(client: AsyncClient, db_session):
    member = await _member(db_session)
    headers = _headers(member.id, "member")
    tfs = await _timeframes(client, headers)
    response = await client.post(
        "/api/admin/roadmap/items", json={"timeframe_id": tfs["short"]["id"], "text": "x"}, headers=headers
    )
    assert response.status_code in (401, 403)


async def test_create_item_publishes_notice_and_audits(client: AsyncClient, db_session):
    headers = await _admin_headers(db_session)
    tfs = await _timeframes(client, headers)
    body = await _create(client, headers, tfs["short"]["id"], "ব্যাংক অ্যাকাউন্ট খোলা", owner="কোষাধ্যক্ষ")

    short = _section(body, "short")
    assert short["total"] == 1 and short["items"][0]["owner"] == "কোষাধ্যক্ষ"
    notices = (await db_session.execute(sa_select(Notice))).scalars().all()
    assert len(notices) == 1 and notices[0].title.startswith("🆕 নতুন পরিকল্পনা")
    actions = {a.action for a in (await db_session.execute(sa_select(AuditLog))).scalars().all()}
    assert {"roadmap_item.create", "roadmap_item.notice_published"} <= actions


async def test_create_without_notify_skips_notice(client: AsyncClient, db_session):
    headers = await _admin_headers(db_session)
    tfs = await _timeframes(client, headers)
    await _create(client, headers, tfs["mid"]["id"], "পিকনিক", notify=False)
    assert (await db_session.execute(sa_select(Notice))).scalars().all() == []


async def test_status_done_recomputes_percent_and_notifies(client: AsyncClient, db_session):
    headers = await _admin_headers(db_session)
    tfs = await _timeframes(client, headers)
    tf_id = tfs["mid"]["id"]
    for text in ("এক", "দুই", "তিন"):
        body = await _create(client, headers, tf_id, text, notify=False)
    item_id = _section(body, "mid")["items"][0]["id"]

    response = await client.post(
        f"/api/admin/roadmap/items/{item_id}/status", json={"status": "done"}, headers=headers
    )
    assert response.status_code == 200
    mid = _section(response.json(), "mid")
    assert (mid["done"], mid["total"], mid["percent"]) == (1, 3, 33)
    assert next(i for i in mid["items"] if i["id"] == item_id)["completed_at"] is not None

    notices = (await db_session.execute(sa_select(Notice))).scalars().all()
    assert [n.title for n in notices] == ["✅ সম্পন্ন: এক"]

    # Back to in-progress clears the completion date and does not re-notify.
    response = await client.post(
        f"/api/admin/roadmap/items/{item_id}/status", json={"status": "in_progress"}, headers=headers
    )
    mid = _section(response.json(), "mid")
    assert mid["done"] == 0 and mid["in_progress"] == 1
    assert next(i for i in mid["items"] if i["id"] == item_id)["completed_at"] is None
    assert len((await db_session.execute(sa_select(Notice))).scalars().all()) == 1


async def test_future_completion_date_rejected(client: AsyncClient, db_session):
    headers = await _admin_headers(db_session)
    tfs = await _timeframes(client, headers)
    body = await _create(client, headers, tfs["short"]["id"], "কাজ", notify=False)
    item_id = _section(body, "short")["items"][0]["id"]
    response = await client.post(
        f"/api/admin/roadmap/items/{item_id}/status",
        json={"status": "done", "completed_at": "2999-01-01"},
        headers=headers,
    )
    assert response.status_code == 400


async def test_move_between_timeframes_and_edit_fields(client: AsyncClient, db_session):
    headers = await _admin_headers(db_session)
    tfs = await _timeframes(client, headers)
    body = await _create(client, headers, tfs["short"]["id"], "অফিস", note="পুরনো", notify=False)
    item_id = _section(body, "short")["items"][0]["id"]

    response = await client.put(
        f"/api/admin/roadmap/items/{item_id}",
        json={"timeframe_id": tfs["long"]["id"], "note": None, "target_date": "2027-03-01"},
        headers=headers,
    )
    assert response.status_code == 200
    payload = response.json()
    assert _section(payload, "short")["total"] == 0
    moved = _section(payload, "long")["items"][0]
    assert moved["note"] is None and moved["target_date"] == "2027-03-01"
    audit = (
        await db_session.execute(sa_select(AuditLog).where(AuditLog.action == "roadmap_item.update"))
    ).scalar_one()
    assert "moved short -> long" in audit.detail


async def test_reorder_validates_and_applies(client: AsyncClient, db_session):
    headers = await _admin_headers(db_session)
    tfs = await _timeframes(client, headers)
    tf_id = tfs["short"]["id"]
    for text in ("ক", "খ", "গ"):
        body = await _create(client, headers, tf_id, text, notify=False)
    ids = [i["id"] for i in _section(body, "short")["items"]]

    bad = await client.post(
        "/api/admin/roadmap/reorder", json={"timeframe_id": tf_id, "item_ids": ids[:2]}, headers=headers
    )
    assert bad.status_code == 400

    response = await client.post(
        "/api/admin/roadmap/reorder", json={"timeframe_id": tf_id, "item_ids": ids[::-1]}, headers=headers
    )
    assert response.status_code == 200
    assert [i["text"] for i in _section(response.json(), "short")["items"]] == ["গ", "খ", "ক"]


async def test_delete_hides_item_from_members(client: AsyncClient, db_session):
    headers = await _admin_headers(db_session)
    tfs = await _timeframes(client, headers)
    body = await _create(client, headers, tfs["short"]["id"], "মুছে ফেলা হবে", notify=False)
    item_id = _section(body, "short")["items"][0]["id"]

    response = await client.delete(f"/api/admin/roadmap/items/{item_id}", headers=headers)
    assert response.status_code == 200
    assert _section(response.json(), "short")["total"] == 0
    missing = await client.delete(f"/api/admin/roadmap/items/{item_id}", headers=headers)
    assert missing.status_code == 404


async def test_archive_done_only_carries_unfinished_over(client: AsyncClient, db_session):
    headers = await _admin_headers(db_session)
    tfs = await _timeframes(client, headers)
    tf_id = tfs["short"]["id"]
    await _create(client, headers, tf_id, "শেষ", status="done", notify=False)
    await _create(client, headers, tf_id, "চলছে", status="in_progress", notify=False)

    response = await client.post("/api/admin/roadmap/archive?only_done=true", headers=headers)
    assert response.status_code == 200 and response.json() == {"archived": 1}
    short = (await _timeframes(client, headers))["short"]
    assert [i["text"] for i in short["items"]] == ["চলছে"]

    archive = await client.get("/api/admin/roadmap/archive", headers=headers)
    assert archive.status_code == 200
    cycles = archive.json()
    assert len(cycles) == 1 and cycles[0]["done"] == 1


async def test_archive_with_nothing_active_is_400(client: AsyncClient, db_session):
    headers = await _admin_headers(db_session)
    response = await client.post("/api/admin/roadmap/archive", headers=headers)
    assert response.status_code == 400


async def test_pdf_export_for_member(client: AsyncClient, db_session):
    headers = await _admin_headers(db_session)
    tfs = await _timeframes(client, headers)
    await _create(client, headers, tfs["short"]["id"], "সদস্য নিবন্ধন", status="done", notify=False)
    await _create(client, headers, tfs["long"]["id"], "রাস্তা উন্নয়ন", note="শুরু হয়েছে", notify=False)

    member = await _member(db_session)
    response = await client.get("/api/roadmap/export.pdf", headers=_headers(member.id, "member"))
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert response.content.startswith(b"%PDF")
