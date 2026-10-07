from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Column, Date, DateTime, ForeignKey, Index, Integer, Numeric, String, Table, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

# Plain strings (not native enums) so the vocabulary can grow without a
# migration - same rationale as financial_transactions.
PAYMENT_STATUS_PENDING = "pending"
PAYMENT_STATUS_APPROVED = "approved"
PAYMENT_STATUS_REJECTED = "rejected"
PAYMENT_STATUSES = (PAYMENT_STATUS_PENDING, PAYMENT_STATUS_APPROVED, PAYMENT_STATUS_REJECTED)

installment_payment_items = Table(
    "installment_payment_items",
    Base.metadata,
    Column("payment_id", ForeignKey("installment_payments.id", ondelete="CASCADE"), primary_key=True),
    Column("installment_id", ForeignKey("installments.id", ondelete="CASCADE"), primary_key=True, index=True),
)


class InstallmentPayment(Base):
    """A member's self-reported payment for one or more DUE installments.
    It only turns those installments PAID once a committee member verifies
    the transaction reference against the society's account."""

    __tablename__ = "installment_payments"
    __table_args__ = (
        # The same mobile-banking / bank transaction can back one payment only.
        Index("uq_installment_payments_method_ref", "method", "transaction_ref", unique=True),
        Index("ix_installment_payments_status_created", "status", "created_at"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    member_id: Mapped[int] = mapped_column(
        ForeignKey("members.id", ondelete="CASCADE"), nullable=False, index=True
    )
    method: Mapped[str] = mapped_column(String(64), nullable=False)
    transaction_ref: Mapped[str] = mapped_column(String(64), nullable=False)
    sender_account: Mapped[str | None] = mapped_column(String(64), nullable=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    paid_on: Mapped[date] = mapped_column(Date, nullable=False)
    proof_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    note: Mapped[str | None] = mapped_column(String(500), nullable=True)

    status: Mapped[str] = mapped_column(String(16), nullable=False, default=PAYMENT_STATUS_PENDING)
    rejection_reason: Mapped[str | None] = mapped_column(String(500), nullable=True)
    reviewed_by: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    member: Mapped["Member"] = relationship(lazy="joined")  # noqa: F821
    installments: Mapped[list["Installment"]] = relationship(  # noqa: F821
        secondary=installment_payment_items, lazy="selectin", order_by="(Installment.year, Installment.month)"
    )


from app.models.installment import Installment  # noqa: E402,F401
from app.models.member import Member  # noqa: E402,F401
