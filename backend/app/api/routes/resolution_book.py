"""Online Resolution Book (অনলাইন রেজোলিউশন বুক) routes.

Reads are open to every logged-in account (member or admin tier); every
mutation is gated by the shared `manage_resolution_book` permission.
Committee edits inside the window are normal edits; past the window only an
admin may change a record and the audit row marks it as a logged correction.
"""
import asyncio
import uuid
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, Query, Response, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import get_settings
from app.core.deps import AccountActor, get_account_actor
from app.core.permissions import require_permission
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.member import Member
from app.models.resolution_book import (
    ATTENDANCE_PRESENT,
    MEETING_STATUS_CANCELLED,
    MEETING_STATUS_COMPLETED,
    MEETING_STATUS_SCHEDULED,
    MEETING_TYPES,
    RECORDING_AUDIO,
    RECORDING_CHAT_LOG,
    RECORDING_SCREENSHOT,
    RECORDING_TYPES,
    RECORDING_VIDEO,
    RESOLUTION_STATUS_DONE,
    Meeting,
    MeetingAttendance,
    MeetingRecording,
    Resolution,
)
from app.schemas.resolution_book import (
    AttendanceBulkIn,
    DashboardOut,
    MeetingCreate,
    MeetingDetailOut,
    MeetingPageOut,
    MeetingUpdate,
    RecordingOut,
    ResolutionCreate,
    ResolutionOut,
    ResolutionStatusUpdateOut,
    ResolutionUpdate,
    SuggestedMeetingNoOut,
)
from app.services.audit import record_audit
from app.services.finance import BN_MONTHS
from app.services.resolution_book import (
    build_dashboard,
    edit_cutoff_exceeded,
    list_meetings,
    load_meeting,
    meeting_detail_dict,
    meeting_no_taken,
    new_meeting_notice_title,
    next_meeting_no,
    next_meeting_notice_title,
    present_count,
    publish_resolution_book_notice,
    resolution_done_notice_title,
    resolution_to_dict,
    search_meetings_and_resolutions,
    uploader_names_for,
    validate_votes,
)
from app.services.resolution_book_pdf import (
    MinutesPdfAttendance,
    MinutesPdfData,
    MinutesPdfResolution,
    bn_digits,
    build_meeting_minutes_pdf,
)

router = APIRouter(tags=["resolution-book"])

settings = get_settings()

_DHAKA = timezone(timedelta(hours=6), name="Asia/Dhaka")
_AUDIT_TEXT_MAX = 80

# Meeting attachments: type is validated from the file's magic bytes, not the
# extension. Cap is generous for meeting videos; audio/image/text are far
# smaller in practice.
_MAX_RECORDING_BYTES = 100 * 1024 * 1024
_RECORDING_MAGIC: tuple[tuple[bytes, str], ...] = (
    (b"\x1a\x45\xdf\xa3", RECORDING_VIDEO),  # webm / mkv
    (b"ftyp", RECORDING_VIDEO),  # mp4 / m4a (offset 4)
    (b"ID3", RECORDING_AUDIO),  # mp3 with tag
    (b"\xff\xfb", RECORDING_AUDIO),  # mp3 raw
    (b"\xff\xf3", RECORDING_AUDIO),
    (b"RIFF", RECORDING_AUDIO),  # wav (also webp - resolved by subtype below)
    (b"OggS", RECORDING_AUDIO),
    (b"\x89PNG", RECORDING_SCREENSHOT),
    (b"\xff\xd8\xff", RECORDING_SCREENSHOT),  # jpeg
)


def _short(text: str) -> str:
    return text if len(text) <= _AUDIT_TEXT_MAX else text[: _AUDIT_TEXT_MAX - 1] + "…"


def _datetime_label(value: datetime) -> str:
    local = value.astimezone(_DHAKA)
    return bn_digits(f"{local.day} {BN_MONTHS[local.month - 1]} {local.year}, {local:%H:%M}")


def _sniff_file_type(contents: bytes) -> str | None:
    for magic, file_type in _RECORDING_MAGIC:
        if magic == b"ftyp":
            if contents[4:8] == b"ftyp":
                return RECORDING_VIDEO
            continue
        if contents.startswith(magic):
            if magic == b"RIFF":
                return RECORDING_VIDEO if contents[8:12] == b"WEBP" else RECORDING_AUDIO
            return file_type
    # Plain-text chat log: printable UTF-8 without a binary signature.
    try:
        contents[:4096].decode("utf-8")
        if b"\x00" not in contents[:4096]:
            return RECORDING_CHAT_LOG
    except UnicodeDecodeError:
        pass
    return None


