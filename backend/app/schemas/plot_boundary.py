"""Request/response schemas for plot boundaries.

The bulk map list intentionally exposes only a minimal, non-sensitive property
set — boundary_id, dag numbers, review status, is_mine and the geometry. Owner
names and phones live behind the lazy, rate-limited owner endpoint only.
"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.plot_boundary import PlotBoundaryVersion

DISCLAIMER_EN = (
    "This is a member-marked approximate boundary; it is not a substitute for "
    "an official survey or legal documents."
)
DISCLAIMER_BN = (
    "এটি সদস্য-চিহ্নিত আনুমানিক সীমানা; সরকারি জরিপ বা দলিলের বিকল্প নয়।"
)


class BoundaryGeometry(BaseModel):
    type: str = Field(default="Polygon")
    coordinates: list[list[list[float]]]


class BoundaryCreateRequest(BaseModel):
    property_id: int
    geometry: BoundaryGeometry


class BoundaryUpdateRequest(BaseModel):
    geometry: BoundaryGeometry


class AdminBoundaryUpsertRequest(BaseModel):
    """Admin add/edit on behalf of a member — goes live immediately."""

    member_id: int | None = None
    property_id: int
    geometry: BoundaryGeometry
    # Required confirmation when the shape overlaps an approved boundary; on
    # save the overlap becomes a dispute record.
    confirm_overlap: bool = False
    note: str | None = Field(default=None, max_length=2000)


class AdminDeleteRequest(BaseModel):
    reason: str = Field(min_length=3, max_length=2000)


class BoundaryReportRequest(BaseModel):
    note: str = Field(min_length=5, max_length=2000)


class MapFeatureOut(BaseModel):
    """One GeoJSON-style feature in the viewport list — no names, no phones.

    Other members see only `approved` (live) polygons; the caller's own
    pending/rejected version is included with is_mine=true."""

    boundary_id: int
    property_id: int
    rs_dag: str | None
    cs_dag: str | None
    review_status: str
    status: str  # alias of review_status for older clients
    is_mine: bool
    is_disputed: bool = False
    geometry: dict


class PlotMapOut(BaseModel):
    disclaimer_en: str = DISCLAIMER_EN
    disclaimer_bn: str = DISCLAIMER_BN
    count: int
    features: list[MapFeatureOut]


class OwnerOut(BaseModel):
    boundary_id: int
    owner_name: str
    mobile: str | None
    contact_hidden: bool
    rs_dag: str | None
    cs_dag: str | None
    land_quantity: str | None
    computed_area_sqm: float | None
    computed_area_shotangsho: float | None
    review_status: str
    status: str  # alias of review_status for older clients
    is_disputed: bool = False


class MyBoundaryOut(BaseModel):
    """One of the caller's boundaries: the live shape plus the actionable
    (pending, or last rejected) version with its review note."""

    id: int
    property_id: int
    rs_dag: str | None
    cs_dag: str | None
    land_quantity: str | None

    has_pending: bool
    review_status: str
    status: str  # alias of review_status for older clients
    geometry: dict | None  # the actionable shape: pending, else live, else last rejected
    computed_area_sqm: float | None
    computed_area_shotangsho: float | None
    current_version: int
    review_note: str | None  # decision note on the pending/rejected version
    warnings: list[str] = []

    live_review_status: str | None
    live_geometry: dict | None


class BoundaryVersionOut(BaseModel):
    id: int
    version: int
    geometry: dict
    computed_area_sqm: float | None
    review_status: str
    status: str  # alias of review_status for older clients
    change_type: str
    submitted_by_role: str
    changed_by_member_id: int | None
    changed_by_admin_id: int | None
    reviewed_at: str | None
    review_note: str | None
    note: str | None
    created_at: datetime


def version_out(v: PlotBoundaryVersion) -> BoundaryVersionOut:
    return BoundaryVersionOut(
        id=v.id,
        version=v.version,
        geometry=v.geom,
        computed_area_sqm=float(v.computed_area_sqm) if v.computed_area_sqm is not None else None,
        review_status=v.review_status,
        status=v.review_status,
        change_type=v.change_type,
        submitted_by_role=v.submitted_by_role,
        changed_by_member_id=v.changed_by_member_id,
        changed_by_admin_id=v.changed_by_admin_id,
        reviewed_at=v.reviewed_at,
        review_note=v.review_note,
        note=v.note,
        created_at=v.created_at,
    )


class AdminBoundaryOut(BaseModel):
    id: int
    property_id: int
    member_id: int
    member_name: str
    member_mobile: str | None
    rs_dag: str | None
    cs_dag: str | None
    khatian_no: str | None
    land_quantity: str | None

    # Derived workflow state: 'pending' | 'approved' | 'rejected' | 'deleted'
    status: str
    live_version_id: int | None
    pending_version_id: int | None
    live_review_status: str | None
    pending_review_status: str | None
    is_disputed: bool = False
    current_version: int

    # The actionable geometry: pending shape if one awaits review, else live.
    geometry: dict | None
    computed_area_sqm: float | None
    computed_area_shotangsho: float | None
    review_note: str | None

    is_deleted: bool
    deleted_reason: str | None
    deleted_at: str | None


class ReviewActionRequest(BaseModel):
    note: str | None = Field(default=None, max_length=2000)


class PendingCountOut(BaseModel):
    count: int


class BoundaryDisputeOut(BaseModel):
    id: int
    boundary_id: int
    other_boundary_id: int | None
    overlap_area_sqm: float | None
    note: str | None
    status: str
    resolution_note: str | None


class DisputeResolveRequest(BaseModel):
    resolution_note: str = Field(min_length=5, max_length=2000)
    dismiss: bool = False
