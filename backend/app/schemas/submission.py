from pydantic import BaseModel, EmailStr

from app.schemas.common import AddressDetail, Nominee, PropertyIn


class SubmissionPayload(BaseModel):
    """JSON payload sent as the 'payload' form field alongside file uploads
    (memberPhoto, and propertyDoc_<propertyIndex>_<docIndex> files).

    Field names mirror src/lib/types.ts FormData/PropertyItem/Nominee, snake_cased.
    """

    full_name: str
    father_or_husband: str
    mother: str
    dob: str
    nationality: str
    occupation: str
    nid: str
    mobile: str
    gender: str
    email: EmailStr

    permanent_address: AddressDetail | None = None
    current_address: AddressDetail | None = None

    urgent_contact_name: str | None = None
    urgent_contact_relation: str | None = None
    urgent_contact_mobile: str | None = None
    urgent_contact_address: str | None = None

    properties: list[PropertyIn] = []
    nominees: list[Nominee] = []

    admission_fee: str
    subscription: str
    receipt_no: str
    payment_method: str

    member_signature: str | None = None
    submission_date: str
