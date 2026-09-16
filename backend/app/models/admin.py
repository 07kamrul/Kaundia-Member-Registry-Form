from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import DateTime, Enum, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class AdminRole(str, PyEnum):
    SUPER_ADMIN = "super_admin"
    EXECUTIVE_COMMITTEE = "executive_committee"
    ADMINISTRATOR = "administrator"


class AdminUser(Base):
    __tablename__ = "admin_users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[AdminRole] = mapped_column(
        Enum(AdminRole, name="admin_role", values_callable=lambda enum_cls: [member.value for member in enum_cls]),
        nullable=False,
        default=AdminRole.ADMINISTRATOR,
        server_default=AdminRole.ADMINISTRATOR.value,
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
