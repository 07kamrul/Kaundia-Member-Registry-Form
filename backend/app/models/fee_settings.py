from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    SmallInteger,
    String,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class FeeSetting(Base):
    __tablename__ = "fee_settings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    key: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    value: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    unit: Mapped[str | None] = mapped_column(String(32), nullable=True)

    # 'other' | 'installment' - which member payment page (if any) offers
    # this fee. Drives the Other Fees catalog instead of a hard-coded list.
    fee_category: Mapped[str] = mapped_column(
        String(32), nullable=False, default="other", server_default="other"
    )

    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    status: Mapped[int] = mapped_column(SmallInteger, default=1, nullable=False, index=True)

    created_by: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class FeeType(Base):
    """An admin-managed fee definition (the generic Fee Settings catalog).

    A fee type's *rates* still live in the versioned ``fee_settings`` rows so
    existing history keeps working; the derivation from a fee type key to its
    setting keys lives in ``services/fee_catalog.setting_keys_for``.
    """

    __tablename__ = "fee_types"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    key: Mapped[str] = mapped_column(String(64), nullable=False, unique=True, index=True)
    label_bn: Mapped[str] = mapped_column(String(128), nullable=False)
    label_en: Mapped[str] = mapped_column(String(128), nullable=False)

    # fixed | tiered | head_additional | variable - selects which inputs the
    # version form shows and which calculation service prices the fee.
    calculation_type: Mapped[str] = mapped_column(String(32), nullable=False, default="fixed")
    unit: Mapped[str] = mapped_column(String(32), nullable=False, default="taka")

    is_recurring: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_pay_once: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    # 'other' | 'installment' - same grouping flag as fee_settings.fee_category.
    fee_category: Mapped[str] = mapped_column(
        String(32), nullable=False, default="other", server_default="other"
    )
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    # Only used by head_additional fees whose legacy setting keys don't follow
    # the derived `<key>` / `<key>_additional_head` pattern (the seeded picnic
    # fee reuses picnic_head_fee / picnic_additional_head_fee).
    head_setting_key: Mapped[str | None] = mapped_column(String(64), nullable=True)
    additional_setting_key: Mapped[str | None] = mapped_column(String(64), nullable=True)

    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    created_by: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
