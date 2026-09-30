from sqlalchemy import Integer
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class MemberIdSequence(Base):
    """Single-row global counter behind the UKAMKS-N member id format.

    The row is locked (SELECT ... FOR UPDATE) when a new id is minted, so
    concurrent approvals cannot draw the same value. Values are never reused:
    the counter only moves forward, even if a member is later deleted.
    """

    __tablename__ = "member_id_sequence"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, default=1)
    value: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
