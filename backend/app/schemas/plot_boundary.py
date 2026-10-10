"""Request/response schemas for plot boundaries.

The bulk map list intentionally exposes only a minimal, non-sensitive property
set — boundary_id, dag numbers, status, is_mine and the geometry. Owner names
and phones live behind the lazy, rate-limited owner endpoint only.
"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

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


class BoundaryReportRequest(BaseModel):
    note: str = Field(min_length=5, max_length=2000)


class BoundaryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    property_id: int
    status: str
    geometry: dict
    computed_area_sqm: float | None
    computed_area_shotangsho: float | None
    current_version: int
    review_note: str | None = None
    warnings: list[str] = []


class MyBoundaryOut(BoundaryOut):
    rs_dag: str | None
    cs_dag: str | None
    land_quantity: str | None


class MapFeatureOut(BaseModel):
    """One GeoJSON-style feature in the viewport list — no names, no phones."""

    boundary_id: int
    property_id: int
    rs_dag: str | None
    cs_dag: str | None
    status: str
    is_mine: bool
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
    status: str


class BoundaryVersionOut(BaseModel):
    id: int
    version: int
    geometry: dict
    computed_area_sqm: float | None
    status: str
    change_type: str
    changed_by_member_id: int | None
    changed_by_admin_id: int | None
    note: str | None
    created_at: datetime


def version_out(v: PlotBoundaryVersionLike) -> BoundaryVersionOut:
    return BoundaryVersionOut(
        id=v.id,
        version=v.version,
        geometry=v.geom,
        computed_area_sqm=float(v.computed_area_sqm) if v.computed_area_sqm is not None else None,
        status=v.status,
        change_type=v.change_type,
        changed_by_member_id=v.changed_by_member_id,
        changed_by_admin_id=v.changed_by_admin_id,
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
    status: str
    geometry: dict
    computed_area_sqm: float | None
    computed_area_shotangsho: float | None
    current_version: int
    review_note: str | None
    is_deleted: bool


class ReviewActionRequest(BaseModel):
    note: str | None = Field(default=None, max_length=2000)


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
