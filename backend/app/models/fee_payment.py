from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class FeePayment(Base):
    """A member-recorded payment for a general society fee (installment fee,
    picnic fee, extra fee, ...). Recorded immediately like picnic payments -
    the committee reviews the ledger via GET /admin/fee-payments rather than
    gating each submission behind an approval flow."""

    __tablename__ = "fee_payments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    member_id: Mapped[int] = mapped_column(
        ForeignKey("members.id", ondelete="CASCADE"), nullable=False, index=True
    )
    member: Mapped["Member"] = relationship(lazy="joined")  # noqa: F821 - imported for typing via registry

    # One of FEE_TYPE_KEYS (services/fee_catalog.py); kept as a string so new
    # fee types can be added without a migration.
    fee_type: Mapped[str] = mapped_column(String(32), nullable=False, index=True)

    amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)

    payment_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    receipt_no: Mapped[str | None] = mapped_column(String(64), nullable=True)
    payment_method: Mapped[str | None] = mapped_column(String(64), nullable=True)
    note: Mapped[str | None] = mapped_column(String(500), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
