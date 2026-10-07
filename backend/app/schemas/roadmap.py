from datetime import date, datetime

from pydantic import BaseModel, Field, field_validator

from app.models.roadmap import ROADMAP_STATUSES

_STATUS_PATTERN = rf"^({'|'.join(ROADMAP_STATUSES)})$"


def _blank_to_none(value: str | None) -> str | None:
    if value is None:
        return None
    stripped = value.strip()
    return stripped or None


class RoadmapItemOut(BaseModel):
    id: int
    timeframe_id: int
    text: str
    status: str
    target_date: date | None
    owner: str | None
    note: str | None
    sort_order: int
    completed_at: date | None
    updated_at: datetime | None


class RoadmapTimeframeOut(BaseModel):
    id: int
    key: str
    name_bn: str
    name_en: str
    target_window_bn: str
    target_window_en: str
    sort_order: int
    total: int
    done: int
    in_progress: int
    planned: int
    percent: int
    items: list[RoadmapItemOut]


class RoadmapTotalsOut(BaseModel):
    total: int
    done: int
    in_progress: int
    planned: int
    percent: int


class RoadmapOut(BaseModel):
    last_updated: datetime | None
    totals: RoadmapTotalsOut
    timeframes: list[RoadmapTimeframeOut]


class RoadmapItemCreate(BaseModel):
    timeframe_id: int
    text: str = Field(min_length=1, max_length=500)
    status: str = Field(default="planned", pattern=_STATUS_PATTERN)
    target_date: date | None = None
    owner: str | None = Field(default=None, max_length=120)
    note: str | None = Field(default=None, max_length=1000)
    # Lets the committee add a batch of items quietly and announce once.
    notify: bool = True

    @field_validator("text")
    @classmethod
    def _strip_text(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("Text must not be blank.")
        return stripped

    @field_validator("owner", "note")
    @classmethod
    def _strip_optional(cls, value: str | None) -> str | None:
        return _blank_to_none(value)


class RoadmapItemUpdate(BaseModel):
    """Partial update. Moving an item between timeframes = changing
    `timeframe_id`; status changes go through the dedicated status endpoint
    so they always produce the audit + notice side effects."""

    timeframe_id: int | None = None
    text: str | None = Field(default=None, min_length=1, max_length=500)
    target_date: date | None = None
    owner: str | None = Field(default=None, max_length=120)
    note: str | None = Field(default=None, max_length=1000)

    @field_validator("text")
    @classmethod
    def _strip_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        stripped = value.strip()
        if not stripped:
            raise ValueError("Text must not be blank.")
        return stripped

    @field_validator("owner", "note")
    @classmethod
    def _strip_optional(cls, value: str | None) -> str | None:
        return _blank_to_none(value)


class RoadmapStatusIn(BaseModel):
    status: str = Field(pattern=_STATUS_PATTERN)
    completed_at: date | None = None
    notify: bool = True


class RoadmapReorderIn(BaseModel):
    timeframe_id: int
    item_ids: list[int] = Field(min_length=1, max_length=200)


class RoadmapArchiveOut(BaseModel):
    archived: int


class RoadmapArchivedCycleOut(BaseModel):
    archived_at: datetime
    total: int
    done: int
    items: list[RoadmapItemOut]
