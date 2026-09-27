from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.permissions import require_permission
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.config_list_item import ConfigListItem
from app.models.event import Event
from app.models.notice import Notice
from app.schemas.event import EventCreate, EventOut, EventUpdate
from app.schemas.notice import NoticeCreate, NoticeOut, NoticeUpdate
from app.services.audit import record_audit

# Notices *and* events live behind the one `manage_notices` permission (see
# app/core/permissions.py) - a single admin surface for "what the council
# publishes".
router = APIRouter(prefix="/admin", tags=["notices"])


@router.get("/notices", response_model=list[NoticeOut])
async def list_notices(
    published: bool | None = Query(default=None),
    category_id: int | None = Query(default=None),
    limit: int | None = Query(default=None, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("manage_notices")),
) -> list[Notice]:
    query = select(Notice)
    if published is not None:
        query = query.where(Notice.is_published == published)
    if category_id is not None:
        query = query.where(Notice.category_id == category_id)
    query = query.order_by(Notice.created_at.desc(), Notice.id.desc())
    if offset:
        query = query.offset(offset)
    if limit is not None:
        query = query.limit(limit)
    result = await db.execute(query)
    return list(result.scalars().all())


@router.post("/notices", response_model=NoticeOut, status_code=status.HTTP_201_CREATED)
async def create_notice(
    payload: NoticeCreate,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_notices")),
) -> Notice:
    await _require_category(db, "notice_category", payload.category_id)
    notice = Notice(**payload.model_dump(), created_by=admin.id)
    db.add(notice)
    # Flush first so the audit row can reference the new primary key; the
    # flush and the audit insert share the commit below.
    await db.flush()
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="notice.create",
        entity_type="notice",
        entity_id=str(notice.id),
        detail=f"title={notice.title} published={notice.is_published}",
    )
    await db.commit()
    await db.refresh(notice)
    return notice


@router.patch("/notices/{notice_id}", response_model=NoticeOut)
async def update_notice(
    notice_id: int,
    payload: NoticeUpdate,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_notices")),
) -> Notice:
    notice = await _get_or_404(db, Notice, notice_id, "Notice not found")
    updates = payload.model_dump(exclude_unset=True)
    if "category_id" in updates:
        await _require_category(db, "notice_category", updates["category_id"])
    for field, value in updates.items():
        setattr(notice, field, value)

    record_audit(
        db,
        actor_admin_id=admin.id,
        action="notice.update",
        entity_type="notice",
        entity_id=str(notice.id),
        detail=f"updates={sorted(updates)}",
    )
    await db.commit()
    # `updated_at` is a server-side `onupdate` value the ORM hasn't seen.
    await db.refresh(notice)
    return notice


@router.delete("/notices/{notice_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_notice(
    notice_id: int,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_notices")),
) -> None:
    notice = await _get_or_404(db, Notice, notice_id, "Notice not found")
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="notice.delete",
        entity_type="notice",
        entity_id=str(notice.id),
        detail=f"title={notice.title}",
    )
    await db.delete(notice)
    await db.commit()


@router.get("/events", response_model=list[EventOut])
async def list_events(
    published: bool | None = Query(default=None),
    category_id: int | None = Query(default=None),
    limit: int | None = Query(default=None, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("manage_notices")),
) -> list[Event]:
    query = select(Event)
    if published is not None:
        query = query.where(Event.is_published == published)
    if category_id is not None:
        query = query.where(Event.category_id == category_id)
    # Admin side is a management list, not a programme: soonest first so a
    # draft of this week's event sits at the top rather than in date order.
    query = query.order_by(Event.start_at.asc(), Event.id.desc())
    if offset:
        query = query.offset(offset)
    if limit is not None:
        query = query.limit(limit)
    result = await db.execute(query)
    return list(result.scalars().all())


@router.post("/events", response_model=EventOut, status_code=status.HTTP_201_CREATED)
async def create_event(
    payload: EventCreate,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_notices")),
) -> Event:
    await _require_category(db, "event_category", payload.category_id)
    _require_valid_range(payload.start_at, payload.end_at)
    event = Event(**payload.model_dump(), created_by=admin.id)
    db.add(event)
    await db.flush()
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="event.create",
        entity_type="event",
        entity_id=str(event.id),
        detail=f"title={event.title} start_at={event.start_at} published={event.is_published}",
    )
    await db.commit()
    await db.refresh(event)
    return event


@router.patch("/events/{event_id}", response_model=EventOut)
async def update_event(
    event_id: int,
    payload: EventUpdate,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_notices")),
) -> Event:
    event = await _get_or_404(db, Event, event_id, "Event not found")
    updates = payload.model_dump(exclude_unset=True)
    if "category_id" in updates:
        await _require_category(db, "event_category", updates["category_id"])
    for field, value in updates.items():
        setattr(event, field, value)
    _require_valid_range(event.start_at, event.end_at)

    record_audit(
        db,
        actor_admin_id=admin.id,
        action="event.update",
        entity_type="event",
        entity_id=str(event.id),
        detail=f"updates={sorted(updates)}",
    )
    await db.commit()
    await db.refresh(event)
    return event


@router.delete("/events/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_event(
    event_id: int,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_notices")),
) -> None:
    event = await _get_or_404(db, Event, event_id, "Event not found")
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="event.delete",
        entity_type="event",
        entity_id=str(event.id),
        detail=f"title={event.title}",
    )
    await db.delete(event)
    await db.commit()


async def _get_or_404(db: AsyncSession, model: type[Notice] | type[Event], row_id: int, detail: str):
    result = await db.execute(select(model).where(model.id == row_id))
    row = result.scalar_one_or_none()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=detail)
    return row


async def _require_category(db: AsyncSession, list_category: str, category_id: int | None) -> None:
    """Reject a category id that isn't a row of `list_category`.

    The FK would reject it anyway, but only as an opaque 500 - and this also
    stops a notice being filed under the event categories (or vice versa).
    """
    if category_id is None:
        return
    row = await db.get(ConfigListItem, category_id)
    if row is None or row.category != list_category:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown {list_category} id: {category_id}",
        )


def _require_valid_range(start_at: datetime, end_at: datetime | None) -> None:
    if end_at is not None and _utc_naive(end_at) < _utc_naive(start_at):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="end_at must not be before start_at",
        )


def _utc_naive(value: datetime) -> datetime:
    """Naive UTC form for comparisons.

    SQLite hands timezone-aware columns back as offset-less datetimes, so a
    freshly parsed (aware) `end_at` would otherwise be compared against an
    aware/naive mix and raise.
    """
    if value.tzinfo is None:
        return value
    return value.astimezone(timezone.utc).replace(tzinfo=None)
