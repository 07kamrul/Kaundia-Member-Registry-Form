"""Member-facing plot map and boundary endpoints.

Privacy rules mirror the neighbour directory: the viewport list carries no
names or phones; owner details are fetched lazily per boundary, rate-limited
and audited to deter scraping. Phone visibility reuses the
`show_in_neighbour_directory` opt-out so one setting governs both features.

Visibility: other members see only the LIVE (approved) version of a boundary;
the owner additionally sees their own pending/rejected version. Anonymous
access is 401 unless BOUNDARY_MAP_PUBLIC_VIEW is on — and even then anonymous
callers only ever get dag numbers plus geometry, never names or mobiles.
"""

import logging
import math

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.deps import get_current_member_optional
from app.core.permissions import require_member_permission
from app.core.rate_limit import SlidingWindowRateLimiter
from app.db.session import get_db
from app.models.member import Member, MemberStatus
from app.models.plot_boundary import (
    BoundaryDispute,
    PlotBoundary,
    PlotBoundaryVersion,
    ReviewStatus,
)
from app.models.property import Property
from app.schemas.plot_boundary import version_out as _version_out
from app.schemas.plot_boundary import (
    DISCLAIMER_BN,
    DISCLAIMER_EN,
    BoundaryCreateRequest,
    BoundaryGeometry,
    BoundaryReportRequest,
    BoundaryUpdateRequest,
    BoundaryVersionOut,
    MapFeatureOut,
    MyBoundaryOut,
    OwnerOut,
    PlotMapOut,
)
from app.services import plot_boundary as boundary_service
from app.services.audit import record_audit
from app.services.email import send_email

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/member", tags=["member"])

VIEW_PERMISSION = "boundary.view"
DRAW_PERMISSION = "boundary.draw_own"

_settings = get_settings()
_owner_limiter = SlidingWindowRateLimiter(
    max_requests=_settings.boundary_owner_lookup_rate_limit,
    window_seconds=_settings.boundary_owner_lookup_rate_window_seconds,
)


def _enforce_owner_rate_limit(member_id: int) -> None:
    retry_after = _owner_limiter.check(member_id)
    if retry_after is None:
        return
    logger.warning("Boundary owner lookup rate limit reached by member_id=%s", member_id)
    raise HTTPException(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        detail={
            "code": "BOUNDARY_OWNER_RATE_LIMITED",
            "message": "Too many owner lookups. Please try again later.",
        },
        headers={"Retry-After": str(max(1, math.ceil(retry_after)))},
    )


def _parse_bbox(raw: str) -> tuple[float, float, float, float]:
    try:
        min_lng, min_lat, max_lng, max_lat = (float(v) for v in raw.split(","))
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "INVALID_BBOX", "message": "bbox must be minLng,minLat,maxLng,maxLat"},
        )
    if not (-180 <= min_lng < max_lng <= 180 and -90 <= min_lat < max_lat <= 90):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "INVALID_BBOX", "message": "bbox is not a valid rectangle"},
        )
    return min_lng, min_lat, max_lng, max_lat


def _in_viewport(geometry: dict, bbox: tuple[float, float, float, float]) -> bool:
    min_lng, min_lat, max_lng, max_lat = bbox
    ring = geometry.get("coordinates", [[]])[0]
    if not ring:
        return False
    return any(min_lng <= lng <= max_lng and min_lat <= lat <= max_lat for lng, lat in ring)


async def _load_version(db: AsyncSession, version_id: int | None) -> PlotBoundaryVersion | None:
    if version_id is None:
        return None
    return await db.get(PlotBoundaryVersion, version_id)


