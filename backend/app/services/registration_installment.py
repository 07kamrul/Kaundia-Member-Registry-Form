"""Turn the চাঁদা paid with the registration form into a PAID installment so
it shows up in the member's চাঁদার ইতিহাস alongside later payments."""

from datetime import date, datetime, timezone
from decimal import Decimal, InvalidOperation
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.installment import Installment, InstallmentStatus


def parse_registration_paid_at(member: Any) -> datetime:
    """The submission date (ISO ``YYYY-MM-DD``) is when the চাঁদা was paid;
    fall back to the review time, then now, if it is not parseable."""
    try:
        paid_on = date.fromisoformat(str(member.submission_date).strip()[:10])
        return datetime(paid_on.year, paid_on.month, paid_on.day, tzinfo=timezone.utc)
    except (TypeError, ValueError):
        return member.reviewed_at or datetime.now(timezone.utc)


def _parse_amount(raw: Any) -> Decimal | None:
    try:
        amount = Decimal(str(raw).strip())
    except (InvalidOperation, ValueError):
        return None
    return amount if amount.is_finite() and amount > 0 else None


def build_registration_installment(member: Any) -> Installment | None:
    amount = _parse_amount(member.subscription)
    if amount is None:
        return None
    paid_at = parse_registration_paid_at(member)
    return Installment(
        member_id=member.id,
        year=paid_at.year,
        month=paid_at.month,
        amount=amount,
        status=InstallmentStatus.PAID,
        paid_at=paid_at,
    )


async def add_registration_installment(db: AsyncSession, member: Any) -> Installment | None:
    """Stage the registration installment unless that month is already
    recorded (e.g. an admin entered it by hand). Caller commits."""
    installment = build_registration_installment(member)
    if installment is None:
        return None
    existing = await db.execute(
        select(Installment.id).where(
            Installment.member_id == member.id,
            Installment.year == installment.year,
            Installment.month == installment.month,
        )
    )
    if existing.first() is not None:
        return None
    db.add(installment)
    return installment
