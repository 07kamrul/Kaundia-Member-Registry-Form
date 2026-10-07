"""Online Resolution Book (অনলাইন রেজোলিউশন বুক): read-model assembly,
meeting-number generation, vote/attendance validation and the Notices
integration.

The router, the PDF export and the tests all read the same payload builders
here, so the exported minutes can never drift from the live data.
"""
from datetime import date, datetime, time, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.admin import AdminUser
from app.models.member import Member
from app.models.notice import Notice
from app.models.resolution_book import (
    ATTENDANCE_PRESENT,
    MEETING_STATUS_COMPLETED,
    RESOLUTION_STATUS_DONE,
    RESOLUTION_STATUS_IN_PROGRESS,
    RESOLUTION_STATUS_PENDING,
    Meeting,
    MeetingAttendance,
    MeetingRecording,
    Resolution,
)
from app.services.audit import record_audit

# Committee edits stay normal edits until this many hours after the meeting
# date; beyond the window an Admin must do it and the change is audited as a
# correction (same audit-preserving philosophy as the finance module).
EDIT_WINDOW_HOURS = 72

NOTICE_TITLE_TEXT_MAX = 120
NOTICE_BODY_TEXT_MAX = 400


def meeting_no_prefix(year: int) -> str:
    return f"SVA-{year}-"


async def next_meeting_no(db: AsyncSession, for_date: date) -> str:
    """Auto-suggest the next free "SVA-YYYY-NNN" for the given meeting year."""
    prefix = meeting_no_prefix(for_date.year)
    year_start = date(for_date.year, 1, 1)
    year_end = date(for_date.year + 1, 1, 1)
    count = (
        await db.execute(
            select(func.count())
            .select_from(Meeting)
            .where(Meeting.date >= year_start, Meeting.date < year_end)
        )
    ).scalar_one()
    return f"{prefix}{count + 1:03d}"


async def meeting_no_taken(db: AsyncSession, meeting_no: str, exclude_id: int | None = None) -> bool:
    conditions = [func.lower(Meeting.meeting_no) == meeting_no.lower()]
    if exclude_id is not None:
        conditions.append(Meeting.id != exclude_id)
    existing = await db.execute(select(Meeting.id).where(*conditions))
    return existing.first() is not None


async def edit_cutoff_exceeded(meeting: Meeting) -> bool:
    """Committee edits are allowed only within the window after the meeting."""
    if meeting.status == MEETING_STATUS_COMPLETED:
        cutoff = datetime.combine(meeting.date, time(23, 59, 59))
        hours = (datetime.now(timezone.utc) - cutoff.replace(tzinfo=timezone.utc)).total_seconds() / 3600
        return hours > EDIT_WINDOW_HOURS
    return False


async def uploader_names_for(db: AsyncSession, meeting: Meeting) -> dict[int, str]:
    admin_ids = {rec.uploaded_by for rec in meeting.recordings if rec.uploaded_by is not None}
    if not admin_ids:
        return {}
    rows = await db.execute(select(AdminUser.id, AdminUser.name).where(AdminUser.id.in_(admin_ids)))
    return dict(rows.all())


async def load_meeting(db: AsyncSession, meeting_id: int) -> Meeting:
    meeting = (
        await db.execute(
            select(Meeting)
            .where(Meeting.id == meeting_id)
            .options(
                selectinload(Meeting.resolutions).selectinload(Resolution.assigned_to),
                selectinload(Meeting.attendance).selectinload(MeetingAttendance.member),
                selectinload(Meeting.recordings),
            )
        )
    ).scalar_one_or_none()
    if meeting is None:
        from fastapi import HTTPException, status

        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Meeting not found.")
    return meeting


def present_count(meeting: Meeting) -> int:
    return sum(1 for entry in meeting.attendance if entry.status == ATTENDANCE_PRESENT)


def attendance_stats(meeting: Meeting) -> tuple[int, int, int]:
    total = len(meeting.attendance)
    present = present_count(meeting)
    percent = round(present * 100 / total) if total else 0
    return present, total, percent


def validate_votes(present: int, vote_for: int, vote_against: int, vote_neutral: int) -> None:
    """A resolution's votes can never exceed the members present. Tampered or
    inconsistent submissions are rejected with a clear message."""
    total_votes = vote_for + vote_against + vote_neutral
    if total_votes > present:
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                f"মোট ভোট ({total_votes}) উপস্থিত সদস্য সংখ্যা ({present}) এর বেশি হতে পারে না। "
                f"Total votes must not exceed the number of members present ({present})."
            ),
        )


