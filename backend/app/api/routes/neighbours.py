"""Neighbour plot owner directory for logged-in members.

The lookup is always derived from the caller's own plots (the JWT member id).
There is deliberately no parameter naming another member, plot or dag, so the
endpoint cannot be used to enumerate the society, and no export path: this
JSON response is the only way the data leaves the server.
"""

import logging
import math

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.permissions import require_member_permission
from app.core.rate_limit import SlidingWindowRateLimiter
from app.db.session import get_db
from app.models.member import Member, MemberStatus
from app.schemas.neighbour import NeighbourDirectoryOut
from app.services.audit import record_audit
from app.services.neighbour_ranking import DagType
from app.services.neighbours import describe_lookup, find_member_neighbours

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/member", tags=["member"])

NEIGHBOUR_PERMISSION = "neighbour.view"

_settings = get_settings()
_lookup_limiter = SlidingWindowRateLimiter(
    max_requests=_settings.neighbour_lookup_rate_limit,
    window_seconds=_settings.neighbour_lookup_rate_window_seconds,
)


def _require_approved(member: Member) -> None:
    if member.status != MemberStatus.APPROVED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": "NEIGHBOUR_DIRECTORY_APPROVED_ONLY",
                "message": "The neighbour directory is available to approved members only.",
            },
        )


def _enforce_lookup_rate_limit(member_id: int) -> None:
    retry_after = _lookup_limiter.check(member_id)
    if retry_after is None:
        return
    logger.warning("Neighbour lookup rate limit reached by member_id=%s", member_id)
    raise HTTPException(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        detail={
            "code": "NEIGHBOUR_LOOKUP_RATE_LIMITED",
            "message": "Too many neighbour lookups. Please try again later.",
        },
        headers={"Retry-After": str(max(1, math.ceil(retry_after)))},
    )


@router.get("/neighbours", response_model=NeighbourDirectoryOut)
async def get_my_neighbours(
    dag_type: DagType | None = Query(
        default=None, description="rs or cs; defaults to the type the member's own plots carry"
    ),
    member: Member = Depends(require_member_permission(NEIGHBOUR_PERMISSION)),
    db: AsyncSession = Depends(get_db),
) -> NeighbourDirectoryOut:
    _require_approved(member)
    _enforce_lookup_rate_limit(member.id)

    directory = await find_member_neighbours(
        db,
        member_id=member.id,
        dag_type=dag_type,
        plot_limit=get_settings().neighbour_plot_limit,
    )
    record_audit(
        db,
        actor_admin_id=None,
        action="neighbour.lookup",
        entity_type="member",
        entity_id=str(member.id),
        detail=describe_lookup(directory),
    )
    await db.commit()
    return NeighbourDirectoryOut.from_directory(directory)
