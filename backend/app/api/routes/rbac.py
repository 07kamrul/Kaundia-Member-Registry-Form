from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.deps import get_current_admin
from app.core.permissions import PERMISSION_CATALOG, get_effective_permissions, require_permission
from app.db.session import get_db
from app.models.admin import AdminRole, AdminUser
from app.models.rbac import Permission, Role, UserPermissionOverride
from app.schemas.rbac import (
    AdminUserOut,
    PermissionOut,
    PermissionOverrideIn,
    PermissionOverrideOut,
    RoleOut,
    RolePermissionsUpdate,
)

router = APIRouter(prefix="/admin/rbac", tags=["rbac"])


@router.get("/me/permissions", response_model=list[str])
async def my_permissions(
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
) -> list[str]:
    return sorted(await get_effective_permissions(db, admin))


@router.get("/permissions", response_model=list[PermissionOut])
async def list_permissions(
    _admin: AdminUser = Depends(require_permission("manage_roles")),
) -> list[PermissionOut]:
    return [
        PermissionOut(key=p.key, resource=p.resource, action=p.action, description=p.description)
        for p in PERMISSION_CATALOG
    ]


@router.get("/roles", response_model=list[RoleOut])
async def list_roles(
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("manage_roles")),
) -> list[RoleOut]:
    result = await db.execute(select(Role).options(selectinload(Role.permissions)))
    roles = result.scalars().all()
    return [
        RoleOut(
            id=role.id,
            name=role.name,
            description=role.description,
            permission_keys=sorted(p.key for p in role.permissions),
        )
        for role in roles
    ]


@router.put("/roles/{role_id}/permissions", response_model=RoleOut)
async def update_role_permissions(
    role_id: int,
    payload: RolePermissionsUpdate,
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("manage_roles")),
) -> RoleOut:
    result = await db.execute(
        select(Role).where(Role.id == role_id).options(selectinload(Role.permissions))
    )
    role = result.scalar_one_or_none()
    if role is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not found")

    perm_result = await db.execute(
        select(Permission).where(Permission.key.in_(payload.permission_keys))
    )
    permissions = perm_result.scalars().all()
    found_keys = {p.key for p in permissions}
    missing = set(payload.permission_keys) - found_keys
    if missing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown permission keys: {sorted(missing)}",
        )

    role.permissions = list(permissions)
    await db.commit()
    await db.refresh(role, attribute_names=["permissions"])

    return RoleOut(
        id=role.id,
        name=role.name,
        description=role.description,
        permission_keys=sorted(p.key for p in role.permissions),
    )


@router.get("/users", response_model=list[AdminUserOut])
async def list_admin_users(
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("manage_users")),
) -> list[AdminUserOut]:
    result = await db.execute(select(AdminUser).where(AdminUser.role != AdminRole.SUPER_ADMIN))
    return [
        AdminUserOut(id=user.id, name=user.name, email=user.email, role=user.role.value)
        for user in result.scalars().all()
    ]


@router.get("/users/{user_id}/overrides", response_model=list[PermissionOverrideOut])
async def list_user_overrides(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("manage_users")),
) -> list[PermissionOverrideOut]:
    result = await db.execute(
        select(UserPermissionOverride, Permission.key)
        .join(Permission, Permission.id == UserPermissionOverride.permission_id)
        .where(UserPermissionOverride.user_id == user_id)
    )
    return [
        PermissionOverrideOut(permission_key=key, granted=override.granted)
        for override, key in result.all()
    ]


@router.put("/users/{user_id}/overrides", response_model=list[PermissionOverrideOut])
async def set_user_overrides(
    user_id: int,
    payload: list[PermissionOverrideIn],
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("manage_users")),
) -> list[PermissionOverrideOut]:
    user_result = await db.execute(select(AdminUser).where(AdminUser.id == user_id))
    if user_result.scalar_one_or_none() is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    existing_result = await db.execute(
        select(UserPermissionOverride).where(UserPermissionOverride.user_id == user_id)
    )
    for existing in existing_result.scalars().all():
        await db.delete(existing)

    perm_result = await db.execute(
        select(Permission).where(Permission.key.in_([item.permission_key for item in payload]))
    )
    key_to_permission = {p.key: p for p in perm_result.scalars().all()}
    missing = {item.permission_key for item in payload} - set(key_to_permission)
    if missing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown permission keys: {sorted(missing)}",
        )

    for item in payload:
        db.add(
            UserPermissionOverride(
                user_id=user_id,
                permission_id=key_to_permission[item.permission_key].id,
                granted=item.granted,
            )
        )
    await db.commit()

    return [
        PermissionOverrideOut(permission_key=item.permission_key, granted=item.granted)
        for item in payload
    ]
