from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.services.fee_calculation import PICNIC_MAX_ADDITIONAL_HEADS


class PicnicAdditionalHead(BaseModel):
    """Informational label for one additional seat; does not affect price."""

    name: str = Field(min_length=1, max_length=255)
    relation: str = Field(min_length=1, max_length=128)


class PicnicPaymentIn(BaseModel):
    additional_heads: int = Field(default=0, ge=0, le=PICNIC_MAX_ADDITIONAL_HEADS)
    additional_people: list[PicnicAdditionalHead] = []
    payment_date: date
    receipt_no: str | None = Field(default=None, max_length=64)
    payment_method: str | None = Field(default=None, max_length=64)

    @field_validator("additional_heads", mode="before")
    @classmethod
    def require_integer(cls, value: object) -> object:
        # Reject 2.5 / "2" so the count is always a true integer, not a float.
        if isinstance(value, float) and not value.is_integer():
            raise ValueError("Additional heads must be a whole number")
        if isinstance(value, str) and not value.isdigit():
            raise ValueError("Additional heads must be a whole number")
        return value

    @field_validator("additional_people")
    @classmethod
    def labels_match_count(cls, value: list[PicnicAdditionalHead], info) -> list[PicnicAdditionalHead]:
        count = info.data.get("additional_heads")
        if count is not None and len(value) > count:
            raise ValueError("More labels than additional heads")
        return value


class PicnicPaymentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    head_price: Decimal
    additional_price: Decimal
    additional_count: int
    total: Decimal
    additional_heads: list | None
    payment_date: date
    receipt_no: str | None
    payment_method: str | None
    created_at: datetime
