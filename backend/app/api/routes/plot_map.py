"""Member-facing plot map and boundary endpoints.

Privacy rules mirror the neighbour directory: the viewport list carries no
names or phones; owner details are fetched lazily per boundary, rate-limited
and audited to deter scraping. Phone visibility reuses the
`show_in_neighbour_directory` opt-out so one setting governs both features.
"""

import logging
import math

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.permissions import require_member_permission
from app.core.rate_limit import SlidingWindowRateLimiter
from app.db.session import get_db
from app.models.member import Member, MemberStatus
from app.models.plot_boundary import BoundaryDispute, BoundaryStatus, PlotBoundary, PlotBoundaryVersion
from app.models.property import Property
from app.schemas.plot_boundary import version_out as _version_out
from app.schemas.plot_boundary import (
    DISCLAIMER_BN,
    DISCLAIMER_EN,
    BoundaryCreateRequest,
    BoundaryGeometry,
    BoundaryOut,
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


def _in_viewport(boundary: PlotBoundary, bbox: tuple[float, float, float, float]) -> bool:
    min_lng, min_lat, max_lng, max_lat = bbox
    ring = boundary.geom.get("coordinates", [[]])[0]
    if not ring:
        return False
    return any(min_lng <= lng <= max_lng and min_lat <= lat <= max_lat for lng, lat in ring)


@router.get("/plot-map", response_model=PlotMapOut)
async def get_plot_map(
    bbox: str = Query(..., description="minLng,minLat,maxLng,maxLat"),
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> PlotMapOut:
    if member.status != MemberStatus.APPROVED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "APPROVED_MEMBERS_ONLY", "message": "Approved members only."},
        )
    viewport = _parse_bbox(bbox)
    cap = get_settings().boundary_map_result_cap

    result = await db.execute(
        select(PlotBoundary)
        .where(
            PlotBoundary.is_deleted.is_(False),
            PlotBoundary.status.in_(
                [BoundaryStatus.APPROVED.value, BoundaryStatus.DISPUTED.value]
            )
            | (PlotBoundary.member_id == member.id),
        )
        .limit(cap + 1)
    )
    rows = list(result.scalars().all())

    features: list[MapFeatureOut] = []
    for boundary in rows:
        if not (boundary.member_id == member.id or _in_viewport(boundary, viewport)):
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
                status=boundary.status,
                is_mine=boundary.member_id == member.id,
                geometry=boundary.geom,
            )
        )
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

    # Own boundary: full details. Someone else's: only after review/approval.
    is_mine = boundary.member_id == member.id
    if not is_mine and boundary.status not in (
        BoundaryStatus.APPROVED.value,
        BoundaryStatus.DISPUTED.value,
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": "BOUNDARY_NOT_APPROVED",
                "message": "Details are available after the boundary is approved.",
            },
        )

    property_row = await db.get(Property, boundary.property_id)
    owner = await db.get(Member, boundary.member_id)
    contact_hidden = not owner.show_in_neighbour_directory

    record_audit(
        db,
        actor_admin_id=None,
        action="boundary.owner_lookup",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"viewer_member_id={member.id} owner_member_id={boundary.member_id}",
    )
    await db.commit()

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
        status=boundary.status,
    )


def _to_out(boundary: PlotBoundary, property_row: Property | None, warnings: list[str]) -> MyBoundaryOut:
    return MyBoundaryOut(
        id=boundary.id,
        property_id=boundary.property_id,
        status=boundary.status,
        geometry=boundary.geom,
        computed_area_sqm=boundary.computed_area_sqm,
        computed_area_shotangsho=boundary.computed_area_shotangsho,
        current_version=boundary.current_version,
        review_note=boundary.review_note,
        rs_dag=property_row.dag_no_rs if property_row else None,
        cs_dag=property_row.dag_no_cs if property_row else None,
        land_quantity=property_row.land_quantity if property_row else None,
        warnings=warnings,
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
        warnings = (
            [boundary.review_note]
            if boundary.review_note and boundary.review_note.startswith("AREA_MISMATCH")
            else []
        )
        out.append(_to_out(boundary, property_row, warnings))
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
    return _to_out(boundary, property_row, _warnings_of(boundary))


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
    property_row = await db.get(Property, boundary.property_id)
    return _to_out(boundary, property_row, _warnings_of(boundary))


@router.delete("/plot-boundaries/{boundary_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_boundary(
    boundary_id: int,
    member: Member = Depends(require_member_permission(DRAW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> None:
    await boundary_service.soft_delete_boundary(db, member, boundary_id)
    await db.commit()


@router.get("/plot-boundaries/{boundary_id}/versions", response_model=list[BoundaryVersionOut])
async def my_boundary_versions(
    boundary_id: int,
    member: Member = Depends(require_member_permission(DRAW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> list[PlotBoundaryVersion]:
    boundary = await boundary_service._owned_boundary(db, member, boundary_id)
    result = await db.execute(
        select(PlotBoundaryVersion)
        .where(PlotBoundaryVersion.boundary_id == boundary.id)
        .order_by(PlotBoundaryVersion.version)
    )
    return [_version_out(v) for v in result.scalars().all()]


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


def _warnings_of(boundary: PlotBoundary) -> list[str]:
    if boundary.review_note and boundary.review_note.startswith("AREA_MISMATCH"):
        return [boundary.review_note]
    return []


async def _notify_submission(db: AsyncSession, boundary: PlotBoundary) -> None:
    """Email the committee on submission. Delivery errors never block the save."""
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
    "BoundaryOut",
]
