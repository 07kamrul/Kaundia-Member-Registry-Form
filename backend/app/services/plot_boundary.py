"""Business rules for member-drawn plot boundaries.

Validation is authoritative here; clients mirror it for UX only. Area,
overlap and containment math comes from `app.services.geo`. Owner-facing
values (name, dag, quantity) are never stored on the boundary — popups join
to `properties`/`members` live.
"""

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.models.member import Member, MemberStatus
from app.models.plot_boundary import (
    BoundaryDispute,
    BoundaryStatus,
    ChangeType,
    PlotBoundary,
    PlotBoundaryVersion,
)
from app.models.property import Property
from app.services import geo
from app.services.audit import record_audit


class ValidationIssue(Exception):
    """Polygon rejected with a machine-readable code."""

    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.message = message


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _society_bounds() -> geo.Bounds:
    return geo.parse_bounds(get_settings().boundary_society_bbox)


def area_warnings(ring: list[list[float]], property_row: Property | None) -> list[str]:
    """Warnings (never errors) comparing computed area to the declared quantity."""
    warnings: list[str] = []
    area = geo.geodesic_area_sqm(ring)
    declared = _parse_land_quantity_sqm(property_row.land_quantity if property_row else None)
    if declared and area > 0:
        tolerance = get_settings().boundary_area_tolerance_pct / 100
        if abs(area - declared) / declared > tolerance:
            warnings.append(
                f"AREA_MISMATCH: computed {area:.0f} m² vs declared {declared:.0f} m² "
                f"(tolerance {get_settings().boundary_area_tolerance_pct}%)"
            )
    return warnings


def _parse_land_quantity_sqm(raw: str | None) -> float | None:
    """Land quantities are free-text (e.g. '5', '5 শতাংশ'); interpret a bare
    number as shotangsho, the local unit."""
    if not raw:
        return None
    text = raw.strip().replace(",", "")
    digits = "".join(ch for ch in text if ch.isdigit() or ch == ".")
    if not digits:
        return None
    try:
        value = float(digits)
    except ValueError:
        return None
    return value * geo.SQM_PER_SHOTANGSHO


def validate_polygon(geometry: dict) -> list[list[float]]:
    """Full server-side validation; returns the normalized ring or raises."""
    settings = get_settings()
    try:
        ring = geo.normalize_geometry(geometry)
    except ValueError as exc:
        raise ValidationIssue("INVALID_GEOMETRY", str(exc)) from exc

    if geo.distinct_vertices(ring) > settings.boundary_max_vertices:
        raise ValidationIssue(
            "TOO_MANY_VERTICES",
            f"at most {settings.boundary_max_vertices} vertices are allowed",
        )

    bounds = _society_bounds()
    outside = [(lng, lat) for lng, lat in ring[:-1] if not bounds.contains(lng, lat)]
    if outside:
        raise ValidationIssue(
            "OUTSIDE_SOCIETY_AREA", "the polygon lies outside the society bounding box"
        )

    if geo.has_self_intersection(ring):
        raise ValidationIssue("SELF_INTERSECTING", "the polygon edges cross themselves")

    if geo.geodesic_area_sqm(ring) <= 0.01:
        raise ValidationIssue("ZERO_AREA", "the polygon has no area")
    return ring


async def _own_property(db: AsyncSession, member: Member, property_id: int) -> Property:
    result = await db.execute(
        select(Property).where(Property.id == property_id, Property.member_id == member.id)
    )
    property_row = result.scalar_one_or_none()
    if property_row is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": "NOT_YOUR_PROPERTY",
                "message": "You can only draw boundaries for your own properties.",
            },
        )
    return property_row


async def _ensure_no_active_boundary(db: AsyncSession, property_id: int) -> None:
    result = await db.execute(
        select(PlotBoundary.id).where(
            PlotBoundary.property_id == property_id, PlotBoundary.is_deleted.is_(False)
        )
    )
    if result.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "BOUNDARY_EXISTS",
                "message": "This property already has a boundary. Edit it instead.",
            },
        )


