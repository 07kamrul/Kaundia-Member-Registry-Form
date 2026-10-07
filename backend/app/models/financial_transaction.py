from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Date, DateTime, ForeignKey, Index, Integer, Numeric, SmallInteger, String, func, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

# Free-text vocabularies kept as plain strings (not native enums) so the
# type/status/source vocabularies can grow without a migration per new value -
# same rationale as society_costs.
FINANCE_TYPE_INCOME = "income"
FINANCE_TYPE_EXPENSE = "expense"
FINANCE_TYPES = (FINANCE_TYPE_INCOME, FINANCE_TYPE_EXPENSE)

FINANCE_STATUS_DRAFT = "draft"
FINANCE_STATUS_PENDING = "pending"
FINANCE_STATUS_APPROVED = "approved"
FINANCE_STATUS_REJECTED = "rejected"
FINANCE_STATUSES = (FINANCE_STATUS_DRAFT, FINANCE_STATUS_PENDING, FINANCE_STATUS_APPROVED, FINANCE_STATUS_REJECTED)

# Income transactions can point at a payment record that already exists in
# the system (monthly subscription, picnic fee, cost-share collection) so the
# collection is not double-counted when it enters the fund ledger.
FINANCE_SOURCE_INSTALLMENT = "installment"
FINANCE_SOURCE_PICNIC_PAYMENT = "picnic_payment"
FINANCE_SOURCE_COST_SHARE = "cost_share"
FINANCE_SOURCES = (FINANCE_SOURCE_INSTALLMENT, FINANCE_SOURCE_PICNIC_PAYMENT, FINANCE_SOURCE_COST_SHARE)

FINANCE_INCOME_CATEGORY = "finance_income_category"
FINANCE_EXPENSE_CATEGORY = "finance_expense_category"


class FinancialTransaction(Base):
    """One row of the society fund ledger. Only rows with status 'approved'
    and is_active=1 are ever exposed to members; edits and deletes are
    soft (audit-preserving) rather than silent overwrites."""

    __tablename__ = "financial_transactions"
    __table_args__ = (
        Index("ix_financial_transactions_status_active", "status", "is_active"),
        # A payment record can back at most one live ledger row, and a
        # reference number is unique whenever it is set. Partial (WHERE
        # NOT NULL) unique indexes: NULL pairs must not collide.
        Index(
            "uq_financial_transactions_payment_link",
            "linked_payment_type",
            "linked_payment_id",
            unique=True,
            sqlite_where=text("linked_payment_type IS NOT NULL"),
            postgresql_where=text("linked_payment_type IS NOT NULL"),
        ),
        Index(
            "uq_financial_transactions_reference_no",
            "reference_no",
            unique=True,
            sqlite_where=text("reference_no IS NOT NULL"),
            postgresql_where=text("reference_no IS NOT NULL"),
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    txn_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    type: Mapped[str] = mapped_column(String(8), nullable=False, index=True)
    category_id: Mapped[int | None] = mapped_column(
        ForeignKey("config_list_items.id", ondelete="SET NULL"), nullable=True, index=True
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    description: Mapped[str] = mapped_column(String(2000), nullable=False)
    reference_no: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    attachment_url: Mapped[str | None] = mapped_column(String(512), nullable=True)

    status: Mapped[str] = mapped_column(String(16), nullable=False, default=FINANCE_STATUS_PENDING)
    rejection_reason: Mapped[str | None] = mapped_column(String(500), nullable=True)
    # Committee-internal notes; never serialized to member-facing endpoints.
    internal_notes: Mapped[str | None] = mapped_column(String(2000), nullable=True)

    linked_payment_type: Mapped[str | None] = mapped_column(String(24), nullable=True)
    linked_payment_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    reversal_of_id: Mapped[int | None] = mapped_column(
        ForeignKey("financial_transactions.id", ondelete="SET NULL"), nullable=True
    )

    created_by: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    approved_by: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    is_active: Mapped[int] = mapped_column(SmallInteger, default=1, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    category = relationship("ConfigListItem", lazy="joined")
    creator = relationship("AdminUser", foreign_keys=[created_by], lazy="joined")
    approver = relationship("AdminUser", foreign_keys=[approved_by], lazy="joined")
