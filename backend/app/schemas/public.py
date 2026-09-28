from datetime import date as date_type
from decimal import Decimal

from pydantic import BaseModel, Field


class PublicStatsOut(BaseModel):
    pending_count: int
    approved_count: int
    monthly_subscription_total: float


class SubscriptionQuoteRequest(BaseModel):
    land_size_decimal: Decimal
    billing_date: date_type | None = Field(default=None, alias="date")

    model_config = {"populate_by_name": True}


class SubscriptionQuoteOut(BaseModel):
    base: Decimal
    extra_decimals: Decimal
    extra_amount: Decimal
    total: Decimal
    unit: str
    rate_version_effective_from: date_type | None