def record_version(
    boundary: PlotBoundary,
    *,
    change_type: ChangeType,
    member_id: int | None = None,
    admin_id: int | None = None,
    note: str | None = None,
) -> PlotBoundaryVersion:
    version = PlotBoundaryVersion(
        boundary_id=boundary.id,
        version=boundary.current_version,
        geom=boundary.geom,
        computed_area_sqm=boundary.computed_area_sqm,
        status=boundary.status,
        change_type=change_type.value,
        changed_by_member_id=member_id,
        changed_by_admin_id=admin_id,
        note=note,
    )
    return version


async def create_boundary(db: AsyncSession, member: Member, property_id: int, geometry: dict) -> PlotBoundary:
    if member.status != MemberStatus.APPROVED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "APPROVED_MEMBERS_ONLY", "message": "Approved members only."},
        )
    property_row = await _own_property(db, member, property_id)
    await _ensure_no_active_boundary(db, property_id)

    ring = validate_polygon(geometry)
    area = round(geo.geodesic_area_sqm(ring), 2)

    boundary = PlotBoundary(
        property_id=property_id,
        member_id=member.id,
        geom=geometry,
        computed_area_sqm=area,
        computed_area_shotangsho=round(geo.to_shotangsho(area), 2),
        status=BoundaryStatus.PENDING_REVIEW.value,
        current_version=1,
        review_note="; ".join(area_warnings(ring, property_row)) or None,
    )
    db.add(boundary)
    await db.flush()
    db.add(
        record_version(boundary, change_type=ChangeType.CREATE, member_id=member.id)
    )
    record_audit(
        db,
        actor_admin_id=None,
        action="boundary.create",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"member_id={member.id} property_id={property_id} area_sqm={area}",
    )
    return boundary


async def update_boundary(
    db: AsyncSession, member: Member, boundary_id: int, geometry: dict
) -> PlotBoundary:
    boundary = await _owned_boundary(db, member, boundary_id)
    ring = validate_polygon(geometry)
    area = round(geo.geodesic_area_sqm(ring), 2)

    property_row = await db.get(Property, boundary.property_id)
    boundary.geom = geometry
    boundary.computed_area_sqm = area
    boundary.computed_area_shotangsho = round(geo.to_shotangsho(area), 2)
    # An edit to a previously approved boundary always goes back to review;
    # the approved version stays in the version history until re-approved.
    boundary.status = BoundaryStatus.PENDING_REVIEW.value
    boundary.review_note = "; ".join(area_warnings(ring, property_row)) or None
    boundary.current_version += 1
    db.add(
        record_version(boundary, change_type=ChangeType.EDIT, member_id=member.id)
    )
    record_audit(
        db,
        actor_admin_id=None,
        action="boundary.edit",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"member_id={member.id} version={boundary.current_version} area_sqm={area}",
    )
    return boundary


async def soft_delete_boundary(db: AsyncSession, member: Member, boundary_id: int) -> None:
    boundary = await _owned_boundary(db, member, boundary_id)
    boundary.is_deleted = True
    boundary.status = BoundaryStatus.PENDING_REVIEW.value  # historical marker; row is kept
    db.add(
        record_version(boundary, change_type=ChangeType.DELETE, member_id=member.id)
    )
    record_audit(
        db,
        actor_admin_id=None,
        action="boundary.delete",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"member_id={member.id}",
    )


async def _owned_boundary(db: AsyncSession, member: Member, boundary_id: int) -> PlotBoundary:
    result = await db.execute(
        select(PlotBoundary).where(
            PlotBoundary.id == boundary_id,
            PlotBoundary.member_id == member.id,
            PlotBoundary.is_deleted.is_(False),
        )
    )
    boundary = result.scalar_one_or_none()
    if boundary is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Boundary not found")
    return boundary


