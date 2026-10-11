"""Schemas for the unified member "Other Fees" page.

Covers every non-installment fee: fixed amounts resolved from Fee Settings,
variable amounts entered by the member (donation, extra, ...), and the
special per-head picnic calculation.
"""

from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class OtherFeeTypeOut(BaseModel):
    """One payable fee type as offered on the Other Fees page.

    calculation:
      - fixed:    amount comes from Fee Settings (read-only for the member)
      - variable: the member enters the amount (> 0, server-validated)
      - picnic:   head + additional heads, computed from the two picnic keys
    """

    key: str
    label: str
    calculation: str
    amount: float | None = None
    unit: str | None = None
    pay_once: bool = False
    already_paid: bool | None = None
    head_fee: float | None = None
    additional_head_fee: float | None = None


class OtherFeePaymentIn(BaseModel):
    fee_type: str
    payment_date: date
    payment_method: str | None = Field(default=None, max_length=64)
    receipt_no: str | None = Field(default=None, max_length=64)
    note: str | None = Field(default=None, max_length=500)
    # Only used by variable (custom-amount) types; ignored everywhere else -
    # fixed and picnic totals are always recomputed server-side.
    amount: Decimal | None = Field(default=None, gt=0, decimal_places=2, max_digits=12)
    # Only used by the picnic calculation.
    additional_heads: int | None = Field(default=None, ge=0)
    additional_people: list[dict] | None = None

    @field_validator("amount")
    @classmethod
    def sane_amount(cls, value: Decimal | None) -> Decimal | None:
        if value is not None and value > Decimal("10000000"):
            raise ValueError("Amount is unreasonably large")
        return value

    @field_validator("additional_heads")
    @classmethod
    def whole_heads(cls, value: int | None) -> int | None:
        if value is not None and isinstance(value, bool):
            raise ValueError("Additional heads must be a whole number")
        return value


class OtherFeePaymentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    source: str
    fee_type: str
    amount: Decimal
    payment_date: date
    additional_heads: int | None
    receipt_no: str | None
    payment_method: str | None
    note: str | None
    created_at: datetime


class OtherFeeHistoryPage(BaseModel):
    items: list[OtherFeePaymentOut]
    total: int
    page: int
    page_size: int
    summary: "OtherFeeHistorySummary"


class OtherFeeHistorySummary(BaseModel):
    total_paid: float
    by_type: dict[str, float]


OtherFeeHistoryPage.model_rebuild()


class AdminOtherFeePaymentOut(OtherFeePaymentOut):
    member_id: int
    member_name: str | None = None


class AdminOtherFeeHistoryPage(OtherFeeHistoryPage):
    items: list[AdminOtherFeePaymentOut]
