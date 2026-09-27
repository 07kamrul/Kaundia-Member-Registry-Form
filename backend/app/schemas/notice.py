from datetime import datetime

from pydantic import BaseModel, ConfigDict, field_validator

from app.schemas.common import as_utc


class NoticeCreate(BaseModel):
    title: str
    body: str
    category_id: int | None = None
    is_published: bool = False
    is_members_only: bool = False
    publish_at: datetime | None = None

    _publish_at_as_utc = field_validator("publish_at")(as_utc)


class NoticeUpdate(BaseModel):
    """Partial update - only the keys the client actually sent are applied."""

    title: str | None = None
    body: str | None = None
    category_id: int | None = None
    is_published: bool | None = None
    is_members_only: bool | None = None
    publish_at: datetime | None = None

    _publish_at_as_utc = field_validator("publish_at")(as_utc)


class NoticeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    body: str
    category_id: int | None
    is_published: bool
    is_members_only: bool
    publish_at: datetime | None
    created_by: int | None
    created_at: datetime
    updated_at: datetime
