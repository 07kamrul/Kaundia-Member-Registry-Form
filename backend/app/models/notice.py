from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Notice(Base):
    """Bulletin shown on the public notices pages.

    `category_id` points at a `config_list_items` row (category
    'notice_category') instead of a dedicated category table. Publication is
    two-gated: `is_published` must be true *and* `publish_at` (when set) must
    have passed before the row is visible publicly - so a notice can be
    written now and go live later. `is_members_only` hides it from the
    unauthenticated public endpoints (no member-only consumer yet; the column
    exists so adding one is not a breaking schema change).
    """

    __tablename__ = "notices"
    __table_args__ = (
        Index("ix_notices_is_published_publish_at", "is_published", "publish_at"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    category_id: Mapped[int | None] = mapped_column(
        ForeignKey("config_list_items.id", ondelete="SET NULL"), nullable=True, index=True
    )
    is_published: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_members_only: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    publish_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_by: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
