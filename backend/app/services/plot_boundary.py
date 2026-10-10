"""Business rules for member-drawn plot boundaries.

Validation is authoritative here; clients mirror it for UX only. Area,
overlap and containment math comes from `app.services.geo`. Owner-facing
values (name, dag, quantity) are never stored on the boundary — popups join
to `properties`/`members` live.

Review state is version-level: a member submission creates a `pending`
version and the boundary keeps its previous `live` version until an admin
approves. Admin create/edit goes live immediately (the admin is the
verifier). Version rows are immutable except the review fields set once at
decision time; they are never hard-deleted.
"""

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.models.member import Member, MemberStatus
from app.models.plot_boundary import (
    BoundaryDispute,
    ChangeType,
    PlotBoundary,
    PlotBoundaryVersion,
    ReviewStatus,
    SubmittedByRole,
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


def _mirror_status(boundary: PlotBoundary) -> str:
    """Effective review status for the boundary-level mirror column."""
    if boundary.pending_version_id is not None:
        return ReviewStatus.PENDING.value
    if boundary.live_version_id is not None:
        return ReviewStatus.APPROVED.value
    return ReviewStatus.REJECTED.value


def _new_version(
    boundary: PlotBoundary,
    *,
    ring_area: float,
    review_status: ReviewStatus,
    change_type: ChangeType,
    member_id: int | None = None,
    admin_id: int | None = None,
    submitted_by_role: SubmittedByRole = SubmittedByRole.MEMBER,
    review_note: str | None = None,
    note: str | None = None,
    reviewed_by_admin_id: int | None = None,
    reviewed_at: str | None = None,
) -> PlotBoundaryVersion:
    return PlotBoundaryVersion(
        boundary_id=boundary.id,
        version=boundary.current_version,
        geom=boundary.geom,
        computed_area_sqm=boundary.computed_area_sqm,
        review_status=review_status.value,
        status=review_status.value,  # legacy mirror column
        change_type=change_type.value,
        changed_by_member_id=member_id,
        changed_by_admin_id=admin_id,
        submitted_by_role=submitted_by_role.value,
        review_note=review_note,
        note=note,
        reviewed_by_admin_id=reviewed_by_admin_id,
        reviewed_at=reviewed_at,
    )


def record_version(
    boundary: PlotBoundary,
    *,
    change_type: ChangeType,
    member_id: int | None = None,
    admin_id: int | None = None,
    note: str | None = None,
) -> PlotBoundaryVersion:
    """Legacy shim kept for callers/tests; records a pending member version."""
    return _new_version(
        boundary,
        ring_area=0,
        review_status=ReviewStatus.PENDING,
        change_type=change_type,
        member_id=member_id,
        admin_id=admin_id,
        submitted_by_role=SubmittedByRole.ADMIN if admin_id and not member_id else SubmittedByRole.MEMBER,
        note=note,
    )


async def _supersede_pending(db: AsyncSession, boundary: PlotBoundary) -> None:
    """A boundary has at most one pending submission; a new submission replaces
    it (the old pending row is marked `superseded`, never deleted)."""
    if boundary.pending_version_id is None:
        return
    pending = await db.get(PlotBoundaryVersion, boundary.pending_version_id)
    if pending is not None and pending.review_status == ReviewStatus.PENDING.value:
        pending.review_status = ReviewStatus.SUPERSEDED.value
        pending.status = ReviewStatus.SUPERSEDED.value
    boundary.pending_version_id = None


async def _validate_and_stage(
    db: AsyncSession, boundary: PlotBoundary, geometry: dict, property_row: Property | None
) -> float:
    ring = validate_polygon(geometry)
    area = round(geo.geodesic_area_sqm(ring), 2)
    boundary.geom = geometry
    boundary.computed_area_sqm = area
    boundary.computed_area_shotangsho = round(geo.to_shotangsho(area), 2)
    boundary.review_note = "; ".join(area_warnings(ring, property_row)) or None
    boundary.current_version += 1
    return area


def _actionable_version(boundary: PlotBoundary, versions: list[PlotBoundaryVersion]) -> PlotBoundaryVersion | None:
    """The version the owner acts on: the pending one, else the last
    rejected/submitted one when there is no live shape, else the live one."""
    if boundary.pending_version_id is not None:
        return next((v for v in versions if v.id == boundary.pending_version_id), None)
    if boundary.live_version_id is None:
        return versions[-1] if versions else None
    return next((v for v in versions if v.id == boundary.live_version_id), None)


async def create_boundary(db: AsyncSession, member: Member, property_id: int, geometry: dict) -> PlotBoundary:
    """Member draw → a *pending* version. Nobody but the owner sees the
    boundary until an admin approves (then it becomes the live version)."""
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
        status=ReviewStatus.PENDING.value,
        review_note="; ".join(area_warnings(ring, property_row)) or None,
        current_version=1,
    )
    db.add(boundary)
    await db.flush()
    version = _new_version(
        boundary,
        ring_area=area,
        review_status=ReviewStatus.PENDING,
        change_type=ChangeType.CREATE,
        member_id=member.id,
        review_note=boundary.review_note,
    )
    db.add(version)
    await db.flush()
    boundary.pending_version_id = version.id
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
    """Member edit → a new pending version replacing any existing pending one.
    The previously approved shape stays live for everyone until approval."""
    boundary = await _owned_boundary(db, member, boundary_id)
    property_row = await db.get(Property, boundary.property_id)
    await _supersede_pending(db, boundary)
    area = await _validate_and_stage(db, boundary, geometry, property_row)

    version = _new_version(
        boundary,
        ring_area=area,
        review_status=ReviewStatus.PENDING,
        change_type=ChangeType.EDIT,
        member_id=member.id,
        review_note=boundary.review_note,
    )
    db.add(version)
    await db.flush()
    boundary.pending_version_id = version.id
    boundary.status = ReviewStatus.PENDING.value
    record_audit(
        db,
        actor_admin_id=None,
        action="boundary.edit",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"member_id={member.id} version={boundary.current_version} area_sqm={area}",
    )
    return boundary


