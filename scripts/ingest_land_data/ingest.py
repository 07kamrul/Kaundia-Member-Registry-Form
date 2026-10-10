#!/usr/bin/env python3
"""One-off ingest of the Uttar Kaundia BDS mouza map into local JSON/GeoJSON.

Dev-only tool — the app never imports this. Fetches every sheet of the mouza
from settlement.gov.bd politely (1 request at a time, delay between requests,
descriptive User-Agent, local raw cache, abort on 403/429), normalizes and
validates the features, and writes the committed dataset under
``data/uttar-kaundia/``.

The source map layer carries only Dag_No per polygon — no owner names, no
khatian numbers, no land class, no area. This script deliberately does not
touch the khatian-detail endpoints that contain third-party personal data.

Run:  python3 ingest.py [--delay 2.0] [--force]
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import time
import unicodedata
from datetime import datetime, timezone
from pathlib import Path

import requests

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
RAW_DIR = PROJECT_ROOT / "data" / "_raw"
# Lives under backend/ so the Docker build context (./backend) bakes the
# dataset into the image via its existing `COPY . .`.
OUT_DIR = PROJECT_ROOT / "backend" / "data" / "uttar-kaundia"
DAGS_DIR = OUT_DIR / "dags"

BASE = "https://settlement.gov.bd"
RSNUM = "201901"  # বি ডি এস (BDS 2019) — the only survey served for this district
COMCOD = "4105"  # Dhaka district
UNITCOD = "010510211"  # Uttar Kaundia mouza, Savar Upazila
SURVEY_KEY = "bds"

# Uttar Kaundia mouza + margin (lng 90.30–90.36, lat 23.78–23.84)
MOUZA_BBOX = (90.2950, 23.7800, 90.3600, 23.8400)

RAJUK_BASE = "https://masterplan.rajuk.gov.bd"
RAJUK_LAYER = RAJUK_BASE + "/server/rest/services/rajuk_db/Rajuk_dap_db/FeatureServer/0/query"
# Uttar Kaundia RS plots: actual extent from the layer (wider than the BDS bbox)
RAJUK_BBOX = (90.2950, 23.7800, 90.3600, 23.8400)

USER_AGENT = (
    "UttarKaundiaSocietyIngest/1.0 (land-record geometry capture for a "
    "residents' society app; contact: committee@uttarkaundia.org; "
    "low-rate, cached, one-off runs)"
)

# Bangla digits ০১২৩৪৫৬৭৮৯ → ASCII
_BN_DIGITS = str.maketrans("০১২৩৪৫৬৭৮৯", "0123456789")


class AbortIngest(Exception):
    """Raised when the source signals we should stop (403/429/blocked)."""


def bn_to_ascii(text: str) -> str:
    return (text or "").translate(_BN_DIGITS).strip()


def _send_with_backoff(session: requests.Session, method: str, url: str,
                       delay: float, cache_path: Path | None = None,
                       **kwargs) -> requests.Response:
    for attempt in range(5):
        time.sleep(delay)
        try:
            resp = session.request(method, url, timeout=45, **kwargs)
        except requests.RequestException:
            if attempt == 4:
                raise
            time.sleep(delay * 2 ** attempt)  # exponential backoff
            continue
        if resp.status_code in (403, 429):
            raise AbortIngest(f"{resp.status_code} from {url} — access is being rate-limited/blocked; aborting.")
        resp.raise_for_status()
        if cache_path is not None:
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            cache_path.write_bytes(resp.content)
        return resp
    raise AbortIngest(f"unreachable: {url}")


def http_get(session: requests.Session, url: str, params: dict | None = None,
             delay: float = 2.0, force: bool = False) -> requests.Response:
    """GET with a file cache under data/_raw so reruns don't refetch."""
    cache_key = re.sub(r"[^A-Za-z0-9_.-]+", "_", url.split(BASE)[-1]) + "_" + hashlib.sha1(
        json.dumps(params or {}, sort_keys=True).encode()).hexdigest()[:10] + ".json"
    cache_path = RAW_DIR / cache_key
    if not force and cache_path.exists():
        resp = requests.Response()
        resp.status_code = 200
        resp._content = cache_path.read_bytes()
        return resp
    return _send_with_backoff(session, "GET", url, delay, cache_path=cache_path, params=params)


