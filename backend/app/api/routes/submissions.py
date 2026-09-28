import json
from datetime import date

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import ValidationError
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from decimal import Decimal, InvalidOperation

from app.db.session import get_db
from app.models.fee_settings import FeeSetting
from app.models.member import Member, MemberStatus
from app.models.property import ApplicableDoc, CoOwner, Property
from app.models.nominee import Nominee
from app.schemas.member import SubmissionCreateResponse
from app.schemas.submission import SubmissionPayload
from app.services.fee_calculation import calculate_monthly_subscription
from app.services.storage import save_upload_file, slugify_path_segment

router = APIRouter(tags=["submissions"])


async def resolve_active_fee(db: AsyncSession, key: str, on_date: date) -> str:
    """Active fee-setting value as of `on_date`. The client-sent amount is
    never trusted: the stored fee is always re-resolved here at submit time."""
    # Overlapping active versions can exist (e.g. a backdated new version
    # whose end_date still covers the period of the old one); the latest
    # start_date wins, matching the versioned-settings semantics elsewhere.
    result = await db.execute(
        select(FeeSetting.value)
        .where(
            FeeSetting.key == key,
            FeeSetting.start_date <= on_date,
            or_(FeeSetting.end_date.is_(None), FeeSetting.end_date >= on_date),
        )
        .order_by(FeeSetting.start_date.desc(), FeeSetting.id.desc())
        .limit(1)
    )
    value = result.scalar_one_or_none()
    if value is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"No active fee setting configured for '{key}'",
        )
    return str(value)


def _total_share_quantity(data: SubmissionPayload) -> Decimal:
    total = Decimal("0")
    for property_in in data.properties:
        try:
            total += Decimal(property_in.my_share_quantity or "0")
        except InvalidOperation:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Invalid land share quantity",
            )
    return total