@router.get("/plot-map", response_model=PlotMapOut)
async def get_plot_map(
    bbox: str = Query(..., description="minLng,minLat,maxLng,maxLat"),
    member: Member | None = Depends(get_current_member_optional),
    db: AsyncSession = Depends(get_db),
) -> PlotMapOut:
    if member is None:
        if not get_settings().boundary_map_public_view:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    elif member.status != MemberStatus.APPROVED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "APPROVED_MEMBERS_ONLY", "message": "Approved members only."},
        )

    viewport = _parse_bbox(bbox)
    cap = get_settings().boundary_map_result_cap

    # Live polygons for everyone; the caller's own pending/rejected version on top.
    query = select(PlotBoundary).where(PlotBoundary.is_deleted.is_(False))
    if member is None:
        query = query.where(PlotBoundary.live_version_id.is_not(None))
    else:
        query = query.where(
            or_(
                PlotBoundary.live_version_id.is_not(None),
                PlotBoundary.member_id == member.id,
            )
        )
    result = await db.execute(query.limit(cap + 1))
    rows = list(result.scalars().all())

    features: list[MapFeatureOut] = []
    for boundary in rows:
        is_mine = member is not None and boundary.member_id == member.id
        pending = await _load_version(db, boundary.pending_version_id if is_mine else None)
        if boundary.live_version_id is None:
            # No live shape: only the owner sees their pending/rejected one.
            if not (is_mine and pending is not None
                    and pending.review_status in (ReviewStatus.PENDING.value, ReviewStatus.REJECTED.value)):
                continue
            geometry, review_status = pending.geom, pending.review_status
            live = None
        else:
            live = await _load_version(db, boundary.live_version_id)
            geometry, review_status = live.geom, live.review_status
        if not _in_viewport(geometry, viewport):
            continue
        if len(features) >= cap:
            break
        property_row = await db.get(Property, boundary.property_id)
        features.append(
            MapFeatureOut(
                boundary_id=boundary.id,
                property_id=boundary.property_id,
                rs_dag=property_row.dag_no_rs if property_row else None,
                cs_dag=property_row.dag_no_cs if property_row else None,
                review_status=review_status,
                status=review_status,
                is_mine=is_mine,
                geometry=geometry,
            )
        )
        if is_mine and live is not None and pending is not None and pending.review_status in (
            ReviewStatus.PENDING.value,
            ReviewStatus.REJECTED.value,
        ):
            # The owner also sees their proposed shape as a dashed overlay.
            features.append(
                MapFeatureOut(
                    boundary_id=boundary.id,
                    property_id=boundary.property_id,
                    rs_dag=property_row.dag_no_rs if property_row else None,
                    cs_dag=property_row.dag_no_cs if property_row else None,
                    review_status=pending.review_status,
                    status=pending.review_status,
                    is_mine=True,
                    geometry=pending.geom,
                )
            )

    flagged = await boundary_service.open_disputes(db, [f.boundary_id for f in features])
    for feature in features:
        feature.is_disputed = feature.boundary_id in flagged
    return PlotMapOut(count=len(features), features=features)


@router.get("/plot-map/{boundary_id}/owner", response_model=OwnerOut)
async def get_boundary_owner(
    boundary_id: int,
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> OwnerOut:
    if member.status != MemberStatus.APPROVED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "APPROVED_MEMBERS_ONLY", "message": "Approved members only."},
        )
    _enforce_owner_rate_limit(member.id)

    result = await db.execute(
        select(PlotBoundary).where(
            PlotBoundary.id == boundary_id, PlotBoundary.is_deleted.is_(False)
        )
    )
    boundary = result.scalar_one_or_none()
    if boundary is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Boundary not found")

    # Own boundary: full details. Someone else's: only once a shape is live.
    is_mine = boundary.member_id == member.id
    if not is_mine and boundary.live_version_id is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": "BOUNDARY_NOT_APPROVED",
                "message": "Details are available after the boundary is approved.",
            },
        )

    live = await _load_version(db, boundary.live_version_id)
    property_row = await db.get(Property, boundary.property_id)
    owner = await db.get(Member, boundary.member_id)
    contact_hidden = not owner.show_in_neighbour_directory
    flagged = await boundary_service.open_disputes(db, [boundary.id])

    record_audit(
        db,
        actor_admin_id=None,
        action="boundary.owner_lookup",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"viewer_member_id={member.id} owner_member_id={boundary.member_id}",
    )
    await db.commit()

    review_status = live.review_status if live else ReviewStatus.REJECTED.value
    return OwnerOut(
        boundary_id=boundary.id,
        owner_name=owner.full_name,
        mobile=None if contact_hidden else owner.mobile,
        contact_hidden=contact_hidden,
        rs_dag=property_row.dag_no_rs if property_row else None,
        cs_dag=property_row.dag_no_cs if property_row else None,
        land_quantity=property_row.land_quantity if property_row else None,
        computed_area_sqm=float(boundary.computed_area_sqm or 0) or None,
        computed_area_shotangsho=float(boundary.computed_area_shotangsho or 0) or None,
        review_status=review_status,
        status=review_status,
        is_disputed=boundary.id in flagged,
    )


