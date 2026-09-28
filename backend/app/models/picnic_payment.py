from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Integer, JSON, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class PicnicPayment(Base):
    __tablename__ = "picnic_payments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    member_id: Mapped[int] = mapped_column(
        ForeignKey("members.id", ondelete="CASCADE"), nullable=False, index=True
    )
    member: Mapped["Member"] = relationship(lazy="joined")  # noqa: F821 - imported for typing via registry

    # Snapshot of the fee versions effective on the payment date, so later
    # rate changes never alter what was already paid.
    head_price: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    additional_price: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    additional_count: Mapped[int] = mapped_column(Integer, nullable=False)
    total: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)

    # Informational labels for each additional head: [{name, relation}].
    additional_heads: Mapped[list | None] = mapped_column(JSON, nullable=True)

    payment_date: Mapped[date] = mapped_column(Date, nullable=False)
    receipt_no: Mapped[str | None] = mapped_column(String(64), nullable=True)
    payment_method: Mapped[str | None] = mapped_column(String(64), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
