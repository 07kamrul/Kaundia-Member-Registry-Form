"""Member-facing land-record endpoints backed by the local dataset.

Serves the ingested BDS mouza map (geometry + dag numbers only — the source
layer contains no personal data) through our own authenticated API, with the
same guards as the plot-map feature: approved members only, bbox required,
result caps, rate limiting. No outbound network calls.
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.config import get_settings
from app.core.permissions import require_member_permission
from app.models.member import Member, MemberStatus
from app.services.land_data import (
    LandDataProvider,
    get_land_data_provider,
)
from app.api.routes.plot_map import _parse_bbox

router = APIRouter(prefix="/land", tags=["land"])

VIEW_PERMISSION = "boundary.view"


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


@router.get("/dag/{survey}/{sheet}/{dag}")
def get_single_dag(
    survey: str,
    sheet: str,
    dag: str,
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
    provider: LandDataProvider = Depends(get_land_data_provider),
) -> dict:
    _approved(member)
    feature = provider.get_dag(survey, sheet, dag)
    if feature is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "DAG_NOT_FOUND", "message": "No such dag in the local dataset."},
        )
    return feature


@router.get("/dag/{survey}/lookup/{dag_no}")
def lookup_dag(
    survey: str,
    dag_no: str,
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
    provider: LandDataProvider = Depends(get_land_data_provider),
) -> dict:
    """Find every sheet containing a dag number (accepts Bangla digits)."""
    _approved(member)
    features = provider.find_dags(survey, dag_no)
    return {"type": "FeatureCollection", "count": len(features), "features": features}


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


__all__ = ["router"]