async def _my_boundary_out(db: AsyncSession, boundary: PlotBoundary, property_row: Property | None) -> MyBoundaryOut:
    versions = await boundary_service.boundary_versions(db, boundary.id)
    by_id = {v.id: v for v in versions}
    live = by_id.get(boundary.live_version_id)
    pending = by_id.get(boundary.pending_version_id)

    # The actionable version: the pending one, else the latest rejected one
    # when it is newer than the live shape (the owner must see the rejection
    # note and be able to resubmit), else the live shape.
    actionable = pending
    if actionable is None and versions:
        last = versions[-1]
        if last.review_status == ReviewStatus.REJECTED.value and (
            live is None or last.version > live.version
        ):
            actionable = last
    if actionable is None:
        actionable = live

    review_note = (pending or (actionable if actionable is not live else None))
    note = review_note.review_note if review_note is not None else None
    warnings = [note] if note and note.startswith("AREA_MISMATCH") else []

    return MyBoundaryOut(
        id=boundary.id,
        property_id=boundary.property_id,
        rs_dag=property_row.dag_no_rs if property_row else None,
        cs_dag=property_row.dag_no_cs if property_row else None,
        land_quantity=property_row.land_quantity if property_row else None,
        has_pending=pending is not None,
        review_status=actionable.review_status if actionable else ReviewStatus.REJECTED.value,
        status=actionable.review_status if actionable else ReviewStatus.REJECTED.value,
        geometry=actionable.geom if actionable else None,
        computed_area_sqm=actionable.computed_area_sqm if actionable else None,
        computed_area_shotangsho=(
            round(float(actionable.computed_area_sqm) / 40.47, 2)
            if actionable and actionable.computed_area_sqm is not None else None
        ),
        current_version=boundary.current_version,
        review_note=note,
        warnings=warnings,
        live_review_status=live.review_status if live else None,
        live_geometry=live.geom if live else None,
    )


