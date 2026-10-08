from datetime import date
from pathlib import Path

import json

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    Query,
    UploadFile,
    status,
)
from pydantic import ValidationError
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.deps import (
    AccountActor,
    get_account_actor,
    get_current_member,
    get_current_member_detail,
)
from app.core.security import ADMIN_ROLES, hash_password_async, verify_password_async
from app.db.session import get_db
from app.models.credential import MemberCredential
from app.models.installment import Installment
from app.models.member import Member, MemberStatus
from app.models.picnic_payment import PicnicPayment
from app.models.property import Property
from app.models.property_change_request import (
    PropertyChangeAction,
    PropertyChangeRequest,
    PropertyChangeStatus,
)
from app.schemas.property_request import (
    PropertyRequestOut,
    PropertyRequestPayload,
)
from app.schemas.auth import ChangePasswordRequest, validate_new_password
from app.schemas.installment import InstallmentOut
from app.schemas.member import MemberDetail, MemberProfileUpdate
from app.schemas.picnic_payment import PicnicPaymentIn, PicnicPaymentOut
from app.services.audit import record_audit
from app.services.email import send_email
from app.services.fee_calculation import calculate_picnic_fee, resolve_picnic_rates
from app.services.storage import save_upload_file, slugify_path_segment

from fastapi import Query

router = APIRouter(prefix="/member", tags=["member"])

FEE_MANAGER_PAYMENT_MESSAGE = "Fee managers cannot make member payments."


def _reject_fee_manager(actor: AccountActor) -> None:
    """Member payments are for paying members only. Admin-tier accounts
    (fee managers) configure rates in Fee Settings and review every member's
    payments via GET /admin/picnic-payments - they never pay as a member, so
    these endpoints reject them explicitly instead of relying on the UI."""
    if actor.admin is not None and actor.role in ADMIN_ROLES:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=FEE_MANAGER_PAYMENT_MESSAGE,
        )

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


@router.get("/picnic-rates")
async def get_picnic_rates(
    payment_date: date | None = Query(default=None),
    _actor: AccountActor = Depends(get_account_actor),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """The picnic rate versions effective on the given (or today's) date.
    Read-only: members and committee/admin accounts can all read; the values
    are only ever changed through Fee Settings."""
    rates = await resolve_picnic_rates(db, payment_date or date.today())
    if rates is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "code": "PICNIC_RATES_NOT_CONFIGURED",
                "message": "Picnic fee has not been set up yet. Please contact the committee.",
            },
        )
    return {
        "head_fee": float(rates["head_fee"]),
        "additional_head_fee": float(rates["additional_head_fee"]),
        "unit": rates["unit"],
        "effective_from": rates["effective_from"],
    }


@router.get("/picnic-payments", response_model=list[PicnicPaymentOut])
async def list_picnic_payments(
    actor: AccountActor = Depends(get_account_actor),
    db: AsyncSession = Depends(get_db),
) -> list[PicnicPayment]:
    _reject_fee_manager(actor)
    if actor.member is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only accounts linked to a member profile can record picnic payments.",
        )
    query = select(PicnicPayment).where(PicnicPayment.member_id == actor.member.id)
    result = await db.execute(
        query.order_by(PicnicPayment.payment_date.desc(), PicnicPayment.id.desc())
    )
    return list(result.scalars().all())


@router.post("/picnic-payments", response_model=PicnicPaymentOut, status_code=status.HTTP_201_CREATED)
async def create_picnic_payment(
    payload: PicnicPaymentIn,
    actor: AccountActor = Depends(get_account_actor),
    db: AsyncSession = Depends(get_db),
) -> PicnicPayment:
    _reject_fee_manager(actor)
    if actor.member is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only accounts linked to a member profile can record picnic payments.",
        )
    member = actor.member
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


# save_upload_file also accepts PDFs (documents/receipts need them); a member
# photo is always an image, so reject PDFs here before the storage layer does.
_PHOTO_EXTENSIONS = {".jpg", ".jpeg", ".png"}


@router.post("/me/photo", response_model=MemberDetail)
async def upload_my_photo(
    photo: UploadFile = File(...),
    member: Member = Depends(get_current_member_detail),
    db: AsyncSession = Depends(get_db),
) -> Member:
    """Replace the member's profile photo.

    Upload files can be lost from the server's uploads directory (e.g. saved
    before the uploads volume existed), leaving the stored path pointing at
    nothing; the member needs a way to restore the photo themselves. Swapping
    the photo is not a core-field edit, so it does not re-queue approval.
    """
    suffix = Path(photo.filename or "").suffix.lower()
    if suffix not in _PHOTO_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Unsupported photo type; use JPG or PNG.",
        )
    member.member_photo_path = await save_upload_file(photo, f"photos/member_{member.id}")
    await db.commit()
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
        # 422 (not 401): the frontend treats any 401 as an expired session and logs out.
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail={
                "message": "Current password is incorrect",
                "errors": {"current_password": "Current password is incorrect"},
            },
        )

    errors = validate_new_password(payload.current_password, payload.new_password)
    if errors:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail={"message": next(iter(errors.values())), "errors": errors},
        )

    credential.password_hash = await hash_password_async(payload.new_password)
    credential.must_change_password = False
    await db.commit()

# --- Property change requests ----------------------------------------------
# Members never write to `properties` directly once approved; every add,
# edit or delete lands here as a PENDING request that the management
# committee approves or cancels with a reason.


async def _load_own_property(db: AsyncSession, member: Member, property_id: int) -> Property:
    result = await db.execute(
        select(Property)
        .options(
            selectinload(Property.co_owners),
            selectinload(Property.applicable_docs),
        )
        .where(Property.id == property_id, Property.member_id == member.id)
    )
    property_ = result.scalar_one_or_none()
    if property_ is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Property not found")
    return property_


