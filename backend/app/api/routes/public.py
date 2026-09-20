from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.member import Member, MemberStatus
from app.schemas.public import PublicStatsOut

router = APIRouter(prefix="/public", tags=["public"])


def _parse_amount(value: str | None) -> float:
    if not value:
        return 0
    try:
        return float(value)
    except ValueError:
        return 0


@router.get("/stats", response_model=PublicStatsOut)
async def get_public_stats(db: AsyncSession = Depends(get_db)) -> PublicStatsOut:
    pending_count = await db.scalar(
        select(func.count()).select_from(Member).where(Member.status == MemberStatus.PENDING)
    )
    approved_count = await db.scalar(
        select(func.count()).select_from(Member).where(Member.status == MemberStatus.APPROVED)
    )

    approved_subscriptions = await db.scalars(
        select(Member.subscription).where(Member.status == MemberStatus.APPROVED)
    )
    monthly_subscription_total = sum(_parse_amount(value) for value in approved_subscriptions)

    return PublicStatsOut(
        pending_count=pending_count or 0,
        approved_count=approved_count or 0,
        monthly_subscription_total=monthly_subscription_total,
    )
