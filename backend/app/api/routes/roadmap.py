"""Society roadmap (আমাদের পরিকল্পনা): a read view for every logged-in
account plus the committee's management endpoints behind `manage_roadmap`.

Admin mutations return the full roadmap payload so the management screen's
completion percentages refresh from the same numbers members see. Every
mutation writes an audit row; completing or adding an item can publish a
Notice through the existing notices table.
"""
from datetime import date, datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.deps import AccountActor, get_account_actor
from app.core.permissions import require_permission
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.roadmap import ROADMAP_STATUS_DONE, RoadmapItem, RoadmapTimeframe
from app.schemas.roadmap import (
    RoadmapArchiveOut,
    RoadmapArchivedCycleOut,
    RoadmapItemCreate,
    RoadmapItemOut,
    RoadmapItemUpdate,
    RoadmapOut,
    RoadmapReorderIn,
    RoadmapStatusIn,
)
from app.services.audit import record_audit
from app.services.finance import BN_MONTHS
from app.services.roadmap import (
    build_roadmap,
    done_notice_title,
    ensure_default_timeframes,
    item_to_dict,
    new_item_notice_title,
    publish_roadmap_notice,
)
from app.services.roadmap_pdf import (
    RoadmapPdfItem,
    RoadmapPdfSection,
    RoadmapReportData,
    bn_digits,
    build_roadmap_pdf,
)

router = APIRouter(tags=["roadmap"])

settings = get_settings()

_DHAKA = timezone(timedelta(hours=6), name="Asia/Dhaka")
_ARCHIVE_CYCLES_LIMIT = 20
_AUDIT_TEXT_MAX = 80


def _today_dhaka() -> date:
    return datetime.now(_DHAKA).date()


def _datetime_label(value: datetime) -> str:
    local = value.astimezone(_DHAKA)
    return bn_digits(f"{local.day} {BN_MONTHS[local.month - 1]} {local.year}, {local:%H:%M}")


def _short(text: str) -> str:
    return text if len(text) <= _AUDIT_TEXT_MAX else text[: _AUDIT_TEXT_MAX - 1] + "…"


async def _load_timeframe(db: AsyncSession, timeframe_id: int) -> RoadmapTimeframe:
    await ensure_default_timeframes(db)
    timeframe = (
        await db.execute(select(RoadmapTimeframe).where(RoadmapTimeframe.id == timeframe_id))
    ).scalar_one_or_none()
    if timeframe is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unknown roadmap timeframe.")
    return timeframe


async def _load_active_item(db: AsyncSession, item_id: int) -> RoadmapItem:
    item = (
        await db.execute(select(RoadmapItem).where(RoadmapItem.id == item_id, RoadmapItem.is_active == 1))
    ).scalar_one_or_none()
    if item is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Roadmap item not found.")
    return item


async def _next_sort_order(db: AsyncSession, timeframe_id: int) -> int:
    current = (
        await db.execute(
            select(func.max(RoadmapItem.sort_order)).where(
                RoadmapItem.timeframe_id == timeframe_id, RoadmapItem.is_active == 1
            )
        )
    ).scalar_one_or_none()
    return 0 if current is None else current + 1


async def _roadmap_out(db: AsyncSession) -> RoadmapOut:
    # Commits expire ORM state; rebuild from a clean read.
    db.expire_all()
    return RoadmapOut(**await build_roadmap(db))


# ---------------------------------------------------------------------------
# Members (and every authenticated admin-tier account)
# ---------------------------------------------------------------------------


@router.get("/roadmap", response_model=RoadmapOut)
async def get_roadmap(
    db: AsyncSession = Depends(get_db),
    _actor: AccountActor = Depends(get_account_actor),
) -> RoadmapOut:
    return RoadmapOut(**await build_roadmap(db))


def _pdf_section(timeframe: dict) -> RoadmapPdfSection:
    return RoadmapPdfSection(
        name=timeframe["name_bn"],
        window=timeframe["target_window_bn"],
        done=timeframe["done"],
        total=timeframe["total"],
        percent=timeframe["percent"],
        items=tuple(
            RoadmapPdfItem(
                text=item["text"],
                status=item["status"],
                target_date=item["target_date"],
                owner=item["owner"],
                note=item["note"],
                completed_at=item["completed_at"],
            )
            for item in timeframe["items"]
        ),
    )