async def _save_recording(upload: UploadFile, meeting_no: str) -> tuple[str, str, int, str]:
    """Store under the upload root but in a dedicated subfolder; served only
    through the authenticated download endpoint, never /uploads browsing of
    the meeting folder."""
    contents: list[bytes] = []
    total = 0
    while True:
        chunk = await upload.read(1024 * 1024)
        if not chunk:
            break
        total += len(chunk)
        if total > _MAX_RECORDING_BYTES:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="ফাইলটি 100 MB সীমা ছাড়িয়ে গেছে। File exceeds the 100 MB upload limit.",
            )
        contents.append(chunk)
    data = b"".join(contents)
    file_type = _sniff_file_type(data[:64] if len(data) >= 64 else data)
    if file_type is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                "অসমর্থিত ফাইল। ভিডিও, অডিও, ছবি বা টেক্সট (chat log) আপলোড করুন। "
                "Unsupported file - upload video, audio, image or text."
            ),
        )
    subdir = Path("resolution-book") / meeting_no.replace("/", "-")
    filename = f"{uuid.uuid4().hex}{Path(upload.filename or 'attachment').suffix.lower()[:16]}"
    target = settings.upload_root / subdir / filename

    def _write() -> None:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)

    await asyncio.to_thread(_write)
    original_name = (upload.filename or filename)[:255]
    return str(subdir / filename), original_name, total, file_type


# ---------------------------------------------------------------------------
# Reads - every logged-in account
# ---------------------------------------------------------------------------