async def withdraw_pending(db: AsyncSession, member: Member, boundary_id: int) -> None:
    """Member withdraws their own pending submission; the live shape is
    untouched and the pending row is kept (marked `withdrawn`)."""
    boundary = await _owned_boundary(db, member, boundary_id)
    if boundary.pending_version_id is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "NOT_PENDING", "message": "There is no pending submission to withdraw."},
        )
    pending = await db.get(PlotBoundaryVersion, boundary.pending_version_id)
    pending.review_status = ReviewStatus.WITHDRAWN.value
    pending.status = ReviewStatus.WITHDRAWN.value
    pending.reviewed_at = _now_iso()
    boundary.pending_version_id = None
    boundary.status = _mirror_status(boundary)
    record_audit(
        db,
        actor_admin_id=None,
        action="boundary.withdraw",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"member_id={member.id} version={pending.version}",
    )


async def admin_create_boundary(
    db: AsyncSession,
    admin_id: int,
    member_id: int,
    property_id: int,
    geometry: dict,
    *,
    confirm_overlap: bool = False,
) -> tuple[PlotBoundary, list[BoundaryDispute]]:
    """Admin adds a polygon on behalf of a member — the admin is the verifier,
    so it goes live immediately (versioned, audited; overlap requires confirm)."""
    member = await db.get(Member, member_id)
    if member is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Member not found")
    result = await db.execute(
        select(Property).where(Property.id == property_id, Property.member_id == member_id)
    )
    property_row = result.scalar_one_or_none()
    if property_row is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "PROPERTY_NOT_OWNED", "message": "That property does not belong to the member."},
        )
    await _ensure_no_active_boundary(db, property_id)

    ring = validate_polygon(geometry)
    area = round(geo.geodesic_area_sqm(ring), 2)

    boundary = PlotBoundary(
        property_id=property_id,
        member_id=member_id,
        geom=geometry,
        computed_area_sqm=area,
        computed_area_shotangsho=round(geo.to_shotangsho(area), 2),
        status=ReviewStatus.APPROVED.value,
        review_note="; ".join(area_warnings(ring, property_row)) or None,
        current_version=1,
    )
    db.add(boundary)
    await db.flush()
    version = _new_version(
        boundary,
        ring_area=area,
        review_status=ReviewStatus.APPROVED,
        change_type=ChangeType.ADMIN_CREATE,
        admin_id=admin_id,
        submitted_by_role=SubmittedByRole.ADMIN,
        review_note=boundary.review_note,
        reviewed_by_admin_id=admin_id,
        reviewed_at=_now_iso(),
    )
    db.add(version)
    await db.flush()
    boundary.live_version_id = version.id

    if confirm_overlap:
        disputes = await open_disputes_for(db, boundary, ring)
    else:
        overlaps = await detect_overlaps(db, boundary.id, ring)
        if overlaps:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "code": "OVERLAP_CONFIRMATION_REQUIRED",
                    "message": "The polygon overlaps approved boundaries; confirm to save and open disputes.",
                    "overlaps": [
                        {"boundary_id": other_id, "overlap_area_sqm": overlap}
                        for other_id, overlap in overlaps
                    ],
                },
            )
        disputes = []

    record_audit(
        db,
        actor_admin_id=admin_id,
        action="boundary.admin_create",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"member_id={member_id} property_id={property_id} area_sqm={area} disputes={len(disputes)}",
    )
    return boundary, disputes