async def detect_overlaps(db: AsyncSession, boundary: PlotBoundary) -> list[tuple[PlotBoundary, float]]:
    """Compare an approved boundary against all other approved, live polygons."""
    result = await db.execute(
        select(PlotBoundary).where(
            PlotBoundary.id != boundary.id,
            PlotBoundary.status == BoundaryStatus.APPROVED.value,
            PlotBoundary.is_deleted.is_(False),
        )
    )
    ring = boundary.geom["coordinates"][0]
    min_overlap = get_settings().boundary_min_overlap_sqm
    overlaps: list[tuple[PlotBoundary, float]] = []
    for other in result.scalars().all():
        other_ring = other.geom["coordinates"][0]
        overlap = geo.intersection_area_sqm(ring, other_ring)
        if overlap >= min_overlap:
            overlaps.append((other, round(overlap, 2)))
    return overlaps


async def open_disputes_for(db: AsyncSession, boundary: PlotBoundary) -> list[BoundaryDispute]:
    """Create dispute rows for overlaps and mark both sides disputed.

    An existing open dispute for the same pair is left alone so repeated
    approvals never duplicate rows."""
    disputes: list[BoundaryDispute] = []
    for other, overlap in await detect_overlaps(db, boundary):
        existing = (
            await db.execute(
                select(BoundaryDispute).where(
                    BoundaryDispute.status == "open",
                    BoundaryDispute.boundary_id == boundary.id,
                    BoundaryDispute.other_boundary_id == other.id,
                )
            )
        ).scalar_one_or_none()
        if existing is not None:
            continue
        dispute = BoundaryDispute(boundary_id=boundary.id, other_boundary_id=other.id, overlap_area_sqm=overlap)
        db.add(dispute)
        disputes.append(dispute)
        boundary.status = BoundaryStatus.DISPUTED.value
        other.status = BoundaryStatus.DISPUTED.value
        record_audit(
            db,
            actor_admin_id=None,
            action="boundary.dispute_opened",
            entity_type="boundary_dispute",
            entity_id=str(boundary.id),
            detail=f"other_boundary={other.id} overlap_sqm={overlap}",
        )
    return disputes


async def build_evidence(db: AsyncSession, boundary_id: int) -> dict:
    """Admin-only GeoJSON evidence bundle: polygon, all versions, review
    decisions and audit entries, with the standing disclaimer."""
    result = await db.execute(select(PlotBoundary).where(PlotBoundary.id == boundary_id))
    boundary = result.scalar_one_or_none()
    if boundary is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Boundary not found")

    property_row = await db.get(Property, boundary.property_id)
    member = await db.get(Member, boundary.member_id)
    versions = (
        (await db.execute(
            select(PlotBoundaryVersion)
            .where(PlotBoundaryVersion.boundary_id == boundary_id)
            .order_by(PlotBoundaryVersion.version)
        ))
        .scalars()
        .all()
    )

    return {
        "type": "FeatureCollection",
        "disclaimer_en": "This is a member-marked approximate boundary; it is not a substitute for an official survey or legal documents.",
        "disclaimer_bn": "এটি সদস্য-চিহ্নিত আনুমানিক সীমানা; সরকারি জরিপ বা দলিলের বিকল্প নয়।",
        "generated_at": _now_iso(),
        "boundary": {
            "id": boundary.id,
            "property_id": boundary.property_id,
            "status": boundary.status,
            "current_version": boundary.current_version,
            "computed_area_sqm": float(boundary.computed_area_sqm or 0),
            "computed_area_shotangsho": float(boundary.computed_area_shotangsho or 0),
            "review_note": boundary.review_note,
            "owner_name": member.full_name if member else None,
            "rs_dag": property_row.dag_no_rs if property_row else None,
            "cs_dag": property_row.dag_no_cs if property_row else None,
            "land_quantity": property_row.land_quantity if property_row else None,
        },
        "features": [
            {
                "type": "Feature",
                "properties": {
                    "version": v.version,
                    "status": v.status,
                    "change_type": v.change_type,
                    "changed_by_member_id": v.changed_by_member_id,
                    "changed_by_admin_id": v.changed_by_admin_id,
                    "note": v.note,
                    "recorded_at": v.created_at.isoformat() if v.created_at else None,
                },
                "geometry": v.geom,
            }
            for v in versions
        ],
    }
