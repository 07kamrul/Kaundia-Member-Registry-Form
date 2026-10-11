from datetime import date, datetime

from pydantic import BaseModel, ConfigDict


class FeeSettingCreate(BaseModel):
    key: str
    value: float
    unit: str | None = None
    start_date: date | None = None
    # 'other' | 'installment' - which member payment page offers this fee.
    # Defaults to the current active version's category, else 'other'.
    fee_category: str | None = None


class FeeSettingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    key: str
    value: float
    unit: str | None = None
    fee_category: str = "other"
    start_date: date
    end_date: date | None = None
    status: int
    created_by: int | None = None
    created_at: datetime
    updated_at: datetime
