from datetime import date, datetime, time as dt_time

from sqlalchemy import Date, DateTime, ForeignKey, Index, Integer, String, Text, Time, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

# Plain-string vocabularies (not native enums) so a new value never needs a
# migration - same rationale as roadmap / financial_transactions.
MEETING_TYPE_ONLINE = "online"
MEETING_TYPE_OFFLINE = "offline"
MEETING_TYPES = (MEETING_TYPE_ONLINE, MEETING_TYPE_OFFLINE)

MEETING_STATUS_SCHEDULED = "scheduled"
MEETING_STATUS_COMPLETED = "completed"
MEETING_STATUS_CANCELLED = "cancelled"
MEETING_STATUSES = (MEETING_STATUS_SCHEDULED, MEETING_STATUS_COMPLETED, MEETING_STATUS_CANCELLED)

RESOLUTION_STATUS_PENDING = "pending"
RESOLUTION_STATUS_IN_PROGRESS = "in_progress"
RESOLUTION_STATUS_DONE = "done"
RESOLUTION_STATUSES = (RESOLUTION_STATUS_PENDING, RESOLUTION_STATUS_IN_PROGRESS, RESOLUTION_STATUS_DONE)

ATTENDANCE_PRESENT = "present"
ATTENDANCE_ABSENT = "absent"
ATTENDANCE_STATUSES = (ATTENDANCE_PRESENT, ATTENDANCE_ABSENT)

RECORDING_VIDEO = "video"
RECORDING_AUDIO = "audio"
RECORDING_SCREENSHOT = "screenshot"
RECORDING_CHAT_LOG = "chat_log"
RECORDING_TYPES = (RECORDING_VIDEO, RECORDING_AUDIO, RECORDING_SCREENSHOT, RECORDING_CHAT_LOG)


class Meeting(Base):
    """One recorded sitting of the society (অনলাইন রেজোলিউশন বুক)."""

    __tablename__ = "meetings"
    __table_args__ = (
        Index("ix_meetings_date", "date"),
        Index("ix_meetings_status_date", "status", "date"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    meeting_no: Mapped[str] = mapped_column(String(32), unique=True, nullable=False)
    date: Mapped[date] = mapped_column(Date, nullable=False)
    time: Mapped[dt_time | None] = mapped_column(Time, nullable=True)
    meeting_type: Mapped[str] = mapped_column(String(16), nullable=False, default=MEETING_TYPE_ONLINE)
    chairperson: Mapped[str] = mapped_column(String(255), nullable=False)
    chairperson_member_id: Mapped[int | None] = mapped_column(
        ForeignKey("members.id", ondelete="SET NULL"), nullable=True
    )
    agenda: Mapped[str] = mapped_column(Text, nullable=False)
    summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    next_meeting_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default=MEETING_STATUS_COMPLETED)
    created_by: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    resolutions = relationship("Resolution", back_populates="meeting", lazy="selectin")
    attendance = relationship("MeetingAttendance", back_populates="meeting", lazy="selectin")
    recordings = relationship("MeetingRecording", back_populates="meeting", lazy="selectin")


class Resolution(Base):
    """A decision taken in a meeting, with its vote tally and optional action item."""

    __tablename__ = "resolutions"
    __table_args__ = (
        Index("ix_resolutions_meeting_no", "meeting_id", "resolution_no", unique=True),
        Index("ix_resolutions_status", "status"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    meeting_id: Mapped[int] = mapped_column(ForeignKey("meetings.id", ondelete="CASCADE"), nullable=False)
    resolution_no: Mapped[int] = mapped_column(Integer, nullable=False)
    decision: Mapped[str] = mapped_column(Text, nullable=False)
    vote_for: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    vote_against: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    vote_neutral: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    assigned_to_member_id: Mapped[int | None] = mapped_column(
        ForeignKey("members.id", ondelete="SET NULL"), nullable=True
    )
    task: Mapped[str | None] = mapped_column(Text, nullable=True)
    due_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default=RESOLUTION_STATUS_PENDING)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    meeting = relationship("Meeting", back_populates="resolutions")
    assigned_to = relationship("Member", lazy="joined")


class MeetingAttendance(Base):
    """One member's present/absent record for one meeting."""

    __tablename__ = "meeting_attendance"
    __table_args__ = (
        Index("ix_meeting_attendance_meeting_member", "meeting_id", "member_id", unique=True),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    meeting_id: Mapped[int] = mapped_column(ForeignKey("meetings.id", ondelete="CASCADE"), nullable=False)
    member_id: Mapped[int] = mapped_column(ForeignKey("members.id", ondelete="CASCADE"), nullable=False)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default=ATTENDANCE_ABSENT)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    meeting = relationship("Meeting", back_populates="attendance")
    member = relationship("Member", lazy="joined")


class MeetingRecording(Base):
    """An attachment (video/audio/screenshot/chat log) of a meeting, stored on
    the shared upload disk but served only through the authenticated
    download endpoint - never via the public /uploads mount."""

    __tablename__ = "meeting_recordings"
    __table_args__ = (Index("ix_meeting_recordings_meeting", "meeting_id"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    meeting_id: Mapped[int] = mapped_column(ForeignKey("meetings.id", ondelete="CASCADE"), nullable=False)
    file_path: Mapped[str] = mapped_column(String(512), nullable=False)
    original_name: Mapped[str] = mapped_column(String(255), nullable=False)
    file_type: Mapped[str] = mapped_column(String(16), nullable=False)
    file_size: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    uploaded_by: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    uploaded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    meeting = relationship("Meeting", back_populates="recordings")
