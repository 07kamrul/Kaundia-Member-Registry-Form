import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.admin import AdminRole, AdminUser

pytestmark = pytest.mark.asyncio


@pytest_asyncio.fixture
async def super_admin(db_session: AsyncSession) -> AdminUser:
    admin = AdminUser(
        email="super@example.com",
        password_hash=hash_password("superpass123"),
        name="Super Admin",
        role=AdminRole.SUPER_ADMIN,
    )
    db_session.add(admin)
    await db_session.commit()
    await db_session.refresh(admin)
    return admin


@pytest_asyncio.fixture
async def super_admin_headers(super_admin: AdminUser) -> dict[str, str]:
    token = create_access_token(str(super_admin.id), "super_admin")
    return {"Authorization": f"Bearer {token}"}


async def test_create_admin_user_rejects_case_insensitive_duplicate_email(
    client: AsyncClient, admin_user: AdminUser, super_admin_headers: dict[str, str]
) -> None:
    response = await client.post(
        "/api/admin/rbac/users",
        json={
            "name": "Duplicate Admin",
            "email": "Admin@Example.com",
            "password": "anotherpass123",
            "role": "administrator",
        },
        headers=super_admin_headers,
    )
    assert response.status_code == 400
    assert "already in use" in response.json()["detail"].lower()


async def test_create_admin_user_stores_normalized_email(
    client: AsyncClient, super_admin_headers: dict[str, str]
) -> None:
    response = await client.post(
        "/api/admin/rbac/users",
        json={
            "name": "New Admin",
            "email": " New.Admin@Example.com ",
            "password": "newpass123",
            "role": "administrator",
        },
        headers=super_admin_headers,
    )
    assert response.status_code == 201
    assert response.json()["email"] == "new.admin@example.com"