@router.get("/roadmap/export.pdf")
async def export_roadmap_pdf(
    db: AsyncSession = Depends(get_db),
    _actor: AccountActor = Depends(get_account_actor),
) -> Response:
    roadmap = await build_roadmap(db)
    totals = roadmap["totals"]
    now = datetime.now(_DHAKA)
    data = RoadmapReportData(
        org_name=settings.organization_name,
        generated_at_label=_datetime_label(now),
        last_updated_label=_datetime_label(roadmap["last_updated"]) if roadmap["last_updated"] else "—",
        overall_done=totals["done"],
        overall_in_progress=totals["in_progress"],
        overall_planned=totals["planned"],
        overall_total=totals["total"],
        overall_percent=totals["percent"],
        sections=tuple(_pdf_section(tf) for tf in roadmap["timeframes"]),
    )
    filename = f"roadmap-{now:%Y%m%d}.pdf"
    return Response(
        content=build_roadmap_pdf(data),
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


# ---------------------------------------------------------------------------
# Committee management
# ---------------------------------------------------------------------------


@router.post("/admin/roadmap/items", response_model=RoadmapOut, status_code=status.HTTP_201_CREATED)
async def create_roadmap_item(
    payload: RoadmapItemCreate,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_roadmap")),
) -> RoadmapOut:
    timeframe = await _load_timeframe(db, payload.timeframe_id)
    is_done = payload.status == ROADMAP_STATUS_DONE
    item = RoadmapItem(
        timeframe_id=timeframe.id,
        text=payload.text,
        status=payload.status,
        target_date=payload.target_date,
        owner=payload.owner,
        note=payload.note,
        sort_order=await _next_sort_order(db, timeframe.id),
        completed_at=_today_dhaka() if is_done else None,
        is_active=1,
        created_by=admin.id,
    )
    db.add(item)
    await db.flush()
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="roadmap_item.create",
        entity_type="roadmap_item",
        entity_id=str(item.id),
        detail=f"[{timeframe.key}] {_short(item.text)} ({item.status})",
    )
    if payload.notify:
        title = done_notice_title(item) if is_done else new_item_notice_title(item)
        await publish_roadmap_notice(db, admin, title=title, item=item, timeframe_label=timeframe.name_bn)
    await db.commit()
    return await _roadmap_out(db)


@router.put("/admin/roadmap/items/{item_id}", response_model=RoadmapOut)
async def update_roadmap_item(
    item_id: int,
    payload: RoadmapItemUpdate,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_roadmap")),
) -> RoadmapOut:
    item = await _load_active_item(db, item_id)
    sent = payload.model_fields_set
    changes: list[str] = []

    if payload.timeframe_id is not None and payload.timeframe_id != item.timeframe_id:
        target = await _load_timeframe(db, payload.timeframe_id)
        old_key = item.timeframe.key if item.timeframe is not None else str(item.timeframe_id)
        item.timeframe_id = target.id
        item.sort_order = await _next_sort_order(db, target.id)
        changes.append(f"moved {old_key} -> {target.key}")
    if payload.text is not None and payload.text != item.text:
        item.text = payload.text
        changes.append("text")
    for field in ("target_date", "owner", "note"):
        if field in sent and getattr(payload, field) != getattr(item, field):
            setattr(item, field, getattr(payload, field))
            changes.append(field)

    if not changes:
        return await _roadmap_out(db)
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="roadmap_item.update",
        entity_type="roadmap_item",
        entity_id=str(item.id),
        detail=f"{_short(item.text)}: {', '.join(changes)}",
    )
    await db.commit()
    return await _roadmap_out(db)


@router.post("/admin/roadmap/items/{item_id}/status", response_model=RoadmapOut)
async def set_roadmap_item_status(
    item_id: int,
    payload: RoadmapStatusIn,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_roadmap")),
) -> RoadmapOut:
    item = await _load_active_item(db, item_id)
    previous = item.status
    becomes_done = payload.status == ROADMAP_STATUS_DONE

    if payload.completed_at is not None and payload.completed_at > _today_dhaka():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Completion date cannot be in the future."
        )
    date_unchanged = payload.completed_at is None or payload.completed_at == item.completed_at
    if previous == payload.status and (not becomes_done or date_unchanged):
        return await _roadmap_out(db)

    item.status = payload.status
    item.completed_at = (payload.completed_at or item.completed_at or _today_dhaka()) if becomes_done else None
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="roadmap_item.status",
        entity_type="roadmap_item",
        entity_id=str(item.id),
        detail=f"{_short(item.text)}: {previous} -> {payload.status}",
    )
    if becomes_done and previous != ROADMAP_STATUS_DONE and payload.notify:
        timeframe_label = item.timeframe.name_bn if item.timeframe is not None else ""
        await publish_roadmap_notice(
            db, admin, title=done_notice_title(item), item=item, timeframe_label=timeframe_label
        )
    await db.commit()
    return await _roadmap_out(db)


