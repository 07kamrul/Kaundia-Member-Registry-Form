"""Proxies for official external map data shown on the plot boundary map.

Two upstream sources, both fetched server-side because they send no CORS
headers and one of them keeps its access token in a browser-only app config:

- BDS mouza map (settlement.gov.bd): per-sheet GeoJSON via
  ``POST /Khatian/GetSheetJsonBySurvey``. Uttar Kaundia's constants below were
  resolved once from the site's own dropdown cascade and are stable survey
  identifiers, so the whole mouza is fetched and cached.
- RAJUK DAP masterplan (masterplan.rajuk.gov.bd): ArcGIS FeatureServer query
  against the RS plot layer, restricted to the Uttar Kaundia mouza and the
  requested viewport. The token is the public API key the RAJUK app itself
  ships in /config.json.
"""

import asyncio
import logging
import time

import httpx
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.routes.plot_map import _parse_bbox
from app.core.permissions import require_member_permission
from app.models.member import Member

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/member/external-maps", tags=["member"])

VIEW_PERMISSION = "boundary.view"

BDS_BASE = "https://settlement.gov.bd"
BDS_SURVEY_RSNUM = "201901"  # BDS 2019 survey
BDS_COMCOD = "4105"  # Dhaka district
BDS_UNITCOD = "010510211"  # Uttar Kaundia mouza, Savar Upazila

RAJUK_BASE = "https://masterplan.rajuk.gov.bd"
RAJUK_FEATURE_LAYER = f"{RAJUK_BASE}/server/rest/services/rajuk_db/Rajuk_dap_db/FeatureServer/0/query"
RAJUK_MOUZA_FILTER = "address_search LIKE '%Uttar Kaundia%'"
# Actual extent of the Uttar Kaundia RS plots (queried once from the layer);
# requests far outside it are answered locally without hitting upstream.
RAJUK_MOUZA_BBOX = (90.3039, 23.7851, 90.3423, 23.8327)

_UPSTREAM_TIMEOUT = httpx.Timeout(30.0)
_CACHE_TTL_SECONDS = 24 * 60 * 60


def _cache_get(key: str):
    entry = _cache.get(key)
    if entry and time.monotonic() - entry[0] < _CACHE_TTL_SECONDS:
        return entry[1]
    return None


def _cache_put(key: str, value) -> None:
    _cache[key] = (time.monotonic(), value)


_cache: dict[str, tuple[float, object]] = {}

_client_lock = asyncio.Lock()
_client: httpx.AsyncClient | None = None


async def _get_client() -> httpx.AsyncClient:
    global _client
    async with _client_lock:
        if _client is None or _client.is_closed:
            # RAJUK's token is referer-bound: without its own Origin the
            # FeatureServer answers "Invalid Token" even with a valid key.
            _client = httpx.AsyncClient(
                timeout=_UPSTREAM_TIMEOUT,
                follow_redirects=True,
                headers={"Referer": f"{RAJUK_BASE}/", "Origin": RAJUK_BASE},
            )
        return _client


async def _fetch_bds_mouza() -> dict:
    cached = _cache_get("bds_mouza")
    if cached is not None:
        return cached

    client = await _get_client()
    try:
        sheets = (
            await client.get(
                f"{BDS_BASE}/Khatian/GetSheetListBySurveyMap",
                params={"comcod": BDS_COMCOD, "rsnum": BDS_SURVEY_RSNUM, "unitcod": BDS_UNITCOD},
            )
        ).json()
        sheet_nos = sorted({s.get("shetnum") for s in sheets or [] if s and s.get("shetnum")})

        async def sheet_geojson(sheet_no: str) -> dict | None:
            resp = await client.post(
                f"{BDS_BASE}/Khatian/GetSheetJsonBySurvey",
                data={
                    "rsnum": BDS_SURVEY_RSNUM,
                    "comcod": BDS_COMCOD,
                    "unitcod": BDS_UNITCOD,
                    "sheetno": sheet_no,
                },
            )
            if resp.status_code != 200 or not resp.text.strip():
                return None
            data = resp.json()
            return data if isinstance(data, dict) and data.get("type") == "FeatureCollection" else None

        results = await asyncio.gather(*(sheet_geojson(s) for s in sheet_nos))
    except httpx.HTTPError as exc:
        logger.warning("BDS upstream fetch failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": "UPSTREAM_UNAVAILABLE", "message": "BDS map service is unavailable."},
        ) from exc

    features = [f for fc in results if fc for f in fc.get("features", [])]
    if not features:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": "UPSTREAM_EMPTY", "message": "No BDS map data for this mouza."},
        )
    mouza: dict = {"type": "FeatureCollection", "features": features}
    _cache_put("bds_mouza", mouza)
    return mouza