@router.post("/submissions", response_model=SubmissionCreateResponse, status_code=status.HTTP_201_CREATED)
async def create_submission(
    payload: str = Form(...),
    member_photo: UploadFile | None = File(None),
    receipt_photo: UploadFile | None = File(None),
    doc_files: list[UploadFile] = File(default=[]),
    db: AsyncSession = Depends(get_db),
) -> SubmissionCreateResponse:
    """Public endpoint. Accepts multipart/form-data with:
    - 'payload': JSON string matching SubmissionPayload, where each
      applicable_doc entry's order corresponds to the order of files in
      'doc_files' flattened across properties in order.
    - 'member_photo': optional file upload for the member's photo.
    - 'receipt_photo': optional file upload for the money receipt image.
    - 'doc_files': ordered list of files for each property's applicable_docs.
    """
    try:
        data = SubmissionPayload.model_validate(json.loads(payload))
    except (json.JSONDecodeError, ValidationError) as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc

    member = Member(
        status=MemberStatus.PENDING,
        full_name=data.full_name,
        father_or_husband=data.father_or_husband,
        mother=data.mother,
        dob=data.dob,
        nationality=data.nationality,
        occupation=data.occupation,
        nid=data.nid,
        mobile=data.mobile,
        gender=data.gender,
        email=data.email,
        permanent_house=data.permanent_address.house if data.permanent_address else None,
        permanent_road=data.permanent_address.road if data.permanent_address else None,
        permanent_post_office=data.permanent_address.post_office if data.permanent_address else None,
        permanent_upazila=data.permanent_address.upazila if data.permanent_address else None,
        permanent_district=data.permanent_address.district if data.permanent_address else None,
        permanent_division=data.permanent_address.division if data.permanent_address else None,
        current_house=data.current_address.house if data.current_address else None,
        current_road=data.current_address.road if data.current_address else None,
        current_post_office=data.current_address.post_office if data.current_address else None,
        current_upazila=data.current_address.upazila if data.current_address else None,
        current_district=data.current_address.district if data.current_address else None,
        current_division=data.current_address.division if data.current_address else None,
        urgent_contact_name=data.urgent_contact_name,
        urgent_contact_relation=data.urgent_contact_relation,
        urgent_contact_mobile=data.urgent_contact_mobile,
        urgent_contact_address=data.urgent_contact_address,
        # Client-sent admission_fee is deliberately ignored — the amount
        # stored on the submission is the server-resolved active version.
        admission_fee=await resolve_active_fee(db, "admission_fee", date.today()),
        # Client-sent subscription is deliberately ignored - it is always
        # recomputed from the tiered rates active today and the submitted
        # land share, the same calculation the quote endpoint returns.
        subscription=str(
            (
                await calculate_monthly_subscription(
                    db, _total_share_quantity(data), date.today()
                )
            ).total
        ),
        receipt_no=data.receipt_no,
        payment_method=data.payment_method,
        member_signature=data.member_signature,
        submission_date=data.submission_date,
        # Seed both collections so they read as already-loaded: after the
        # flush below the member is persistent, and appending to an unloaded
        # collection on a persistent object would trigger a lazy SELECT.
        properties=[],
        nominees=[],
    )

    db.add(member)
    await db.flush()  # assigns member.id, used to namespace uploaded files below

    member_dir = f"member_{member.id}"

    # --- Pass 1: every disk write, with no database work interleaved. -------
    # Uploads can be up to 10 MB each; doing them before the object graph is
    # built keeps the connection checked out for the shortest window that the
    # `member_{id}` folder naming allows, and keeps all blocking file work out
    # of the insert path.
    if member_photo is not None and member_photo.filename:
        member.member_photo_path = await save_upload_file(member_photo, f"photos/{member_dir}")

    if receipt_photo is not None and receipt_photo.filename:
        member.receipt_photo_path = await save_upload_file(receipt_photo, f"receipts/{member_dir}")

    doc_file_iter = iter(doc_files)
    doc_paths: list[list[str | None]] = []
    for property_in in data.properties:
        paths: list[str | None] = []
        for doc_in in property_in.applicable_docs:
            doc_file = next(doc_file_iter, None)
            file_path = None
            if doc_file is not None and doc_file.filename:
                # Folder name is an ASCII slug; the Bengali display label stays
                # in `ApplicableDoc.doc_type` only.
                doc_type_dir = slugify_path_segment(doc_in.doc_type)
                file_path = await save_upload_file(doc_file, f"documents/{member_dir}/{doc_type_dir}")
            paths.append(file_path)
        doc_paths.append(paths)

    # --- Pass 2: build the whole object graph, then commit once. ------------
    # Children hang off their parents' relationships instead of carrying a
    # pre-assigned foreign key, so SQLAlchemy orders the inserts itself. That
    # removes the old per-property `flush()` - one round-trip per property -
    # in favour of a single flush at commit.
    for property_in, paths in zip(data.properties, doc_paths, strict=True):
        member.properties.append(
            Property(
                property_type=property_in.property_type,
                property_type_other=property_in.property_type_other,
                khatian_no=property_in.khatian_no,
                dag_no_cs=property_in.dag_no_cs,
                dag_no_rs=property_in.dag_no_rs,
                holding_number=property_in.holding_number,
                land_quantity=property_in.land_quantity,
                my_share_quantity=property_in.my_share_quantity,
                ownership=property_in.ownership,
                co_owners=[
                    CoOwner(owner_name=co_owner_in.owner_name, owner_phone=co_owner_in.owner_phone)
                    for co_owner_in in property_in.co_owners
                ],
                applicable_docs=[
                    ApplicableDoc(doc_type=doc_in.doc_type, file_path=file_path)
                    for doc_in, file_path in zip(property_in.applicable_docs, paths, strict=True)
                ],
            )
        )

    for nominee_in in data.nominees:
        member.nominees.append(
            Nominee(
                name=nominee_in.name,
                relation=nominee_in.relation,
                mobile=nominee_in.mobile,
                address=nominee_in.address,
            )
        )

    await db.commit()
    # No refresh: `id` is populated by the flush, `status` comes from a
    # Python-side default, and expire_on_commit=False leaves both intact.
    return SubmissionCreateResponse(id=member.id, status=member.status)
