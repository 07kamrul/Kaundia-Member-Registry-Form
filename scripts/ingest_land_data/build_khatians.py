#!/usr/bin/env python3
"""Build the served khatian dataset from the raw cache of fetch_khatians.py.

Writes ``backend/data/uttar-kaundia/khatians/bds/<sheet>.json`` — one file per
sheet, mapping ASCII dag number -> record — and records provenance, the verified
land-area unit and sha256 checksums in ``meta.json`` (``khatians`` block).

Owner names exist ONLY in these files: never in the geometry GeoJSON,
``dag-index.json`` or any list/bbox response (see backend land_data service).

Record shape (survey and sheet are implied by the file path)::

    {"total_land": {"value": 0.7649, "unit": "acre"},
     "khatians": [{"khatian_no": "12012", "owners": ["..."],
                   "stage_code": "objection", "stage_bn": "আপত্তি স্তর"}]}

``total_land`` mirrors the portal popup: the plot area (``tpltarea``) when the
portal reports one, otherwise the sum of the khatian shares (``kpltarea``).
Dags the portal hides ("khatians not shown on the map") get ``"khatians": []``
plus ``"source_note": "hidden_by_source"`` and a geometry-derived total.

    python3 build_khatians.py            # build + validate + write
    python3 build_khatians.py --check    # validate only, write nothing
"""

import argparse
import hashlib
import json
import statistics
import sys
from datetime import datetime, timezone
from pathlib import Path

from fetch_khatians import RAW_PATH, REPO, load_cache

DATA_DIR = REPO / "backend" / "data" / "uttar-kaundia"
INDEX_PATH = DATA_DIR / "dag-index.json"
META_PATH = DATA_DIR / "meta.json"
OUT_DIR = DATA_DIR / "khatians"
SURVEY = "bds"
SQM_PER_ACRE = 4046.8564224
UNIT = "acre"
# Median(geometry area / official value) must sit this close to 1 to accept the unit.
UNIT_TOLERANCE = 0.05
MIN_SAMPLE_VALUE = 0.05  # ignore tiny plots: polygon rounding dominates there
STAGE_CODES = {"আপত্তি স্তর": "objection", "আপিল স্তর": "appeal"}
HIDDEN_BY_SOURCE = "hidden_by_source"
MOUZA = {
    "name_bn": "উত্তর কাউন্দিয়া",
    "name_en": "Uttar Kaundia",
    "upazila_bn": "সাভার",
    "upazila_en": "Savar",
    "district_bn": "ঢাকা",
    "district_en": "Dhaka",
}


def stage_code(stage_bn: str) -> str | None:
    return STAGE_CODES.get(stage_bn)


def official_total(rows_c: list[dict]) -> float:
    plot_area = max((r.get("tpltarea") or 0 for r in rows_c), default=0)
    if plot_area > 0:
        return round(plot_area, 4)
    return round(sum(r.get("kpltarea") or 0 for r in rows_c), 4)


def build_record(data: dict, area_sqm: float) -> tuple[dict, bool]:
    """Return (record, derived_total_from_geometry)."""
    rows_a = data.get("rptKhtSearch01a") or []
    rows_b = data.get("rptKhtSearch01b") or []
    rows_c = data.get("rptKhtSearch01c") or []

    owners: dict[str, list[str]] = {}
    for row in rows_b:
        name = (row.get("ownname") or "").strip()
        if name:
            owners.setdefault(str(row.get("khtnum")), []).append(name)

    khatians = []
    for row in rows_a:
        number = str(row.get("khtnum") or "").strip()
        stage_bn = (row.get("khtstatus") or "").strip()
        khatians.append(
            {
                "khatian_no": number,
                "owners": owners.get(number, []),
                "stage_code": stage_code(stage_bn),
                "stage_bn": stage_bn,
            }
        )

    total = official_total(rows_c)
    derived = total <= 0
    if derived:
        total = round(area_sqm / SQM_PER_ACRE, 4)
    record: dict = {"total_land": {"value": total, "unit": UNIT}, "khatians": khatians}
    if not khatians:
        record["source_note"] = HIDDEN_BY_SOURCE
    return record, derived