def http_post_form(session: requests.Session, url: str, data: dict,
                   delay: float = 2.0, force: bool = False) -> dict:
    cache_key = re.sub(r"[^A-Za-z0-9_.-]+", "_", url.split(BASE)[-1]) + "_" + hashlib.sha1(
        json.dumps(data, sort_keys=True).encode()).hexdigest()[:10] + ".json"
    cache_path = RAW_DIR / cache_key
    cached = cache_path.read_text() if cache_path.exists() else ""
    if not force and cached.strip():
        return json.loads(cached)
    resp = _send_with_backoff(session, "POST", url, delay, cache_path=cache_path, data=data)
    if not resp.text.strip():
        # Sheets without geometry answer with an empty body — not a block.
        return {}
    return resp.json()


def fetch_sheets(session: requests.Session, delay: float, force: bool) -> list[dict]:
    data = http_get(session, f"{BASE}/Khatian/GetSheetListBySurveyMap",
                    params={"comcod": COMCOD, "rsnum": RSNUM, "unitcod": UNITCOD},
                    delay=delay, force=force).json()
    sheets = sorted({s["shetnum"] for s in data if s.get("shetnum")})
    return sheets


def fetch_sheet_geojson(session: requests.Session, sheet: str,
                        delay: float, force: bool) -> dict | None:
    data = http_post_form(session, f"{BASE}/Khatian/GetSheetJsonBySurvey",
                          data={"rsnum": RSNUM, "comcod": COMCOD,
                                "unitcod": UNITCOD, "sheetno": sheet},
                          delay=delay, force=force)
    if isinstance(data, dict) and data.get("type") == "FeatureCollection":
        return data
    return None


def ring_area_sqm(ring: list[list[float]]) -> float:
    """Approximate planar area (square metres) on a local equirectangular
    projection — good enough for a sanity range check, not for records."""
    if len(ring) < 3:
        return 0.0
    lat0 = sum(p[1] for p in ring) / len(ring)
    m_per_deg_lat = 111_320.0
    m_per_deg_lng = 111_320.0 * _cos_deg(lat0)
    shoelace = 0.0
    for (x1, y1), (x2, y2) in zip(ring, ring[1:] + ring[:1]):
        shoelace += (x1 * m_per_deg_lng) * (y2 * m_per_deg_lat) - (x2 * m_per_deg_lng) * (y1 * m_per_deg_lat)
    return abs(shoelace) / 2.0


def _cos_deg(deg: float) -> float:
    import math
    return math.cos(math.radians(deg))


def validate_feature(feature: dict, sheet: str, errors: list[str]) -> dict | None:
    geom = feature.get("geometry")
    dag = bn_to_ascii(str(feature.get("properties", {}).get("Dag_No", "")))
    if not dag:
        errors.append(f"sheet {sheet}: feature without Dag_No dropped")
        return None
    if not geom or geom.get("type") != "Polygon" or not geom.get("coordinates"):
        errors.append(f"sheet {sheet} dag {dag}: non-polygon geometry dropped")
        return None
    ring = [[round(p[0], 6), round(p[1], 6)] for p in geom["coordinates"][0]]
    if len(ring) < 4:
        errors.append(f"sheet {sheet} dag {dag}: degenerate ring dropped")
        return None
    xs = [p[0] for p in ring]
    ys = [p[1] for p in ring]
    bbox = (min(xs), min(ys), max(xs), max(ys))
    if not (MOUZA_BBOX[0] <= bbox[0] and bbox[2] <= MOUZA_BBOX[2]
            and MOUZA_BBOX[1] <= bbox[1] and bbox[3] <= MOUZA_BBOX[3]):
        errors.append(f"sheet {sheet} dag {dag}: geometry outside mouza bbox dropped")
        return None
    # GeoJSON order check:{lng,lat} — latitudes must be ~7-24, longitudes ~88-93 here
    if not all(20 < p[1] < 28 for p in ring) or not all(86 < p[0] < 94 for p in ring):
        errors.append(f"sheet {sheet} dag {dag}: coordinates look swapped (lat/lng) — dropped")
        return None
    area = sum(ring_area_sqm(r) for r in [geom["coordinates"][0]])
    if area < 1 or area > 500_000:
        errors.append(f"sheet {sheet} dag {dag}: implausible area {area:.0f} sqm dropped")
        return None
    return {
        "type": "Feature",
        "properties": {
            "survey": SURVEY_KEY,
            "sheet": sheet,
            "dag": dag,
            "label_bn": str(feature["properties"].get("Dag_No", "")).strip(),
            "area_sqm": round(area, 1),
        },
        "geometry": {"type": "Polygon", "coordinates": [ring]},
    }