def _property_request_snapshot(property_: Property) -> PropertyRequestPayload:
    """Read-only snapshot stored on a delete request so the reviewer can see
    exactly what would be removed."""
    return PropertyRequestPayload(
        property_type=property_.property_type or [],
        property_type_other=property_.property_type_other,
        khatian_no=property_.khatian_no,
        dag_no_cs=property_.dag_no_cs,
        dag_no_rs=property_.dag_no_rs,
        holding_number=property_.holding_number,
        land_quantity=property_.land_quantity,
        my_share_quantity=property_.my_share_quantity,
        ownership=property_.ownership,
        joint_owner_count=property_.joint_owner_count,
        co_owners=[
            {"owner_name": co.owner_name, "owner_phone": co.owner_phone}
            for co in property_.co_owners
        ],
        docs=[
            {"doc_type": doc.doc_type, "keep_path": doc.file_path}
            for doc in property_.applicable_docs
        ],
    )


@router.get("/property-requests", response_model=list[PropertyRequestOut])
async def list_my_property_requests(
    member: Member = Depends(get_current_member),
    db: AsyncSession = Depends(get_db),
) -> list[PropertyChangeRequest]:
    result = await db.execute(
        select(PropertyChangeRequest)
        .where(PropertyChangeRequest.member_id == member.id)
        .order_by(PropertyChangeRequest.created_at.desc(), PropertyChangeRequest.id.desc())
    )
    return list(result.scalars().all())


@router.post(
    "/property-requests",
    response_model=PropertyRequestOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_property_request(
    action: PropertyChangeAction = Form(...),
    payload: str = Form(..., description="JSON-encoded PropertyRequestPayload"),
    property_id: int | None = Form(default=None),
    doc_files: list[UploadFile] = File(default=[]),
    member: Member = Depends(get_current_member),
    db: AsyncSession = Depends(get_db),
) -> PropertyChangeRequest:
    try:
        data = PropertyRequestPayload.model_validate(json.loads(payload))
    except (json.JSONDecodeError, ValidationError) as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail={"message": "Invalid property payload", "errors": str(exc)},
        )

    target: Property | None = None
    if action in (PropertyChangeAction.EDIT, PropertyChangeAction.DELETE):
        if property_id is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="property_id is required for edit and delete requests",
            )
        target = await _load_own_property(db, member, property_id)
    elif property_id is not None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="property_id is only valid for edit and delete requests",
        )

    if target is not None:
        # One pending request per property: a second change must wait for the
        # first decision, otherwise two approvals would race on the same row.
        pending_duplicate = await db.scalar(
            select(func.count())
            .select_from(PropertyChangeRequest)
            .where(
                PropertyChangeRequest.member_id == member.id,
                PropertyChangeRequest.property_id == target.id,
                PropertyChangeRequest.status == PropertyChangeStatus.PENDING,
            )
        )
        if pending_duplicate:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="This property already has a request waiting for review.",
            )

    if action == PropertyChangeAction.DELETE:
        # The member's payload is ignored for deletes: the stored snapshot is
        # taken from the live row so the reviewer sees the real state.
        data = _property_request_snapshot(target)
    else:
        # Resolve document entries. Uploads are written to their final
        # member-scoped folder now - the path is only linked to a Property row
        # on approval - and any client-supplied existing path must stay inside
        # that folder so paths belonging to other accounts cannot be adopted.
        uploads = [f for f in doc_files if f is not None and f.filename]
        expected = sum(1 for doc in data.docs if doc.keep_path is None)
        if expected != len(uploads):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="Document files do not match the submitted document list.",
            )
        upload_iter = iter(uploads)
        for doc in data.docs:
            if doc.keep_path is None:
                doc.keep_path = await save_upload_file(
                    next(upload_iter),
                    f"documents/member_{member.id}/{slugify_path_segment(doc.doc_type)}",
                )
            elif not doc.keep_path.startswith(f"documents/member_{member.id}/"):
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                    detail="Invalid document reference.",
                )

    request = PropertyChangeRequest(
        member_id=member.id,
        property_id=target.id if target is not None else None,
        action=action,
        payload=data.model_dump(),
        status=PropertyChangeStatus.PENDING,
    )
    db.add(request)
    await db.flush()
    record_audit(
        db,
        actor_admin_id=None,
        action="property.request.create",
        entity_type="property_change_request",
        entity_id=str(request.id),
        detail=f"member_id={member.id} action={action.value} property_id={property_id}",
    )
    await db.commit()
    await db.refresh(request)
    return request


@router.post("/property-requests/{request_id}/withdraw", response_model=PropertyRequestOut)
async def withdraw_property_request(
    request_id: int,
    member: Member = Depends(get_current_member),
    db: AsyncSession = Depends(get_db),
) -> PropertyChangeRequest:
    result = await db.execute(
        select(PropertyChangeRequest).where(
            PropertyChangeRequest.id == request_id,
            PropertyChangeRequest.member_id == member.id,
        )
    )
    request = result.scalar_one_or_none()
    if request is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Request not found")
    if request.status != PropertyChangeStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Only pending requests can be withdrawn.",
        )

    request.status = PropertyChangeStatus.CANCELLED
    request.cancel_reason = "Withdrawn by the member."
    record_audit(
        db,
        actor_admin_id=None,
        action="property.request.withdraw",
        entity_type="property_change_request",
        entity_id=str(request.id),
        detail=f"member_id={member.id} action={request.action.value}",
    )
    await db.commit()
    await db.refresh(request)
    return request
