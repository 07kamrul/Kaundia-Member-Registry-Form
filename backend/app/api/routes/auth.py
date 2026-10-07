from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.permissions import ROLE_DEFAULT_PERMISSIONS, get_effective_permissions
from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password_async,
    verify_password_async,
)
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.credential import MemberCredential
from app.models.member import Member
from app.models.password_reset import PasswordResetToken
from app.schemas.auth import (
    AdminLoginRequest,
    ForgotPasswordRequest,
    LoginRequest,
    MemberLoginRequest,
    ResetPasswordOK,
    ResetPasswordRequest,
    TokenResponse,
    validate_new_password,
)
from app.services.audit import record_audit
from app.services.email import send_email

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
    identifier = payload.identifier.strip().lower()

    admin_result = await db.execute(select(AdminUser).where(AdminUser.email == identifier))
    admin = admin_result.scalar_one_or_none()
    if admin is not None and await verify_password_async(payload.password, admin.password_hash):
        return await _admin_token_response(db, admin)

    credential_result = await db.execute(
        select(MemberCredential).where(MemberCredential.username == identifier)
    )
    credential = credential_result.scalar_one_or_none()
    if credential is not None and await verify_password_async(payload.password, credential.password_hash):
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
    email = payload.email.strip().lower()
    result = await db.execute(select(AdminUser).where(AdminUser.email == email))
    admin = result.scalar_one_or_none()
    if admin is None or not await verify_password_async(payload.password, admin.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    return await _admin_token_response(db, admin)


@router.post("/member/login", response_model=TokenResponse)
async def member_login(payload: MemberLoginRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    username = payload.username.strip().lower()
    result = await db.execute(
        select(MemberCredential).where(MemberCredential.username == username)
    )
    credential = result.scalar_one_or_none()
    if credential is None or not await verify_password_async(payload.password, credential.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    return TokenResponse(
        access_token=create_access_token(str(credential.member_id), "member"),
        refresh_token=create_refresh_token(str(credential.member_id), "member"),
        must_change_password=credential.must_change_password,
        role="member",
        permissions=MEMBER_PERMISSIONS,
    )


RESET_TOKEN_TTL_MINUTES = 30


def _hash_reset_token(raw_token: str) -> str:
    import hashlib

    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()


async def _issue_reset_token(
    db: AsyncSession, *, user_type: str, member_id: int | None, admin_id: int | None
) -> str:
    """Mint a single-use reset token, invalidating any earlier unused ones."""
    import secrets

    now = datetime.now(timezone.utc)
    stale = await db.execute(
        select(PasswordResetToken).where(
            PasswordResetToken.user_type == user_type,
            PasswordResetToken.used_at.is_(None),
            PasswordResetToken.expires_at > now,
            (
                PasswordResetToken.member_id == member_id
                if user_type == "member"
                else PasswordResetToken.admin_id == admin_id
            ),
        )
    )
    for row in stale.scalars().all():
        row.used_at = now

    raw_token = secrets.token_urlsafe(32)
    db.add(
        PasswordResetToken(
            user_type=user_type,
            member_id=member_id,
            admin_id=admin_id,
            token_hash=_hash_reset_token(raw_token),
            expires_at=now + timedelta(minutes=RESET_TOKEN_TTL_MINUTES),
        )
    )
    await db.commit()
    return raw_token


def _reset_email_body(identifier: str, reset_url: str) -> str:
    return (
        f"<p>Dear {identifier},</p>"
        "<p>We received a request to reset your account password.</p>"
        f'<p><a href="{reset_url}">{reset_url}</a></p>'
        f"<p>This link is valid for {RESET_TOKEN_TTL_MINUTES} minutes and can be "
        "used only once. If you did not request a reset, you can safely "
        "ignore this email - your current password will keep working.</p>"
        "<hr/>"
        '<p style="color:#6b7280;font-size:12px">This is an automated message '
        "from the উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ পরিষদ member registry.</p>"
    )


@router.post("/forgot-password", response_model=ResetPasswordOK)
async def forgot_password(
    payload: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)
) -> ResetPasswordOK:
    """Email a password reset link.

    Always responds the same way whether or not the identifier matches an
    account, so the endpoint cannot be used to discover which accounts exist.
    """
    identifier = payload.identifier.strip().lower()
    if not identifier:
        return ResetPasswordOK()

    admin = (
        await db.execute(select(AdminUser).where(AdminUser.email == identifier))
    ).scalar_one_or_none()
    if admin is not None:
        user_type, member_id, admin_id, to_email = "admin", None, admin.id, admin.email
    else:
        credential = (
            await db.execute(
                select(MemberCredential).where(MemberCredential.username == identifier)
            )
        ).scalar_one_or_none()
        member = None
        if credential is None:
            # Also allow the registered email address, which is the identifier
            # members are most likely to remember if they lost their member ID.
            member = (
                await db.execute(select(Member).where(Member.email == identifier))
            ).scalar_one_or_none()
            if member is not None:
                credential = (
                    await db.execute(
                        select(MemberCredential).where(MemberCredential.member_id == member.id)
                    )
                ).scalar_one_or_none()
        elif credential is not None:
            member = (
                await db.execute(select(Member).where(Member.id == credential.member_id))
            ).scalar_one_or_none()
        if credential is None or member is None or member.status != "approved":
            # Pending/rejected members have no login to reset, so treat them
            # the same as an unknown identifier.
            user_type, member_id, admin_id, to_email = None, None, None, None
        else:
            user_type, member_id, admin_id, to_email = "member", member.id, None, member.email

    if user_type is not None:
        raw_token = await _issue_reset_token(
            db, user_type=user_type, member_id=member_id, admin_id=admin_id
        )
        reset_url = (
            get_settings().frontend_base_url.rstrip("/") + "/reset-password?token=" + raw_token
        )
        await send_email(
            to=to_email,
            subject="Kaundia Member Registry - Password Reset Request",
            html_body=_reset_email_body(identifier, reset_url),
        )
    return ResetPasswordOK()


@router.post("/reset-password", response_model=ResetPasswordOK)
async def reset_password(
    payload: ResetPasswordRequest, db: AsyncSession = Depends(get_db)
) -> ResetPasswordOK:
    if errors := validate_new_password("", payload.new_password):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail={"errors": errors}
        )

    row = (
        await db.execute(
            select(PasswordResetToken).where(
                PasswordResetToken.token_hash == _hash_reset_token(payload.token),
                PasswordResetToken.used_at.is_(None),
                PasswordResetToken.expires_at > datetime.now(timezone.utc),
            )
        )
    ).scalar_one_or_none()
    if row is None or (row.member_id is None and row.admin_id is None):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset link. Please request a new one.",
        )

    if row.user_type == "admin":
        admin = (
            await db.execute(select(AdminUser).where(AdminUser.id == row.admin_id))
        ).scalar_one_or_none()
        if admin is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Account not found"
            )
        admin.password_hash = await hash_password_async(payload.new_password)
        record_audit(
            db,
            actor_admin_id=None,
            action="admin.self_reset_password",
            entity_type="admin_user",
            entity_id=str(admin.id),
            detail="password reset via email link",
        )
    else:
        credential = (
            await db.execute(
                select(MemberCredential).where(MemberCredential.member_id == row.member_id)
            )
        ).scalar_one_or_none()
        if credential is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Account not found"
            )
        credential.password_hash = await hash_password_async(payload.new_password)
        credential.must_change_password = False
        record_audit(
            db,
            actor_admin_id=None,
            action="member.self_reset_password",
            entity_type="member",
            entity_id=str(row.member_id),
            detail=f"password reset via email link for {credential.username}",
        )

    row.used_at = datetime.now(timezone.utc)
    await db.commit()
    return ResetPasswordOK()
