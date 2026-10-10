# Land data ingest (`scripts/ingest_land_data/`)

Dev-only tool. Downloads the Uttar Kaundia mouza map from
`settlement.gov.bd` once, validates it, and writes the committed dataset under
`data/uttar-kaundia/`. **The app never imports this** — at runtime the backend
reads only the local JSON files (see `backend/app/services/land_data.py`).

## Usage

```bash
python3 -m venv .venv && .venv/bin pip install -r requirements.txt
.venv/bin/python ingest.py            # 2 s delay between requests, uses raw cache
.venv/bin/python ingest.py --force    # refetch everything
```

Raw upstream responses are cached in `data/_raw/` (gitignored) so reruns are
free and reviewable.

## Source endpoints (captured 2026-10, verified live)

Base: `https://settlement.gov.bd` (ASP.NET session-free, form-encoded POST,
JSON responses, no auth/CSRF token needed for these read endpoints).

| Endpoint | Method | Parameters | Response |
|---|---|---|---|
| `/Khatian/GetSheetListBySurveyMap` | GET | `comcod`, `rsnum`, `unitcod` | JSON array of `{unitcod, rsnum, shetnum, shetnumb, shetdesc, mapref, mapurl, rsnumb}` — one entry per sheet (`shetnum` `"000"`…"098", zero-padded 3-digit ASCII) |
| `/Khatian/GetSheetJsonBySurvey` | POST (form) | `rsnum`, `comcod`, `unitcod`, `sheetno` | GeoJSON `FeatureCollection` with `crs: EPSG:4326`; per feature `properties: {FID, Id, Dag_No}` + Polygon geometry. Sheets with no geometry return an **empty body** (not an error) |
| `/Khatian/GetSurveyListDistrictWise` | POST (form) | `districtid`, `comcod` | JSON array of `{rsnum, rsname}` — surveys available for the district |

Other cascade endpoints seen in the site JS (`kh-search.js`, `MapSearch.js`):
`GetDivisionList`, `getdistrictlistdivisionwise`, `GetThanaListBySurvey(Map)`,
`GetMouzaListBySurvey(Map)`, `GetSheetListBySurvey`, `GetKhatianDataList`.

## Mouza / survey identifiers

- Division ঢাকা `010000000` → District ঢাকা `010500000` (`comcod` `4105`) →
  Upazila সাভার `010510000` → Mouza উত্তর কাউন্দিয়া `unitcod` `010510211`.
- **Survey: only বি ডি এস (BDS) 2019, `rsnum` `201901`.**
  `GetSurveyListDistrictWise` for Dhaka district returns exactly one survey
  (`201901 বি ডি এস`). CS/SA/RS are **not served** by this portal and no
  dag cross-reference between surveys exists — recorded in `meta.json`.
  Members who registered CS/RS dag numbers therefore cannot be auto-linked
  to BDS polygons by dag number; matching is manual (map click / committee).

## CRS & coordinate order

The source declares and delivers **EPSG:4326** with `[lng, lat]` GeoJSON
order (verified: values ≈ lng 90.32–90.35, lat 23.78–23.83; assert against
the known point 23.828, 90.331 which falls inside the dataset bbox). No
reprojection is applied; `pyproj` is only needed if the source ever changes.

## Field policy (privacy)

The map layer carries only `Dag_No`. **No owner names or personal data exist
in it**, and the personal-data-bearing khatian endpoints (`GetKhatianDataList`
etc.) are deliberately not ingested. `area_sqm` in our dataset is computed
from geometry (approximate, sanity range 1–500 000 m²). `khatian_no` and
`land_class` are unavailable in this source.

## Validation performed before writing

- Polygon rings ≥ 4 points, coordinate order sanity check (lat/lng swap
  detector), everything inside the mouza bbox `(90.295, 23.780, 90.360,
  23.840)` — 13 dags on sheet `092` fall outside (that sheet spills into a
  neighbouring mouza) and are dropped and logged.
- No duplicate `(survey, sheet, dag)` keys (checked, count recorded in meta).
- Bangla digits normalized to ASCII in `dag`; original kept in `label_bn`.
- Coordinates rounded to 6 decimals (~0.1 m). No geometry simplification.

## Outputs (`data/uttar-kaundia/`, committed)

```
meta.json                     mouza codes, sources, fetched_at, dataset_version, counts, sha256 per file, attribution
sheets.json                   {"bds": ["000", ... "098"]}
dags/bds/<sheet>.geojson      FeatureCollection per sheet (properties: survey, sheet, dag, label_bn, area_sqm)
dag-index.json                "<survey>:<sheet>:<dag>" → {centroid, area_sqm}
```

Reruns print an added/removed dag diff against the previous committed
`dag-index.json` so dataset updates are reviewable in git.

## Politeness rules baked in

Sequential requests only, `--delay` (default 2 s) sleep before every request,
descriptive User-Agent with contact email, local raw cache, exponential
backoff on timeouts (5 attempts), **hard abort on HTTP 403/429**.
