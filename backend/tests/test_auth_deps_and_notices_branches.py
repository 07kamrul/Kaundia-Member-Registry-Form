"""Auth dependency edge cases and notices/events 404 + validation branches."""

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token, create_refresh_token, hash_password
from app.models.admin import AdminRole, AdminUser

pytestmark = pytest.mark.asyncio


async def _ec_admin(db_session) -> AdminUser:
    admin = AdminUser(
        email="ec-admin@example.com",
        password_hash=hash_password("adminpass123"),
        name="EC",
        role=AdminRole.EXECUTIVE_COMMITTEE,
    )
    db_session.add(admin)
    await db_session.commit()
    await db_session.refresh(admin)
    return admin


class TestAuthDependencyEdges:
    async def test_missing_authorization_header_is_401(self, client: AsyncClient) -> None:
        response = await client.get("/api/admin/submissions")
        assert response.status_code == 401

    async def test_refresh_token_is_not_a_valid_access_token(
        self, client: AsyncClient, db_session, admin_user: AdminUser
    ) -> None:
        refresh = create_refresh_token(str(admin_user.id), "executive_committee")
        response = await client.get(
            "/api/admin/submissions", headers={"Authorization": f"Bearer {refresh}"}
        )
        assert response.status_code == 401

    async def test_token_with_non_numeric_subject_is_401(
        self, client: AsyncClient, db_session, admin_user: AdminUser
    ) -> None:
        token = create_access_token("not-a-number", "executive_committee")
        response = await client.get(
            "/api/admin/submissions", headers={"Authorization": f"Bearer {token}"}
        )
        assert response.status_code == 401

    async def test_member_role_token_rejected_on_admin_endpoint(
        self, client: AsyncClient, db_session, admin_user: AdminUser
    ) -> None:
        token = create_access_token(str(admin_user.id), "member")
        response = await client.get(
            "/api/admin/submissions", headers={"Authorization": f"Bearer {token}"}
        )
        assert response.status_code == 403

    async def test_admin_role_token_rejected_on_member_endpoint(
        self, client: AsyncClient, db_session, admin_user: AdminUser
    ) -> None:
        token = create_access_token(str(admin_user.id), "executive_committee")
        response = await client.get(
            "/api/member/me", headers={"Authorization": f"Bearer {token}"}
        )
        assert response.status_code == 403

    async def test_unknown_role_token_rejected_on_shared_endpoint(
        self, client: AsyncClient, db_session, admin_user: AdminUser
    ) -> None:
        token = create_access_token(str(admin_user.id), "member")
        # picnic-rates uses get_account_actor; a stale/unknown role claim must
        # fail closed. "member" with an admin-user subject has no Member row.
        response = await client.get(
            "/api/member/picnic-rates", headers={"Authorization": f"Bearer {token}"}
        )
        assert response.status_code in (401, 403)


class TestNoticesEventsBranches:
    async def _headers(self, client: AsyncClient) -> dict:
        login = await client.post(
            "/api/admin/login", json={"email": "admin@example.com", "password": "adminpass123"}
        )
        return {"Authorization": f"Bearer {login.json()['access_token']}"}

    async def test_update_and_delete_missing_notice_404(
        self, client: AsyncClient, db_session, admin_user: AdminUser
    ) -> None:
        headers = await self._headers(client)
        assert (
            await client.patch(
                "/api/admin/notices/424242", json={"title": "x"}, headers=headers
            )
        ).status_code == 404
        assert (
            await client.delete("/api/admin/notices/424242", headers=headers)
        ).status_code == 404
        assert (
            await client.patch(
                "/api/admin/events/424242", json={"title": "x"}, headers=headers
            )
        ).status_code == 404
        assert (
            await client.delete("/api/admin/events/424242", headers=headers)
        ).status_code == 404

    async def test_notice_with_unknown_category_400(
        self, client: AsyncClient, db_session, admin_user: AdminUser
    ) -> None:
        headers = await self._headers(client)
        created = await client.post(
            "/api/admin/notices",
            json={"title": "T", "body": "B", "category_id": 987654},
            headers=headers,
        )
        assert created.status_code == 400
        assert "category" in created.json()["detail"].lower()

    async def test_event_with_invalid_date_range_400(
        self, client: AsyncClient, db_session, admin_user: AdminUser
    ) -> None:
        headers = await self._headers(client)
        created = await client.post(
            "/api/admin/events",
            json={
                "title": "Backwards",
                "description": "d",
                "location": "loc",
                "start_at": "2026-11-02T10:00:00",
                "end_at": "2026-11-01T10:00:00",
                "is_published": True,
                "is_members_only": False,
            },
            headers=headers,
        )
        assert created.status_code == 400
