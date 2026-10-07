from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

# Free-text values kept as plain strings (not native enums) so the split and
# payment-source vocabularies can grow without a migration per new value.
PAYMENT_SOURCE_SOCIETY_FUND = "society_fund"
PAYMENT_SOURCE_MEMBER_BILLED = "member_billed"

SPLIT_METHOD_EQUAL = "equal"
SPLIT_METHOD_BY_LAND = "by_land_quantity"
SPLIT_METHOD_MANUAL = "manual"

SHARE_UNPAID = "unpaid"
SHARE_PARTIAL = "partial"
SHARE_PAID = "paid"


class SocietyCost(Base):
    __tablename__ = "society_costs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    category_id: Mapped[int | None] = mapped_column(
        ForeignKey("config_list_items.id", ondelete="SET NULL"), nullable=True, index=True
    )
    total_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    incurred_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    payment_source: Mapped[str] = mapped_column(String(32), nullable=False, default=PAYMENT_SOURCE_SOCIETY_FUND)
    receipt_file_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    notes: Mapped[str | None] = mapped_column(String(2000), nullable=True)

    created_by: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    category = relationship("ConfigListItem", lazy="joined")
    split = relationship(
        "CostSplit", uselist=False, back_populates="cost", cascade="all, delete-orphan", lazy="joined"
    )


class CostSplit(Base):
    __tablename__ = "cost_splits"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    society_cost_id: Mapped[int] = mapped_column(
        ForeignKey("society_costs.id", ondelete="CASCADE"), nullable=False, index=True
    )
    split_method: Mapped[str] = mapped_column(String(32), nullable=False)
    created_by: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    cost = relationship("SocietyCost", back_populates="split", lazy="joined")
    shares = relationship(
        "CostSplitShare", back_populates="split", cascade="all, delete-orphan", lazy="selectin"
    )


class CostSplitShare(Base):
    __tablename__ = "cost_split_shares"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    cost_split_id: Mapped[int] = mapped_column(
        ForeignKey("cost_splits.id", ondelete="CASCADE"), nullable=False, index=True
    )
    member_id: Mapped[int] = mapped_column(
        ForeignKey("members.id", ondelete="CASCADE"), nullable=False, index=True
    )
    amount_due: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    amount_paid: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False, default=Decimal("0"))
    status: Mapped[str] = mapped_column(String(16), nullable=False, default=SHARE_UNPAID)
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    payment_method_id: Mapped[int | None] = mapped_column(
        ForeignKey("config_list_items.id", ondelete="SET NULL"), nullable=True
    )
    receipt_no: Mapped[str | None] = mapped_column(String(64), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    split = relationship("CostSplit", back_populates="shares", lazy="joined")
    member = relationship("Member", lazy="joined")
    payment_method = relationship("ConfigListItem", lazy="joined")