@router.delete("/admin/roadmap/items/{item_id}", response_model=RoadmapOut)
async def delete_roadmap_item(
    item_id: int,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_roadmap")),
) -> RoadmapOut:
    item = await _load_active_item(db, item_id)
    item.is_active = 0
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="roadmap_item.delete",
        entity_type="roadmap_item",
        entity_id=str(item.id),
        detail=_short(item.text),
    )
    await db.commit()
    return await _roadmap_out(db)


@router.post("/admin/roadmap/reorder", response_model=RoadmapOut)
async def reorder_roadmap_items(
    payload: RoadmapReorderIn,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_roadmap")),
) -> RoadmapOut:
    timeframe = await _load_timeframe(db, payload.timeframe_id)
    items = (
        (
            await db.execute(
                select(RoadmapItem).where(RoadmapItem.timeframe_id == timeframe.id, RoadmapItem.is_active == 1)
            )
        )
        .scalars()
        .unique()
        .all()
    )
    by_id = {item.id: item for item in items}
    if len(payload.item_ids) != len(set(payload.item_ids)) or set(payload.item_ids) != set(by_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reorder must list every active item of the timeframe exactly once.",
        )
    for position, item_id in enumerate(payload.item_ids):
        by_id[item_id].sort_order = position
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="roadmap_item.reorder",
        entity_type="roadmap_timeframe",
        entity_id=str(timeframe.id),
        detail=f"[{timeframe.key}] order: {', '.join(str(i) for i in payload.item_ids)}",
    )
    await db.commit()
    return await _roadmap_out(db)


@router.post("/admin/roadmap/archive", response_model=RoadmapArchiveOut)
async def archive_roadmap(
    only_done: bool = Query(default=False),
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_roadmap")),
) -> RoadmapArchiveOut:
    """Close the current cycle: active items move to the archive (all of
    them, or only the completed ones so unfinished work carries over)."""
    conditions = [RoadmapItem.is_active == 1]
    if only_done:
        conditions.append(RoadmapItem.status == ROADMAP_STATUS_DONE)
    items = (await db.execute(select(RoadmapItem).where(*conditions))).scalars().unique().all()
    if not items:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nothing to archive.")
    archived_at = datetime.now(timezone.utc)
    for item in items:
        item.is_active = 0
        item.archived_at = archived_at
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="roadmap.archive",
        entity_type="roadmap",
        entity_id="cycle",
        detail=f"archived {len(items)} item(s){' (done only)' if only_done else ''}",
    )
    await db.commit()
    return RoadmapArchiveOut(archived=len(items))


@router.get("/admin/roadmap/archive", response_model=list[RoadmapArchivedCycleOut])
async def list_roadmap_archive(
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("manage_roadmap")),
) -> list[RoadmapArchivedCycleOut]:
    items = (
        (
            await db.execute(
                select(RoadmapItem)
                .where(RoadmapItem.archived_at.is_not(None))
                .order_by(RoadmapItem.archived_at.desc(), RoadmapItem.timeframe_id, RoadmapItem.sort_order)
            )
        )
        .scalars()
        .unique()
        .all()
    )
    cycles: dict[datetime, list[RoadmapItem]] = {}
    for item in items:
        cycles.setdefault(item.archived_at, []).append(item)
    return [
        RoadmapArchivedCycleOut(
            archived_at=archived_at,
            total=len(cycle_items),
            done=sum(1 for i in cycle_items if i.status == ROADMAP_STATUS_DONE),
            items=[RoadmapItemOut(**item_to_dict(i)) for i in cycle_items],
        )
        for archived_at, cycle_items in list(cycles.items())[:_ARCHIVE_CYCLES_LIMIT]
    ]
