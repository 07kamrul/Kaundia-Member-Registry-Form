"""Admin endpoints for boundary review, disputes, versions and evidence export.

Gated by `boundary.review` (approve/reject, add/edit on behalf) and
`boundary.manage` (disputes, evidence, delete). Every decision writes an audit
row plus an immutable version row. Admin add/edit goes live immediately — the
admin is the verifier; member submissions wait in the pending queue.
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
    PlotBoundary,
    PlotBoundaryVersion,
    ReviewStatus,
)
from app.models.property import Property
from app.schemas.plot_boundary import version_out as _version_out
from app.schemas.plot_boundary import (
    AdminBoundaryOut,
    AdminBoundaryUpsertRequest,
    AdminDeleteRequest,
    BoundaryDisputeOut,
    BoundaryVersionOut,
    DisputeResolveRequest,
    PendingCountOut,
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


async def _load_version(db: AsyncSession, version_id: int | None) -> PlotBoundaryVersion | None:
    if version_id is None:
        return None
    return await db.get(PlotBoundaryVersion, version_id)


def _effective_status(boundary: PlotBoundary) -> str:
    if boundary.is_deleted:
        return "deleted"
    if boundary.pending_version_id is not None:
        return ReviewStatus.PENDING.value
    if boundary.live_version_id is not None:
        return ReviewStatus.APPROVED.value
    return ReviewStatus.REJECTED.value


async def _to_admin_out(boundary: PlotBoundary, property_row: Property | None, member: Member | None, db: AsyncSession) -> AdminBoundaryOut:
    live = await _load_version(db, boundary.live_version_id)
    pending = await _load_version(db, boundary.pending_version_id)
    actionable = pending or live
    flagged = await boundary_service.open_disputes(db, [boundary.id])
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
        status=_effective_status(boundary),
        live_version_id=boundary.live_version_id,
        pending_version_id=boundary.pending_version_id,
        live_review_status=live.review_status if live else None,
        pending_review_status=pending.review_status if pending else None,
        is_disputed=boundary.id in flagged,
        current_version=boundary.current_version,
        geometry=actionable.geom if actionable else None,
        computed_area_sqm=actionable.computed_area_sqm if actionable else None,
        computed_area_shotangsho=boundary.computed_area_shotangsho,
        review_note=(pending.review_note if pending else boundary.review_note),
        is_deleted=boundary.is_deleted,
        deleted_reason=boundary.deleted_reason,
        deleted_at=boundary.deleted_at,
    )


async def _notify_owner(db: AsyncSession, boundary: PlotBoundary, subject: str, body: str) -> None:
    owner = await db.get(Member, boundary.member_id)
    if owner and owner.email:
        try:
            await send_email(owner.email, subject, body)
        except Exception:  # pragma: no cover - best effort
            logger.exception("boundary notification email failed")


async def _boundary_out_or_404(db: AsyncSession, boundary_id: int) -> AdminBoundaryOut:
    boundary = await _load_boundary(db, boundary_id)
    property_row = await db.get(Property, boundary.property_id)
    member = await db.get(Member, boundary.member_id)
    return await _to_admin_out(boundary, property_row, member, db)


@router.get("/plot-boundaries/pending/count", response_model=PendingCountOut)
async def pending_count(
    _admin: AdminUser = Depends(require_permission(REVIEW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> PendingCountOut:
    """Dashboard/nav badge: how many member submissions await review."""
    total = (
        await db.execute(
            select(func.count())
            .select_from(PlotBoundary)
            .where(
                PlotBoundary.is_deleted.is_(False),
                PlotBoundary.pending_version_id.is_not(None),
            )
        )
    ).scalar_one()
    return PendingCountOut(count=total)


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
    rows = (await db.execute(query)).scalars().all()

    out: list[AdminBoundaryOut] = []
    for boundary in rows:
        effective = _effective_status(boundary)
        if boundary_status and effective != boundary_status:
            continue
        property_row = await db.get(Property, boundary.property_id)
        member = await db.get(Member, boundary.member_id)
        out.append(await _to_admin_out(boundary, property_row, member, db))
    return out


@router.get("/plot-boundaries/{boundary_id}", response_model=AdminBoundaryOut)
async def get_boundary(
    boundary_id: int,
    _admin: AdminUser = Depends(require_permission(REVIEW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> AdminBoundaryOut:
    return await _boundary_out_or_404(db, boundary_id)


@router.post("/plot-boundaries", response_model=AdminBoundaryOut, status_code=status.HTTP_201_CREATED)
async def admin_create_boundary(
    payload: AdminBoundaryUpsertRequest,
    admin: AdminUser = Depends(require_permission(MANAGE_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> AdminBoundaryOut:
    """Add a polygon on behalf of any member — goes live immediately."""
    boundary, disputes = await boundary_service.admin_create_boundary(
        db, admin.id, payload.member_id, payload.property_id, payload.geometry.model_dump(),
        confirm_overlap=payload.confirm_overlap,
    )
    await db.commit()
    await db.refresh(boundary)
    await _notify_owner(
        db, boundary,
        "জমির সীমানা কমিটি কর্তৃক যুক্ত / Plot boundary added by the committee",
        f"<p>A boundary #{boundary.id} was added for your property #{boundary.property_id} "
        f"by the committee and is now visible on the map.</p>",
    )
    return await _boundary_out_or_404(db, boundary.id)


@router.put("/plot-boundaries/{boundary_id}", response_model=AdminBoundaryOut)
async def admin_edit_boundary(
    boundary_id: int,
    payload: AdminBoundaryUpsertRequest,
    admin: AdminUser = Depends(require_permission(MANAGE_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> AdminBoundaryOut:
    """Edit any member's polygon — goes live immediately, member is notified."""
    boundary, disputes = await boundary_service.admin_edit_boundary(
        db, admin.id, boundary_id, payload.geometry.model_dump(),
        confirm_overlap=payload.confirm_overlap,
    )
    await db.commit()
    await db.refresh(boundary)
    await _notify_owner(
        db, boundary,
        "জমির সীমানা কমিটি কর্তৃক সম্পাদিত / Plot boundary edited by the committee",
        f"<p>Your boundary #{boundary.id} was corrected by the committee.</p>",
    )
    return await _boundary_out_or_404(db, boundary_id)


