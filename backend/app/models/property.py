from sqlalchemy import ForeignKey, Integer, JSON, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Property(Base):
    __tablename__ = "properties"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    member_id: Mapped[int] = mapped_column(ForeignKey("members.id", ondelete="CASCADE"), nullable=False)

    property_type: Mapped[list] = mapped_column(JSON, default=list, nullable=False)
    property_type_other: Mapped[str | None] = mapped_column(String(255), nullable=True)
    khatian_no: Mapped[str | None] = mapped_column(String(128), nullable=True)
    dag_no_cs: Mapped[str | None] = mapped_column(String(128), nullable=True)
    dag_no_rs: Mapped[str | None] = mapped_column(String(128), nullable=True)
    holding_number: Mapped[str | None] = mapped_column(String(128), nullable=True)
    land_quantity: Mapped[str | None] = mapped_column(String(128), nullable=True)
    ownership: Mapped[str | None] = mapped_column(String(32), nullable=True)

    member: Mapped["Member"] = relationship(back_populates="properties")
    co_owners: Mapped[list["CoOwner"]] = relationship(
        back_populates="property", cascade="all, delete-orphan"
    )
    applicable_docs: Mapped[list["ApplicableDoc"]] = relationship(
        back_populates="property", cascade="all, delete-orphan"
    )


class CoOwner(Base):
    __tablename__ = "co_owners"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    property_id: Mapped[int] = mapped_column(
        ForeignKey("properties.id", ondelete="CASCADE"), nullable=False
    )
    owner_name: Mapped[str] = mapped_column(String(255), nullable=False)
    owner_phone: Mapped[str] = mapped_column(String(32), nullable=False)

    property: Mapped["Property"] = relationship(back_populates="co_owners")


class ApplicableDoc(Base):
    __tablename__ = "applicable_docs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    property_id: Mapped[int] = mapped_column(
        ForeignKey("properties.id", ondelete="CASCADE"), nullable=False
    )
    doc_type: Mapped[str] = mapped_column(String(255), nullable=False)
    file_path: Mapped[str | None] = mapped_column(String(512), nullable=True)

    property: Mapped["Property"] = relationship(back_populates="applicable_docs")


from app.models.member import Member  # noqa: E402