@router.get("/resolution-book/meetings", response_model=MeetingPageOut)
async def list_meetings_route(
    q: str | None = Query(default=None, max_length=120),
    meeting_type: str | None = Query(default=None, pattern=rf"^({'|'.join(MEETING_TYPES)})$"),
    meeting_status: str | None = Query(
        default=None,
        pattern=rf"^({'|'.join((MEETING_STATUS_SCHEDULED, MEETING_STATUS_COMPLETED, MEETING_STATUS_CANCELLED))})$",
    ),
    date_from: date | None = None,
    date_to: date | None = None,
    limit: int | None = Query(default=None, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    _actor: AccountActor = Depends(get_account_actor),
) -> MeetingPageOut:
    result = await list_meetings(
        db,
        q=q,
        meeting_type=meeting_type,
        status_filter=meeting_status,
        date_from=date_from,
        date_to=date_to,
        limit=limit,
        offset=offset,
    )
    return MeetingPageOut(**result)


@router.get("/resolution-book/search", response_model=None)
async def search_route(
    q: str | None = Query(default=None, max_length=120),
    meeting_type: str | None = Query(default=None, pattern=rf"^({'|'.join(MEETING_TYPES)})$"),
    date_from: date | None = None,
    date_to: date | None = None,
    db: AsyncSession = Depends(get_db),
    _actor: AccountActor = Depends(get_account_actor),
) -> dict:
    return await search_meetings_and_resolutions(
        db, q=q, date_from=date_from, date_to=date_to, meeting_type=meeting_type
    )


@router.get("/resolution-book/summary", response_model=DashboardOut)
async def dashboard_route(
    db: AsyncSession = Depends(get_db),
    _actor: AccountActor = Depends(get_account_actor),
) -> DashboardOut:
    return DashboardOut(**await build_dashboard(db))


@router.get("/resolution-book/meetings/suggest-no", response_model=SuggestedMeetingNoOut)
async def suggest_meeting_no(
    for_date: date = Query(default_factory=date.today),
    db: AsyncSession = Depends(get_db),
    _actor: AccountActor = Depends(get_account_actor),
) -> SuggestedMeetingNoOut:
    meeting_no = await next_meeting_no(db, for_date)
    return SuggestedMeetingNoOut(
        meeting_no=meeting_no, available=not await meeting_no_taken(db, meeting_no)
    )


@router.get("/resolution-book/meetings/{meeting_id}", response_model=MeetingDetailOut)
async def meeting_detail(
    meeting_id: int,
    db: AsyncSession = Depends(get_db),
    _actor: AccountActor = Depends(get_account_actor),
) -> MeetingDetailOut:
    meeting = await load_meeting(db, meeting_id)
    created_by_name = None
    if meeting.created_by is not None:
        admin = (
            await db.execute(select(AdminUser.name).where(AdminUser.id == meeting.created_by))
        ).first()
        created_by_name = admin[0] if admin else None
    uploaders = await uploader_names_for(db, meeting)
    return MeetingDetailOut(**meeting_detail_dict(meeting, created_by_name, uploaders))


@router.get("/resolution-book/meetings/{meeting_id}/attendance")
async def meeting_attendance(
    meeting_id: int,
    db: AsyncSession = Depends(get_db),
    _actor: AccountActor = Depends(get_account_actor),
) -> MeetingDetailOut:
    meeting = await load_meeting(db, meeting_id)
    return MeetingDetailOut(**meeting_detail_dict(meeting))


@router.get("/resolution-book/meetings/{meeting_id}/export.pdf")
async def export_meeting_pdf(
    meeting_id: int,
    db: AsyncSession = Depends(get_db),
    _actor: AccountActor = Depends(get_account_actor),
) -> Response:
    meeting = await load_meeting(db, meeting_id)
    data = MinutesPdfData(
        org_name=settings.organization_name,
        generated_at_label=_datetime_label(datetime.now(_DHAKA)),
        meeting_no=meeting.meeting_no,
        meeting_date=meeting.date,
        meeting_time=meeting.time.strftime("%H:%M") if meeting.time else None,
        meeting_type=meeting.meeting_type,
        chairperson=meeting.chairperson,
        agenda=meeting.agenda,
        summary=meeting.summary,
        next_meeting_date=meeting.next_meeting_date,
        resolutions=tuple(
            MinutesPdfResolution(
                resolution_no=r.resolution_no,
                decision=r.decision,
                vote_for=r.vote_for,
                vote_against=r.vote_against,
                vote_neutral=r.vote_neutral,
                assigned_to=r.assigned_to.full_name if r.assigned_to else None,
                task=r.task,
                due_date=r.due_date,
                status=r.status,
            )
            for r in sorted(meeting.resolutions, key=lambda r: r.resolution_no)
        ),
        attendance=tuple(
            MinutesPdfAttendance(full_name=e.member.full_name, status=e.status)
            for e in sorted(meeting.attendance, key=lambda e: e.member.full_name)
        ),
    )
    now = datetime.now(_DHAKA)
    filename = f"minutes-{meeting.meeting_no}-{now:%Y%m%d}.pdf"
    return Response(
        content=build_meeting_minutes_pdf(data),
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.get("/resolution-book/recordings/{recording_id}/download")
async def download_recording(
    recording_id: int,
    db: AsyncSession = Depends(get_db),
    _actor: AccountActor = Depends(get_account_actor),
) -> FileResponse:
    recording = (
        await db.execute(select(MeetingRecording).where(MeetingRecording.id == recording_id))
    ).scalar_one_or_none()
    if recording is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording not found.")
    path = settings.upload_root / recording.file_path
    if not path.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File missing on disk.")
    return FileResponse(path, filename=recording.original_name)


# ---------------------------------------------------------------------------
# Committee / admin writes
# ---------------------------------------------------------------------------


async def _resolve_members_exist(db: AsyncSession, member_ids: set[int]) -> None:
    if not member_ids:
        return
    found = (await db.execute(select(Member.id).where(Member.id.in_(member_ids)))).scalars().all()
    missing = member_ids - set(found)
    if missing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown member id(s): {', '.join(str(i) for i in sorted(missing))}",
        )


async def _apply_attendance(db: AsyncSession, meeting: Meeting, entries, *, replace: bool = False) -> None:
    member_ids = {entry.member_id for entry in entries}
    await _resolve_members_exist(db, member_ids)
    if replace:
        for existing in list(meeting.attendance):
            await db.delete(existing)
        await db.flush()
    for entry in entries:
        db.add(
            MeetingAttendance(
                meeting_id=meeting.id,
                member_id=entry.member_id,
                status=entry.status,
            )
        )
    await db.flush()


async def _apply_resolutions(
    db: AsyncSession, meeting: Meeting, resolutions, present: int
) -> None:
    for payload in resolutions:
        total_votes = payload.vote_for + payload.vote_against + payload.vote_neutral
        if total_votes > present:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    f"সিদ্ধান্ত-{payload.decision[:30]}: মোট ভোট ({total_votes}) উপস্থিত সদস্য সংখ্যা ({present}) "
                    f"এর বেশি হতে পারে না। Total votes must not exceed members present ({present})."
                ),
            )
    if resolutions:
        await _resolve_members_exist(db, {r.assigned_to_member_id for r in resolutions if r.assigned_to_member_id})
    for index, payload in enumerate(resolutions, start=1):
        db.add(
            Resolution(
                meeting_id=meeting.id,
                resolution_no=index,
                decision=payload.decision,
                vote_for=payload.vote_for,
                vote_against=payload.vote_against,
                vote_neutral=payload.vote_neutral,
                assigned_to_member_id=payload.assigned_to_member_id,
                task=payload.task,
                due_date=payload.due_date,
                status=payload.status,
            )
        )
    await db.flush()


