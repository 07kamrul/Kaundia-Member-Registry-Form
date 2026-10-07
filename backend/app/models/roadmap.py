from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Index, Integer, SmallInteger, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

# Plain-string vocabulary (not a native enum) so a new status never needs a
# migration - same rationale as financial_transactions.
ROADMAP_STATUS_PLANNED = "planned"
ROADMAP_STATUS_IN_PROGRESS = "in_progress"
ROADMAP_STATUS_DONE = "done"
ROADMAP_STATUSES = (ROADMAP_STATUS_PLANNED, ROADMAP_STATUS_IN_PROGRESS, ROADMAP_STATUS_DONE)


class RoadmapTimeframe(Base):
    """One horizon of the society roadmap (১ মাস / ৪ মাস / ১ বছর). Seeded by
    the migration; admins only edit labels, never add ad hoc horizons."""

    __tablename__ = "roadmap_timeframes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    key: Mapped[str] = mapped_column(String(16), unique=True, nullable=False)
    name_bn: Mapped[str] = mapped_column(String(120), nullable=False)
    name_en: Mapped[str] = mapped_column(String(120), nullable=False)
    target_window_bn: Mapped[str] = mapped_column(String(60), nullable=False)
    target_window_en: Mapped[str] = mapped_column(String(60), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class RoadmapItem(Base):
    """A single plan item. `is_active=0` with `archived_at` set means the item
    belongs to a closed roadmap cycle; `is_active=0` without it means removed.
    Both are soft so the audit trail keeps pointing at real rows."""

    __tablename__ = "roadmap_items"
    __table_args__ = (Index("ix_roadmap_items_timeframe_active", "timeframe_id", "is_active", "sort_order"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    timeframe_id: Mapped[int] = mapped_column(
        ForeignKey("roadmap_timeframes.id", ondelete="RESTRICT"), nullable=False
    )
    text: Mapped[str] = mapped_column(String(500), nullable=False)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default=ROADMAP_STATUS_PLANNED)
    target_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    owner: Mapped[str | None] = mapped_column(String(120), nullable=True)
    note: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    completed_at: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_active: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=1)
    archived_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_by: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    timeframe = relationship("RoadmapTimeframe", lazy="joined")