@router.get("/plot-boundaries/mine", response_model=list[MyBoundaryOut])
async def list_my_boundaries(
    member: Member = Depends(require_member_permission(DRAW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> list[MyBoundaryOut]:
    result = await db.execute(
        select(PlotBoundary)
        .where(PlotBoundary.member_id == member.id, PlotBoundary.is_deleted.is_(False))
        .order_by(PlotBoundary.id)
    )
    out: list[MyBoundaryOut] = []
    for boundary in result.scalars().all():
        property_row = await db.get(Property, boundary.property_id)
        out.append(await _my_boundary_out(db, boundary, property_row))
    return out


@router.post("/plot-boundaries", response_model=MyBoundaryOut, status_code=status.HTTP_201_CREATED)
async def create_boundary(
    payload: BoundaryCreateRequest,
    member: Member = Depends(require_member_permission(DRAW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> MyBoundaryOut:
    boundary = await boundary_service.create_boundary(db, member, payload.property_id, payload.geometry.model_dump())
    await db.commit()
    await db.refresh(boundary)
    await _notify_submission(db, boundary)
    property_row = await db.get(Property, boundary.property_id)
    return await _my_boundary_out(db, boundary, property_row)


@router.put("/plot-boundaries/{boundary_id}", response_model=MyBoundaryOut)
async def update_boundary(
    boundary_id: int,
    payload: BoundaryUpdateRequest,
    member: Member = Depends(require_member_permission(DRAW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> MyBoundaryOut:
    boundary = await boundary_service.update_boundary(db, member, boundary_id, payload.geometry.model_dump())
    await db.commit()
    await db.refresh(boundary)
    await _notify_submission(db, boundary)
    property_row = await db.get(Property, boundary.property_id)
    return await _my_boundary_out(db, boundary, property_row)


@router.post("/plot-boundaries/{boundary_id}/withdraw", response_model=MyBoundaryOut)
async def withdraw_boundary(
    boundary_id: int,
    member: Member = Depends(require_member_permission(DRAW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> MyBoundaryOut:
    await boundary_service.withdraw_pending(db, member, boundary_id)
    await db.commit()
    await db.refresh(boundary := await db.get(PlotBoundary, boundary_id))
    property_row = await db.get(Property, boundary.property_id)
    return await _my_boundary_out(db, boundary, property_row)


@router.get("/plot-boundaries/{boundary_id}/versions", response_model=list[BoundaryVersionOut])
async def my_boundary_versions(
    boundary_id: int,
    member: Member = Depends(require_member_permission(DRAW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> list[PlotBoundaryVersion]:
    boundary = await boundary_service._owned_boundary(db, member, boundary_id)
    return [_version_out(v) for v in await boundary_service.boundary_versions(db, boundary.id)]


@router.post("/plot-boundaries/{boundary_id}/report", status_code=status.HTTP_202_ACCEPTED)
async def report_boundary(
    boundary_id: int,
    payload: BoundaryReportRequest,
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """"Report a problem" from the popup: opens a note-only dispute for the committee."""
    result = await db.execute(
        select(PlotBoundary).where(PlotBoundary.id == boundary_id, PlotBoundary.is_deleted.is_(False))
    )
    boundary = result.scalar_one_or_none()
    if boundary is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Boundary not found")

    dispute = BoundaryDispute(boundary_id=boundary.id, note=f"[by member {member.id}] {payload.note}")
    db.add(dispute)
    record_audit(
        db,
        actor_admin_id=None,
        action="boundary.reported",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"reporter_member_id={member.id}",
    )
    await db.commit()
    return {"received": True, "dispute_id": dispute.id}


async def _notify_submission(db: AsyncSession, boundary: PlotBoundary) -> None:
    """Email the committee on each new pending submission. Delivery errors
    never block the save."""
    owner = await db.get(Member, boundary.member_id)
    property_row = await db.get(Property, boundary.property_id)
    dags = " / ".join(filter(None, [property_row.dag_no_rs and f"RS {property_row.dag_no_rs}",
                                    property_row.dag_no_cs and f"CS {property_row.dag_no_cs}"]))
    from app.core.config import get_settings as _gs

    settings = _gs()
    try:
        await send_email(
            settings.smtp_sender_email,
            "নতুন জমির সীমানা রিভিউয়ের অপেক্ষায় / New plot boundary to review",
            f"<p>Boundary #{boundary.id} for property #{boundary.property_id} "
            f"({dags}) was submitted by member #{boundary.member_id} ({owner.full_name}).</p>",
        )
    except Exception:  # pragma: no cover - email is best-effort
        logger.exception("boundary submission email failed")


# Re-exported for tests.
__all__ = [
    "router",
    "DISCLAIMER_EN",
    "DISCLAIMER_BN",
    "BoundaryGeometry",
]
