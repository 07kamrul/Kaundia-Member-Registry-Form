import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.admin import AdminRole, AdminUser
from app.models.audit_log import AuditLog
from app.models.rbac import Role

pytestmark = pytest.mark.asyncio


async def _login(client: AsyncClient) -> dict[str, str]:
    response = await client.post(
        "/api/admin/login", json={"email": "admin@example.com", "password": "adminpass123"}
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


async def _add_category(client: AsyncClient, headers: dict[str, str], category: str, value: str) -> int:
    response = await client.post(
        "/api/admin/config-lists",
        json={"category": category, "value": value, "label": value},
        headers=headers,
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


def _public_titles(rows: list[dict]) -> list[str]:
    return [row["title"] for row in rows]


async def test_admin_notice_endpoints_are_gated_by_manage_notices(
    client: AsyncClient, db_session: AsyncSession, admin_user: AdminUser
) -> None:
    """Every notice/event admin route rejects callers without `manage_notices` -
    not just the ones the UI happens to render."""
    headers = await _login(client)

    # An admin whose (non-super) role row grants nothing at all.
    role = Role(name="notice-free", description="no permissions")
    db_session.add(role)
    await db_session.flush()
    under_privileged = AdminUser(
        email="limited@example.com",
        password_hash=hash_password("adminpass123"),
        name="Limited",
        role=AdminRole.ADMINISTRATOR,
        role_id=role.id,
    )
    db_session.add(under_privileged)
    await db_session.commit()
    limited_login = await client.post(
        "/api/admin/login", json={"email": "limited@example.com", "password": "adminpass123"}
    )
    assert limited_login.status_code == 200
    limited = {"Authorization": f"Bearer {limited_login.json()['access_token']}"}

    notice_body = {"title": "t", "body": "b"}
    event_body = {"title": "t", "start_at": "2030-01-01T10:00:00Z"}

    cases = [
        ("GET", "/api/admin/notices", None),
        ("POST", "/api/admin/notices", notice_body),
        ("PATCH", "/api/admin/notices/1", notice_body),
        ("DELETE", "/api/admin/notices/1", None),
        ("GET", "/api/admin/events", None),
        ("POST", "/api/admin/events", event_body),
        ("PATCH", "/api/admin/events/1", event_body),
        ("DELETE", "/api/admin/events/1", None),
    ]

    for method, path, body in cases:
        # No token at all -> 401 on every route.
        anon = await client.request(method, path, json=body)
        assert anon.status_code == 401, f"{method} {path}: {anon.status_code}"

        # Token without the permission -> 403 on every route.
        forbidden = await client.request(method, path, json=body, headers=limited)
        assert forbidden.status_code == 403, f"{method} {path}: {forbidden.status_code}"
        assert "manage_notices" in forbidden.json()["detail"]

        # The privileged admin gets past the gate (404/201/204, never 401/403).
        allowed = await client.request(method, path, json=body, headers=headers)
        assert allowed.status_code not in (401, 403), f"{method} {path}: {allowed.status_code}"


async def test_public_notices_only_show_published_and_live(
    client: AsyncClient, admin_user: AdminUser
) -> None:
    headers = await _login(client)

    draft = await client.post(
        "/api/admin/notices",
        json={"title": "Draft notice", "body": "not yet"},
        headers=headers,
    )
    assert draft.status_code == 201
    notice_id = draft.json()["id"]

    listed = await client.get("/api/public/notices")
    assert listed.status_code == 200
    assert _public_titles(listed.json()) == []

    # Publish -> live (no publish_at set means "immediately").
    published = await client.patch(
        f"/api/admin/notices/{notice_id}", json={"is_published": True}, headers=headers
    )
    assert published.status_code == 200
    listed = await client.get("/api/public/notices")
    assert _public_titles(listed.json()) == ["Draft notice"]

    # Published but scheduled for the future -> hidden again.
    await client.patch(
        f"/api/admin/notices/{notice_id}",
        json={"publish_at": "2999-01-01T00:00:00Z"},
        headers=headers,
    )
    listed = await client.get("/api/public/notices")
    assert _public_titles(listed.json()) == []

    # Scheduled time reached -> live.
    await client.patch(
        f"/api/admin/notices/{notice_id}",
        json={"publish_at": "2020-01-01T00:00:00Z"},
        headers=headers,
    )
    listed = await client.get("/api/public/notices")
    assert _public_titles(listed.json()) == ["Draft notice"]

    # Unpublish -> hidden again.
    await client.patch(
        f"/api/admin/notices/{notice_id}", json={"is_published": False}, headers=headers
    )
    listed = await client.get("/api/public/notices")
    assert _public_titles(listed.json()) == []

    # Members-only rows are filtered out of the public endpoint entirely.
    await client.post(
        "/api/admin/notices",
        json={
            "title": "Members only",
            "body": "internal",
            "is_published": True,
            "is_members_only": True,
        },
        headers=headers,
    )
    listed = await client.get("/api/public/notices")
    assert _public_titles(listed.json()) == []


async def test_public_notices_pagination_and_newest_first(
    client: AsyncClient, admin_user: AdminUser
) -> None:
    headers = await _login(client)
    for index in range(3):
        response = await client.post(
            "/api/admin/notices",
            json={"title": f"Notice {index}", "body": "b", "is_published": True},
            headers=headers,
        )
        assert response.status_code == 201

    all_rows = (await client.get("/api/public/notices")).json()
    assert _public_titles(all_rows) == ["Notice 2", "Notice 1", "Notice 0"]

    first_page = (await client.get("/api/public/notices?limit=2")).json()
    assert _public_titles(first_page) == ["Notice 2", "Notice 1"]

    second_page = (await client.get("/api/public/notices?limit=2&offset=2")).json()
    assert _public_titles(second_page) == ["Notice 0"]


async def test_admin_notice_filters_and_category_validation(
    client: AsyncClient, admin_user: AdminUser
) -> None:
    headers = await _login(client)
    notice_category = await _add_category(client, headers, "notice_category", "সাধারণ")
    event_category = await _add_category(client, headers, "event_category", "সভা")

    draft = (
        await client.post(
            "/api/admin/notices", json={"title": "Draft", "body": "b"}, headers=headers
        )
    ).json()
    live = (
        await client.post(
            "/api/admin/notices",
            json={"title": "Live", "body": "b", "is_published": True, "category_id": notice_category},
            headers=headers,
        )
    ).json()

    published = (await client.get("/api/admin/notices?published=true", headers=headers)).json()
    assert [row["title"] for row in published] == ["Live"]
    drafts = (await client.get("/api/admin/notices?published=false", headers=headers)).json()
    assert [row["title"] for row in drafts] == ["Draft"]

    by_category = (
        await client.get(f"/api/admin/notices?category_id={notice_category}", headers=headers)
    ).json()
    assert [row["title"] for row in by_category] == ["Live"]
    assert draft["category_id"] is None
    assert live["category_id"] == notice_category

    # A notice may not be filed under the event categories, and a missing
    # category id is a 400 rather than an opaque FK failure.
    wrong_list = await client.post(
        "/api/admin/notices",
        json={"title": "Misfiled", "body": "b", "category_id": event_category},
        headers=headers,
    )
    assert wrong_list.status_code == 400
    unknown = await client.post(
        "/api/admin/notices",
        json={"title": "Ghost", "body": "b", "category_id": 99999},
        headers=headers,
    )
    assert unknown.status_code == 400

    deleted = await client.delete(f"/api/admin/notices/{draft['id']}", headers=headers)
    assert deleted.status_code == 204
    missing = await client.patch(
        f"/api/admin/notices/{draft['id']}", json={"title": "x"}, headers=headers
    )
    assert missing.status_code == 404


async def test_public_events_upcoming_first_and_only_published(
    client: AsyncClient, admin_user: AdminUser
) -> None:
    headers = await _login(client)

    async def create_event(payload: dict) -> dict:
        response = await client.post("/api/admin/events", json=payload, headers=headers)
        assert response.status_code == 201, response.text
        return response.json()

    await create_event(
        {"title": "Long past", "start_at": "2020-05-01T10:00:00Z", "is_published": True}
    )
    await create_event(
        {"title": "Recent past", "start_at": "2024-05-01T10:00:00Z", "is_published": True}
    )
    await create_event({"title": "Later", "start_at": "2035-05-01T10:00:00Z", "is_published": True})
    await create_event({"title": "Sooner", "start_at": "2030-05-01T10:00:00Z", "is_published": True})
    await create_event({"title": "Draft", "start_at": "2029-01-01T10:00:00Z"})
    await create_event(
        {
            "title": "Members only",
            "start_at": "2029-01-01T10:00:00Z",
            "is_published": True,
            "is_members_only": True,
        }
    )

    listed = await client.get("/api/public/events")
    assert listed.status_code == 200
    # Upcoming (soonest first) then past (most recent first); drafts and
    # members-only rows never appear.
    assert _public_titles(listed.json()) == ["Sooner", "Later", "Recent past", "Long past"]

    page = (await client.get("/api/public/events?limit=2")).json()
    assert _public_titles(page) == ["Sooner", "Later"]

    # end_at before start_at is rejected on create and on update.
    bad_range = await client.post(
        "/api/admin/events",
        json={"title": "Backwards", "start_at": "2030-05-01T10:00:00Z", "end_at": "2030-05-01T09:00:00Z"},
        headers=headers,
    )
    assert bad_range.status_code == 400

    created = await create_event(
        {"title": "Range", "start_at": "2031-05-01T10:00:00Z", "end_at": "2031-05-01T12:00:00Z"}
    )
    bad_update = await client.patch(
        f"/api/admin/events/{created['id']}",
        json={"end_at": "2031-05-01T08:00:00Z"},
        headers=headers,
    )
    assert bad_update.status_code == 400

    # The management list orders by start_at (soonest first) and honours filters.
    admin_list = (await client.get("/api/admin/events", headers=headers)).json()
    assert _public_titles(admin_list)[0] == "Long past"
    drafts = (await client.get("/api/admin/events?published=false", headers=headers)).json()
    assert [row["title"] for row in drafts] == ["Draft", "Range"]


async def test_every_mutation_writes_an_audit_row(
    client: AsyncClient, db_session: AsyncSession, admin_user: AdminUser
) -> None:
    headers = await _login(client)

    created = await client.post(
        "/api/admin/notices", json={"title": "Audited", "body": "b"}, headers=headers
    )
    assert created.status_code == 201
    notice_id = created.json()["id"]

    await client.patch(
        f"/api/admin/notices/{notice_id}", json={"is_published": True}, headers=headers
    )
    await client.delete(f"/api/admin/notices/{notice_id}", headers=headers)

    event_created = await client.post(
        "/api/admin/events",
        json={"title": "Audited event", "start_at": "2030-05-01T10:00:00Z"},
        headers=headers,
    )
    assert event_created.status_code == 201
    event_id = event_created.json()["id"]
    await client.patch(
        f"/api/admin/events/{event_id}", json={"is_published": True}, headers=headers
    )
    await client.delete(f"/api/admin/events/{event_id}", headers=headers)

    rows = (await db_session.execute(select(AuditLog))).scalars().all()
    actions = sorted(row.action for row in rows if row.entity_type in ("notice", "event"))
    assert actions == [
        "event.create",
        "event.delete",
        "event.update",
        "notice.create",
        "notice.delete",
        "notice.update",
    ]
    notice_rows = [row for row in rows if row.entity_type == "notice"]
    assert all(row.actor_admin_id == admin_user.id for row in notice_rows)
    assert all(row.entity_id for row in rows)
