from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.models.installment import InstallmentStatus


class InstallmentCreate(BaseModel):
    year: int
    month: int
    amount: float


class InstallmentUpdate(BaseModel):
    status: InstallmentStatus


class InstallmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    member_id: int
    year: int
    month: int
    amount: float
    status: InstallmentStatus
    paid_at: datetime | None = None
    created_at: datetime