async def _audit_and_notice(
    db: AsyncSession,
    admin: AdminUser,
    meeting: Meeting,
    action: str,
    detail: str,
    *,
    notify: bool,
    notice_body: str | None = None,
    title: str | None = None,
) -> None:
    record_audit(
        db,
        actor_admin_id=admin.id,
        action=action,
        entity_type="meeting",
        entity_id=str(meeting.id),
        detail=_short(detail),
    )
    if notify:
        await publish_resolution_book_notice(
            db, admin, title=title or new_meeting_notice_title(meeting), body=notice_body or ""
        )


@router.post("/resolution-book/meetings", response_model=MeetingDetailOut, status_code=status.HTTP_201_CREATED)
async def create_meeting(
    payload: MeetingCreate,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_resolution_book")),
) -> MeetingDetailOut:
    """Atomic create: meeting + attendance + resolutions land in one
    transaction - a failed validation leaves no partial meeting behind."""
    meeting_no = payload.meeting_no or await next_meeting_no(db, payload.date)
    if await meeting_no_taken(db, meeting_no):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f'সভা নম্বর "{meeting_no}" ইতিমধ্যে ব্যবহৃত হয়েছে। Meeting number already exists.',
        )
    member_ids = {entry.member_id for entry in payload.attendance}
    if payload.chairperson_member_id:
        member_ids.add(payload.chairperson_member_id)
    await _resolve_members_exist(db, member_ids)

    meeting = Meeting(
        meeting_no=meeting_no,
        date=payload.date,
        time=payload.time,
        meeting_type=payload.meeting_type,
        chairperson=payload.chairperson,
        chairperson_member_id=payload.chairperson_member_id,
        agenda=payload.agenda,
        summary=payload.summary,
        next_meeting_date=payload.next_meeting_date,
        status=payload.status,
        created_by=admin.id,
    )
    db.add(meeting)
    await db.flush()

    present = sum(1 for entry in payload.attendance if entry.status == ATTENDANCE_PRESENT)
    await _apply_attendance(db, meeting, payload.attendance)
    await _apply_resolutions(db, meeting, payload.resolutions, present)

    record_audit(
        db,
        actor_admin_id=admin.id,
        action="meeting.create",
        entity_type="meeting",
        entity_id=str(meeting.id),
        detail=f"{meeting.meeting_no} ({payload.date}) resolutions={len(payload.resolutions)} present={present}",
    )
    if payload.notify:
        body_lines = [
            f"সভা নম্বর: {meeting.meeting_no}",
            f"তারিখ: {meeting.date.strftime('%d-%m-%Y')}",
            f"গৃহীত সিদ্ধান্ত: {bn_digits(len(payload.resolutions))} টি",
            "সম্পূর্ণ কার্যবিবরণী দেখতে লগইন করে 'রেজোলিউশন বুক' পেজটি দেখুন।",
        ]
        await publish_resolution_book_notice(
            db,
            admin,
            title=new_meeting_notice_title(meeting),
            body="\n".join(body_lines),
        )
    meeting_id_value = meeting.id
    admin_name = admin.name
    await db.commit()
    db.expire_all()
    meeting = await load_meeting(db, meeting_id_value)
    return MeetingDetailOut(**meeting_detail_dict(meeting, created_by_name=admin_name))


