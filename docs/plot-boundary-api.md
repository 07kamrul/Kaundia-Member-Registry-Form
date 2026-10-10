# Plot Boundary API contract (implemented in `backend/`)

All endpoints are under the API prefix `/api`. Anonymous requests get 401 everywhere (exception: `GET /member/plot-map` when `BOUNDARY_MAP_PUBLIC_VIEW=true` — dag numbers + geometry only, never names/phones, and the owner endpoint stays 401).
Polygon geometry is **RFC 7946 GeoJSON: `{"type":"Polygon","coordinates":[[[lng,lat],...]]}`** — `[longitude, latitude]` order, ring closed.

## Review model (version-level)

Review state lives on **`plot_boundary_versions`**, not on the boundary:

- `review_status`: `pending | approved | rejected | superseded | withdrawn` (immutable except the review fields written once at decision time).
- A boundary exposes `live_version_id` (the approved shape everyone sees; `null` until first approval) and `pending_version_id` (at most ONE submission awaiting review; a new member edit **replaces** it — the old pending row becomes `superseded`).
- Member add/edit → **pending**; nobody but the owner sees it until an admin approves. A rejected *new* polygon never goes live; a rejected *edit* leaves the previous live shape untouched.
- Admin add/edit goes **live immediately** (`change_type: admin_create|admin_edit`, `submitted_by_role: "admin"`, audited, member notified).
- Member **delete does not exist**; admins soft-delete with a mandatory reason. "Disputed" is a flag derived from open `boundary_disputes`, never a review status.

## Member endpoints (member JWT; permission `boundary.view` / `boundary.draw_own`)

- `GET /api/member/plot-map?bbox=minLng,minLat,maxLng,maxLat` →
  `{ disclaimer_en, disclaimer_bn, count, features: [{ boundary_id, property_id, rs_dag, cs_dag, review_status, status, is_mine, is_disputed, geometry }] }`
  Live (approved) polygons for everyone; the caller's own pending/rejected version additionally, marked `is_mine`. **No names/phones.**
- `GET /api/member/plot-map/{boundary_id}/owner` → `{ boundary_id, owner_name, mobile|null, contact_hidden, rs_dag, cs_dag, land_quantity, computed_area_sqm, computed_area_shotangsho, review_status, is_disputed }`. Rate-limited (429 with `Retry-After`, code `BOUNDARY_OWNER_RATE_LIMITED`); 403 `BOUNDARY_NOT_APPROVED` until a live version exists (owner always allowed). `mobile` is null when the owner opted out (`contact_hidden: true`).
- `GET /api/member/plot-boundaries/mine` → `MyBoundaryOut[]`: `{ id, property_id, has_pending, review_status, geometry, computed_area_sqm, computed_area_shotangsho, current_version, review_note, live_review_status, live_geometry, rs_dag, cs_dag, land_quantity, warnings[] }` — `geometry` is the actionable shape (pending, else latest rejection, else live); `review_note` carries the admin's rejection note.
- `POST /api/member/plot-boundaries` `{ property_id, geometry }` → 201 `MyBoundaryOut` (pending version; + `warnings`, e.g. `AREA_MISMATCH: ...`)
- `PUT /api/member/plot-boundaries/{id}` `{ geometry }` → `MyBoundaryOut` (new pending version; replaces any existing pending one — old becomes `superseded`; live untouched)
- `POST /api/member/plot-boundaries/{id}/withdraw` → `MyBoundaryOut` (pending → `withdrawn`; 409 `NOT_PENDING` if nothing pending)
- **No member DELETE.**
- `GET /api/member/plot-boundaries/{id}/versions` → `BoundaryVersionOut[]`: `{ id, version, geometry, computed_area_sqm, review_status, change_type (create|edit|admin_create|admin_edit|delete), submitted_by_role, changed_by_member_id, changed_by_admin_id, reviewed_at, review_note, note, created_at }`
- `POST /api/member/plot-boundaries/{id}/report` `{ note }` → 202 `{ received, dispute_id }`

Validation failures return **400** with `{"detail":{"code":"INVALID_GEOMETRY|SELF_INTERSECTING|OUTSIDE_SOCIETY_AREA|ZERO_AREA|TOO_MANY_VERTICES","message":"..."}}`. Drawing for someone else's property: 403 `NOT_YOUR_PROPERTY`. Second boundary for the same property: 409 `BOUNDARY_EXISTS`.

## Admin endpoints (admin JWT; `boundary.review` for review/list/versions, `boundary.manage` for add/edit/delete/disputes/evidence)

- `GET /api/admin/plot-boundaries?status=pending|approved|rejected|deleted&search=&include_deleted=` → `AdminBoundaryOut[]` (adds member_name, member_mobile, khatian_no, live/pending pointers, `is_disputed`, deleted reason/at; `geometry` is the pending shape when one awaits review)
- `GET /api/admin/plot-boundaries/pending/count` → `{ count }` (dashboard/nav badge)
- `GET /api/admin/plot-boundaries/{id}` → `AdminBoundaryOut`
- `POST /api/admin/plot-boundaries` `{ member_id, property_id, geometry, confirm_overlap?, note? }` → 201 `AdminBoundaryOut` (**live immediately**). If the shape overlaps an approved polygon and `confirm_overlap` is false → 409 `OVERLAP_CONFIRMATION_REQUIRED` with `overlaps: [{boundary_id, overlap_area_sqm}]`; on save the overlaps become dispute records.
- `PUT /api/admin/plot-boundaries/{id}` `{ geometry, confirm_overlap? }` → `AdminBoundaryOut` (live immediately; supersedes any pending member submission; member notified)
- `DELETE /api/admin/plot-boundaries/{id}` `{ reason! }` → `AdminBoundaryOut` (soft delete; 422 if reason missing; history kept; member notified)
- `POST /api/admin/plot-boundary-versions/{version_id}/approve` `{ note? }` → `AdminBoundaryOut` (version → approved/live, previous live → `superseded`; overlap detection runs and opens disputes; 409 `NOT_PENDING`)
- `POST /api/admin/plot-boundary-versions/{version_id}/reject` `{ note! }` → `AdminBoundaryOut` (422 `NOTE_REQUIRED` if empty; live untouched)
- `GET /api/admin/plot-boundaries/{id}/versions` → `BoundaryVersionOut[]`
- `GET /api/admin/plot-boundaries/{id}/evidence` → GeoJSON FeatureCollection bundle with disclaimer, boundary summary, all versions
- `GET /api/admin/boundary-disputes?status=open|resolved|dismissed` → `{ id, boundary_id, other_boundary_id|null, overlap_area_sqm, note, status, resolution_note }[]`
- `POST /api/admin/boundary-disputes/{id}/resolve` `{ resolution_note, dismiss? }` → dispute out

Every approve/reject/add/edit/delete writes exactly one audit row; version rows are never mutated after the decision and never hard-deleted.

## Notifications

- Admins: email on each new pending submission (plus the pending-count badge endpoint above).
- Member: submitted, approved, rejected (with note), admin-edited, admin-deleted (with reason).

## Standing disclaimer (show in UI, both languages)

- BN: `এটি সদস্য-চিহ্নিত আনুমানিক সীমানা; সরকারি জরিপ বা দলিলের বিকল্প নয়।`
- EN: `This is a member-marked approximate boundary; it is not a substitute for an official survey or legal documents.`

## Units

`computed_area_sqm` is geodesic m²; `computed_area_shotangsho` = m² / 40.47 (1 শতাংশ = 435.6 sq ft). Declared `land_quantity` from properties is a free-text string interpreted as shotangsho.
