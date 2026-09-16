from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.models.member import MemberStatus
from app.schemas.common import ApplicableDocIn, CoOwner, Nominee, PropertyIn


class SubmissionCreateResponse(BaseModel):
    id: int
    status: MemberStatus


class ApplicableDocOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    doc_type: str
    file_path: str | None = None


class CoOwnerOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    owner_name: str
    owner_phone: str


class PropertyOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    property_type: list[str]
    property_type_other: str | None = None
    khatian_no: str | None = None
    dag_no_cs: str | None = None
    dag_no_rs: str | None = None
    land_quantity: str | None = None
    ownership: str | None = None
    co_owners: list[CoOwnerOut] = []
    applicable_docs: list[ApplicableDocOut] = []


class NomineeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    relation: str
    mobile: str
    address: str | None = None


class MemberSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    member_id: str | None = None
    status: MemberStatus
    full_name: str
    mobile: str
    email: str
    created_at: datetime


class MemberDetail(MemberSummary):
    father_or_husband: str
    mother: str
    dob: str
    nationality: str
    occupation: str
    nid: str
    gender: str
    permanent_house: str | None = None
    permanent_road: str | None = None
    permanent_post_office: str | None = None
    permanent_upazila: str | None = None
    permanent_district: str | None = None
    current_house: str | None = None
    current_road: str | None = None
    current_post_office: str | None = None
    current_upazila: str | None = None
    current_district: str | None = None
    urgent_contact_name: str | None = None
    urgent_contact_relation: str | None = None
    urgent_contact_mobile: str | None = None
    urgent_contact_address: str | None = None
    admission_fee: str
    subscription: str
    receipt_no: str
    payment_method: str
    member_signature: str | None = None
    submission_date: str
    member_photo_path: str | None = None
    reviewed_at: datetime | None = None
    rejection_reason: str | None = None
    properties: list[PropertyOut] = []
    nominees: list[NomineeOut] = []


class RejectRequest(BaseModel):
    reason: str


class ApproveResponse(BaseModel):
    member_id: str
    email_sent: bool