async def admin_edit_boundary(
    db: AsyncSession,
    admin_id: int,
    boundary_id: int,
    geometry: dict,
    *,
    confirm_overlap: bool = False,
) -> tuple[PlotBoundary, list[BoundaryDispute]]:
    """Admin edit of any member's polygon — goes live immediately, superseding
    any pending member submission."""
    boundary = await _load_boundary(db, boundary_id)
    if boundary.is_deleted:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "BOUNDARY_DELETED", "message": "A deleted boundary cannot be edited."},
        )
    property_row = await db.get(Property, boundary.property_id)
    await _supersede_pending(db, boundary)
    area = await _validate_and_stage(db, boundary, geometry, property_row)

    version = _new_version(
        boundary,
        ring_area=area,
        review_status=ReviewStatus.APPROVED,
        change_type=ChangeType.ADMIN_EDIT,
        admin_id=admin_id,
        submitted_by_role=SubmittedByRole.ADMIN,
        review_note=boundary.review_note,
        reviewed_by_admin_id=admin_id,
        reviewed_at=_now_iso(),
    )
    db.add(version)
    await db.flush()
    previous_live_id = boundary.live_version_id
    boundary.live_version_id = version.id
    boundary.pending_version_id = None
    boundary.status = ReviewStatus.APPROVED.value
    if previous_live_id is not None:
        previous = await db.get(PlotBoundaryVersion, previous_live_id)
        if previous is not None:
            previous.review_status = ReviewStatus.SUPERSEDED.value
            previous.status = ReviewStatus.SUPERSEDED.value

    if confirm_overlap:
        disputes = await open_disputes_for(db, boundary, boundary.geom["coordinates"][0])
    else:
        overlaps = await detect_overlaps(db, boundary.id, boundary.geom["coordinates"][0])
        if overlaps:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "code": "OVERLAP_CONFIRMATION_REQUIRED",
                    "message": "The polygon overlaps approved boundaries; confirm to save and open disputes.",
                    "overlaps": [
                        {"boundary_id": other_id, "overlap_area_sqm": overlap}
                        for other_id, overlap in overlaps
                    ],
                },
            )
        disputes = []

    record_audit(
        db,
        actor_admin_id=admin_id,
        action="boundary.admin_edit",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"member_id={boundary.member_id} version={boundary.current_version} area_sqm={area} disputes={len(disputes)}",
    )
    return boundary, disputes


async def admin_delete_boundary(
    db: AsyncSession, admin_id: int, boundary_id: int, reason: str
) -> PlotBoundary:
    """Admin-only soft delete; members can never delete (evidence trail)."""
    boundary = await _load_boundary(db, boundary_id)
    if boundary.is_deleted:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "ALREADY_DELETED", "message": "This boundary is already deleted."},
        )
    boundary.is_deleted = True
    boundary.deleted_by_admin_id = admin_id
    boundary.deleted_reason = reason
    boundary.deleted_at = _now_iso()
    boundary.pending_version_id = None
    boundary.status = ReviewStatus.REJECTED.value  # historical marker; row is kept
    db.add(
        _new_version(
            boundary,
            ring_area=0,
            review_status=ReviewStatus.SUPERSEDED,
            change_type=ChangeType.DELETE,
            admin_id=admin_id,
            submitted_by_role=SubmittedByRole.ADMIN,
            note=reason,
        )
    )
    record_audit(
        db,
        actor_admin_id=admin_id,
        action="boundary.delete",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"member_id={boundary.member_id} reason={reason}",
    )
    return boundary


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