@router.put("/resolution-book/meetings/{meeting_id}", response_model=MeetingDetailOut)
async def update_meeting(
    meeting_id: int,
    payload: MeetingUpdate,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_resolution_book")),
) -> MeetingDetailOut:
    meeting = await load_meeting(db, meeting_id)
    post_cutoff = await edit_cutoff_exceeded(meeting)
    sent = payload.model_fields_set
    changes: list[str] = []
    for field in (
        "date",
        "time",
        "meeting_type",
        "chairperson",
        "chairperson_member_id",
        "agenda",
        "summary",
        "next_meeting_date",
        "status",
    ):
        if field in sent and getattr(payload, field) != getattr(meeting, field):
            changes.append(field)
            setattr(meeting, field, getattr(payload, field))
    if not changes:
        return MeetingDetailOut(**meeting_detail_dict(meeting))

    record_audit(
        db,
        actor_admin_id=admin.id,
        action="meeting.update" + ("_correction" if post_cutoff else ""),
        entity_type="meeting",
        entity_id=str(meeting.id),
        detail=(
            f"{'POST-CUTOFF CORRECTION by ' if post_cutoff else ''}"
            f"{meeting.meeting_no}: {', '.join(changes)}"
        ),
    )
    if "next_meeting_date" in changes and payload.next_meeting_date:
        await publish_resolution_book_notice(
            db,
            admin,
            title=next_meeting_notice_title(meeting),
            body=f"{meeting.meeting_no} এর পরবর্তী সভা নির্ধারিত হয়েছে: "
            f"{payload.next_meeting_date.strftime('%d-%m-%Y')}",
        )
    meeting_id_value = meeting.id
    admin_name = admin.name
    await db.commit()
    db.expire_all()
    meeting = await load_meeting(db, meeting_id_value)
    return MeetingDetailOut(**meeting_detail_dict(meeting, created_by_name=admin_name))


@router.post("/resolution-book/meetings/{meeting_id}/attendance", response_model=MeetingDetailOut)
async def bulk_attendance(
    meeting_id: int,
    payload: AttendanceBulkIn,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_resolution_book")),
) -> MeetingDetailOut:
    meeting = await load_meeting(db, meeting_id)
    await _apply_attendance(db, meeting, payload.entries, replace=True)
    total = len(payload.entries)
    present = sum(1 for e in payload.entries if e.status == ATTENDANCE_PRESENT)
    # Attendance shrinks the vote ceiling: existing tallies are re-validated.
    for resolution in meeting.resolutions:
        validate_votes(present, resolution.vote_for, resolution.vote_against, resolution.vote_neutral)
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="meeting.attendance",
        entity_type="meeting",
        entity_id=str(meeting.id),
        detail=f"{meeting.meeting_no}: present={present}/{total} ({len(payload.entries)} entries written)",
    )
    meeting_id_value = meeting.id
    admin_name = admin.name
    await db.commit()
    db.expire_all()
    meeting = await load_meeting(db, meeting_id_value)
    return MeetingDetailOut(**meeting_detail_dict(meeting, created_by_name=admin_name))


@router.post("/resolution-book/meetings/{meeting_id}/resolutions", response_model=MeetingDetailOut, status_code=status.HTTP_201_CREATED)
async def add_resolution(
    meeting_id: int,
    payload: ResolutionCreate,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_resolution_book")),
) -> MeetingDetailOut:
    meeting = await load_meeting(db, meeting_id)
    validate_votes(present_count(meeting), payload.vote_for, payload.vote_against, payload.vote_neutral)
    if payload.assigned_to_member_id:
        await _resolve_members_exist(db, {payload.assigned_to_member_id})
    next_no = max((r.resolution_no for r in meeting.resolutions), default=0) + 1
    resolution = Resolution(
        meeting_id=meeting.id,
        resolution_no=next_no,
        decision=payload.decision,
        vote_for=payload.vote_for,
        vote_against=payload.vote_against,
        vote_neutral=payload.vote_neutral,
        assigned_to_member_id=payload.assigned_to_member_id,
        task=payload.task,
        due_date=payload.due_date,
        status=payload.status,
    )
    db.add(resolution)
    await db.flush()
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="resolution.create",
        entity_type="resolution",
        entity_id=str(resolution.id),
        detail=f"{meeting.meeting_no}/সিদ্ধান্ত-{next_no}: {_short(payload.decision)}",
    )
    meeting_id_value = meeting.id
    admin_name = admin.name
    await db.commit()
    db.expire_all()
    meeting = await load_meeting(db, meeting_id_value)
    return MeetingDetailOut(**meeting_detail_dict(meeting, created_by_name=admin_name))


