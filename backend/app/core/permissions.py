"""Permission catalog and resolution helpers for the Role -> Permission -> Resource/Action RBAC model.

Routes must gate on permission keys (`require_permission("manage_notices")`), never on role
names, so permissions can be recomposed per role or per user without touching route code.
"""
import time
from dataclasses import dataclass

from fastapi import Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.deps import get_current_admin, get_current_member
from app.db.session import get_db
from app.models.admin import AdminRole, AdminUser
from app.models.member import Member
from app.models.rbac import Permission, Role, UserPermissionOverride

# Effective permissions change only when an admin edits a role or a user's
# overrides - both rare, explicit, admin-driven events - yet they were
# recomputed with 2 queries on *every* gated request. A short-lived process
# cache keyed by (user id, role, role id) removes those round-trips; the TTL
# bounds staleness for out-of-band edits (e.g. a second app instance), and
# every in-process RBAC mutation calls `invalidate_permission_cache()`.
_PERMISSION_CACHE_TTL_SECONDS = 60.0
_permission_cache: dict[tuple[int, str, int | None], tuple[float, frozenset[str]]] = {}


def invalidate_permission_cache() -> None:
    """Drop cached effective permissions after an RBAC mutation."""
    _permission_cache.clear()


def _cache_key(admin: AdminUser) -> tuple[int, str, int | None]:
    return (admin.id, admin.role.value, admin.role_id)


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
    PermissionDef("manage_fee_settings", "fee_settings", "manage", "Manage fee settings versions"),
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
    PermissionDef("manage_costs", "cost", "manage", "Record society costs, split them among members and collect payments"),
    PermissionDef(
        "manage_finance", "finance", "manage", "Record, edit and approve fund transactions in the transparency ledger"
    ),
    PermissionDef(
        "manage_roadmap", "roadmap", "manage", "Add, edit, reorder and update the status of society roadmap items"
    ),
    PermissionDef(
        "manage_resolution_book",
        "resolution_book",
        "manage",
        "Record meetings, attendance, resolutions and attachments in the online resolution book",
    ),
    PermissionDef("notice.view", "notice", "view", "View notices"),
    PermissionDef("event.view", "event", "view", "View events"),
    # Reports
    PermissionDef("report.view", "report", "view", "View committee-level reports"),
    PermissionDef("report.view_operational", "report", "view_operational", "View operational reports"),
    # Profile (member self-service)
    PermissionDef("profile.view_own", "profile", "view_own", "View own profile"),
    PermissionDef("profile.edit_own", "profile", "edit_own", "Edit own profile"),
    PermissionDef(
        "neighbour.view", "neighbour", "view", "View owners of own and nearest neighbouring plots"
    ),
    # Plot boundaries (member-drawn polygons on the map)
    PermissionDef("boundary.draw_own", "boundary", "draw_own", "Draw and edit own plot boundaries"),
    PermissionDef("boundary.view", "boundary", "view", "View the plot map and boundary popups"),
    PermissionDef("boundary.review", "boundary", "review", "Review and approve/reject plot boundaries"),
    PermissionDef("boundary.manage", "boundary", "manage", "Manage boundary disputes and evidence"),
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
        "manage_fee_settings",
        "manage_system_config",
        "manage_costs",
        "manage_finance",
        "manage_roadmap",
        "manage_resolution_book",
        "boundary.view",
        "boundary.review",
        "boundary.manage",
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
        "manage_system_config",
        "manage_fee_settings",
        "manage_finance",
        "manage_roadmap",
        "manage_resolution_book",
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
        "neighbour.view",
        "boundary.view",
        "boundary.draw_own",
    ),
}

MEMBER_ROLE = "member"


def is_super_admin(admin: AdminUser) -> bool:
    return admin.role == AdminRole.SUPER_ADMIN


async def _load_effective_permissions(db: AsyncSession, admin: AdminUser) -> set[str]:
    """role's permissions ∪ granted overrides − revoked overrides."""
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


async def get_effective_permissions(db: AsyncSession, admin: AdminUser) -> set[str]:
    """role's permissions ∪ granted overrides − revoked overrides."""
    if is_super_admin(admin):
        return set(PERMISSION_KEYS)

    key = _cache_key(admin)
    cached = _permission_cache.get(key)
    now = time.monotonic()
    if cached is not None and now - cached[0] < _PERMISSION_CACHE_TTL_SECONDS:
        return set(cached[1])

    effective = frozenset(await _load_effective_permissions(db, admin))
    _permission_cache[key] = (now, effective)
    return set(effective)


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


def require_member_permission(permission_key: str):
    """Dependency factory: gate a member-token route by permission key.

    Member tokens carry the static member permission set (the same list the
    login response hands the client), so removing a key from that set closes
    the route as well as hiding its navigation entry."""

    async def _dependency(member: Member = Depends(get_current_member)) -> Member:
        if permission_key not in ROLE_DEFAULT_PERMISSIONS[MEMBER_ROLE]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing required permission: {permission_key}",
            )
        return member

    return _dependency