def member_ref(member: Member | None) -> dict | None:
    if member is None:
        return None
    return {"id": member.id, "full_name": member.full_name, "member_id": member.member_id}


def resolution_to_dict(resolution: Resolution) -> dict:
    return {
        "id": resolution.id,
        "meeting_id": resolution.meeting_id,
        "resolution_no": resolution.resolution_no,
        "decision": resolution.decision,
        "vote_for": resolution.vote_for,
        "vote_against": resolution.vote_against,
        "vote_neutral": resolution.vote_neutral,
        "assigned_to": member_ref(resolution.assigned_to),
        "task": resolution.task,
        "due_date": resolution.due_date,
        "status": resolution.status,
        "updated_at": resolution.updated_at,
    }


def meeting_list_dict(meeting: Meeting) -> dict:
    present, total, percent = attendance_stats(meeting)
    return {
        "id": meeting.id,
        "meeting_no": meeting.meeting_no,
        "date": meeting.date,
        "time": meeting.time,
        "meeting_type": meeting.meeting_type,
        "chairperson": meeting.chairperson,
        "next_meeting_date": meeting.next_meeting_date,
        "status": meeting.status,
        "resolution_count": len(meeting.resolutions),
        "attendance_present": present,
        "attendance_total": total,
        "attendance_percent": percent,
    }


def meeting_detail_dict(
    meeting: Meeting,
    created_by_name: str | None = None,
    uploader_names: dict[int, str] | None = None,
) -> dict:
    uploader_names = uploader_names or {}
    return {
        **meeting_list_dict(meeting),
        "agenda": meeting.agenda,
        "summary": meeting.summary,
        "created_by": created_by_name,
        "updated_at": meeting.updated_at,
        "resolutions": [resolution_to_dict(r) for r in sorted(meeting.resolutions, key=lambda r: r.resolution_no)],
        "attendance": [
            {"member": member_ref(entry.member), "status": entry.status}
            for entry in sorted(meeting.attendance, key=lambda e: (e.member.full_name, e.member.id))
        ],
        "recordings": [
            {
                "id": rec.id,
                "meeting_id": rec.meeting_id,
                "original_name": rec.original_name,
                "file_type": rec.file_type,
                "file_size": rec.file_size,
                "uploaded_by": uploader_names.get(rec.uploaded_by),
                "uploaded_at": rec.uploaded_at,
            }
            for rec in sorted(meeting.recordings, key=lambda r: r.uploaded_at or datetime.min.replace(tzinfo=timezone.utc))
        ],
    }


async def list_meetings(
    db: AsyncSession,
    *,
    q: str | None = None,
    meeting_type: str | None = None,
    status_filter: str | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
    limit: int | None = None,
    offset: int = 0,
) -> dict:
    """Forgiving search: partial match on meeting no, chairperson, agenda and
    summary, plus date-range / type / status filters."""
    conditions = []
    if q:
        needle = f"%{q.strip()}%"
        conditions.append(
            Meeting.meeting_no.ilike(needle)
            | Meeting.chairperson.ilike(needle)
            | Meeting.agenda.ilike(needle)
            | Meeting.summary.ilike(needle)
        )
    if meeting_type:
        conditions.append(Meeting.meeting_type == meeting_type)
    if status_filter:
        conditions.append(Meeting.status == status_filter)
    if date_from:
        conditions.append(Meeting.date >= date_from)
    if date_to:
        conditions.append(Meeting.date <= date_to)

    total = (
        await db.execute(select(func.count()).select_from(Meeting).where(*(conditions or [])))
    ).scalar_one()

    query = (
        select(Meeting)
        .options(
            selectinload(Meeting.resolutions),
            selectinload(Meeting.attendance),
        )
        .order_by(Meeting.date.desc(), Meeting.id.desc())
    )
    if conditions:
        query = query.where(*conditions)
    if limit is not None:
        query = query.limit(limit).offset(offset)

    meetings = (await db.execute(query)).scalars().unique().all()
    return {"total": total, "items": [meeting_list_dict(m) for m in meetings]}