def verify_unit(samples: list[tuple[float, float]]) -> dict:
    """samples = (geometry area in m², official value). Decide acre vs hectare."""
    if not samples:
        return {"unit": None, "verified": False, "samples": 0}
    median_acre = statistics.median(sqm / SQM_PER_ACRE / v for sqm, v in samples)
    median_hectare = statistics.median(sqm / 10_000 / v for sqm, v in samples)
    verified = abs(median_acre - 1) <= UNIT_TOLERANCE
    return {
        "unit": UNIT if verified else None,
        "verified": verified,
        "method": "median(geometry area / official value) assuming each unit; 1.0 means match",
        "median_ratio_if_acre": round(median_acre, 4),
        "median_ratio_if_hectare": round(median_hectare, 4),
        "samples": len(samples),
    }


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--check", action="store_true", help="validate only")
    args = parser.parse_args()

    index = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    cache = load_cache()
    by_sheet: dict[str, dict[str, dict]] = {}
    unit_samples: list[tuple[float, float]] = []
    missing: list[str] = []
    stats = {"dags": 0, "with_khatians": 0, "empty": 0, "derived_total": 0, "khatians": 0}

    for key, entry in sorted(index.items()):
        _survey, sheet, dag = key.split(":")
        raw = cache.get(dag)
        if raw is None:
            missing.append(key)
            continue
        record, derived = build_record(raw["data"], entry["area_sqm"])
        official = official_total(raw["data"].get("rptKhtSearch01c") or [])
        if official > MIN_SAMPLE_VALUE:
            unit_samples.append((entry["area_sqm"], official))
        by_sheet.setdefault(sheet, {})[dag] = record
        stats["dags"] += 1
        stats["khatians"] += len(record["khatians"])
        stats["derived_total"] += derived
        stats["with_khatians" if record["khatians"] else "empty"] += 1

    unit = verify_unit(unit_samples)
    print(f"counts: {stats}; missing from cache: {len(missing)}")
    print(f"unit check: {unit}")
    if missing:
        print(f"FAIL: {len(missing)} dags not fetched yet, e.g. {missing[:5]}")
        return 1
    if not unit["verified"]:
        print("FAIL: land-area unit not verified; refusing to write")
        return 1
    if args.check:
        return 0

    (OUT_DIR / SURVEY).mkdir(parents=True, exist_ok=True)
    checksums: dict[str, str] = {}
    for sheet, records in sorted(by_sheet.items()):
        path = OUT_DIR / SURVEY / f"{sheet}.json"
        path.write_text(
            json.dumps(records, ensure_ascii=False, separators=(",", ":"), sort_keys=True),
            encoding="utf-8",
        )
        checksums[f"khatians/{SURVEY}/{sheet}.json"] = sha256(path)

    meta = json.loads(META_PATH.read_text(encoding="utf-8"))
    meta["khatians"] = {
        "source": {
            "base_url": "https://settlement.gov.bd",
            "endpoint": "POST /Khatian/GetKhatianDataList_MapSearch",
            "survey": "BDS 2019 (rsnum 201901)",
        },
        "fetched_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "mouza": MOUZA,
        "land_unit": unit,
        "counts": stats,
        "raw_cache": f"{RAW_PATH.relative_to(REPO)} (gitignored)",
        "sha256": checksums,
    }
    meta["field_policy"] = (
        "The geometry layer carries only Dag_No; owner names live exclusively in "
        "khatians/<survey>/<sheet>.json, served by the members-only, rate-limited, "
        "audited detail endpoint — never in geometry, index, list or search output. "
        "area_sqm is computed from geometry (approximate); the official total_land "
        "is in acres (verified, see khatians.land_unit)."
    )
    META_PATH.write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {len(checksums)} sheet files to {OUT_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
