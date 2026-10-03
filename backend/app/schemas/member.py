from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.member import MemberStatus
from app.schemas.installment import InstallmentOut
from app.schemas.picnic_payment import PicnicPaymentOut
from app.schemas.common import ApplicableDocIn, CoOwner, Nominee, PropertyIn, validate_phone


class SubmissionCreateResponse(BaseModel):
    id: int
    status: MemberStatus


class MemberProfileUpdate(BaseModel):
    # Core (identity/address) fields - editing any of these on an already
    # approved member re-queues the member for review (see CORE_PROFILE_FIELDS
    # in app/api/routes/member.py).
    full_name: str | None = None
    father_or_husband: str | None = None
    mother: str | None = None
    dob: str | None = None
    nationality: str | None = None
    occupation: str | None = None
    nid: str | None = None
    gender: str | None = None
    permanent_house: str | None = None
    permanent_road: str | None = None
    permanent_post_office: str | None = None
    permanent_upazila: str | None = None
    permanent_district: str | None = None
    permanent_division: str | None = None
    current_house: str | None = None
    current_road: str | None = None
    current_post_office: str | None = None
    current_upazila: str | None = None
    current_district: str | None = None
    current_division: str | None = None

    # Non-core (contact) fields - applied immediately, no re-review.
    mobile: str | None = None
    email: str | None = None
    urgent_contact_name: str | None = None
    urgent_contact_relation: str | None = None
    urgent_contact_mobile: str | None = None
    urgent_contact_address: str | None = None

    _validate_phones = field_validator("mobile", "urgent_contact_mobile")(validate_phone)


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
    holding_number: str | None = None
    land_quantity: str | None = None
    my_share_quantity: str | None = None
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
    due_installments: int = 0


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
    permanent_division: str | None = None
    current_house: str | None = None
    current_road: str | None = None
    current_post_office: str | None = None
    current_upazila: str | None = None
    current_district: str | None = None
    current_division: str | None = None
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
    receipt_photo_path: str | None = None
    reviewed_at: datetime | None = None
    rejection_reason: str | None = None
    notification_status: str | None = None
    properties: list[PropertyOut] = []
    nominees: list[NomineeOut] = []


class RejectRequest(BaseModel):
    # The reason is emailed to the applicant, so a blank one is never valid.
    reason: str = Field(min_length=1)

    @field_validator("reason")
    @classmethod
    def _strip_reason(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("reason must not be blank")
        return stripped


class RejectResponse(BaseModel):
    status: str
    email_sent: bool


class ApproveResponse(BaseModel):
    member_id: str
    email_sent: bool


class MemberAuditEntry(BaseModel):
    id: int
    action: str
    detail: str | None = None
    actor_name: str | None = None
    created_at: datetime


class MemberFeeSummary(BaseModel):
    """Roll-up of a member's installments (all amounts in taka)."""

    due_count: int
    paid_count: int
    due_total: float
    paid_total: float


class MemberProfile(MemberDetail):
    """Everything the admin member-detail drawer shows, in one response."""

    updated_at: datetime
    reviewed_by_name: str | None = None
    fee_summary: MemberFeeSummary
    installments: list[InstallmentOut] = []
    picnic_payments: list[PicnicPaymentOut] = []
    audit_trail: list[MemberAuditEntry] = []
