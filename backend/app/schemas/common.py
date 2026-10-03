from datetime import datetime, timezone

from pydantic import BaseModel, field_validator

from app.services.normalization import normalize_mobile

DIGITS_ONLY_PATTERN = r"^\d+$"


def validate_digits_only(value: str | None) -> str | None:
    if value is not None and value != "" and not value.isdigit():
        raise ValueError("must contain digits only")
    return value


def validate_phone(value: str | None) -> str | None:
    """Normalise an optional international phone number to E.164."""
    if value is None or value.strip() == "":
        return value
    return normalize_mobile(value)


def as_utc(value: datetime | None) -> datetime | None:
    """Normalise a client's datetime to UTC.

    `publish_at`/`start_at` are compared against `now()` on the server, so a
    naive value would otherwise be interpreted in whatever timezone the
    process happens to run in, and an offset other than UTC would be stored
    with its local fields (SQLite has no tz support and drops the offset).
    """
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


class AddressDetail(BaseModel):
    house: str | None = None
    road: str | None = None
    post_office: str | None = None
    upazila: str | None = None
    district: str | None = None
    division: str | None = None


class Nominee(BaseModel):
    name: str
    relation: str
    mobile: str
    address: str | None = None

    _validate_mobile = field_validator("mobile")(validate_phone)


class CoOwner(BaseModel):
    owner_name: str
    owner_phone: str


class ApplicableDocIn(BaseModel):
    doc_type: str


class PropertyIn(BaseModel):
    property_type: list[str] = []
    property_type_other: str | None = None
    khatian_no: str | None = None
    dag_no_cs: str | None = None
    dag_no_rs: str | None = None
    holding_number: str | None = None
    land_quantity: str | None = None
    my_share_quantity: str | None = None
    ownership: str | None = None
    co_owners: list[CoOwner] = []
    applicable_docs: list[ApplicableDocIn] = []

    _validate_land_quantity = field_validator("land_quantity")(validate_digits_only)
    _validate_my_share_quantity = field_validator("my_share_quantity")(validate_digits_only)
