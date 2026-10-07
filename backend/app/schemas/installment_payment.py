from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.installment import InstallmentOut


class PaymentAccountOut(BaseModel):
    """Where members send money - admin-editable via the 'payment_account'
    config list (value = method name, label = account details)."""

    method: str
    details: str


class InstallmentPaymentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    method: str
    transaction_ref: str
    sender_account: str | None = None
    amount: Decimal
    paid_on: date
    proof_url: str | None = None
    note: str | None = None
    status: str
    rejection_reason: str | None = None
    reviewed_at: datetime | None = None
    created_at: datetime
    installments: list[InstallmentOut] = []


class InstallmentPaymentAdminOut(InstallmentPaymentOut):
    member_id: int
    member_name: str | None = None
    member_display_id: str | None = None


class PayableSummaryOut(BaseModel):
    due: list[InstallmentOut]
    pending_installment_ids: list[int]
    total_due: Decimal
    accounts: list[PaymentAccountOut]
    payments: list[InstallmentPaymentOut]


class PaymentRejectIn(BaseModel):
    reason: str = Field(min_length=3, max_length=500)