async def search_meetings_and_resolutions(
    db: AsyncSession, *, q: str | None, date_from: date | None, date_to: date | None, meeting_type: str | None
) -> dict:
    """Search hits meetings on their own fields AND on resolution decisions;
    matched resolutions are surfaced so the UI can highlight them."""
    matched_resolutions: dict[int, list[dict]] = {}
    if q:
        needle = f"%{q.strip()}%"
        rows = await db.execute(
            select(Resolution).where(Resolution.decision.ilike(needle) | Resolution.task.ilike(needle))
        )
        for resolution in rows.scalars().unique():
            matched_resolutions.setdefault(resolution.meeting_id, []).append(resolution_to_dict(resolution))

    result = await list_meetings(
        db, q=q, meeting_type=meeting_type, date_from=date_from, date_to=date_to, limit=100
    )
    if matched_resolutions:
        seen = {item["id"] for item in result["items"]}
        extra_ids = [mid for mid in matched_resolutions if mid not in seen]
        if extra_ids:
            extra = (
                (
                    await db.execute(
                        select(Meeting)
                        .where(Meeting.id.in_(extra_ids))
                        .options(
                            selectinload(Meeting.resolutions),
                            selectinload(Meeting.attendance),
                        )
                        .order_by(Meeting.date.desc(), Meeting.id.desc())
                    )
                )
                .scalars()
                .unique()
                .all()
            )
            result["items"].extend(meeting_list_dict(m) for m in extra)
            result["total"] = len({i["id"] for i in result["items"]}) + max(
                0, result["total"] - len(seen)
            )
    return {"total": result["total"], "items": result["items"], "matched_resolutions": matched_resolutions}


async def build_dashboard(db: AsyncSession) -> dict:
    now_year = datetime.now(timezone.utc).year
    total = (await db.execute(select(func.count()).select_from(Meeting))).scalar_one()
    this_year = (
        await db.execute(
            select(func.count())
            .select_from(Meeting)
            .where(Meeting.date >= date(now_year, 1, 1), Meeting.date < date(now_year + 1, 1, 1))
        )
    ).scalar_one()

    meetings = (
        await db.execute(
            select(Meeting)
            .options(
                selectinload(Meeting.resolutions),
                selectinload(Meeting.attendance),
            )
            .order_by(Meeting.date.desc(), Meeting.id.desc())
        )
    ).scalars().unique().all()

    percents = [attendance_stats(m)[2] for m in meetings if m.attendance]
    avg = round(sum(percents) / len(percents)) if percents else 0

    upcoming = max(
        (m.next_meeting_date for m in meetings if m.next_meeting_date), default=None
    )
    open_actions = sum(
        1
        for m in meetings
        for r in m.resolutions
        if r.status in (RESOLUTION_STATUS_PENDING, RESOLUTION_STATUS_IN_PROGRESS)
    )

    return {
        "total_meetings": total,
        "meetings_this_year": this_year,
        "average_attendance_percent": avg,
        "open_action_items": open_actions,
        "upcoming_meeting_date": upcoming,
        "recent_meetings": [meeting_list_dict(m) for m in meetings[:10]],
    }


# ---------------------------------------------------------------------------
# Notices integration
# ---------------------------------------------------------------------------


def _truncate(text: str, limit: int) -> str:
    return text if len(text) <= limit else text[: limit - 1] + "…"


async def publish_resolution_book_notice(
    db: AsyncSession, admin: AdminUser, *, title: str, body: str
) -> Notice:
    """Announce a resolution-book change through the existing Notices feature.
    The caller commits (alongside its own change)."""
    notice = Notice(
        title=title,
        body=body,
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
        action="meeting.notice_published",
        entity_type="notice",
        entity_id=str(notice.id),
        detail=f"auto notice: {_truncate(title, 80)}",
    )
    return notice


def new_meeting_notice_title(meeting: Meeting) -> str:
    return f"📋 নতুন সভার রেকর্ড যোগ হয়েছে: {meeting.meeting_no}"


def resolution_done_notice_title(meeting: Meeting, resolution: Resolution) -> str:
    return f"✅ সিদ্ধান্ত বাস্তবায়িত: {meeting.meeting_no} / সিদ্ধান্ত-{resolution.resolution_no}"


def next_meeting_notice_title(meeting: Meeting) -> str:
    return f"🗓️ পরবর্তী সভার তারিখ নির্ধারিত: {meeting.meeting_no}"
