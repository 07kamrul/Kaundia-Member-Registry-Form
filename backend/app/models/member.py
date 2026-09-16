import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class MemberStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class Member(Base):
    __tablename__ = "members"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    member_id: Mapped[str | None] = mapped_column(String(32), unique=True, nullable=True, index=True)
    status: Mapped[MemberStatus] = mapped_column(
        Enum(MemberStatus, name="member_status"), default=MemberStatus.PENDING, nullable=False
    )

    # Member info
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    father_or_husband: Mapped[str] = mapped_column(String(255), nullable=False)
    mother: Mapped[str] = mapped_column(String(255), nullable=False)
    dob: Mapped[str] = mapped_column(String(32), nullable=False)
    nationality: Mapped[str] = mapped_column(String(64), nullable=False)
    occupation: Mapped[str] = mapped_column(String(255), nullable=False)
    nid: Mapped[str] = mapped_column(String(64), nullable=False)
    mobile: Mapped[str] = mapped_column(String(32), nullable=False)
    gender: Mapped[str] = mapped_column(String(16), nullable=False)
    email: Mapped[str] = mapped_column(String(255), nullable=False)

    # Address info
    permanent_house: Mapped[str | None] = mapped_column(String(255), nullable=True)
    permanent_road: Mapped[str | None] = mapped_column(String(255), nullable=True)
    permanent_post_office: Mapped[str | None] = mapped_column(String(255), nullable=True)
    permanent_upazila: Mapped[str | None] = mapped_column(String(255), nullable=True)
    permanent_district: Mapped[str | None] = mapped_column(String(255), nullable=True)
    current_house: Mapped[str | None] = mapped_column(String(255), nullable=True)
    current_road: Mapped[str | None] = mapped_column(String(255), nullable=True)
    current_post_office: Mapped[str | None] = mapped_column(String(255), nullable=True)
    current_upazila: Mapped[str | None] = mapped_column(String(255), nullable=True)
    current_district: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # Urgent contact
    urgent_contact_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    urgent_contact_relation: Mapped[str | None] = mapped_column(String(128), nullable=True)
    urgent_contact_mobile: Mapped[str | None] = mapped_column(String(32), nullable=True)
    urgent_contact_address: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Payment
    admission_fee: Mapped[str] = mapped_column(String(32), nullable=False)
    subscription: Mapped[str] = mapped_column(String(32), nullable=False)
    receipt_no: Mapped[str] = mapped_column(String(64), nullable=False)
    payment_method: Mapped[str] = mapped_column(String(64), nullable=False)

    # Signature
    member_signature: Mapped[str | None] = mapped_column(Text, nullable=True)
    submission_date: Mapped[str] = mapped_column(String(32), nullable=False)

    # Photo
    member_photo_path: Mapped[str | None] = mapped_column(String(512), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    reviewed_by: Mapped[int | None] = mapped_column(ForeignKey("admin_users.id"), nullable=True)
    rejection_reason: Mapped[str | None] = mapped_column(Text, nullable=True)

    properties: Mapped[list["Property"]] = relationship(
        back_populates="member", cascade="all, delete-orphan"
    )
    nominees: Mapped[list["Nominee"]] = relationship(
        back_populates="member", cascade="all, delete-orphan"
    )
    credential: Mapped["MemberCredential | None"] = relationship(
        back_populates="member", cascade="all, delete-orphan", uselist=False
    )
    installments: Mapped[list["Installment"]] = relationship(
        back_populates="member", cascade="all, delete-orphan"
    )


from app.models.property import Property  # noqa: E402
from app.models.nominee import Nominee  # noqa: E402
from app.models.credential import MemberCredential  # noqa: E402
from app.models.installment import Installment  # noqa: E402