def centroid(feature: dict) -> list[float]:
    ring = feature["geometry"]["coordinates"][0][:-1]
    return [round(sum(p[0] for p in ring) / len(ring), 6),
            round(sum(p[1] for p in ring) / len(ring), 6)]


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--delay", type=float, default=2.0,
                        help="seconds between upstream requests (default 2.0)")
    parser.add_argument("--force", action="store_true",
                        help="refetch even when raw cache exists")
    args = parser.parse_args()

    session = requests.Session()
    session.headers.update({"User-Agent": USER_AGENT})

    sheets = fetch_sheets(session, args.delay, args.force)
    print(f"{len(sheets)} sheets for survey {RSNUM} (BDS)")

    all_features: list[dict] = []
    errors: list[str] = []
    per_sheet: dict[str, list[dict]] = {}

    for i, sheet in enumerate(sheets, 1):
        fc = fetch_sheet_geojson(session, sheet, args.delay, args.force)
        kept = []
        if fc:
            for f in fc.get("features", []):
                v = validate_feature(f, sheet, errors)
                if v:
                    kept.append(v)
        per_sheet[sheet] = kept
        all_features.extend(kept)
        if i % 10 == 0 or i == len(sheets):
            print(f"  sheet {i}/{len(sheets)} — {len(all_features)} dags kept so far")

    seen: set[tuple[str, str, str]] = set()
    duplicates = 0
    for f in all_features:
        key = (f["properties"]["survey"], f["properties"]["sheet"], f["properties"]["dag"])
        if key in seen:
            duplicates += 1
        seen.add(key)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    DAGS_DIR.mkdir(parents=True, exist_ok=True)

    # dags/<survey>/<sheet>.geojson
    old_files = {p for p in DAGS_DIR.rglob("*.geojson")}
    new_files: set[Path] = set()
    for sheet, feats in per_sheet.items():
        out = DAGS_DIR / SURVEY_KEY / f"{sheet}.geojson"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(
            {"type": "FeatureCollection", "features": feats},
            ensure_ascii=False, separators=(",", ":")))
        new_files.add(out)
    for stale in old_files - new_files:
        stale.unlink()

    # dag-index.json
    index: dict[str, dict] = {}
    for f in all_features:
        p = f["properties"]
        index[f"{p['survey']}:{p['sheet']}:{p['dag']}"] = {
            "centroid": centroid(f),
            "area_sqm": p["area_sqm"],
        }
    (OUT_DIR / "dag-index.json").write_text(
        json.dumps(index, ensure_ascii=False, separators=(",", ":")))

    # sheets.json
    (OUT_DIR / "sheets.json").write_text(json.dumps(
        {SURVEY_KEY: sorted(per_sheet)}, ensure_ascii=False, separators=(",", ":")))

    masterplan = fetch_masterplan(session, args.delay, args.force)

    # meta.json with per-file checksums
    committed = [OUT_DIR / "sheets.json", OUT_DIR / "dag-index.json"] + sorted(new_files)
    if (OUT_DIR / "masterplan.geojson").exists():
        committed.append(OUT_DIR / "masterplan.geojson")
    checksums = {str(p.relative_to(OUT_DIR)): sha256_file(p) for p in committed}
    meta = {
        "mouza": "উত্তর কাউন্দিয়া (Uttar Kaundia)",
        "division": {"code": "010000000", "name": "ঢাকা"},
        "district": {"code": "010500000", "comcod": COMCOD, "name": "ঢাকা"},
        "upazila": {"code": "010510000", "name": "সাভার"},
        "unitcod": UNITCOD,
        "surveys": {
            SURVEY_KEY: {
                "rsnum": RSNUM,
                "name_bn": "বি ডি এস",
                "note": ("The portal serves only BDS 2019 for this district. "
                         "CS/SA/RS surveys are not available and no dag "
                         "cross-reference between surveys is provided, so "
                         "member-entered CS/RS dag numbers cannot be matched "
                         "to BDS polygons automatically."),
            }
        },
        "source": {
            "base_url": BASE,
            "endpoints": [
                "GET /Khatian/GetSheetListBySurveyMap",
                "POST /Khatian/GetSheetJsonBySurvey",
            ],
            "source_crs": "EPSG:4326 (as declared by the source; no reprojection applied)",
        },
        "field_policy": (
            "The source map layer provides only Dag_No per polygon. No owner "
            "names or other personal data exist in this layer; the "
            "personal-data-bearing khatian-detail endpoints were not ingested. "
            "khatian_no, land_class and source area are not available in the "
            "map layer; area_sqm is computed from geometry (approximate)."
        ),
        "mouza_bbox": list(MOUZA_BBOX),
        "fetched_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "dataset_version": datetime.now(timezone.utc).strftime("%Y%m%d"),
        "counts": {
            "sheets": len(per_sheet),
            "dags": len(all_features),
            "duplicates": duplicates,
            "dropped": len(errors),
        },
        "sha256": checksums,
        "masterplan": {
            "source": RAJUK_BASE + " (RAJUK Detailed Area Plan 2022-2035, public app key)",
            "result": masterplan,
        },
        "attribution": (
            "Map geometry from settlement.gov.bd (Directorate of Land Records "
            "& Surveys, Bangladesh) — draft BDS khatian maps; polygons may "
            "change at any survey stage. For internal use by the Uttar "
            "Kaundia Society members' app."
        ),
    }
    (OUT_DIR / "meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2) + "\n")

    total_size = sum(p.stat().st_size for p in committed)
    print(f"\nDone: {len(all_features)} dags across {len(per_sheet)} sheets, "
          f"{total_size/1024:.0f} KiB total")
    if duplicates:
        print(f"WARNING: {duplicates} duplicate (survey,sheet,dag) keys")
    if errors:
        print(f"{len(errors)} validation notes (first 10):")
        for e in errors[:10]:
            print("  -", e)
    diff_report(all_features)
    return 0


def fetch_masterplan(session: requests.Session, delay: float, force: bool) -> dict:
    """One-time capture of the RAJUK DAP 2022-2035 RS plots for the mouza.

    Uses the same public API key the RAJUK web app itself ships in
    /config.json (referer-bound), exactly like the app's own browser calls.
    """
    out_path = OUT_DIR / "masterplan.geojson"
    if not force and out_path.exists():
        print("masterplan.geojson already exists; skipping RAJUK fetch (--force to refetch)")
        return {"skipped": True}

    # RAJUK's token is referer-bound: without its app's Origin the FeatureServer
    # answers 498 Invalid Token even with a valid key.
    session.headers.update({"Referer": f"{RAJUK_BASE}/", "Origin": RAJUK_BASE})
    cfg = http_get(session, f"{RAJUK_BASE}/config.json", delay=delay, force=force).json()
    token = (cfg or {}).get("API_KEY")
    if not token:
        print("RAJUK config.json had no API_KEY; masterplan overlay skipped")
        return {"skipped": True}
    min_lng, min_lat, max_lng, max_lat = RAJUK_BBOX
    params = {
        "f": "json",
        "where": "address_search LIKE '%Uttar Kaundia%'",
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
    data = http_get(session, RAJUK_LAYER, params=params, delay=delay, force=force).json()
    if isinstance(data, dict) and data.get("error"):
        print(f"RAJUK query error: {data['error']} — masterplan overlay skipped")
        return {"skipped": True}
    features = []
    for feat in data.get("features", []):
        rings = [[[round(p[0], 6), round(p[1], 6)] for p in ring]
                 for ring in feat.get("geometry", {}).get("rings", [])]
        if not rings:
            continue
        features.append({
            "type": "Feature",
            "properties": feat.get("attributes", {}),
            "geometry": {"type": "Polygon", "coordinates": rings},
        })
    out_path.write_text(json.dumps(
        {"type": "FeatureCollection", "features": features},
        ensure_ascii=False, separators=(",", ":")))
    print(f"masterplan.geojson: {len(features)} RAJUK DAP RS plots")
    return {"plots": len(features)}


def diff_report(features: list[dict]) -> None:
    """Compare against the previous committed dataset; print added/removed dags."""
    old_index_path = OUT_DIR / "dag-index.json"
    if not old_index_path.exists():
        return
    try:
        old_keys = set(json.loads(old_index_path.read_text()))
    except json.JSONDecodeError:
        return
    new_keys = {f"{f['properties']['survey']}:{f['properties']['sheet']}:{f['properties']['dag']}"
                for f in features}
    added = new_keys - old_keys
    removed = old_keys - new_keys
    print(f"diff vs previous dataset: +{len(added)} added, -{len(removed)} removed")
    for k in sorted(added)[:20]:
        print("  +", k)
    for k in sorted(removed)[:20]:
        print("  -", k)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except AbortIngest as exc:
        print(f"ABORTED: {exc}", file=sys.stderr)
        sys.exit(2)