@router.get("/bds/mouza")
async def get_bds_mouza(
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
) -> dict:
    """Official BDS mouza plot GeoJSON for Uttar Kaundia (settlement.gov.bd)."""
    return await _fetch_bds_mouza()


async def _rajuk_token(client: httpx.AsyncClient) -> str:
    cached = _cache_get("rajuk_token")
    if cached is not None:
        return cached
    try:
        cfg = (await client.get(f"{RAJUK_BASE}/config.json")).json()
        token = (cfg or {}).get("API_KEY")
    except (httpx.HTTPError, ValueError) as exc:
        logger.warning("RAJUK config fetch failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": "UPSTREAM_UNAVAILABLE", "message": "RAJUK map service is unavailable."},
        ) from exc
    if not token:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": "UPSTREAM_UNAVAILABLE", "message": "RAJUK map service is unavailable."},
        )
    _cache_put("rajuk_token", token)
    return token


def _esri_polygon_to_geojson(geometry: dict | None) -> dict | None:
    if not geometry or "rings" not in geometry:
        return None
    rings = [[pt[:2] for pt in ring] for ring in geometry["rings"]]
    return {"type": "Polygon", "coordinates": rings}


async def _fetch_rajuk_plots(bbox: tuple[float, float, float, float]) -> dict:
    client = await _get_client()
    token = await _rajuk_token(client)
    min_lng, min_lat, max_lng, max_lat = bbox
    params = {
        "f": "json",
        "where": RAJUK_MOUZA_FILTER,
        "geometry": f"{min_lng},{min_lat},{max_lng},{max_lat}",
        "geometryType": "esriGeometryEnvelope",
        "inSR": "4326",
        "spatialRel": "esriSpatialRelIntersects",
        "outFields": "plot_no,rs_plot_no,address_search",
        "outSR": "4326",
        "returnGeometry": "true",
        "resultRecordCount": 3000,
        "token": token,
    }
    try:
        resp = await client.get(RAJUK_FEATURE_LAYER, params=params)
        data = resp.json()
    except httpx.HTTPError as exc:
        logger.warning("RAJUK upstream fetch failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": "UPSTREAM_UNAVAILABLE", "message": "RAJUK map service is unavailable."},
        ) from exc
    if isinstance(data, dict) and data.get("error"):
        logger.warning("RAJUK query error: %s", data["error"])
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": "UPSTREAM_ERROR", "message": "RAJUK map query failed."},
        )

    features = []
    for feat in data.get("features", []):
        geom = _esri_polygon_to_geojson(feat.get("geometry"))
        if geom is None:
            continue
        features.append({"type": "Feature", "properties": feat.get("attributes", {}), "geometry": geom})
    return {"type": "FeatureCollection", "features": features}


@router.get("/rajuk/plots")
async def get_rajuk_plots(
    bbox: str = Query(..., description="minLng,minLat,maxLng,maxLat"),
    member: Member = Depends(require_member_permission(VIEW_PERMISSION)),
) -> dict:
    """RAJUK DAP RS plots for the Uttar Kaundia mouza intersecting the bbox."""
    viewport = _parse_bbox(bbox)
    min_lng, min_lat, max_lng, max_lat = viewport
    mx_lng, mx_lat, my_lng, my_lat = RAJUK_MOUZA_BBOX
    if max_lng < mx_lng or min_lng > my_lng or max_lat < mx_lat or min_lat > my_lat:
        return {"type": "FeatureCollection", "features": []}
    key = "rajuk:%.4f,%.4f,%.4f,%.4f" % viewport
    cached = _cache_get(key)
    if cached is not None:
        return cached
    plots = await _fetch_rajuk_plots(viewport)
    _cache_put(key, plots)
    return plots


__all__ = ["router"]
