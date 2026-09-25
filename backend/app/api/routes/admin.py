from datetime import datetime, timezone
from enum import Enum

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.permissions import require_permission
from app.core.security import generate_temp_password, hash_password
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.credential import MemberCredential
from app.models.installment import Installment, InstallmentStatus
from app.models.member import Member, MemberStatus
from app.models.property import Property
from app.schemas.installment import InstallmentCreate, InstallmentOut, InstallmentUpdate
from app.schemas.member import ApproveResponse, MemberDetail, MemberSummary, RejectRequest
from app.services.email import send_email
from app.services.storage import save_upload_file

router = APIRouter(prefix="/admin", tags=["admin"])


class AttachmentKind(str, Enum):
    MEMBER_PHOTO = "member_photo"
    RECEIPT_PHOTO = "receipt_photo"


# kind -> (Member column, upload subfolder); mirrors the public submission route
_ATTACHMENT_TARGETS = {
    AttachmentKind.MEMBER_PHOTO: ("member_photo_path", "photos"),
    AttachmentKind.RECEIPT_PHOTO: ("receipt_photo_path", "receipts"),
}


@router.get("/submissions", response_model=list[MemberSummary])
async def list_submissions(
    status_filter: MemberStatus | None = Query(default=None, alias="status"),
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("membership.review")),
) -> list[Member]:
    query = select(Member).options(selectinload(Member.properties))
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


@router.put("/submissions/{member_id}/attachments/{kind}", response_model=MemberDetail)
async def replace_attachment(
    member_id: int,
    kind: AttachmentKind,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("membership.review")),
) -> Member:
    """Replace a member's photo or receipt, e.g. when the stored file is lost."""
    member = await _get_member_or_404(db, member_id)
    column, folder = _ATTACHMENT_TARGETS[kind]
    new_path = await save_upload_file(file, f"{folder}/member_{member.id}")
    setattr(member, column, new_path)
    await db.commit()
    return await _get_member_or_404(db, member_id)


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
) -> list[MemberSummary]:
    members_result = await db.execute(select(Member).order_by(Member.created_at.desc()))
    members = list(members_result.scalars().all())

    due_counts_result = await db.execute(
        select(Installment.member_id, func.count())
        .where(Installment.status == InstallmentStatus.DUE)
        .group_by(Installment.member_id)
    )
    due_counts = dict(due_counts_result.all())

    return [
        MemberSummary(
            id=member.id,
            member_id=member.member_id,
            status=member.status,
            full_name=member.full_name,
            mobile=member.mobile,
            email=member.email,
            created_at=member.created_at,
            due_installments=due_counts.get(member.id, 0),
        )
        for member in members
    ]


@router.get("/members/{member_id}/installments", response_model=list[InstallmentOut])
async def list_member_installments(
    member_id: int,
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("member.view_all")),
) -> list[Installment]:
    await _get_member_or_404(db, member_id)
    result = await db.execute(
        select(Installment)
        .where(Installment.member_id == member_id)
        .order_by(Installment.year, Installment.month)
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
