"""Permission catalog and resolution helpers for the Role -> Permission -> Resource/Action RBAC model.

Routes must gate on permission keys (`require_permission("manage_notices")`), never on role
names, so permissions can be recomposed per role or per user without touching route code.
"""
from dataclasses import dataclass

from fastapi import Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.deps import get_current_admin
from app.db.session import get_db
from app.models.admin import AdminRole, AdminUser
from app.models.rbac import Permission, Role, UserPermissionOverride


@dataclass(frozen=True)
class PermissionDef:
    key: str
    resource: str
    action: str
    description: str


PERMISSION_CATALOG: tuple[PermissionDef, ...] = (
    # User & role administration (Super Admin only)
    PermissionDef("manage_users", "user", "manage", "Create/update/deactivate users, assign roles"),
    PermissionDef("manage_roles", "role", "manage", "Manage roles and role permission assignments"),
    PermissionDef("manage_system_config", "system", "manage", "Manage system configuration"),
    PermissionDef("manage_organization", "organization", "manage", "Manage organization settings"),
    PermissionDef("view_audit_log", "audit", "view", "View audit/access logs"),
    # Members
    PermissionDef("member.view_all", "member", "view_all", "View all members"),
    PermissionDef("member.manage", "member", "manage", "Manage member records"),
    PermissionDef("member.register", "member", "register", "Register new members"),
    PermissionDef("member.verify", "member", "verify", "Verify member registration/profile"),
    # Properties
    PermissionDef("property.view_all", "property", "view_all", "View all properties"),
    PermissionDef("property.review", "property", "review", "Review property submissions"),
    PermissionDef("property.view_own", "property", "view_own", "View own property"),
    PermissionDef("property.edit_own", "property", "edit_own", "Edit own property"),
    # Documents
    PermissionDef("document.verify", "document", "verify", "Verify uploaded documents"),
    # Membership
    PermissionDef("membership.review", "membership", "review", "Review membership submissions"),
    PermissionDef("approve_membership", "membership", "approve", "Approve membership applications"),
    PermissionDef("membership.view_own_status", "membership", "view_own_status", "View own membership status"),
    # Complaints / requests
    PermissionDef("complaint.view_all", "complaint", "view_all", "View all complaints"),
    PermissionDef("complaint.review", "complaint", "review", "Review complaints (committee level)"),
    PermissionDef("complaint.view_assigned", "complaint", "view_assigned", "View assigned complaints"),
    PermissionDef("complaint.process", "complaint", "process", "Process assigned complaints"),
    PermissionDef("complaint.create", "complaint", "create", "Create a complaint"),
    PermissionDef("request.create", "request", "create", "Create a request"),
    # Notices & events
    PermissionDef("manage_notices", "notice", "manage", "Manage notices and events"),
    PermissionDef("notice.view", "notice", "view", "View notices"),
    PermissionDef("event.view", "event", "view", "View events"),
    # Reports
    PermissionDef("report.view", "report", "view", "View committee-level reports"),
    PermissionDef("report.view_operational", "report", "view_operational", "View operational reports"),
    # Profile (member self-service)
    PermissionDef("profile.view_own", "profile", "view_own", "View own profile"),
    PermissionDef("profile.edit_own", "profile", "edit_own", "Edit own profile"),
)

PERMISSION_KEYS: frozenset[str] = frozenset(p.key for p in PERMISSION_CATALOG)

ROLE_DEFAULT_PERMISSIONS: dict[str, tuple[str, ...]] = {
    AdminRole.SUPER_ADMIN.value: tuple(p.key for p in PERMISSION_CATALOG),
    AdminRole.EXECUTIVE_COMMITTEE.value: (
        "member.view_all",
        "member.manage",
        "property.view_all",
        "property.review",
        "membership.review",
        "approve_membership",
        "complaint.view_all",
        "complaint.review",
        "manage_notices",
        "report.view",
    ),
    AdminRole.ADMINISTRATOR.value: (
        "member.register",
        "member.verify",
        "member.manage",
        "document.verify",
        "manage_notices",
        "complaint.view_assigned",
        "complaint.process",
        "report.view_operational",
    ),
    "member": (
        "profile.view_own",
        "profile.edit_own",
        "property.view_own",
        "property.edit_own",
        "membership.view_own_status",
        "notice.view",
        "event.view",
        "complaint.create",
        "request.create",
    ),
}


def is_super_admin(admin: AdminUser) -> bool:
    return admin.role == AdminRole.SUPER_ADMIN


async def get_effective_permissions(db: AsyncSession, admin: AdminUser) -> set[str]:
    """role's permissions ∪ granted overrides − revoked overrides."""
    if is_super_admin(admin):
        return set(PERMISSION_KEYS)

    granted: set[str] = set()
    role = None
    if admin.role_id is not None:
        result = await db.execute(
            select(Role).where(Role.id == admin.role_id).options(selectinload(Role.permissions))
        )
        role = result.scalar_one_or_none()

    if role is not None:
        granted = {perm.key for perm in role.permissions}
    else:
        # No linked roles-table row yet (e.g. DB provisioned without the RBAC
        # seed data) - fall back to the static default set for this role name.
        granted = set(ROLE_DEFAULT_PERMISSIONS.get(admin.role.value, ()))

    override_result = await db.execute(
        select(UserPermissionOverride, Permission.key)
        .join(Permission, Permission.id == UserPermissionOverride.permission_id)
        .where(UserPermissionOverride.user_id == admin.id)
    )
    for override, key in override_result.all():
        if override.granted:
            granted.add(key)
        else:
            granted.discard(key)

    return granted


async def can(db: AsyncSession, admin: AdminUser, permission_key: str) -> bool:
    if is_super_admin(admin):
        return True
    effective = await get_effective_permissions(db, admin)
    return permission_key in effective


def require_permission(permission_key: str):
    """Dependency factory: gate a route by permission key, not role name."""

    async def _dependency(
        admin: AdminUser = Depends(get_current_admin),
        db: AsyncSession = Depends(get_db),
    ) -> AdminUser:
        if not await can(db, admin, permission_key):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing required permission: {permission_key}",
            )
        return admin

    return _dependency
