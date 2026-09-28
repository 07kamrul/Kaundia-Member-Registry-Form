from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_member, get_current_member_detail
from app.core.security import hash_password_async, verify_password_async
from app.db.session import get_db
from app.models.credential import MemberCredential
from app.models.installment import Installment
from app.models.member import Member, MemberStatus
from app.models.picnic_payment import PicnicPayment
from app.schemas.auth import ChangePasswordRequest
from app.schemas.installment import InstallmentOut
from app.schemas.member import MemberDetail, MemberProfileUpdate
from app.schemas.picnic_payment import PicnicPaymentIn, PicnicPaymentOut
from app.services.audit import record_audit
from app.services.email import send_email
from app.services.fee_calculation import calculate_picnic_fee

router = APIRouter(prefix="/member", tags=["member"])

# Editing any of these on an APPROVED member re-queues them to PENDING for
# management review, since they affect identity/eligibility verification.
# Contact-only fields (mobile, email, urgent contact) apply immediately.
CORE_PROFILE_FIELDS = frozenset(
    {
        "full_name",
        "father_or_husband",
        "mother",
        "dob",
        "nationality",
        "occupation",
        "nid",
        "gender",
        "permanent_house",
        "permanent_road",
        "permanent_post_office",
        "permanent_upazila",
        "permanent_district",
        "permanent_division",
        "current_house",
        "current_road",
        "current_post_office",
        "current_upazila",
        "current_district",
        "current_division",
    }
)


@router.get("/me", response_model=MemberDetail)
async def get_my_profile(
    member: Member = Depends(get_current_member_detail),
) -> Member:
    # The dependency already authenticated *and* eager-loaded the detail graph
    # in a single query set; re-selecting the member here used to double the
    # round-trips for the most frequently hit member endpoint.
    return member


@router.get("/installments", response_model=list[InstallmentOut])
async def list_my_installments(
    member: Member = Depends(get_current_member),
    db: AsyncSession = Depends(get_db),
) -> list[Installment]:
    result = await db.execute(
        select(Installment).where(Installment.member_id == member.id).order_by(
            Installment.year, Installment.month
        )
    )
    return list(result.scalars().all())


@router.get("/picnic-payments", response_model=list[PicnicPaymentOut])
async def list_my_picnic_payments(
    member: Member = Depends(get_current_member),
    db: AsyncSession = Depends(get_db),
) -> list[PicnicPayment]:
    result = await db.execute(
        select(PicnicPayment)
        .where(PicnicPayment.member_id == member.id)
        .order_by(PicnicPayment.payment_date.desc(), PicnicPayment.id.desc())
    )
    return list(result.scalars().all())


@router.post("/picnic-payments", response_model=PicnicPaymentOut, status_code=status.HTTP_201_CREATED)
async def create_picnic_payment(
    payload: PicnicPaymentIn,
    member: Member = Depends(get_current_member),
    db: AsyncSession = Depends(get_db),
) -> PicnicPayment:
    # The total is always recomputed from the fee versions effective on the
    # payment date; any client-sent amount is ignored.
    breakdown = await calculate_picnic_fee(db, payload.additional_heads, payload.payment_date)

    payment = PicnicPayment(
        member_id=member.id,
        head_price=breakdown.head_price,
        additional_price=breakdown.additional_price,
        additional_count=breakdown.additional_count,
        total=breakdown.total,
        additional_heads=[person.model_dump() for person in payload.additional_people] or None,
        payment_date=payload.payment_date,
        receipt_no=payload.receipt_no,
        payment_method=payload.payment_method,
    )
    db.add(payment)
    await db.commit()
    await db.refresh(payment)
    return payment


@router.patch("/profile", response_model=MemberDetail)
async def update_my_profile(
    payload: MemberProfileUpdate,
    member: Member = Depends(get_current_member_detail),
    db: AsyncSession = Depends(get_db),
) -> Member:
    updates = payload.model_dump(exclude_unset=True)
    changed_core_fields = [
        field
        for field in updates
        if field in CORE_PROFILE_FIELDS and getattr(member, field) != updates[field]
    ]

    for field, value in updates.items():
        setattr(member, field, value)

    was_approved = member.status == MemberStatus.APPROVED
    if was_approved and changed_core_fields:
        member.status = MemberStatus.PENDING
        member.rejection_reason = None
        record_audit(
            db,
            actor_admin_id=None,
            action="member.self_edit_requeued",
            entity_type="member",
            entity_id=str(member.id),
            detail=f"changed_fields={changed_core_fields}",
        )

    await db.commit()

    if was_approved and changed_core_fields:
        await send_email(
            to=member.email,
            subject="Kaundia Member Registry - Profile Under Review",
            html_body=(
                f"<p>Dear {member.full_name},</p>"
                "<p>You updated core profile details, so your membership has been "
                "placed back under review by the management committee. You will be "
                "notified once it is re-approved.</p>"
            ),
        )

    return member


@router.post("/change-password", status_code=status.HTTP_204_NO_CONTENT)
async def change_password(
    payload: ChangePasswordRequest,
    member: Member = Depends(get_current_member),
    db: AsyncSession = Depends(get_db),
) -> None:
    result = await db.execute(
        select(MemberCredential).where(MemberCredential.member_id == member.id)
    )
    credential = result.scalar_one_or_none()
    if credential is None or not await verify_password_async(payload.current_password, credential.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid current password")

    credential.password_hash = await hash_password_async(payload.new_password)
    credential.must_change_password = False
    await db.commit()
