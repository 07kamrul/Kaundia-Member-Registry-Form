"""Schemas for the generic, admin-managed fee-type catalog."""

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.services.fee_catalog import (
    CALCULATION_TYPES,
    CALC_FIXED,
    FEE_CATEGORIES,
)

_KEY_RE = r"^[a-z][a-z0-9_]*$"


class FeeTypeCreate(BaseModel):
    key: str = Field(pattern=_KEY_RE, min_length=2, max_length=64)
    label_bn: str = Field(min_length=1, max_length=128)
    label_en: str = Field(min_length=1, max_length=128)
    calculation_type: str = CALC_FIXED
    unit: str = "taka"
    is_recurring: bool = False
    is_pay_once: bool = False
    fee_category: str = "other"

    @model_validator(mode="after")
    def _check_enums(self) -> "FeeTypeCreate":
        if self.calculation_type not in CALCULATION_TYPES:
            raise ValueError(f"calculation_type must be one of {', '.join(CALCULATION_TYPES)}")
        if self.fee_category not in FEE_CATEGORIES:
            raise ValueError(f"fee_category must be one of {', '.join(FEE_CATEGORIES)}")
        return self


class FeeTypeUpdate(BaseModel):
    label_bn: str | None = Field(default=None, min_length=1, max_length=128)
    label_en: str | None = Field(default=None, min_length=1, max_length=128)
    unit: str | None = None
    is_recurring: bool | None = None
    is_pay_once: bool | None = None
    fee_category: str | None = None
    is_active: bool | None = None

    @model_validator(mode="after")
    def _check_category(self) -> "FeeTypeUpdate":
        if self.fee_category is not None and self.fee_category not in FEE_CATEGORIES:
            raise ValueError(f"fee_category must be one of {', '.join(FEE_CATEGORIES)}")
        return self


class FeeTypeVersionOut(BaseModel):
    """One historical version of a fee type - the values dict is keyed by the
    fee type's setting keys (single value, tier trio, head pair or bounds)."""

    start_date: date
    end_date: date | None = None
    status: int
    values: dict[str, float]


class FeeTypeCurrentVersion(BaseModel):
    values: dict[str, float]
    unit: str | None = None
    start_date: date


class FeeTypeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    key: str
    label_bn: str
    label_en: str
    calculation_type: str
    unit: str
    is_recurring: bool
    is_pay_once: bool
    fee_category: str
    is_active: bool
    sort_order: int
    created_at: datetime
    current_version: FeeTypeCurrentVersion | None = None
    # Number of payments recorded against this fee (incl. legacy aliases) -
    # the UI asks for confirmation before deactivating when this is > 0.
    payment_count: int = 0


class FeeTypeVersionCreate(BaseModel):
    """Create a new rate version for a fee type. Which fields are required is
    decided by the fee type's calculation_type; extras are ignored."""

    value: float | None = None  # fixed
    base_amount: float | None = None  # tiered
    additional_rate: float | None = None
    base_threshold: float | None = None
    head_fee: float | None = None  # head_additional
    additional_head_fee: float | None = None
    min_amount: float | None = None  # variable (optional bounds)
    max_amount: float | None = None
    unit: str | None = None
    start_date: date | None = None

    @model_validator(mode="after")
    def _validate_amounts(self) -> "FeeTypeVersionCreate":
        for name in (
            "value",
            "base_amount",
            "additional_rate",
            "base_threshold",
            "head_fee",
            "additional_head_fee",
            "min_amount",
            "max_amount",
        ):
            v = getattr(self, name)
            if v is not None and v < 0:
                raise ValueError(f"{name} must not be negative")
        if (
            self.max_amount is not None
            and self.min_amount is not None
            and self.max_amount < self.min_amount
        ):
            raise ValueError("max_amount must not be less than min_amount")
        return self


class FeeTypeCalculateIn(BaseModel):
    """Calculator preview inputs; which field is meaningful depends on the
    fee type's calculation_type."""

    land_size: float | None = None  # tiered
    additional_heads: int | None = None  # head_additional
    amount: float | None = None  # variable (echoed with bounds check)
    on_date: date | None = None