async def _load_boundary(db: AsyncSession, boundary_id: int) -> PlotBoundary:
    boundary = await db.get(PlotBoundary, boundary_id)
    if boundary is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Boundary not found")
    return boundary


async def boundary_versions(db: AsyncSession, boundary_id: int) -> list[PlotBoundaryVersion]:
    result = await db.execute(
        select(PlotBoundaryVersion)
        .where(PlotBoundaryVersion.boundary_id == boundary_id)
        .order_by(PlotBoundaryVersion.version)
    )
    return list(result.scalars().all())


async def approve_version(
    db: AsyncSession, admin_id: int, version_id: int, note: str | None
) -> tuple[PlotBoundary, PlotBoundaryVersion, list[BoundaryDispute]]:
    """Approve a pending version: it becomes the live shape everyone sees, the
    previous live version is superseded, and overlaps open dispute records."""
    version = await db.get(PlotBoundaryVersion, version_id)
    if version is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Version not found")
    boundary = await _load_boundary(db, version.boundary_id)
    if version.review_status != ReviewStatus.PENDING.value:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "NOT_PENDING", "message": "Only a version awaiting review can be approved."},
        )
    if boundary.is_deleted:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "BOUNDARY_DELETED", "message": "A deleted boundary cannot be approved."},
        )

    version.review_status = ReviewStatus.APPROVED.value
    version.status = ReviewStatus.APPROVED.value
    version.reviewed_by_admin_id = admin_id
    version.reviewed_at = _now_iso()
    version.review_note = note

    previous_live_id = boundary.live_version_id
    boundary.live_version_id = version.id
    boundary.pending_version_id = None
    boundary.status = ReviewStatus.APPROVED.value
    boundary.reviewed_at = version.reviewed_at
    if previous_live_id is not None and previous_live_id != version.id:
        previous = await db.get(PlotBoundaryVersion, previous_live_id)
        if previous is not None and previous.review_status == ReviewStatus.APPROVED.value:
            previous.review_status = ReviewStatus.SUPERSEDED.value
            previous.status = ReviewStatus.SUPERSEDED.value

    # Overlap detection runs after approval; overlaps become disputes, not blocks.
    disputes = await open_disputes_for(db, boundary, version.geom["coordinates"][0])
    record_audit(
        db,
        actor_admin_id=admin_id,
        action="boundary.approve",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"version={version.version} note={note or ''} disputes={len(disputes)}",
    )
    return boundary, version, disputes


async def reject_version(
    db: AsyncSession, admin_id: int, version_id: int, note: str
) -> tuple[PlotBoundary, PlotBoundaryVersion]:
    """Reject a pending version. A rejected *new* polygon never goes live; a
    rejected *edit* leaves the previously approved live shape untouched."""
    version = await db.get(PlotBoundaryVersion, version_id)
    if version is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Version not found")
    boundary = await _load_boundary(db, version.boundary_id)
    if version.review_status != ReviewStatus.PENDING.value:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "NOT_PENDING", "message": "Only a version awaiting review can be rejected."},
        )

    version.review_status = ReviewStatus.REJECTED.value
    version.status = ReviewStatus.REJECTED.value
    version.reviewed_by_admin_id = admin_id
    version.reviewed_at = _now_iso()
    version.review_note = note

    boundary.pending_version_id = None
    boundary.review_note = note
    boundary.reviewed_at = version.reviewed_at
    boundary.status = _mirror_status(boundary)
    record_audit(
        db,
        actor_admin_id=admin_id,
        action="boundary.reject",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"version={version.version} note={note}",
    )
    return boundary, version


