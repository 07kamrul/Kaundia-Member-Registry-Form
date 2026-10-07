from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_serializer, model_validator

from app.models.financial_transaction import FINANCE_STATUSES, FINANCE_TYPES


def _money(value: Decimal | float | int | str | None) -> str:
    """Serialize money as a fixed 2-decimal string. JSON floats lose cents on
    large sums; every consumer (frontend formatter included) parses strings."""
    if value is None:
        return "0.00"
    return f"{Decimal(str(value)):.2f}"


class FinanceTransactionBase(BaseModel):
    txn_date: date
    type: str = Field(pattern=rf"^({'|'.join(FINANCE_TYPES)})$")
    category_id: int
    amount: Decimal = Field(gt=0, max_digits=12, decimal_places=2)
    description: str = Field(min_length=1, max_length=2000)
    reference_no: str | None = Field(default=None, max_length=64)
    internal_notes: str | None = Field(default=None, max_length=2000)
    linked_payment_type: str | None = Field(default=None, max_length=24)
    linked_payment_id: int | None = None

    @model_validator(mode="after")
    def _payment_link_only_on_income(self) -> "FinanceTransactionBase":
        if self.linked_payment_type is not None or self.linked_payment_id is not None:
            if self.type != "income":
                raise ValueError("A payment link is only valid on income transactions.")
            if not self.linked_payment_type or self.linked_payment_id is None:
                raise ValueError("A payment link needs both a type and an id.")
        return self


class FinanceTransactionCreate(FinanceTransactionBase):
    # New rows enter as 'draft' (still being prepared) or 'pending' (awaiting
    # approval). 'approved'/'rejected' only happen through the workflow
    # endpoints so the approver is always recorded.
    status: str = Field(default="pending", pattern="^(draft|pending)$")


class FinanceTransactionUpdate(BaseModel):
    txn_date: date | None = None
    type: str | None = Field(default=None, pattern=rf"^({'|'.join(FINANCE_TYPES)})$")
    category_id: int | None = None
    amount: Decimal | None = Field(default=None, gt=0, max_digits=12, decimal_places=2)
    description: str | None = Field(default=None, min_length=1, max_length=2000)
    reference_no: str | None = Field(default=None, max_length=64)
    internal_notes: str | None = Field(default=None, max_length=2000)
    linked_payment_type: str | None = Field(default=None, max_length=24)
    linked_payment_id: int | None = None

    @model_validator(mode="after")
    def _payment_link_consistent(self) -> "FinanceTransactionUpdate":
        if self.linked_payment_id is not None and not self.linked_payment_type:
            raise ValueError("A payment link needs both a type and an id.")
        return self


class FinanceTransactionOut(BaseModel):
    """Member-facing projection: everything on the ledger row except the
    committee-internal fields (internal_notes, rejection_reason, creator)."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    txn_date: date
    type: str
    category_id: int | None
    category_label: str | None = None
    amount: Decimal
    description: str
    reference_no: str | None
    attachment_url: str | None
    status: str
    approved_by_name: str | None = None
    approved_at: datetime | None = None
    reversal_of_id: int | None
    created_at: datetime

    @field_serializer("amount")
    def _serialize_amount(self, value: Decimal) -> str:
        return _money(value)


class FinanceTransactionAdminOut(FinanceTransactionOut):
    model_config = ConfigDict(from_attributes=True)

    internal_notes: str | None
    rejection_reason: str | None
    linked_payment_type: str | None
    linked_payment_id: int | None
    created_by: int | None
    created_by_name: str | None = None
    is_active: bool
    updated_at: datetime


class FinanceLedgerOut(BaseModel):
    items: list[FinanceTransactionOut]
    total: int
    totals: "FinanceTotalsOut"


class FinanceAdminLedgerOut(BaseModel):
    items: list[FinanceTransactionAdminOut]
    total: int
    totals: "FinanceTotalsOut"


class FinanceTotalsOut(BaseModel):
    income: str = "0.00"
    expense: str = "0.00"
    net: str = "0.00"


class FinanceCategoryBreakdownOut(BaseModel):
    category_id: int | None
    category: str
    amount: str
    share: str  # percent of the period total, e.g. "42.31"


class FinancePeriodOut(BaseModel):
    type: str  # month | year | custom | all
    date_from: date | None
    date_to: date | None


class FinanceSeriesPointOut(BaseModel):
    label: str  # "2026-03" (month) / "2025" (year)
    income: str
    expense: str
    net: str


class FinanceSummaryOut(BaseModel):
    period: FinancePeriodOut
    totals: FinanceTotalsOut
    balance: str  # all-time approved income - expense; the hero number
    previous: FinanceTotalsOut | None  # same-length previous window; None for 'all'
    income_by_category: list[FinanceCategoryBreakdownOut]
    expense_by_category: list[FinanceCategoryBreakdownOut]
    previous_income_by_category: list[FinanceCategoryBreakdownOut]
    previous_expense_by_category: list[FinanceCategoryBreakdownOut]
    series: list[FinanceSeriesPointOut]
    granularity: str  # month | year
    transaction_count: int
    last_updated: datetime | None


class FinanceOverviewOut(BaseModel):
    pending_count: int
    month_income: str
    month_expense: str
    month_net: str
    balance: str
    recent: list[FinanceTransactionAdminOut]


class UnlinkedPaymentOut(BaseModel):
    source_type: str  # installment | picnic_payment | cost_share
    source_id: int
    member_name: str | None
    member_display_id: str | None
    amount: str
    paid_on: date
    receipt_no: str | None
    detail: str  # already display-ready summary (month/year, heads, cost title)


class FinanceRejectIn(BaseModel):
    reason: str = Field(min_length=1, max_length=500)


class FinanceReverseIn(BaseModel):
    reason: str = Field(min_length=1, max_length=500)


class FinanceReportNoticeIn(BaseModel):
    period: str = Field(default="month", pattern="^(month|year|custom|all)$")
    date_from: date | None = None
    date_to: date | None = None


class FinanceCategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    type: str  # income | expense
    label: str
    is_active: bool


class FinanceNoticeThresholdOut(BaseModel):
    threshold: str


FinanceTotalsOut.model_rebuild()
FinanceLedgerOut.model_rebuild()
FinanceAdminLedgerOut.model_rebuild()
