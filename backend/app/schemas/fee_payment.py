from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.services.fee_catalog import FEE_TYPE_KEYS


class FeePaymentIn(BaseModel):
    fee_type: str
    amount: Decimal = Field(gt=0, decimal_places=2, max_digits=12)
    payment_date: date
    receipt_no: str | None = Field(default=None, max_length=64)
    payment_method: str | None = Field(default=None, max_length=64)
    note: str | None = Field(default=None, max_length=500)

    @field_validator("fee_type")
    @classmethod
    def known_fee_type(cls, value: str) -> str:
        if value not in FEE_TYPE_KEYS:
            raise ValueError("Unknown fee type")
        return value

    @field_validator("amount")
    @classmethod
    def sane_amount(cls, value: Decimal) -> Decimal:
        if value > Decimal("10000000"):
            raise ValueError("Amount is unreasonably large")
        return value


class FeeTypeOut(BaseModel):
    """One entry of the fee catalog, with the suggested amount resolved from
    the FeeSetting version effective on the requested date (null when the
    committee has not configured one - the member enters the amount)."""

    key: str
    default_amount: float | None
    unit: str | None


class FeePaymentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    member_id: int
    fee_type: str
    amount: Decimal
    payment_date: date
    receipt_no: str | None
    payment_method: str | None
    note: str | None
    created_at: datetime
