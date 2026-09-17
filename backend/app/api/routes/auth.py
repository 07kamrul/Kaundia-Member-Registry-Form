from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.permissions import ROLE_DEFAULT_PERMISSIONS, get_effective_permissions
from app.core.security import create_access_token, create_refresh_token, verify_password
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.credential import MemberCredential
from app.schemas.auth import AdminLoginRequest, LoginRequest, MemberLoginRequest, TokenResponse

router = APIRouter(tags=["auth"])

MEMBER_PERMISSIONS = sorted(ROLE_DEFAULT_PERMISSIONS["member"])


async def _admin_token_response(db: AsyncSession, admin: AdminUser) -> TokenResponse:
    permissions = sorted(await get_effective_permissions(db, admin))
    return TokenResponse(
        access_token=create_access_token(str(admin.id), admin.role.value),
        refresh_token=create_refresh_token(str(admin.id), admin.role.value),
        role=admin.role.value,
        permissions=permissions,
    )


@router.post("/login", response_model=TokenResponse)
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    admin_result = await db.execute(select(AdminUser).where(AdminUser.email == payload.identifier))
    admin = admin_result.scalar_one_or_none()
    if admin is not None and verify_password(payload.password, admin.password_hash):
        return await _admin_token_response(db, admin)

    credential_result = await db.execute(
        select(MemberCredential).where(MemberCredential.username == payload.identifier)
    )
    credential = credential_result.scalar_one_or_none()
    if credential is not None and verify_password(payload.password, credential.password_hash):
        return TokenResponse(
            access_token=create_access_token(str(credential.member_id), "member"),
            refresh_token=create_refresh_token(str(credential.member_id), "member"),
            must_change_password=credential.must_change_password,
            role="member",
            permissions=MEMBER_PERMISSIONS,
        )

    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")


@router.post("/admin/login", response_model=TokenResponse)
async def admin_login(payload: AdminLoginRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    result = await db.execute(select(AdminUser).where(AdminUser.email == payload.email))
    admin = result.scalar_one_or_none()
    if admin is None or not verify_password(payload.password, admin.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    return await _admin_token_response(db, admin)


@router.post("/member/login", response_model=TokenResponse)
async def member_login(payload: MemberLoginRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    result = await db.execute(
        select(MemberCredential).where(MemberCredential.username == payload.username)
    )
    credential = result.scalar_one_or_none()
    if credential is None or not verify_password(payload.password, credential.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    return TokenResponse(
        access_token=create_access_token(str(credential.member_id), "member"),
        refresh_token=create_refresh_token(str(credential.member_id), "member"),
        must_change_password=credential.must_change_password,
        role="member",
        permissions=MEMBER_PERMISSIONS,
    )
