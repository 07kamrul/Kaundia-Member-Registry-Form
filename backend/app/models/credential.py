from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class MemberCredential(Base):
    __tablename__ = "member_credentials"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    member_id: Mapped[int] = mapped_column(
        ForeignKey("members.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    username: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    must_change_password: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    member: Mapped["Member"] = relationship(back_populates="credential")


from app.models.member import Member  # noqa: E402
