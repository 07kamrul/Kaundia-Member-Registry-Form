import json

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.member import Member, MemberStatus
from app.models.property import ApplicableDoc, CoOwner, Property
from app.models.nominee import Nominee
from app.schemas.member import SubmissionCreateResponse
from app.schemas.submission import SubmissionPayload
from app.services.storage import sanitize_path_segment, save_data_url, save_upload_file

router = APIRouter(tags=["submissions"])


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
        admission_fee=data.admission_fee,
        subscription=data.subscription,
        receipt_no=data.receipt_no,
        payment_method=data.payment_method,
        member_signature=data.member_signature,
        submission_date=data.submission_date,
    )

    db.add(member)
    await db.flush()  # assigns member.id, used to namespace uploaded files below

    member_dir = f"member_{member.id}"

    if member_photo is not None and member_photo.filename:
        member.member_photo_path = await save_upload_file(member_photo, f"photos/{member_dir}")

    if receipt_photo is not None and receipt_photo.filename:
        member.receipt_photo_path = await save_upload_file(receipt_photo, f"receipts/{member_dir}")

    doc_file_iter = iter(doc_files)

    for property_in in data.properties:
        property_row = Property(
            member_id=member.id,
            property_type=property_in.property_type,
            property_type_other=property_in.property_type_other,
            khatian_no=property_in.khatian_no,
            dag_no_cs=property_in.dag_no_cs,
            dag_no_rs=property_in.dag_no_rs,
            holding_number=property_in.holding_number,
            land_quantity=property_in.land_quantity,
            ownership=property_in.ownership,
        )
        db.add(property_row)
        await db.flush()  # assigns property_row.id for co_owners/applicable_docs FKs

        for co_owner_in in property_in.co_owners:
            db.add(
                CoOwner(
                    property_id=property_row.id,
                    owner_name=co_owner_in.owner_name,
                    owner_phone=co_owner_in.owner_phone,
                )
            )
        for doc_in in property_in.applicable_docs:
            doc_file = next(doc_file_iter, None)
            file_path = None
            if doc_file is not None and doc_file.filename:
                doc_type_dir = sanitize_path_segment(doc_in.doc_type)
                file_path = await save_upload_file(doc_file, f"documents/{member_dir}/{doc_type_dir}")
            db.add(
                ApplicableDoc(property_id=property_row.id, doc_type=doc_in.doc_type, file_path=file_path)
            )

    for nominee_in in data.nominees:
        db.add(
            Nominee(
                member_id=member.id,
                name=nominee_in.name,
                relation=nominee_in.relation,
                mobile=nominee_in.mobile,
                address=nominee_in.address,
            )
        )

    await db.commit()
    await db.refresh(member)

    return SubmissionCreateResponse(id=member.id, status=member.status)
