"""Member-drawn plot boundary polygons, their immutable version history and
boundary disputes.

The geometry is stored as RFC 7946 GeoJSON (``[lng, lat]`` order) rather than
PostGIS: the dev database is SQLite and the production image has no PostGIS
extension. Owner name, dag numbers and land quantity are deliberately NOT
copied here — the popup joins to `properties` and `members` live.
"""

import enum
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import JSON, Boolean, DateTime, ForeignKey, Integer, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.member import Member
    from app.models.property import Property


class BoundaryStatus(str, enum.Enum):
    DRAFT = "draft"
    PENDING_REVIEW = "pending_review"
    APPROVED = "approved"
    REJECTED = "rejected"
    DISPUTED = "disputed"


class ChangeType(str, enum.Enum):
    CREATE = "create"
    EDIT = "edit"
    APPROVE = "approve"
    REJECT = "reject"
    DELETE = "delete"


class PlotBoundary(Base):
    __tablename__ = "plot_boundaries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    # One active boundary per property; uniqueness of *active* rows is enforced
    # in the service layer (a soft-deleted boundary must allow a redraw).
    property_id: Mapped[int] = mapped_column(
        ForeignKey("properties.id", ondelete="CASCADE"), nullable=False, index=True
    )
    member_id: Mapped[int] = mapped_column(
        ForeignKey("members.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # GeoJSON Polygon: {"type": "Polygon", "coordinates": [[[lng, lat], ...]]}
    geom: Mapped[dict] = mapped_column(JSON, nullable=False)

    computed_area_sqm: Mapped[float | None] = mapped_column(Numeric(14, 2), nullable=True)
    computed_area_shotangsho: Mapped[float | None] = mapped_column(Numeric(14, 2), nullable=True)

    status: Mapped[str] = mapped_column(
        String(32), default=BoundaryStatus.PENDING_REVIEW.value, nullable=False, index=True
    )
    # Last reviewer-facing warning, e.g. area differs from the declared quantity.
    review_note: Mapped[str | None] = mapped_column(Text, nullable=True)

    current_version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    reviewed_by: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[str | None] = mapped_column(String(32), nullable=True)

    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)

    property: Mapped["Property"] = relationship()
    member: Mapped["Member"] = relationship()
    versions: Mapped[list["PlotBoundaryVersion"]] = relationship(
        back_populates="boundary", cascade="all, delete-orphan", order_by="PlotBoundaryVersion.version"
    )
    disputes: Mapped[list["BoundaryDispute"]] = relationship(
        back_populates="boundary",
        foreign_keys="BoundaryDispute.boundary_id",
        cascade="all, delete-orphan",
    )


class PlotBoundaryVersion(Base):
    """Immutable history — the evidence trail. Rows are never updated or removed."""

    __tablename__ = "plot_boundary_versions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    boundary_id: Mapped[int] = mapped_column(
        ForeignKey("plot_boundaries.id", ondelete="CASCADE"), nullable=False, index=True
    )
    version: Mapped[int] = mapped_column(Integer, nullable=False)

    geom: Mapped[dict] = mapped_column(JSON, nullable=False)
    computed_area_sqm: Mapped[float | None] = mapped_column(Numeric(14, 2), nullable=True)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    change_type: Mapped[str] = mapped_column(String(32), nullable=False)

    # The actor is either a member (draw/edit) or an admin (review decision).
    changed_by_member_id: Mapped[int | None] = mapped_column(ForeignKey("members.id", ondelete="SET NULL"))
    changed_by_admin_id: Mapped[int | None] = mapped_column(ForeignKey("admin_users.id", ondelete="SET NULL"))
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    boundary: Mapped[PlotBoundary] = relationship(back_populates="versions")


class BoundaryDispute(Base):
    """An overlap between two approved polygons, or a member's report about one.

    Overlaps are flagged, never hard-blocked: real boundary disputes exist and
    the system records them for the committee instead of hiding them.
    """

    __tablename__ = "boundary_disputes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    boundary_id: Mapped[int] = mapped_column(
        ForeignKey("plot_boundaries.id", ondelete="CASCADE"), nullable=False, index=True
    )
    # NULL when the dispute is a member report rather than an overlap.
    other_boundary_id: Mapped[int | None] = mapped_column(
        ForeignKey("plot_boundaries.id", ondelete="CASCADE"), nullable=True
    )
    overlap_area_sqm: Mapped[float | None] = mapped_column(Numeric(14, 2), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    status: Mapped[str] = mapped_column(String(32), default="open", nullable=False, index=True)
    resolved_by: Mapped[int | None] = mapped_column(ForeignKey("admin_users.id", ondelete="SET NULL"))
    resolved_at: Mapped[str | None] = mapped_column(String(32), nullable=True)
    resolution_note: Mapped[str | None] = mapped_column(Text, nullable=True)

    boundary: Mapped[PlotBoundary] = relationship(
        back_populates="disputes", foreign_keys=[boundary_id]
    )
