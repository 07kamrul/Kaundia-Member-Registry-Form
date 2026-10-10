"""Admin endpoints for boundary review, disputes, versions and evidence export.

Gated by `boundary.review` (approve/reject) and `boundary.manage` (disputes,
evidence). Every decision writes an audit row plus an immutable version row.
"""

import logging
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import JSONResponse
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.permissions import require_permission
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.member import Member
from app.models.plot_boundary import (
    BoundaryDispute,
    BoundaryStatus,
    ChangeType,
    PlotBoundary,
    PlotBoundaryVersion,
)
from app.models.property import Property
from app.schemas.plot_boundary import version_out as _version_out
from app.schemas.plot_boundary import (
    AdminBoundaryOut,
    BoundaryDisputeOut,
    BoundaryVersionOut,
    DisputeResolveRequest,
    ReviewActionRequest,
)
from app.services import plot_boundary as boundary_service
from app.services.audit import record_audit
from app.services.email import send_email

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/admin", tags=["admin"])

REVIEW_PERMISSION = "boundary.review"
MANAGE_PERMISSION = "boundary.manage"


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


async def _load_boundary(db: AsyncSession, boundary_id: int) -> PlotBoundary:
    result = await db.execute(select(PlotBoundary).where(PlotBoundary.id == boundary_id))
    boundary = result.scalar_one_or_none()
    if boundary is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Boundary not found")
    return boundary


def _to_admin_out(boundary: PlotBoundary, property_row: Property | None, member: Member | None) -> AdminBoundaryOut:
    return AdminBoundaryOut(
        id=boundary.id,
        property_id=boundary.property_id,
        member_id=boundary.member_id,
        member_name=member.full_name if member else "",
        member_mobile=member.mobile if member else None,
        rs_dag=property_row.dag_no_rs if property_row else None,
        cs_dag=property_row.dag_no_cs if property_row else None,
        khatian_no=property_row.khatian_no if property_row else None,
        land_quantity=property_row.land_quantity if property_row else None,
        status=boundary.status,
        geometry=boundary.geom,
        computed_area_sqm=boundary.computed_area_sqm,
        computed_area_shotangsho=boundary.computed_area_shotangsho,
        current_version=boundary.current_version,
        review_note=boundary.review_note,
        is_deleted=boundary.is_deleted,
    )


async def _notify_owner(db: AsyncSession, boundary: PlotBoundary, subject: str, body: str) -> None:
    owner = await db.get(Member, boundary.member_id)
    if owner and owner.email:
        try:
            await send_email(owner.email, subject, body)
        except Exception:  # pragma: no cover - best effort
            logger.exception("boundary notification email failed")