async def detect_overlaps(
    db: AsyncSession, exclude_boundary_id: int, ring: list[list[float]]
) -> list[tuple[int, float]]:
    """Compare a ring against every other *live* polygon (approved versions of
    non-deleted boundaries)."""
    result = await db.execute(
        select(PlotBoundaryVersion)
        .join(PlotBoundary, PlotBoundaryVersion.boundary_id == PlotBoundary.id)
        .where(
            PlotBoundary.id != exclude_boundary_id,
            PlotBoundary.live_version_id == PlotBoundaryVersion.id,
            PlotBoundary.is_deleted.is_(False),
        )
    )
    min_overlap = get_settings().boundary_min_overlap_sqm
    overlaps: list[tuple[int, float]] = []
    for other_version in result.scalars().all():
        other_ring = other_version.geom["coordinates"][0]
        overlap = geo.intersection_area_sqm(ring, other_ring)
        if overlap >= min_overlap:
            overlaps.append((other_version.boundary_id, round(overlap, 2)))
    return overlaps


async def open_disputes_for(
    db: AsyncSession, boundary: PlotBoundary, ring: list[list[float]]
) -> list[BoundaryDispute]:
    """Create dispute rows for overlaps with live polygons. Edge-touching (an
    overlap below `boundary_min_overlap_sqm`) never opens a dispute. An
    existing open dispute for the same pair is left alone so repeated
    approvals never duplicate rows."""
    disputes: list[BoundaryDispute] = []
    for other_id, overlap in await detect_overlaps(db, boundary.id, ring):
        existing = (
            await db.execute(
                select(BoundaryDispute).where(
                    BoundaryDispute.status == "open",
                    BoundaryDispute.boundary_id == boundary.id,
                    BoundaryDispute.other_boundary_id == other_id,
                )
            )
        ).scalar_one_or_none()
        if existing is not None:
            continue
        dispute = BoundaryDispute(boundary_id=boundary.id, other_boundary_id=other_id, overlap_area_sqm=overlap)
        db.add(dispute)
        disputes.append(dispute)
        record_audit(
            db,
            actor_admin_id=None,
            action="boundary.dispute_opened",
            entity_type="boundary_dispute",
            entity_id=str(boundary.id),
            detail=f"other_boundary={other_id} overlap_sqm={overlap}",
        )
    return disputes


async def open_disputes(db: AsyncSession, boundary_ids: list[int]) -> set[int]:
    """Boundary ids among `boundary_ids` that have an open dispute — the
    derived "disputed" flag, never a stored review status."""
    if not boundary_ids:
        return set()
    result = await db.execute(
        select(BoundaryDispute.boundary_id, BoundaryDispute.other_boundary_id).where(
            BoundaryDispute.status == "open"
        )
    )
    wanted = set(boundary_ids)
    flagged: set[int] = set()
    for boundary_id, other_id in result.all():
        if boundary_id in wanted:
            flagged.add(boundary_id)
        if other_id in wanted:
            flagged.add(other_id)
    return flagged


async def build_evidence(db: AsyncSession, boundary_id: int) -> dict:
    """Admin-only GeoJSON evidence bundle: polygon, all versions, review
    decisions and audit entries, with the standing disclaimer."""
    boundary = await _load_boundary(db, boundary_id)

    property_row = await db.get(Property, boundary.property_id)
    member = await db.get(Member, boundary.member_id)
    versions = await boundary_versions(db, boundary_id)

    return {
        "type": "FeatureCollection",
        "disclaimer_en": "This is a member-marked approximate boundary; it is not a substitute for an official survey or legal documents.",
        "disclaimer_bn": "এটি সদস্য-চিহ্নিত আনুমানিক সীমানা; সরকারি জরিপ বা দলিলের বিকল্প নয়।",
        "generated_at": _now_iso(),
        "boundary": {
            "id": boundary.id,
            "property_id": boundary.property_id,
            "status": boundary.status,
            "live_version_id": boundary.live_version_id,
            "pending_version_id": boundary.pending_version_id,
            "is_deleted": boundary.is_deleted,
            "deleted_reason": boundary.deleted_reason,
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
                    "review_status": v.review_status,
                    "status": v.review_status,
                    "change_type": v.change_type,
                    "submitted_by_role": v.submitted_by_role,
                    "changed_by_member_id": v.changed_by_member_id,
                    "changed_by_admin_id": v.changed_by_admin_id,
                    "reviewed_by_admin_id": v.reviewed_by_admin_id,
                    "reviewed_at": v.reviewed_at,
                    "note": v.review_note or v.note,
                    "recorded_at": v.created_at.isoformat() if v.created_at else None,
                },
                "geometry": v.geom,
            }
            for v in versions
        ],
    }
