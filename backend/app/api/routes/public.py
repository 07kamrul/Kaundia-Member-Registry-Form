from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.config_list_item import ConfigListItem
from app.models.fee_settings import FeeSetting
from app.models.member import Member, MemberStatus
from app.schemas.config_list import ConfigListItemOut
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
    # Single pass over two narrow columns. The previous version ran three
    # sequential queries (two COUNTs, then a scan of every approved member's
    # subscription) to produce the same three numbers.
    rows = await db.execute(select(Member.status, Member.subscription))

    pending_count = 0
    approved_count = 0
    monthly_subscription_total = 0.0
    for row_status, subscription in rows:
        if row_status == MemberStatus.APPROVED:
            approved_count += 1
            monthly_subscription_total += _parse_amount(subscription)
        elif row_status == MemberStatus.PENDING:
            pending_count += 1

    return PublicStatsOut(
        pending_count=pending_count,
        approved_count=approved_count,
        monthly_subscription_total=monthly_subscription_total,
    )


@router.get("/fee-settings")
async def get_public_fee_settings(db: AsyncSession = Depends(get_db)) -> dict[str, float]:
    today = date.today()
    result = await db.execute(
        select(FeeSetting.key, FeeSetting.value).where(
            FeeSetting.start_date <= today,
            or_(FeeSetting.end_date.is_(None), FeeSetting.end_date >= today),
        )
    )
    return {key: float(value) for key, value in result.all()}


@router.get("/config-lists/{category}", response_model=list[ConfigListItemOut])
async def get_public_config_list(
    category: str, db: AsyncSession = Depends(get_db)
) -> list[ConfigListItem]:
    result = await db.execute(
        select(ConfigListItem)
        .where(ConfigListItem.category == category, ConfigListItem.is_active == 1)
        .order_by(ConfigListItem.sort_order)
    )
    return list(result.scalars().all())
