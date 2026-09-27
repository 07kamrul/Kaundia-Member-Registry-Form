from datetime import date, datetime

from pydantic import BaseModel, ConfigDict


class FeeSettingCreate(BaseModel):
    key: str
    value: float
    unit: str | None = None
    start_date: date | None = None


class FeeSettingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    key: str
    value: float
    unit: str | None = None
    start_date: date
    end_date: date | None = None
    status: int
    created_by: int | None = None
    created_at: datetime
    updated_at: datetime
