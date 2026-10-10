"""Member-facing land-record endpoints backed by the local dataset.

Serves the ingested BDS mouza map (geometry + dag numbers only — the source
layer contains no personal data) through our own authenticated API, with the
same guards as the plot-map feature: approved members only, bbox required,
result caps, rate limiting. No outbound network calls.
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
from app.services.audit import record_audit
from app.services.land_data import (
    LandDataProvider,
    get_land_data_provider,
)
from app.api.routes.plot_map import _parse_bbox

router = APIRouter(prefix="/land", tags=["land"])

VIEW_PERMISSION = "boundary.view"

logger = logging.getLogger(__name__)
_settings = get_settings()
_detail_limiter = SlidingWindowRateLimiter(
    max_requests=_settings.dag_detail_rate_limit,
    window_seconds=_settings.dag_detail_rate_window_seconds,
)


def _enforce_detail_rate_limit(member_id: int) -> None:
    retry_after = _detail_limiter.check(member_id)
    if retry_after is None:
        return
    logger.warning("Dag detail rate limit reached by member_id=%s", member_id)
    raise HTTPException(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        detail={
            "code": "DAG_DETAIL_RATE_LIMITED",
            "message": "Too many dag lookups. Please try again later.",
        },
        headers={"Retry-After": str(max(1, math.ceil(retry_after)))},
    )


def _approved(member: Member) -> Member:
    if member.status != MemberStatus.APPROVED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "APPROVED_MEMBERS_ONLY", "message": "Approved members only."},
        )
    return member


@router.get("/meta")
def get_land_meta(
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
    provider: LandDataProvider = Depends(get_land_data_provider),
) -> dict:
    """Dataset provenance, survey availability, counts. No checksums."""
    _approved(member)
    return provider.dataset_meta()


@router.get("/sheets")
def get_land_sheets(
    survey: str = Query(..., description="e.g. 'bds'"),
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
    provider: LandDataProvider = Depends(get_land_data_provider),
) -> dict:
    _approved(member)
    sheets = provider.list_sheets(survey)
    if not sheets:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "SURVEY_NOT_FOUND", "message": f"No sheets for survey '{survey}'."},
        )
    return {"survey": survey, "sheets": sheets}


@router.get("/dags")
def get_dags_in_bbox(
    bbox: str = Query(..., description="minLng,minLat,maxLng,maxLat"),
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
    provider: LandDataProvider = Depends(get_land_data_provider),
) -> dict:
    """Dag polygons (number + geometry only) whose centroid falls in the bbox."""
    _approved(member)
    viewport = _parse_bbox(bbox)
    cap = get_settings().land_map_result_cap
    features = provider.features_in_bbox(viewport, limit=cap + 1)
    truncated = len(features) > cap
    return {
        "type": "FeatureCollection",
        "count": min(len(features), cap),
        "truncated": truncated,
        "features": features[:cap],
    }


@router.get("/dag/{survey}/lookup/{dag_no}")
def lookup_dag(
    survey: str,
    dag_no: str,
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
    provider: LandDataProvider = Depends(get_land_data_provider),
) -> dict:
    """Find every sheet containing a dag number (accepts Bangla digits).

    Declared before the /dag/{survey}/{sheet}/{dag} catch-all — FastAPI matches
    in declaration order, so "lookup" would otherwise be read as a sheet name.
    """
    _approved(member)
    features = provider.find_dags(survey, dag_no)
    return {"type": "FeatureCollection", "count": len(features), "features": features}


@router.get("/dag/{survey}/{sheet}/{dag}")
async def get_dag_details(
    survey: str,
    sheet: str,
    dag: str,
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
    provider: LandDataProvider = Depends(get_land_data_provider),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Land details + khatian/owner rows for one dag (the official-style dialog).

    The only door to owner names: one dag per call, approved members only,
    rate-limited and audited. There is deliberately no list/search/export.
    """
    _approved(member)
    _enforce_detail_rate_limit(member.id)
    details = provider.get_dag_details(survey, sheet, dag)
    if details is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "code": "DAG_NOT_FOUND",
                "message": f"No dag {dag} on sheet {sheet} of survey '{survey}' in the local dataset.",
            },
        )
    record_audit(
        db,
        actor_admin_id=None,
        action="land.dag_detail_lookup",
        entity_type="land_dag",
        entity_id=f"{details['survey']}:{details['sheet']}:{details['dag']}",
        detail=f"viewer_member_id={member.id}",
    )
    await db.commit()
    return details


@router.get("/masterplan")
def get_masterplan_in_bbox(
    bbox: str = Query(..., description="minLng,minLat,maxLng,maxLat"),
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
    provider: LandDataProvider = Depends(get_land_data_provider),
) -> dict:
    """RAJUK DAP 2022–2035 RS-plot overlay (ingested once at deploy time)."""
    _approved(member)
    viewport = _parse_bbox(bbox)
    cap = get_settings().land_map_result_cap
    features = provider.masterplan_features_in_bbox(viewport, limit=cap + 1)
    return {
        "type": "FeatureCollection",
        "count": min(len(features), cap),
        "truncated": len(features) > cap,
        "features": features[:cap],
    }


@router.get("/masterplan/lookup/{rs_plot_no}")
def lookup_masterplan_plot(
    rs_plot_no: str,
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
    provider: LandDataProvider = Depends(get_land_data_provider),
) -> dict:
    """Find every RS plot with this number (accepts "RS-4611", "4611", Bangla digits)."""
    _approved(member)
    features = provider.masterplan_find(rs_plot_no)
    return {"type": "FeatureCollection", "count": len(features), "features": features}


__all__ = ["router"]
