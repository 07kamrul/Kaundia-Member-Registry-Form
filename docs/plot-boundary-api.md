# Plot Boundary API contract (implemented in `backend/`)

All endpoints are under the API prefix `/api`. Anonymous requests get 401 everywhere.
Polygon geometry is **RFC 7946 GeoJSON: `{"type":"Polygon","coordinates":[[[lng,lat],...]]}`** — `[longitude, latitude]` order, ring closed.

## Member endpoints (member JWT; permission `boundary.view` / `boundary.draw_own`)

- `GET /api/member/plot-map?bbox=minLng,minLat,maxLng,maxLat` →
  `{ disclaimer_en, disclaimer_bn, count, features: [{ boundary_id, property_id, rs_dag, cs_dag, status, is_mine, geometry }] }`
  Approved + disputed polygons for everyone; own polygons of any status. **No names/phones.** Status values: `draft|pending_review|approved|rejected|disputed`.
- `GET /api/member/plot-map/{boundary_id}/owner` → `{ boundary_id, owner_name, mobile|null, contact_hidden, rs_dag, cs_dag, land_quantity, computed_area_sqm, computed_area_shotangsho, status }`. Rate-limited (429 with `Retry-After`, code `BOUNDARY_OWNER_RATE_LIMITED`); 403 code `BOUNDARY_NOT_APPROVED` for others' unapproved polygons. `mobile` is null when the owner opted out (`contact_hidden: true`).
- `GET /api/member/plot-boundaries/mine` → `MyBoundaryOut[]`: `{ id, property_id, status, geometry, computed_area_sqm, computed_area_shotangsho, current_version, review_note, rs_dag, cs_dag, land_quantity, warnings[] }`
- `POST /api/member/plot-boundaries` `{ property_id, geometry }` → 201 `MyBoundaryOut` (+ `warnings`, e.g. `AREA_MISMATCH: ...`)
- `PUT /api/member/plot-boundaries/{id}` `{ geometry }` → `MyBoundaryOut` (goes back to `pending_review`, new version)
- `DELETE /api/member/plot-boundaries/{id}` → 204 (soft delete)
- `GET /api/member/plot-boundaries/{id}/versions` → `BoundaryVersionOut[]`: `{ id, version, geometry, computed_area_sqm, status, change_type, changed_by_member_id, changed_by_admin_id, note, created_at }`
- `POST /api/member/plot-boundaries/{id}/report` `{ note }` → 202 `{ received, dispute_id }`

Validation failures return **400** with `{"detail":{"code":"INVALID_GEOMETRY|SELF_INTERSECTING|OUTSIDE_SOCIETY_AREA|ZERO_AREA|TOO_MANY_VERTICES","message":"..."}}`. Drawing for someone else's property: 403 `NOT_YOUR_PROPERTY`. Second boundary for the same property: 409 `BOUNDARY_EXISTS`.

## Admin endpoints (admin JWT; `boundary.review` for review/list/versions, `boundary.manage` for disputes/evidence)

- `GET /api/admin/plot-boundaries?status=&search=&include_deleted=` → `AdminBoundaryOut[]` (adds member_name, member_mobile, khatian_no)
- `GET /api/admin/plot-boundaries/{id}` → `AdminBoundaryOut`
- `POST /api/admin/plot-boundaries/{id}/approve` `{ note? }` → `AdminBoundaryOut` (runs overlap detection; may return status `disputed`)
- `POST /api/admin/plot-boundaries/{id}/reject` `{ note! }` → `AdminBoundaryOut` (422 `NOTE_REQUIRED` if empty)
- `GET /api/admin/plot-boundaries/{id}/versions` → `BoundaryVersionOut[]`
- `GET /api/admin/plot-boundaries/{id}/evidence` → GeoJSON FeatureCollection bundle with disclaimer, boundary summary, all versions
- `GET /api/admin/boundary-disputes?status=open|resolved|dismissed` → `{ id, boundary_id, other_boundary_id|null, overlap_area_sqm, note, status, resolution_note }[]`
- `POST /api/admin/boundary-disputes/{id}/resolve` `{ resolution_note, dismiss? }` → dispute out

## Standing disclaimer (show in UI, both languages)

- BN: `এটি সদস্য-চিহ্নিত আনুমানিক সীমানা; সরকারি জরিপ বা দলিলের বিকল্প নয়।`
- EN: `This is a member-marked approximate boundary; it is not a substitute for an official survey or legal documents.`

## Units

`computed_area_sqm` is geodesic m²; `computed_area_shotangsho` = m² / 40.47 (1 শতাংশ = 435.6 sq ft). Declared `land_quantity` from properties is a free-text string interpreted as shotangsho.
