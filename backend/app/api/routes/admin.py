from datetime import datetime, timezone
from enum import Enum

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import load_only, selectinload

from app.core.permissions import require_permission
from app.core.security import generate_temp_password, hash_password_async
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.credential import MemberCredential
from app.models.installment import Installment, InstallmentStatus
from app.models.member import Member, MemberStatus
from app.models.nominee import Nominee
from app.models.property import ApplicableDoc, CoOwner, Property
from app.schemas.installment import InstallmentCreate, InstallmentOut, InstallmentUpdate
from app.schemas.member import ApproveResponse, MemberDetail, MemberSummary, RejectRequest
from app.services.email import send_email
from app.services.storage import save_upload_file

router = APIRouter(prefix="/admin", tags=["admin"])

# Columns MemberSummary serialises. List endpoints load only these instead of
# the ~40 member columns - the omitted ones include `member_signature`, a
# base64 blob in a Text column that used to be pulled for every row on every
# list call.
_SUMMARY_COLUMNS = (
    Member.id,
    Member.member_id,
    Member.status,
    Member.full_name,
    Member.mobile,
    Member.email,
    Member.created_at,
)

# Optional windowing for the list endpoints (`limit`/`offset` params below).
# Omitted by default so existing clients keep receiving the full list; clients
# that pass a page size get an O(page) response instead of O(table).


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
    limit: int | None = Query(default=None, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("membership.review")),
) -> list[Member]:
    query = select(Member).options(load_only(*_SUMMARY_COLUMNS))
    if status_filter is not None:
        query = query.where(Member.status == status_filter)
    query = query.order_by(Member.created_at.desc(), Member.id.desc())
    if offset:
        query = query.offset(offset)
    if limit is not None:
        query = query.limit(limit)
    result = await db.execute(query)
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
    # expire_on_commit=False keeps the eager-loaded graph loaded on `member`,
    # so returning it directly skips re-running the 5-query detail fetch.
    return member


@router.post("/submissions/{member_id}/approve", response_model=ApproveResponse)
async def approve_submission(
    member_id: int,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("approve_membership")),
) -> ApproveResponse:
    member = await _get_member_or_404(db, member_id, eager=False)
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
        password_hash=await hash_password_async(temp_password),
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
    member = await _get_member_or_404(db, member_id, eager=False)
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
    limit: int | None = Query(default=None, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("member.view_all")),
) -> list[MemberSummary]:
    query = select(Member).options(load_only(*_SUMMARY_COLUMNS)).order_by(
        Member.created_at.desc(), Member.id.desc()
    )
    if offset:
        query = query.offset(offset)
    if limit is not None:
        query = query.limit(limit)
    members_result = await db.execute(query)
    members = list(members_result.scalars().all())

    # One grouped query for every member's overdue count rather than a
    # per-member lookup; honours the same window as the member page so the
    # aggregate stays proportional to the page, not the table.
    due_query = (
        select(Installment.member_id, func.count())
        .where(Installment.status == InstallmentStatus.DUE)
        .group_by(Installment.member_id)
    )
    if members:
        due_query = due_query.where(Installment.member_id.in_([m.id for m in members]))
    due_counts_result = await db.execute(due_query)
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
    await _require_member_exists(db, member_id)
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
    await _require_member_exists(db, member_id)
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
    await _require_member_exists(db, member_id)

    # Explicit set-based deletes instead of the ORM cascade. `db.delete(member)`
    # has to load every property, co-owner, document, nominee, credential and
    # installment first (and, because Property's children are lazily loaded,
    # issue one SELECT per property) - a burst of N+1 round-trips. These six
    # statements delete the same rows in constant round-trips regardless of how
    # much data the member owns, in child-first order so no FK is violated.
    property_ids = select(Property.id).where(Property.member_id == member_id)
    await db.execute(delete(CoOwner).where(CoOwner.property_id.in_(property_ids)))
    await db.execute(delete(ApplicableDoc).where(ApplicableDoc.property_id.in_(property_ids)))
    await db.execute(delete(Property).where(Property.member_id == member_id))
    await db.execute(delete(Nominee).where(Nominee.member_id == member_id))
    await db.execute(delete(MemberCredential).where(MemberCredential.member_id == member_id))
    await db.execute(delete(Installment).where(Installment.member_id == member_id))
    await db.execute(delete(Member).where(Member.id == member_id))
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
    # expire_on_commit=False: every field InstallmentOut reads is already loaded
    # or just assigned, so an extra SELECT here would only add a round-trip.
    return installment


async def _get_member_or_404(db: AsyncSession, member_id: int, *, eager: bool = True) -> Member:
    """Fetch a member, optionally with the full detail graph.

    ``eager=False`` is for callers that only touch scalar columns (approve,
    reject) - it skips the 4 extra SELECTs the detail graph costs.
    """
    query = select(Member).where(Member.id == member_id)
    if eager:
        query = query.options(
            selectinload(Member.properties).selectinload(Property.co_owners),
            selectinload(Member.properties).selectinload(Property.applicable_docs),
            selectinload(Member.nominees),
        )
    result = await db.execute(query)
    member = result.scalar_one_or_none()
    if member is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Submission not found")
    return member


async def _require_member_exists(db: AsyncSession, member_id: int) -> None:
    """404 if the member is absent, with a single COUNT instead of the full
    5-query detail graph the old existence check ran."""
    exists = await db.scalar(
        select(func.count()).select_from(Member).where(Member.id == member_id)
    )
    if not exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Submission not found")


async def _generate_member_id(db: AsyncSession) -> str:
    year = datetime.now(timezone.utc).year
    prefix = f"KAM-{year}-"
    result = await db.execute(
        select(func.count()).select_from(Member).where(Member.member_id.like(f"{prefix}%"))
    )
    count = result.scalar_one() or 0
    return f"{prefix}{count + 1:04d}"
