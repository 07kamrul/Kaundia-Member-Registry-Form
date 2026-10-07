from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, field_validator

from app.schemas.common import CoOwner, validate_digits_only


class PropertyRequestDocPayload(BaseModel):
    """One row of the final desired applicable-docs list.

    `keep_path` is the stored `ApplicableDoc.file_path` to retain - either an
    existing document (kept as-is) or a path written when the request was
    created (a freshly uploaded file). Entries without `keep_path` are not
    valid in a stored payload: the route fills them in from the uploads.
    """

    doc_type: str
    keep_path: str | None = None


class PropertyRequestPayload(BaseModel):
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
    docs: list[PropertyRequestDocPayload] = []

    _validate_land_quantity = field_validator("land_quantity")(validate_digits_only)
    _validate_my_share_quantity = field_validator("my_share_quantity")(validate_digits_only)


class PropertyRequestOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    member_id: int
    action: str
    property_id: int | None
    payload: dict[str, Any]
    status: str
    cancel_reason: str | None
    reviewed_at: datetime | None
    created_at: datetime


class PropertyRequestAdminOut(PropertyRequestOut):
    member_name: str
    member_code: str | None
