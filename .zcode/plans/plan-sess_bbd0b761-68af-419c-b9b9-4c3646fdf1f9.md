## Multi-Map View Switcher on Plot Boundary Map (/plot-map)

Add a "Map views" control to the plot boundary map. The default view stays exactly as today (member plot boundaries over Street/Satellite). A new control button opens a panel with three map choices:

1. **My Plot Boundary Map** — current view (member-drawn boundaries, search, draw, legend).
2. **BDS Map (settlement.gov.bd)** — official mouza plot map of Uttar Kaundia, looking like image 1: blue plot polygons with dag-number labels, click a dag → popup with details + link to the official site.
3. **RAJUK Masterplan (DAP)** — RS plots restricted to Uttar Kaundia mouza only; click a plot → popup with RS Plot No, JL No 245, Savar Upazila, Dhaka (like image 3).

### Backend (FastAPI)
New file `backend/app/api/routes/external_maps.py`, mounted in `main.py`:
- `GET /api/member/external-maps/bds/mouza` — proxies settlement.gov.bd: fetches all sheets of mouza `010510211` (rsnum `201901`, comcod `4105`) via `POST /Khatian/GetSheetJsonBySurvey`, merges into one FeatureCollection, caches in-memory (98 sheets ≈ 1.8 MB, one-off warm fetch), served gzipped.
- `GET /api/member/external-maps/rajuk/plots?bbox=...` — proxies `masterplan.rajuk.gov.bd/server/rest/services/rajuk_db/Rajuk_dap_db/FeatureServer/0/query` with `where address_search LIKE '%Uttar Kaundia%'`, `geometry=<bbox>`, `outSR=4326`, `f=json`, token from their public `config.json` API key (fetched once, cached; esri JSON → GeoJSON converted server-side). bbox keeps responses small and enforces "Uttar Kaundia only".
- Member-auth guarded, small in-memory TTL cache, httpx client with timeouts and error passthrough (502 if upstream down). Add `httpx` if not already a dependency.

### Frontend (Angular, plot-map component)
- New **"Map views"** button (top-left of map, below zoom) opening a small panel with three option cards (i18n en/bn). Selecting a mode toggles which overlay layers are active; Street/Satellite basemaps remain available under all modes.
- **BDS mode**: a new `bds-map.service.ts` fetches the cached mouza FeatureCollection once and renders `L.geoJSON` polygons styled like image 1 (blue stroke, 0.2 fill), permanent `Dag <no>` tooltip labels at polygon centroids (only at zoom ≥ 16 to avoid clutter), hover highlight, click → popup: Dag No, survey "BDS 2019", Mouza "Uttar Kaundia", plus a link "Open in settlement.gov.bd". Member boundary editing controls are disabled/hidden in this mode; member boundaries can still be shown as an overlay toggle.
- **RAJUK mode**: new `rajuk-map.service.ts` loads plots for the current view bbox (debounced on moveend, reusing the existing pattern), renders polygons (distinct amber/green style), click → popup "RS Plot No / JL No 245 / Savar Upazila / Dhaka". "Locate me", search and draw stay bound to boundary mode only.
- Modes are mutually exclusive for the data layers; own-boundary overlay checkbox remains in all modes.
- i18n keys added to `frontend/public/i18n/en.json` and `bn.json` under `member.plotMap.views.*`.
- Environments: no new keys needed (URLs live in the backend only).
- Unit specs updated for the two new services (HttpTestingController) and component mode switching.

### Verification
- Run backend migrations/tests, `ng test` (via `/usr/local/bin/node` per project convention), and `ng build`.
- Manually verify with dev servers + browser screenshots (desktop + mobile): default view unchanged, BDS view resembles image 1 with dag labels and click popups, RAJUK view shows only Uttar Kaundia plots with the image-3-style popup.

Note: "click the map shows three maps" is implemented as an always-visible "Map views" button on the map (standard Leaflet custom control) — clicking the map canvas itself is reserved for plot interactions.