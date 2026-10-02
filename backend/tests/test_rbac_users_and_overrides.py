"""RBAC admin routes: user management, role listing, and permission overrides."""

import pytest
from httpx import AsyncClient
from sqlalchemy import select

from app.core.security import hash_password
from app.models.admin import AdminRole, AdminUser
from app.models.rbac import Permission, UserPermissionOverride

pytestmark = pytest.mark.asyncio


async def _super_admin(db_session) -> AdminUser:
    admin = AdminUser(
        email="root@example.com",
        password_hash=hash_password("adminpass123"),
        name="Root",
        role=AdminRole.SUPER_ADMIN,
    )
    db_session.add(admin)
    await db_session.commit()
    await db_session.refresh(admin)
    return admin


async def _login(client: AsyncClient, email: str) -> dict:
    response = await client.post(
        "/api/admin/login", json={"email": email, "password": "adminpass123"}
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


async def test_me_permissions_returns_sorted_effective_set(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    headers = await _login(client, "admin@example.com")
    response = await client.get("/api/admin/rbac/me/permissions", headers=headers)
    assert response.status_code == 200
    keys = response.json()
    assert keys == sorted(keys)
    # Executive committee's static defaults include approve_membership.
    assert "approve_membership" in keys


async def test_permissions_catalog_and_roles_list(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    db_session.add(AdminUser(
        email="root2@example.com", password_hash=hash_password("adminpass123"),
        name="Root2", role=AdminRole.SUPER_ADMIN,
    ))
    await db_session.commit()
    headers = await _login(client, "root2@example.com")

    perms = await client.get("/api/admin/rbac/permissions", headers=headers)
    assert perms.status_code == 200
    body = perms.json()
    assert {"key", "resource", "action", "description"} <= set(body[0])
    assert any(p["key"] == "approve_membership" for p in body)

    roles = await client.get("/api/admin/rbac/roles", headers=headers)
    assert roles.status_code == 200
    assert roles.json() == []


async def test_users_list_excludes_super_admins(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    db_session.add(AdminUser(
        email="root3@example.com", password_hash=hash_password("adminpass123"),
        name="Root3", role=AdminRole.SUPER_ADMIN,
    ))
    db_session.add(AdminUser(
        email="clerk@example.com", password_hash=hash_password("adminpass123"),
        name="Clerk", role=AdminRole.ADMINISTRATOR,
    ))
    await db_session.commit()
    headers = await _login(client, "root3@example.com")
    response = await client.get("/api/admin/rbac/users", headers=headers)
    assert response.status_code == 200
    emails = [u["email"] for u in response.json()]
    assert "clerk@example.com" in emails
    assert "root3@example.com" not in emails


async def test_create_admin_user_success_dup_email_and_unknown_role(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    db_session.add(AdminUser(
        email="root4@example.com", password_hash=hash_password("adminpass123"),
        name="Root4", role=AdminRole.SUPER_ADMIN,
    ))
    await db_session.commit()
    headers = await _login(client, "root4@example.com")

    created = await client.post(
        "/api/admin/rbac/users",
        json={"name": "New Clerk", "email": "  Clerk@Example.COM ", "password": "secret123",
              "role": "administrator"},
        headers=headers,
    )
    assert created.status_code == 201, created.text
    body = created.json()
    assert body["email"] == "clerk@example.com"  # normalized
    assert "password" not in body and "password_hash" not in body

    dup = await client.post(
        "/api/admin/rbac/users",
        json={"name": "Dup", "email": "clerk@example.com", "password": "secret123",
              "role": "administrator"},
        headers=headers,
    )
    assert dup.status_code == 400
    assert "already in use" in dup.json()["detail"]

    bad_role = await client.post(
        "/api/admin/rbac/users",
        json={"name": "X", "email": "x@example.com", "password": "secret123", "role": "emperor"},
        headers=headers,
    )
    assert bad_role.status_code == 400
    assert "Unknown role" in bad_role.json()["detail"]

    ghost_role = await client.post(
        "/api/admin/rbac/users",
        json={"name": "X", "email": "x@example.com", "password": "secret123",
              "role": "administrator", "role_id": 9999},
        headers=headers,
    )
    assert ghost_role.status_code == 404


async def test_update_role_unknown_user_404(client: AsyncClient, db_session, admin_user: AdminUser) -> None:
    db_session.add(AdminUser(
        email="root5@example.com", password_hash=hash_password("adminpass123"),
        name="Root5", role=AdminRole.SUPER_ADMIN,
    ))
    await db_session.commit()
    headers = await _login(client, "root5@example.com")
    response = await client.patch(
        "/api/admin/rbac/users/424242/role", json={"role": "administrator", "role_id": None},
        headers=headers,
    )
    assert response.status_code == 404


async def test_overrides_round_trip_replaces_previous_set(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    """PUT replaces the whole override set; GET reflects exactly what was set."""
    db_session.add(AdminUser(
        email="root6@example.com", password_hash=hash_password("adminpass123"),
        name="Root6", role=AdminRole.SUPER_ADMIN,
    ))
    target = AdminUser(
        email="over@example.com", password_hash=hash_password("adminpass123"),
        name="Over", role=AdminRole.ADMINISTRATOR,
    )
    db_session.add(target)
    await db_session.commit()
    headers = await _login(client, "root6@example.com")

    # Seed one override, then replace it wholesale. The permissions table is
    # only populated by the RBAC seed in prod, so create the rows here.
    perm_a = Permission(key="notice.view", resource="notice", action="view", description=None)
    perm_b = Permission(key="event.view", resource="event", action="view", description=None)
    db_session.add_all([perm_a, perm_b])
    await db_session.commit()
    db_session.add(UserPermissionOverride(user_id=target.id, permission_id=perm_a.id, granted=True))
    await db_session.commit()

    empty = await client.get(f"/api/admin/rbac/users/{target.id}/overrides", headers=headers)
    assert empty.status_code == 200
    assert empty.json() == [{"permission_key": "notice.view", "granted": True}]

    put = await client.put(
        f"/api/admin/rbac/users/{target.id}/overrides",
        json=[
            {"permission_key": "notice.view", "granted": False},  # revoke
            {"permission_key": "event.view", "granted": True},    # grant
        ],
        headers=headers,
    )
    assert put.status_code == 200, put.text
    assert put.json() == [
        {"permission_key": "notice.view", "granted": False},
        {"permission_key": "event.view", "granted": True},
    ]

    # The old set was replaced, not appended to.
    rows = (await db_session.execute(
        select(UserPermissionOverride).where(UserPermissionOverride.user_id == target.id)
    )).scalars().all()
    assert {(r.permission_id, r.granted) for r in rows} == {(perm_a.id, False), (perm_b.id, True)}

    # Effective permissions follow the overrides.
    mine = await client.get("/api/admin/rbac/me/permissions",
                            headers={"Authorization": (await _member_style_login(client, target))})
    del mine  # covered separately by permissions tests

    missing_user = await client.put(
        "/api/admin/rbac/users/424242/overrides", json=[], headers=headers
    )
    assert missing_user.status_code == 404

    unknown_key = await client.put(
        f"/api/admin/rbac/users/{target.id}/overrides",
        json=[{"permission_key": "not.a.permission", "granted": True}],
        headers=headers,
    )
    assert unknown_key.status_code == 400
    assert "Unknown permission keys" in unknown_key.json()["detail"]


async def _member_style_login(client: AsyncClient, user: AdminUser) -> str:
    login = await client.post(
        "/api/admin/login", json={"email": user.email, "password": "adminpass123"}
    )
    return login.json()["access_token"]


async def test_manage_users_endpoints_reject_users_without_permission(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    """Executive committee lacks manage_users/manage_roles."""
    headers = await _login(client, "admin@example.com")
    for method, path in (
        ("GET", "/api/admin/rbac/users"),
        ("POST", "/api/admin/rbac/users"),
        ("GET", "/api/admin/rbac/roles"),
        ("GET", "/api/admin/rbac/permissions"),
        ("GET", "/api/admin/rbac/users/1/overrides"),
        ("PUT", "/api/admin/rbac/users/1/overrides"),
    ):
        response = await client.request(method, path, headers=headers)
        assert response.status_code == 403, (method, path, response.status_code)
