"""Member-drawn plot boundary polygons, their immutable version history and
boundary disputes.

The geometry is stored as RFC 7946 GeoJSON (``[lng, lat]`` order) rather than
PostGIS: the dev database is SQLite and the production image has no PostGIS
extension. Owner name, dag numbers and land quantity are deliberately NOT
copied here — the popup joins to `properties` and `members` live.

Review state lives on the VERSION, not on the boundary: `live_version_id` is
the approved shape everyone sees (NULL until the first approval) and
`pending_version_id` is the at-most-one submission awaiting review. The
boundary-level `status` column is kept only as a derived mirror for cheap
filtering; the authoritative state is the version rows.
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


class ReviewStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    SUPERSEDED = "superseded"
    WITHDRAWN = "withdrawn"


class ChangeType(str, enum.Enum):
    CREATE = "create"
    EDIT = "edit"
    ADMIN_CREATE = "admin_create"
    ADMIN_EDIT = "admin_edit"
    DELETE = "delete"


class SubmittedByRole(str, enum.Enum):
    MEMBER = "member"
    ADMIN = "admin"


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

    # GeoJSON Polygon mirror of the actionable version (pending if one awaits
    # review, else live) kept for cheap viewport filtering; the authoritative
    # geometry of each revision lives on the version rows.
    geom: Mapped[dict] = mapped_column(JSON, nullable=False)
    computed_area_sqm: Mapped[float | None] = mapped_column(Numeric(14, 2), nullable=True)
    computed_area_shotangsho: Mapped[float | None] = mapped_column(Numeric(14, 2), nullable=True)

    # Derived mirror for cheap filtering; authoritative state is the versions.
    status: Mapped[str] = mapped_column(
        String(32), default=ReviewStatus.PENDING.value, nullable=False, index=True
    )

    # The approved shape everyone sees (NULL until the first approval) and the
    # at-most-one version awaiting review.
    live_version_id: Mapped[int | None] = mapped_column(
        ForeignKey("plot_boundary_versions.id", ondelete="SET NULL", use_alter=True), nullable=True
    )
    pending_version_id: Mapped[int | None] = mapped_column(
        ForeignKey("plot_boundary_versions.id", ondelete="SET NULL", use_alter=True), nullable=True
    )

    current_version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    # Reviewer-facing warnings on the actionable version, e.g. area mismatch.
    review_note: Mapped[str | None] = mapped_column(Text, nullable=True)

    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
    deleted_by_admin_id: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    deleted_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    deleted_at: Mapped[str | None] = mapped_column(String(32), nullable=True)

    property: Mapped["Property"] = relationship()
    member: Mapped["Member"] = relationship()
    versions: Mapped[list["PlotBoundaryVersion"]] = relationship(
        back_populates="boundary", cascade="all, delete-orphan", order_by="PlotBoundaryVersion.version",
        foreign_keys="PlotBoundaryVersion.boundary_id",
    )
    disputes: Mapped[list["BoundaryDispute"]] = relationship(
        back_populates="boundary",
        foreign_keys="BoundaryDispute.boundary_id",
        cascade="all, delete-orphan",
    )


class PlotBoundaryVersion(Base):
    """Immutable history — the evidence trail. Only the review-decision fields
    (review_status, reviewed_by_admin_id, reviewed_at, review_note) are ever
    written, once, at decision time; rows are never removed."""

    __tablename__ = "plot_boundary_versions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    boundary_id: Mapped[int] = mapped_column(
        ForeignKey("plot_boundaries.id", ondelete="CASCADE"), nullable=False, index=True
    )
    version: Mapped[int] = mapped_column(Integer, nullable=False)

    geom: Mapped[dict] = mapped_column(JSON, nullable=False)
    computed_area_sqm: Mapped[float | None] = mapped_column(Numeric(14, 2), nullable=True)

    review_status: Mapped[str] = mapped_column(
        String(32), default=ReviewStatus.PENDING.value, nullable=False, index=True
    )
    # Legacy mirror of review_status, kept so pre-existing readers work.
    status: Mapped[str] = mapped_column(String(32), nullable=False, default=ReviewStatus.PENDING.value)
    change_type: Mapped[str] = mapped_column(String(32), nullable=False)
    submitted_by_role: Mapped[str] = mapped_column(String(16), default=SubmittedByRole.MEMBER.value, nullable=False)

    # The submitter is either a member (draw/edit) or an admin (create/edit on
    # behalf of a member).
    changed_by_member_id: Mapped[int | None] = mapped_column(ForeignKey("members.id", ondelete="SET NULL"))
    changed_by_admin_id: Mapped[int | None] = mapped_column(ForeignKey("admin_users.id", ondelete="SET NULL"))

    # Set once by the reviewer at decision time (note required on reject).
    reviewed_by_admin_id: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[str | None] = mapped_column(String(32), nullable=True)
    review_note: Mapped[str | None] = mapped_column(Text, nullable=True)

    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    boundary: Mapped[PlotBoundary] = relationship(
        back_populates="versions", foreign_keys=[boundary_id]
    )


class BoundaryDispute(Base):
    """An overlap between two approved polygons, or a member's report about one.

    Overlaps are flagged, never hard-blocked: real boundary disputes exist and
    the system records them for the committee instead of hiding them."""

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
