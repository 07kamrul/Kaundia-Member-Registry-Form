"""Society roadmap: read-model assembly (per-timeframe progress), default
timeframe provisioning and the Notices integration.

Every consumer (member page, admin screen, PDF, slides, share image) reads
the same `build_roadmap()` payload, so the exports can never drift from the
live data.
"""
from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.admin import AdminUser
from app.models.notice import Notice
from app.models.roadmap import (
    ROADMAP_STATUS_DONE,
    ROADMAP_STATUS_IN_PROGRESS,
    ROADMAP_STATUS_PLANNED,
    RoadmapItem,
    RoadmapTimeframe,
)
from app.services.audit import record_audit

# (key, name_bn, name_en, window_bn, window_en) - mirrors migration c8e1f3a5b7d9.
DEFAULT_TIMEFRAMES: tuple[tuple[str, str, str, str, str], ...] = (
    ("short", "স্বল্পমেয়াদি পরিকল্পনা", "Short Term", "আগামী ১ মাস", "Next 1 month"),
    ("mid", "মধ্যমেয়াদি পরিকল্পনা", "Mid Term", "আগামী ৪ মাস", "Next 4 months"),
    ("long", "দীর্ঘমেয়াদি পরিকল্পনা", "Long Term", "আগামী ১ বছর", "Next 1 year"),
)

NOTICE_TITLE_TEXT_MAX = 120
NOTICE_BODY_TEXT_MAX = 200


def completion_percent(done: int, total: int) -> int:
    """Rounded share of done items; an empty section is 0%, not 100%."""
    if total <= 0:
        return 0
    return round(done * 100 / total)


def _truncate(text: str, limit: int) -> str:
    return text if len(text) <= limit else text[: limit - 1] + "…"


def _as_utc(value: datetime) -> datetime:
    # SQLite drops tzinfo on round-trip; Postgres keeps it.
    return value if value.tzinfo is not None else value.replace(tzinfo=timezone.utc)


async def ensure_default_timeframes(db: AsyncSession) -> None:
    """Databases built from metadata (tests, a freshly recreated dev DB) have
    no seeded rows; production gets them from the migration."""
    existing = (await db.execute(select(func.count()).select_from(RoadmapTimeframe))).scalar_one()
    if existing:
        return
    for order, (key, name_bn, name_en, window_bn, window_en) in enumerate(DEFAULT_TIMEFRAMES):
        db.add(
            RoadmapTimeframe(
                key=key,
                name_bn=name_bn,
                name_en=name_en,
                target_window_bn=window_bn,
                target_window_en=window_en,
                sort_order=order,
            )
        )
    await db.commit()


def item_to_dict(item: RoadmapItem) -> dict:
    return {
        "id": item.id,
        "timeframe_id": item.timeframe_id,
        "text": item.text,
        "status": item.status,
        "target_date": item.target_date,
        "owner": item.owner,
        "note": item.note,
        "sort_order": item.sort_order,
        "completed_at": item.completed_at,
        "updated_at": item.updated_at,
    }


def _counts(items: list[RoadmapItem]) -> dict:
    total = len(items)
    done = sum(1 for i in items if i.status == ROADMAP_STATUS_DONE)
    in_progress = sum(1 for i in items if i.status == ROADMAP_STATUS_IN_PROGRESS)
    planned = sum(1 for i in items if i.status == ROADMAP_STATUS_PLANNED)
    return {
        "total": total,
        "done": done,
        "in_progress": in_progress,
        "planned": planned,
        "percent": completion_percent(done, total),
    }


async def _last_updated(db: AsyncSession) -> datetime | None:
    # Removed/archived rows count too: their disappearance is an update.
    item_stamp = (await db.execute(select(func.max(RoadmapItem.updated_at)))).scalar_one_or_none()
    tf_stamp = (await db.execute(select(func.max(RoadmapTimeframe.updated_at)))).scalar_one_or_none()
    stamps = [_as_utc(s) for s in (item_stamp, tf_stamp) if s is not None]
    return max(stamps, default=None)


async def build_roadmap(db: AsyncSession) -> dict:
    await ensure_default_timeframes(db)
    timeframes = (
        (await db.execute(select(RoadmapTimeframe).order_by(RoadmapTimeframe.sort_order, RoadmapTimeframe.id)))
        .scalars()
        .all()
    )
    items = (
        (
            await db.execute(
                select(RoadmapItem)
                .where(RoadmapItem.is_active == 1)
                .order_by(RoadmapItem.sort_order, RoadmapItem.id)
            )
        )
        .scalars()
        .unique()
        .all()
    )
    by_timeframe: dict[int, list[RoadmapItem]] = {tf.id: [] for tf in timeframes}
    for item in items:
        by_timeframe.setdefault(item.timeframe_id, []).append(item)

    return {
        "last_updated": await _last_updated(db),
        "totals": _counts(list(items)),
        "timeframes": [
            {
                "id": tf.id,
                "key": tf.key,
                "name_bn": tf.name_bn,
                "name_en": tf.name_en,
                "target_window_bn": tf.target_window_bn,
                "target_window_en": tf.target_window_en,
                "sort_order": tf.sort_order,
                **_counts(by_timeframe[tf.id]),
                "items": [item_to_dict(i) for i in by_timeframe[tf.id]],
            }
            for tf in timeframes
        ],
    }


def done_notice_title(item: RoadmapItem) -> str:
    return f"✅ সম্পন্ন: {_truncate(item.text, NOTICE_TITLE_TEXT_MAX)}"


def new_item_notice_title(item: RoadmapItem) -> str:
    return f"🆕 নতুন পরিকল্পনা: {_truncate(item.text, NOTICE_TITLE_TEXT_MAX)}"


async def publish_roadmap_notice(
    db: AsyncSession, admin: AdminUser, *, title: str, item: RoadmapItem, timeframe_label: str
) -> Notice:
    """Announce a roadmap change through the existing Notices feature. The
    caller commits (alongside its own change)."""
    body_lines = [f"{timeframe_label}: {_truncate(item.text, NOTICE_BODY_TEXT_MAX)}"]
    if item.note:
        body_lines.append(item.note)
    body_lines.append("সম্পূর্ণ পরিকল্পনা দেখতে লগইন করে 'আমাদের পরিকল্পনা' পেজটি দেখুন।")
    notice = Notice(
        title=title,
        body="\n".join(body_lines),
        is_published=True,
        is_members_only=False,
        publish_at=datetime.now(timezone.utc),
        created_by=admin.id,
    )
    db.add(notice)
    await db.flush()
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="roadmap_item.notice_published",
        entity_type="notice",
        entity_id=str(notice.id),
        detail=f"auto notice for roadmap item #{item.id}",
    )
    return notice
