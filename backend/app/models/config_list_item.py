from datetime import datetime

from sqlalchemy import DateTime, Index, Integer, SmallInteger, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class ConfigListItem(Base):
    """Admin-editable option lists (property types, document types, notice/event
    categories, ...) that used to be hard-coded frontend constants. `category`
    groups items (e.g. 'property_type'); `value` is the stable stored value
    (matches existing free-text data already saved against it); `label` is the
    display text (usually identical to `value` for the Bangla lists migrated in)."""

    __tablename__ = "config_list_items"
    __table_args__ = (
        UniqueConstraint("category", "value", name="uq_config_list_items_category_value"),
        Index("ix_config_list_items_category_active", "category", "is_active"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    category: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    value: Mapped[str] = mapped_column(String(255), nullable=False)
    label: Mapped[str] = mapped_column(String(255), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[int] = mapped_column(SmallInteger, default=1, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
