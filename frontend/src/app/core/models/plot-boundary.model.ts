/**
 * Plot-boundary API models - mirror of the implemented backend contract
 * (docs/plot-boundary-api.md). Geometry is RFC 7946 GeoJSON:
 * [longitude, latitude] order, ring closed. Use geo.helper.ts for the
 * [lat,lng] <-> [lng,lat] conversion - never flip axes ad hoc.
 */

export type BoundaryStatus = 'draft' | 'pending_review' | 'approved' | 'rejected' | 'disputed';

export const BOUNDARY_STATUSES: readonly BoundaryStatus[] = [
  'draft',
  'pending_review',
  'approved',
  'rejected',
  'disputed',
];

export interface PolygonGeometry {
  type: 'Polygon';
  coordinates: number[][][];
}

/** One polygon on the member plot map (no names/phones - by design). */
export interface PlotFeature {
  boundaryId: number;
  propertyId: number;
  rsDag: string | null;
  csDag: string | null;
  status: BoundaryStatus;
  isMine: boolean;
  geometry: PolygonGeometry;
}

export interface PlotFeatureApiModel {
  boundary_id: number;
  property_id: number;
  rs_dag: string | null;
  cs_dag: string | null;
  status: BoundaryStatus;
  is_mine: boolean;
  geometry: PolygonGeometry;
}

export interface PlotMapPage {
  disclaimerEn: string;
  disclaimerBn: string;
  count: number;
  features: PlotFeature[];
}

export interface PlotMapPageApiModel {
  disclaimer_en: string;
  disclaimer_bn: string;
  count: number;
  features: PlotFeatureApiModel[];
}

/** Lazy owner detail fetched when a polygon is clicked. */
export interface BoundaryOwner {
  boundaryId: number;
  ownerName: string;
  /** null when the owner opted out of sharing contact info. */
  mobile: string | null;
  contactHidden: boolean;
  rsDag: string | null;
  csDag: string | null;
  landQuantity: string | null;
  computedAreaSqm: number;
  computedAreaShotangsho: number;
  status: BoundaryStatus;
}

export interface BoundaryOwnerApiModel {
  boundary_id: number;
  owner_name: string;
  mobile: string | null;
  contact_hidden: boolean;
  rs_dag: string | null;
  cs_dag: string | null;
  land_quantity: string | null;
  computed_area_sqm: number;
  computed_area_shotangsho: number;
  status: BoundaryStatus;
}

/** One of the signed-in member's own boundaries (any status). */
export interface MyBoundary {
  id: number;
  propertyId: number;
  status: BoundaryStatus;
  geometry: PolygonGeometry;
  computedAreaSqm: number;
  computedAreaShotangsho: number;
  currentVersion: number;
  reviewNote: string | null;
  rsDag: string | null;
  csDag: string | null;
  landQuantity: string | null;
  warnings: string[];
}

export interface MyBoundaryApiModel {
  id: number;
  property_id: number;
  status: BoundaryStatus;
  geometry: PolygonGeometry;
  computed_area_sqm: number;
  computed_area_shotangsho: number;
  current_version: number;
  review_note: string | null;
  rs_dag: string | null;
  cs_dag: string | null;
  land_quantity: string | null;
  warnings: string[];
}

export interface BoundaryVersion {
  id: number;
  version: number;
  geometry: PolygonGeometry;
  computedAreaSqm: number;
  status: BoundaryStatus;
  changeType: string;
  changedByMemberId: number | null;
  changedByAdminId: number | null;
  note: string | null;
  createdAt: string;
}

export interface BoundaryVersionApiModel {
  id: number;
  version: number;
  geometry: PolygonGeometry;
  computed_area_sqm: number;
  status: BoundaryStatus;
  change_type: string;
  changed_by_member_id: number | null;
  changed_by_admin_id: number | null;
  note: string | null;
  created_at: string;
}

/** Admin listing row - adds member identity to MyBoundary. */
export interface AdminBoundary {
  id: number;
  propertyId: number;
  status: BoundaryStatus;
  geometry: PolygonGeometry;
  computedAreaSqm: number;
  computedAreaShotangsho: number;
  currentVersion: number;
  reviewNote: string | null;
  rsDag: string | null;
  csDag: string | null;
  landQuantity: string | null;
  khatianNo: string | null;
  memberName: string;
  memberMobile: string | null;
}

