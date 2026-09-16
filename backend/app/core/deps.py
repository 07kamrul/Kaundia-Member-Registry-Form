from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import ADMIN_ROLES, TokenRole, decode_token
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.member import Member

bearer_scheme = HTTPBearer(auto_error=False)


async def _get_token_payload(
    credentials: HTTPAuthorizationCredentials | None,
) -> dict:
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    payload = decode_token(credentials.credentials)
    if payload is None or payload.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    return payload


async def get_current_admin(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> AdminUser:
    payload = await _get_token_payload(credentials)
    if payload.get("role") not in ADMIN_ROLES:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required")
    result = await db.execute(select(AdminUser).where(AdminUser.id == int(payload["sub"])))
    admin = result.scalar_one_or_none()
    if admin is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Admin not found")
    return admin


def require_admin_roles(*allowed_roles: TokenRole):
    """Dependency factory gating a route to specific admin tiers.

    Example: Depends(require_admin_roles("super_admin", "executive_committee"))
    """

    async def _dependency(admin: AdminUser = Depends(get_current_admin)) -> AdminUser:
        if admin.role.value not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient role for this action",
            )
        return admin

    return _dependency


async def get_current_member(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> Member:
    payload = await _get_token_payload(credentials)
    if payload.get("role") != "member":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Member access required")
    result = await db.execute(select(Member).where(Member.id == int(payload["sub"])))
    member = result.scalar_one_or_none()
    if member is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Member not found")
    return member
