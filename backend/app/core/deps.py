from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import ADMIN_ROLES, decode_token
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.member import Member
from app.models.property import Property

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


def _subject_id(payload: dict) -> int:
    """Parse the token subject defensively - a well-signed token carrying a
    non-numeric sub must be treated as unauthenticated, not crash as a 500."""
    try:
        return int(payload["sub"])
    except (KeyError, TypeError, ValueError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")


async def get_current_admin(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> AdminUser:
    payload = await _get_token_payload(credentials)
    if payload.get("role") not in ADMIN_ROLES:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required")
    result = await db.execute(select(AdminUser).where(AdminUser.id == _subject_id(payload)))
    admin = result.scalar_one_or_none()
    if admin is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Admin not found")
    return admin


async def _resolve_member(
    credentials: HTTPAuthorizationCredentials | None,
    db: AsyncSession,
    *,
    eager: bool,
) -> Member:
    payload = await _get_token_payload(credentials)
    if payload.get("role") != "member":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Member access required")

    query = select(Member).where(Member.id == _subject_id(payload))
    if eager:
        # One round-trip set instead of the auth lookup + a second full-row
        # re-select of the same member (the profile route used to do both).
        query = query.options(
            selectinload(Member.properties).selectinload(Property.co_owners),
            selectinload(Member.properties).selectinload(Property.applicable_docs),
            selectinload(Member.nominees),
        )
    result = await db.execute(query)
    member = result.scalar_one_or_none()
    if member is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Member not found")
    return member


async def get_current_member(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> Member:
    return await _resolve_member(credentials, db, eager=False)


async def get_current_member_detail(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> Member:
    """Authenticates and returns the member with properties/nominees loaded,
    for endpoints whose response is the full detail graph."""
    return await _resolve_member(credentials, db, eager=True)
