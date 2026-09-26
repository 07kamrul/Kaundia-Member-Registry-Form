import pytest
from httpx import AsyncClient

from app.models.admin import AdminUser

pytestmark = pytest.mark.asyncio


async def test_unified_login_with_admin_email(client: AsyncClient, admin_user: AdminUser) -> None:
    response = await client.post(
        "/api/login", json={"identifier": "admin@example.com", "password": "adminpass123"}
    )
    assert response.status_code == 200
    body = response.json()
    assert body["role"] == "executive_committee"
    assert body["access_token"]


async def test_unified_login_rejects_invalid_credentials(
    client: AsyncClient, admin_user: AdminUser
) -> None:
    wrong_password = await client.post(
        "/api/login", json={"identifier": "admin@example.com", "password": "wrong-password"}
    )
    assert wrong_password.status_code == 401

    unknown_identifier = await client.post(
        "/api/login", json={"identifier": "no-such-user", "password": "whatever"}
    )
    assert unknown_identifier.status_code == 401
