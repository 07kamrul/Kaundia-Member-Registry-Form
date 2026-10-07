from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class SocietyCostBase(BaseModel):
    title: str = Field(min_length=1, max_length=255)
    description: str | None = Field(default=None, max_length=2000)
    category_id: int | None = None
    total_amount: Decimal = Field(gt=0, max_digits=12, decimal_places=2)
    incurred_date: date
    payment_source: str = Field(default="society_fund", pattern="^(society_fund|member_billed)$")
    notes: str | None = Field(default=None, max_length=2000)


class SocietyCostCreate(SocietyCostBase):
    pass


class SocietyCostUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = Field(default=None, max_length=2000)
    category_id: int | None = None
    total_amount: Decimal | None = Field(default=None, gt=0, max_digits=12, decimal_places=2)
    incurred_date: date | None = None
    payment_source: str | None = Field(default=None, pattern="^(society_fund|member_billed)$")
    notes: str | None = Field(default=None, max_length=2000)


class CostSplitShareOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    cost_split_id: int
    member_id: int
    member_name: str | None = None
    member_display_id: str | None = None
    cost_title: str | None = None
    cost_incurred_date: date | None = None
    cost_category: str | None = None
    amount_due: Decimal
    amount_paid: Decimal
    status: str
    paid_at: datetime | None = None
    payment_method_id: int | None = None
    payment_method_label: str | None = None
    receipt_no: str | None = None


class CostSplitOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    society_cost_id: int
    split_method: str
    created_by: int | None = None
    created_at: datetime
    shares: list[CostSplitShareOut] = []


class SocietyCostOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: str | None
    category_id: int | None
    category_label: str | None = None
    total_amount: Decimal
    incurred_date: date
    payment_source: str
    receipt_file_url: str | None
    notes: str | None
    created_by: int | None
    created_at: datetime
    updated_at: datetime
    split: CostSplitOut | None = None


class ManualShareIn(BaseModel):
    member_id: int
    amount_due: Decimal = Field(ge=0, max_digits=12, decimal_places=2)


class CostSplitCreate(BaseModel):
    split_method: str = Field(pattern="^(equal|by_land_quantity|manual)$")
    manual_shares: list[ManualShareIn] | None = None
    allow_mismatch: bool = False
    dry_run: bool = False


class SplitPreviewRow(BaseModel):
    member_id: int
    member_name: str
    amount_due: Decimal


class SharePaymentUpdate(BaseModel):
    amount_paid: Decimal = Field(ge=0, max_digits=12, decimal_places=2)
    payment_method_id: int | None = None
    receipt_no: str | None = Field(default=None, max_length=64)


class CostSummaryOut(BaseModel):
    total_amount: Decimal
    society_fund_total: Decimal
    member_billed_total: Decimal
    outstanding_total: Decimal
    collected_total: Decimal
    by_category: list[dict] = []