@router.delete("/plot-boundaries/{boundary_id}", response_model=AdminBoundaryOut)
async def admin_delete_boundary(
    boundary_id: int,
    payload: AdminDeleteRequest,
    admin: AdminUser = Depends(require_permission(MANAGE_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> AdminBoundaryOut:
    """Soft delete with a mandatory reason; the version history is kept."""
    boundary = await boundary_service.admin_delete_boundary(db, admin.id, boundary_id, payload.reason.strip())
    await db.commit()
    await db.refresh(boundary)
    await _notify_owner(
        db, boundary,
        "জমির সীমানা মুছে ফেলা হয়েছে / Plot boundary removed",
        f"<p>Your boundary #{boundary.id} was removed by the committee. Reason: {payload.reason}</p>",
    )
    return await _boundary_out_or_404(db, boundary_id)


@router.post("/plot-boundary-versions/{version_id}/approve", response_model=AdminBoundaryOut)
async def approve_version(
    version_id: int,
    payload: ReviewActionRequest,
    admin: AdminUser = Depends(require_permission(REVIEW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> AdminBoundaryOut:
    boundary, version, disputes = await boundary_service.approve_version(
        db, admin.id, version_id, payload.note
    )
    await db.commit()
    await db.refresh(boundary)

    await _notify_owner(
        db,
        boundary,
        "জমির সীমানা অনুমোদিত / Plot boundary approved",
        f"<p>Boundary #{boundary.id} (version {version.version}) was approved."
        + (" Overlaps with other boundaries were flagged for committee review.</p>" if disputes else "</p>"),
    )
    return await _boundary_out_or_404(db, boundary.id)


@router.post("/plot-boundary-versions/{version_id}/reject", response_model=AdminBoundaryOut)
async def reject_version(
    version_id: int,
    payload: ReviewActionRequest,
    admin: AdminUser = Depends(require_permission(REVIEW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> AdminBoundaryOut:
    if not payload.note or not payload.note.strip():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "NOTE_REQUIRED", "message": "A rejection note is required."},
        )
    boundary, version = await boundary_service.reject_version(db, admin.id, version_id, payload.note.strip())
    await db.commit()
    await db.refresh(boundary)

    await _notify_owner(
        db,
        boundary,
        "জমির সীমানা বাতিল / Plot boundary rejected",
        f"<p>Boundary #{boundary.id} (version {version.version}) was rejected. Reason: {payload.note}</p>",
    )
    return await _boundary_out_or_404(db, boundary.id)


@router.get("/plot-boundaries/{boundary_id}/versions", response_model=list[BoundaryVersionOut])
async def list_versions(
    boundary_id: int,
    _admin: AdminUser = Depends(require_permission(REVIEW_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> list[PlotBoundaryVersion]:
    await _load_boundary(db, boundary_id)
    return [_version_out(v) for v in await boundary_service.boundary_versions(db, boundary_id)]


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