export interface AdminBoundaryApiModel {
  id: number;
  property_id: number;
  status: BoundaryStatus;
  geometry: PolygonGeometry;
  computed_area_sqm: number;
  computed_area_shotangsho: number;
  current_version: number;
  review_note: string | null;
  rs_dag: string | null;
  cs_dag: string | null;
  land_quantity: string | null;
  khatian_no: string | null;
  member_name: string;
  member_mobile: string | null;
}

export type DisputeStatus = 'open' | 'resolved' | 'dismissed';

export interface BoundaryDispute {
  id: number;
  boundaryId: number;
  otherBoundaryId: number | null;
  overlapAreaSqm: number;
  note: string | null;
  status: DisputeStatus;
  resolutionNote: string | null;
}

export interface BoundaryDisputeApiModel {
  id: number;
  boundary_id: number;
  other_boundary_id: number | null;
  overlap_area_sqm: number;
  note: string | null;
  status: DisputeStatus;
  resolution_note: string | null;
}

function toPlotFeature(api: PlotFeatureApiModel): PlotFeature {
  return {
    boundaryId: api.boundary_id,
    propertyId: api.property_id,
    rsDag: api.rs_dag,
    csDag: api.cs_dag,
    status: api.status,
    isMine: api.is_mine,
    geometry: api.geometry,
  };
}

export function toPlotMapPage(api: PlotMapPageApiModel): PlotMapPage {
  return {
    disclaimerEn: api.disclaimer_en,
    disclaimerBn: api.disclaimer_bn,
    count: api.count,
    features: (api.features ?? []).map(toPlotFeature),
  };
}

export function toBoundaryOwner(api: BoundaryOwnerApiModel): BoundaryOwner {
  return {
    boundaryId: api.boundary_id,
    ownerName: api.owner_name,
    mobile: api.mobile,
    contactHidden: api.contact_hidden,
    rsDag: api.rs_dag,
    csDag: api.cs_dag,
    landQuantity: api.land_quantity,
    computedAreaSqm: api.computed_area_sqm,
    computedAreaShotangsho: api.computed_area_shotangsho,
    status: api.status,
  };
}

export function toMyBoundary(api: MyBoundaryApiModel): MyBoundary {
  return {
    id: api.id,
    propertyId: api.property_id,
    status: api.status,
    geometry: api.geometry,
    computedAreaSqm: api.computed_area_sqm,
    computedAreaShotangsho: api.computed_area_shotangsho,
    currentVersion: api.current_version,
    reviewNote: api.review_note,
    rsDag: api.rs_dag,
    csDag: api.cs_dag,
    landQuantity: api.land_quantity,
    warnings: api.warnings ?? [],
  };
}

export function toBoundaryVersion(api: BoundaryVersionApiModel): BoundaryVersion {
  return {
    id: api.id,
    version: api.version,
    geometry: api.geometry,
    computedAreaSqm: api.computed_area_sqm,
    status: api.status,
    changeType: api.change_type,
    changedByMemberId: api.changed_by_member_id,
    changedByAdminId: api.changed_by_admin_id,
    note: api.note,
    createdAt: api.created_at,
  };
}

export function toAdminBoundary(api: AdminBoundaryApiModel): AdminBoundary {
  return {
    id: api.id,
    propertyId: api.property_id,
    status: api.status,
    geometry: api.geometry,
    computedAreaSqm: api.computed_area_sqm,
    computedAreaShotangsho: api.computed_area_shotangsho,
    currentVersion: api.current_version,
    reviewNote: api.review_note,
    rsDag: api.rs_dag,
    csDag: api.cs_dag,
    landQuantity: api.land_quantity,
    khatianNo: api.khatian_no,
    memberName: api.member_name,
    memberMobile: api.member_mobile,
  };
}

export function toBoundaryDispute(api: BoundaryDisputeApiModel): BoundaryDispute {
  return {
    id: api.id,
    boundaryId: api.boundary_id,
    otherBoundaryId: api.other_boundary_id,
    overlapAreaSqm: api.overlap_area_sqm,
    note: api.note,
    status: api.status,
    resolutionNote: api.resolution_note,
  };
}
