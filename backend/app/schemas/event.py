from datetime import datetime

from pydantic import BaseModel, ConfigDict, field_validator

from app.schemas.common import as_utc


class EventCreate(BaseModel):
    title: str
    description: str | None = None
    location: str | None = None
    category_id: int | None = None
    start_at: datetime
    end_at: datetime | None = None
    is_published: bool = False
    is_members_only: bool = False

    _start_at_as_utc = field_validator("start_at")(as_utc)
    _end_at_as_utc = field_validator("end_at")(as_utc)


class EventUpdate(BaseModel):
    """Partial update - only the keys the client actually sent are applied."""

    title: str | None = None
    description: str | None = None
    location: str | None = None
    category_id: int | None = None
    start_at: datetime | None = None
    end_at: datetime | None = None
    is_published: bool | None = None
    is_members_only: bool | None = None

    _start_at_as_utc = field_validator("start_at")(as_utc)
    _end_at_as_utc = field_validator("end_at")(as_utc)


class EventOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: str | None
    location: str | None
    category_id: int | None
    start_at: datetime
    end_at: datetime | None
    is_published: bool
    is_members_only: bool
    created_by: int | None
    created_at: datetime
    updated_at: datetime