@router.get("/plot-boundaries", response_model=list[AdminBoundaryOut])
async def list_boundaries(
    boundary_status: str | None = Query(default=None, alias="status"),
    search: str | None = Query(default=None, max_length=128),
    include_deleted: bool = False,
    _admin: AdminUser = Depends(require_permission(REVIEW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> list[AdminBoundaryOut]:
    query = select(PlotBoundary).order_by(PlotBoundary.id.desc()).limit(200)
    if not include_deleted:
        query = query.where(PlotBoundary.is_deleted.is_(False))
    if boundary_status:
        query = query.where(PlotBoundary.status == boundary_status)
    if search:
        like = f"%{search.strip()}%"
        query = query.join(Property, PlotBoundary.property_id == Property.id).where(
            or_(
                Property.dag_no_rs.ilike(like),
                Property.dag_no_cs.ilike(like),
                Property.khatian_no.ilike(like),
            )
        )
    rows = (await db.execute(query)).scalars().all()
    out: list[AdminBoundaryOut] = []
    for boundary in rows:
        property_row = await db.get(Property, boundary.property_id)
        member = await db.get(Member, boundary.member_id)
        out.append(_to_admin_out(boundary, property_row, member))
    return out


@router.get("/plot-boundaries/{boundary_id}", response_model=AdminBoundaryOut)
async def get_boundary(
    boundary_id: int,
    _admin: AdminUser = Depends(require_permission(REVIEW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> AdminBoundaryOut:
    boundary = await _load_boundary(db, boundary_id)
    property_row = await db.get(Property, boundary.property_id)
    member = await db.get(Member, boundary.member_id)
    return _to_admin_out(boundary, property_row, member)


@router.post("/plot-boundaries/{boundary_id}/approve", response_model=AdminBoundaryOut)
async def approve_boundary(
    boundary_id: int,
    payload: ReviewActionRequest,
    admin: AdminUser = Depends(require_permission(REVIEW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> AdminBoundaryOut:
    boundary = await _load_boundary(db, boundary_id)
    if boundary.status not in (
        BoundaryStatus.PENDING_REVIEW.value,
        BoundaryStatus.REJECTED.value,
        BoundaryStatus.DISPUTED.value,
    ):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "NOT_PENDING", "message": "Only a boundary awaiting review can be approved."},
        )

    boundary.status = BoundaryStatus.APPROVED.value
    boundary.reviewed_by = admin.id
    boundary.reviewed_at = _now_iso()
    boundary.current_version += 1
    db.add(
        boundary_service.record_version(
            boundary, change_type=ChangeType.APPROVE, admin_id=admin.id, note=payload.note
        )
    )
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="boundary.approve",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"note={payload.note or ''}",
    )

    # Overlap detection runs after approval; overlaps become disputes, not blocks.
    await boundary_service.open_disputes_for(db, boundary)
    await db.commit()
    await db.refresh(boundary)

    disputed = boundary.status == BoundaryStatus.DISPUTED.value
    await _notify_owner(
        db,
        boundary,
        "জমির সীমানা অনুমোদিত / Plot boundary approved",
        f"<p>Boundary #{boundary.id} was approved."
        + (" Overlaps with other boundaries were flagged for committee review.</p>" if disputed else "</p>"),
    )

    property_row = await db.get(Property, boundary.property_id)
    member = await db.get(Member, boundary.member_id)
    return _to_admin_out(boundary, property_row, member)


@router.post("/plot-boundaries/{boundary_id}/reject", response_model=AdminBoundaryOut)
async def reject_boundary(
    boundary_id: int,
    payload: ReviewActionRequest,
    admin: AdminUser = Depends(require_permission(REVIEW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> AdminBoundaryOut:
    boundary = await _load_boundary(db, boundary_id)
    if boundary.status == BoundaryStatus.APPROVED.value:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "ALREADY_APPROVED", "message": "An approved boundary cannot be rejected; edit it instead."},
        )
    if not payload.note:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "NOTE_REQUIRED", "message": "A rejection note is required."},
        )

    boundary.status = BoundaryStatus.REJECTED.value
    boundary.reviewed_by = admin.id
    boundary.reviewed_at = _now_iso()
    boundary.review_note = payload.note
    boundary.current_version += 1
    db.add(
        boundary_service.record_version(
            boundary, change_type=ChangeType.REJECT, admin_id=admin.id, note=payload.note
        )
    )
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="boundary.reject",
        entity_type="plot_boundary",
        entity_id=str(boundary.id),
        detail=f"note={payload.note}",
    )
    await db.commit()
    await db.refresh(boundary)

    await _notify_owner(
        db,
        boundary,
        "জমির সীমানা বাতিল / Plot boundary rejected",
        f"<p>Boundary #{boundary.id} was rejected. Reason: {payload.note}</p>",
    )
    property_row = await db.get(Property, boundary.property_id)
    member = await db.get(Member, boundary.member_id)
    return _to_admin_out(boundary, property_row, member)


@router.get("/plot-boundaries/{boundary_id}/versions", response_model=list[BoundaryVersionOut])
async def list_versions(
    boundary_id: int,
    _admin: AdminUser = Depends(require_permission(REVIEW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> list[PlotBoundaryVersion]:
    await _load_boundary(db, boundary_id)
    result = await db.execute(
        select(PlotBoundaryVersion)
        .where(PlotBoundaryVersion.boundary_id == boundary_id)
        .order_by(PlotBoundaryVersion.version)
    )
    return [_version_out(v) for v in result.scalars().all()]


@router.get("/plot-boundaries/{boundary_id}/evidence")
async def evidence_export(
    boundary_id: int,
    _admin: AdminUser = Depends(require_permission(MANAGE_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> JSONResponse:
    bundle = await boundary_service.build_evidence(db, boundary_id)
    record_audit(
        db,
        actor_admin_id=_admin.id,
        action="boundary.evidence_export",
        entity_type="plot_boundary",
        entity_id=str(boundary_id),
    )
    await db.commit()
    return JSONResponse(content=bundle, headers={"Content-Disposition": f"attachment; filename=boundary-{boundary_id}-evidence.geojson"})


@router.get("/boundary-disputes", response_model=list[BoundaryDisputeOut])
async def list_disputes(
    dispute_status: str | None = Query(default="open", alias="status"),
    _admin: AdminUser = Depends(require_permission(MANAGE_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> list[BoundaryDisputeOut]:
    query = select(BoundaryDispute).order_by(BoundaryDispute.id.desc()).limit(200)
    if dispute_status:
        query = query.where(BoundaryDispute.status == dispute_status)
    return list((await db.execute(query)).scalars().all())


@router.post("/boundary-disputes/{dispute_id}/resolve", response_model=BoundaryDisputeOut)
async def resolve_dispute(
    dispute_id: int,
    payload: DisputeResolveRequest,
    admin: AdminUser = Depends(require_permission(MANAGE_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> BoundaryDispute:
    result = await db.execute(select(BoundaryDispute).where(BoundaryDispute.id == dispute_id))
    dispute = result.scalar_one_or_none()
    if dispute is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Dispute not found")
    if dispute.status != "open":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "ALREADY_RESOLVED", "message": "This dispute is already closed."},
        )

    dispute.status = "dismissed" if payload.dismiss else "resolved"
    dispute.resolved_by = admin.id
    dispute.resolved_at = _now_iso()
    dispute.resolution_note = payload.resolution_note

    # If both sides of the dispute are otherwise fine, restore approved status.
    if dispute.status == "resolved" or dispute.status == "dismissed":
        open_left = (
            await db.execute(
                select(func.count())
                .select_from(BoundaryDispute)
                .where(BoundaryDispute.status == "open", BoundaryDispute.boundary_id == dispute.boundary_id)
            )
        ).scalar_one()
        if open_left == 0:
            boundary = await db.get(PlotBoundary, dispute.boundary_id)
            if boundary and boundary.status == BoundaryStatus.DISPUTED.value:
                boundary.status = BoundaryStatus.APPROVED.value
        if dispute.other_boundary_id:
            open_other = (
                await db.execute(
                    select(func.count())
                    .select_from(BoundaryDispute)
                    .where(
                        BoundaryDispute.status == "open",
                        or_(
                            BoundaryDispute.boundary_id == dispute.other_boundary_id,
                            BoundaryDispute.other_boundary_id == dispute.other_boundary_id,
                        ),
                    )
                )
            ).scalar_one()
            if open_other == 0:
                other = await db.get(PlotBoundary, dispute.other_boundary_id)
                if other and other.status == BoundaryStatus.DISPUTED.value:
                    other.status = BoundaryStatus.APPROVED.value

    record_audit(
        db,
        actor_admin_id=admin.id,
        action="boundary.dispute_resolved",
        entity_type="boundary_dispute",
        entity_id=str(dispute.id),
        detail=f"status={dispute.status} note={payload.resolution_note}",
    )
    await db.commit()
    await db.refresh(dispute)
    return dispute
