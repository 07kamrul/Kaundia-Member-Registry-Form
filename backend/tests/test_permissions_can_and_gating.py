"""RBAC: the effective-permission resolution (role permissions ∪ granted
overrides − revoked overrides), endpoint gating 403/200, and the regression
for the auth.role === 'member' edge case (a member-role token whose subject
has no Member row must be rejected, not 500)."""

import pytest
from httpx import AsyncClient
from sqlalchemy import select, text

from app.core.permissions import can, invalidate_permission_cache
from app.core.security import create_access_token, hash_password
from app.models.admin import AdminRole, AdminUser
from app.models.rbac import Permission, Role, UserPermissionOverride, role_permissions

pytestmark = pytest.mark.asyncio


async def _admin(client: AsyncClient, db_session, email: str, role: AdminRole, role_id=None) -> AdminUser:
    admin = AdminUser(
        email=email,
        password_hash=hash_password("adminpass123"),
        name=email.split("@")[0],
        role=role,
        role_id=role_id,
    )
    db_session.add(admin)
    await db_session.commit()
    await db_session.refresh(admin)
    return admin


async def _headers_for(client: AsyncClient, email: str) -> dict:
    response = await client.post(
        "/api/admin/login", json={"email": email, "password": "adminpass123"}
    )
    assert response.status_code == 200, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


async def _seed_permissions(db_session, keys: tuple[str, ...]) -> dict[str, Permission]:
    perms = {}
    for key in keys:
        perm = Permission(key=key, resource=key.split(".")[0], action="test", description=None)
        db_session.add(perm)
        perms[key] = perm
    await db_session.commit()
    return perms


async def test_can_is_role_permissions_union_overrides_minus_revoked(
    client: AsyncClient, db_session
) -> None:
    perms = await _seed_permissions(db_session, ("notice.view", "event.view", "report.view"))
    role = Role(name="clerk", description=None)
    role.permissions = [perms["notice.view"], perms["event.view"]]
    db_session.add(role)
    await db_session.commit()

    admin = await _admin(client, db_session, "clerk@example.com", AdminRole.ADMINISTRATOR, role.id)

    assert await can(db_session, admin, "notice.view") is True
    assert await can(db_session, admin, "event.view") is True
    assert await can(db_session, admin, "report.view") is False

    # Grant an override the role lacks.
    db_session.add(
        UserPermissionOverride(
            user_id=admin.id, permission_id=perms["report.view"].id, granted=True
        )
    )
    await db_session.commit()
    invalidate_permission_cache()
    assert await can(db_session, admin, "report.view") is True

    # Revoke an override the role has.
    db_session.add(
        UserPermissionOverride(
            user_id=admin.id, permission_id=perms["notice.view"].id, granted=False
        )
    )
    await db_session.commit()
    invalidate_permission_cache()
    assert await can(db_session, admin, "notice.view") is False


async def test_gated_endpoints_reject_missing_permission_and_allow_having_it(
    client: AsyncClient, db_session
) -> None:
    """An ADMINISTRATOR (static defaults: manage_fee_settings and
    manage_system_config, but NOT approve_membership, member.view_all or
    view_audit_log) draws the 403/200 line exactly at those permissions."""
    admin = await _admin(client, db_session, "gatekeeper@example.com", AdminRole.ADMINISTRATOR)
    headers = await _headers_for(client, "gatekeeper@example.com")

    allowed = [
        ("GET", "/api/admin/fee-settings"),                    # manage_fee_settings
        ("GET", "/api/admin/config-lists"),                    # manage_system_config
    ]
    denied = [
        ("GET", "/api/admin/audit-log"),                       # view_audit_log
        ("GET", "/api/admin/members"),                         # member.view_all
        ("GET", "/api/admin/submissions"),                     # membership.review
    ]
    for method, path in allowed:
        response = await client.request(method, path, headers=headers)
        assert response.status_code in (200, 201), (method, path, response.status_code)
    for method, path in denied:
        response = await client.request(method, path, headers=headers)
        assert response.status_code == 403, (method, path, response.status_code)
    del admin


async def test_approve_membership_requires_approve_permission(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    """Administrator lacks approve_membership; executive committee has it."""
    admin_user.role = AdminRole.ADMINISTRATOR
    await db_session.commit()
    invalidate_permission_cache()
    headers = {"Authorization": f"Bearer {create_access_token(str(admin_user.id), 'administrator')}"}

    response = await client.post("/api/admin/submissions/1/approve", headers=headers)
    assert response.status_code == 403


async def test_member_role_token_without_member_record_is_rejected(
    client: AsyncClient, db_session
) -> None:
    """Regression: a management-tier account must never satisfy member-only
    endpoints, even with a token that claims role=member and an id that has
    no matching Member row (the earlier auth.role === 'member' bug)."""
    admin = await _admin(client, db_session, "ghost@example.com", AdminRole.ADMINISTRATOR)
    forged = create_access_token(str(admin.id), "member")

    for path in ("/api/member/me", "/api/member/installments"):
        response = await client.get(path, headers={"Authorization": f"Bearer {forged}"})
        assert response.status_code in (401, 403), (path, response.status_code)


async def test_rbac_writes_produce_exactly_one_audit_row_each(
    client: AsyncClient, db_session
) -> None:
    """Role permission update and user role change each audit once."""
    perms = await _seed_permissions(db_session, ("notice.view", "event.view"))
    role = Role(name="audited-role", description=None)
    db_session.add(role)
    await db_session.commit()
    target = await _admin(client, db_session, "target@example.com", AdminRole.ADMINISTRATOR)
    await _admin(client, db_session, "root@example.com", AdminRole.SUPER_ADMIN)
    await db_session.commit()
    headers = await _headers_for(client, "root@example.com")
    del perms

    put = await client.put(
        f"/api/admin/rbac/roles/{role.id}/permissions",
        json={"permission_keys": ["notice.view", "event.view"]},
        headers=headers,
    )
    assert put.status_code == 200, put.text

    patch = await client.patch(
        f"/api/admin/rbac/users/{target.id}/role",
        json={"role": "executive_committee"},
        headers=headers,
    )
    assert patch.status_code == 200, patch.text

    rows = (
        (
            await db_session.execute(
                text(
                    "SELECT action FROM audit_logs "
                    "WHERE action IN ('role.update_permissions', 'user.update_role') ORDER BY id"
                )
            )
        )
        .scalars()
        .all()
    )
    assert rows == ["role.update_permissions", "user.update_role"]