@router.put("/resolution-book/resolutions/{resolution_id}", response_model=ResolutionStatusUpdateOut)
async def update_resolution(
    resolution_id: int,
    payload: ResolutionUpdate,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_resolution_book")),
) -> ResolutionStatusUpdateOut:
    resolution = (
        await db.execute(
            select(Resolution)
            .where(Resolution.id == resolution_id)
            .options(selectinload(Resolution.assigned_to))
        )
    ).scalar_one_or_none()
    if resolution is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resolution not found.")
    meeting = await load_meeting(db, resolution.meeting_id)
    post_cutoff = await edit_cutoff_exceeded(meeting)

    sent = payload.model_fields_set
    changes: list[str] = []
    if payload.decision is not None and payload.decision != resolution.decision:
        resolution.decision = payload.decision
        changes.append("decision")
    votes_changed = False
    for field in ("vote_for", "vote_against", "vote_neutral"):
        if field in sent and getattr(payload, field) != getattr(resolution, field):
            setattr(resolution, field, getattr(payload, field))
            changes.append(field)
            votes_changed = True
    if votes_changed:
        validate_votes(present_count(meeting), resolution.vote_for, resolution.vote_against, resolution.vote_neutral)
    for field in ("assigned_to_member_id", "task", "due_date", "status"):
        if field in sent and getattr(payload, field) != getattr(resolution, field):
            setattr(resolution, field, getattr(payload, field))
            changes.append(field)

    if not changes:
        return ResolutionStatusUpdateOut(
            resolution=ResolutionOut(**resolution_to_dict(resolution))
        )

    record_audit(
        db,
        actor_admin_id=admin.id,
        action="resolution.update" + ("_correction" if post_cutoff else ""),
        entity_type="resolution",
        entity_id=str(resolution.id),
        detail=(
            f"{'POST-CUTOFF CORRECTION: ' if post_cutoff else ''}"
            f"{meeting.meeting_no}/সিদ্ধান্ত-{resolution.resolution_no}: {', '.join(changes)}"
        ),
    )
    if payload.status == RESOLUTION_STATUS_DONE and resolution.status == RESOLUTION_STATUS_DONE:
        await publish_resolution_book_notice(
            db,
            admin,
            title=resolution_done_notice_title(meeting, resolution),
            body=f"সিদ্ধান্ত: {_short(resolution.decision)}\n"
            "বিস্তারিত দেখতে লগইন করে 'রেজোলিউশন বুক' পেজটি দেখুন।",
        )
    await db.commit()
    await db.refresh(resolution)
    return ResolutionStatusUpdateOut(resolution=ResolutionOut(**resolution_to_dict(resolution)))


@router.post("/resolution-book/meetings/{meeting_id}/recordings", response_model=RecordingOut, status_code=status.HTTP_201_CREATED)
async def upload_recording(
    meeting_id: int,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_resolution_book")),
) -> RecordingOut:
    meeting = await load_meeting(db, meeting_id)
    file_path, original_name, size, file_type = await _save_recording(file, meeting.meeting_no)
    if file_type not in RECORDING_TYPES:
        file_type = RECORDING_CHAT_LOG
    recording = MeetingRecording(
        meeting_id=meeting.id,
        file_path=file_path,
        original_name=original_name,
        file_type=file_type,
        file_size=size,
        uploaded_by=admin.id,
    )
    db.add(recording)
    await db.flush()
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="recording.create",
        entity_type="meeting_recording",
        entity_id=str(recording.id),
        detail=f"{meeting.meeting_no}: {original_name} ({file_type}, {size} bytes)",
    )
    await db.commit()
    await db.refresh(recording)
    return RecordingOut(
        id=recording.id,
        meeting_id=recording.meeting_id,
        original_name=recording.original_name,
        file_type=recording.file_type,
        file_size=recording.file_size,
        uploaded_by=admin.name,
        uploaded_at=recording.uploaded_at,
    )
