import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, JSON, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class PropertyChangeAction(str, enum.Enum):
    ADD = "add"
    EDIT = "edit"
    DELETE = "delete"


class PropertyChangeStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    CANCELLED = "cancelled"


class PropertyChangeRequest(Base):
    """A member-submitted add/edit/delete request against one of their
    properties. Nothing touches the `properties` table until an admin
    approves; a cancelled request keeps the reason the member sees."""

    __tablename__ = "property_change_requests"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    member_id: Mapped[int] = mapped_column(
        ForeignKey("members.id", ondelete="CASCADE"), nullable=False, index=True
    )
    # Null for `add` requests (the property does not exist yet); for edit and
    # delete it pins the exact row the request applies to.
    property_id: Mapped[int | None] = mapped_column(
        ForeignKey("properties.id", ondelete="SET NULL"), nullable=True, index=True
    )
    action: Mapped[PropertyChangeAction] = mapped_column(
        Enum(PropertyChangeAction, name="property_change_action"), nullable=False
    )
    # PropertyRequestPayload snapshot: scalar fields, co_owners and the final
    # desired docs list (doc_type + file_path; new uploads are saved to disk
    # at request time and recorded here).
    payload: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    status: Mapped[PropertyChangeStatus] = mapped_column(
        Enum(PropertyChangeStatus, name="property_change_status"),
        default=PropertyChangeStatus.PENDING,
        nullable=False,
        index=True,
    )
    cancel_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    reviewed_by: Mapped[int | None] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    member: Mapped["Member"] = relationship()
    reviewer: Mapped["AdminUser | None"] = relationship()


from app.models.member import Member  # noqa: E402
from app.models.admin import AdminUser  # noqa: E402
