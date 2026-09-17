from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.permissions import require_permission
from app.core.security import generate_temp_password, hash_password
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.credential import MemberCredential
from app.models.installment import Installment
from app.models.member import Member, MemberStatus
from app.models.property import Property
from app.schemas.installment import InstallmentCreate, InstallmentOut, InstallmentUpdate
from app.schemas.member import ApproveResponse, MemberDetail, MemberSummary, RejectRequest
from app.services.email import send_email

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/submissions", response_model=list[MemberSummary])
async def list_submissions(
    status_filter: MemberStatus | None = Query(default=None, alias="status"),
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("membership.review")),
) -> list[Member]:
    query = select(Member)
    if status_filter is not None:
        query = query.where(Member.status == status_filter)
    result = await db.execute(query.order_by(Member.created_at.desc()))
    return list(result.scalars().all())


@router.get("/submissions/{member_id}", response_model=MemberDetail)
async def get_submission(
    member_id: int,
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("membership.review")),
) -> Member:
    member = await _get_member_or_404(db, member_id)
    return member


@router.post("/submissions/{member_id}/approve", response_model=ApproveResponse)
async def approve_submission(
    member_id: int,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("approve_membership")),
) -> ApproveResponse:
    member = await _get_member_or_404(db, member_id)
    if member.status == MemberStatus.APPROVED:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Already approved")

    generated_member_id = await _generate_member_id(db)
    temp_password = generate_temp_password()
    username = generated_member_id.lower()

    member.member_id = generated_member_id
    member.status = MemberStatus.APPROVED
    member.reviewed_at = datetime.now(timezone.utc)
    member.reviewed_by = admin.id
    member.rejection_reason = None

    credential = MemberCredential(
        member_id=member.id,
        username=username,
        password_hash=hash_password(temp_password),
        must_change_password=True,
    )
    db.add(credential)
    await db.commit()

    email_sent = await send_email(
        to=member.email,
        subject="Kaundia Member Registry - Membership Approved",
        html_body=(
            f"<p>Dear {member.full_name},</p>"
            f"<p>Your membership has been approved.</p>"
            f"<p>Member ID: <b>{generated_member_id}</b><br/>"
            f"Username: <b>{username}</b><br/>"
            f"Temporary password: <b>{temp_password}</b></p>"
            f"<p>Please log in and change your password.</p>"
        ),
    )

    return ApproveResponse(member_id=generated_member_id, email_sent=email_sent)


@router.post("/submissions/{member_id}/reject", status_code=status.HTTP_204_NO_CONTENT)
async def reject_submission(
    member_id: int,
    payload: RejectRequest,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("approve_membership")),
) -> None:
    member = await _get_member_or_404(db, member_id)
    member.status = MemberStatus.REJECTED
    member.reviewed_at = datetime.now(timezone.utc)
    member.reviewed_by = admin.id
    member.rejection_reason = payload.reason
    await db.commit()

    await send_email(
        to=member.email,
        subject="উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ পরিষদ - আবেদনের আপডেট",
        html_body=(
            f"<p>Dear {member.full_name},</p>"
            f"<p>Your membership application was not approved.</p>"
            f"<p>Reason: {payload.reason}</p>"
        ),
    )


@router.get("/members", response_model=list[MemberSummary])
async def list_members(
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("member.view_all")),
) -> list[Member]:
    result = await db.execute(
        select(Member).where(Member.status == MemberStatus.APPROVED).order_by(Member.member_id)
    )
    return list(result.scalars().all())


@router.post(
    "/members/{member_id}/installments",
    response_model=InstallmentOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_installment(
    member_id: int,
    payload: InstallmentCreate,
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("member.manage")),
) -> Installment:
    await _get_member_or_404(db, member_id)
    installment = Installment(
        member_id=member_id, year=payload.year, month=payload.month, amount=payload.amount
    )
    db.add(installment)
    await db.commit()
    await db.refresh(installment)
    return installment


@router.delete("/members/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_member(
    member_id: int,
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("member.manage")),
) -> None:
    member = await _get_member_or_404(db, member_id)
    await db.delete(member)
    await db.commit()


@router.patch("/installments/{installment_id}", response_model=InstallmentOut)
async def update_installment(
    installment_id: int,
    payload: InstallmentUpdate,
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("member.manage")),
) -> Installment:
    result = await db.execute(select(Installment).where(Installment.id == installment_id))
    installment = result.scalar_one_or_none()
    if installment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Installment not found")

    installment.status = payload.status
    installment.paid_at = datetime.now(timezone.utc) if payload.status.value == "paid" else None
    await db.commit()
    await db.refresh(installment)
    return installment


async def _get_member_or_404(db: AsyncSession, member_id: int) -> Member:
    result = await db.execute(
        select(Member)
        .options(
            selectinload(Member.properties).selectinload(Property.co_owners),
            selectinload(Member.properties).selectinload(Property.applicable_docs),
            selectinload(Member.nominees),
        )
        .where(Member.id == member_id)
    )
    member = result.scalar_one_or_none()
    if member is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Submission not found")
    return member


async def _generate_member_id(db: AsyncSession) -> str:
    year = datetime.now(timezone.utc).year
    prefix = f"KAM-{year}-"
    result = await db.execute(
        select(func.count()).select_from(Member).where(Member.member_id.like(f"{prefix}%"))
    )
    count = result.scalar_one() or 0
    return f"{prefix}{count + 1:04d}"
