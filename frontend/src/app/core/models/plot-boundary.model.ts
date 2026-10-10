/**
 * Plot-boundary API models - mirror of the implemented backend contract
 * (docs/plot-boundary-api.md). Geometry is RFC 7946 GeoJSON:
 * [longitude, latitude] order, ring closed. Use geo.helper.ts for the
 * [lat,lng] <-> [lng,lat] conversion - never flip axes ad hoc.
 *
 * Review state is version-level: a boundary has a `live` version everyone
 * sees (approved) and at most one `pending` version awaiting review. The
 * owner additionally sees their own pending/rejected shapes.
 */

export type ReviewStatus = 'pending' | 'approved' | 'rejected' | 'superseded' | 'withdrawn';

export const REVIEW_STATUSES: readonly ReviewStatus[] = [
  'pending',
  'approved',
  'rejected',
  'superseded',
  'withdrawn',
];

/** Derived admin queue status for a boundary. */
export type BoundaryQueueStatus = ReviewStatus | 'deleted';

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
  reviewStatus: ReviewStatus;
  isMine: boolean;
  isDisputed: boolean;
  geometry: PolygonGeometry;
}

export interface PlotFeatureApiModel {
  boundary_id: number;
  property_id: number;
  rs_dag: string | null;
  cs_dag: string | null;
  review_status: ReviewStatus;
  status: ReviewStatus; // legacy alias
  is_mine: boolean;
  is_disputed: boolean;
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
  reviewStatus: ReviewStatus;
  isDisputed: boolean;
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
  review_status: ReviewStatus;
  status: ReviewStatus; // legacy alias
  is_disputed: boolean;
}

/** One of the signed-in member's own boundaries (any status). */
export interface MyBoundary {
  id: number;
  propertyId: number;
  /** True when a submission of this boundary is awaiting review. */
  hasPending: boolean;
  /** Review status of the actionable version (pending, else latest rejection, else live). */
  reviewStatus: ReviewStatus;
  /** The actionable shape: pending if one exists, else live, else last rejected. */
  geometry: PolygonGeometry;
  computedAreaSqm: number;
  computedAreaShotangsho: number;
  currentVersion: number;
  /** Decision note on the pending/rejected version (required on reject). */
  reviewNote: string | null;
  /** The approved shape everyone sees - null until the first approval. */
  liveReviewStatus: ReviewStatus | null;
  liveGeometry: PolygonGeometry | null;
  rsDag: string | null;
  csDag: string | null;
  landQuantity: string | null;
  warnings: string[];
}

export interface MyBoundaryApiModel {
  id: number;
  property_id: number;
  has_pending: boolean;
  review_status: ReviewStatus;
  status: ReviewStatus; // legacy alias
  geometry: PolygonGeometry;
  computed_area_sqm: number;
  computed_area_shotangsho: number;
  current_version: number;
  review_note: string | null;
  live_review_status: ReviewStatus | null;
  live_geometry: PolygonGeometry | null;
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
  reviewStatus: ReviewStatus;
  changeType: string;
  submittedByRole: 'member' | 'admin';
  changedByMemberId: number | null;
  changedByAdminId: number | null;
  reviewedAt: string | null;
  reviewNote: string | null;
  note: string | null;
  createdAt: string;
}

export interface BoundaryVersionApiModel {
  id: number;
  version: number;
  geometry: PolygonGeometry;
  computed_area_sqm: number;
  review_status: ReviewStatus;
  status: ReviewStatus; // legacy alias
  change_type: string;
  submitted_by_role: 'member' | 'admin';
  changed_by_member_id: number | null;
  changed_by_admin_id: number | null;
  reviewed_at: string | null;
  review_note: string | null;
  note: string | null;
  created_at: string;
}

/** Admin listing row - adds member identity and workflow pointers. */
export interface AdminBoundary {
  id: number;
  propertyId: number;
  /** Derived queue status: pending | approved | rejected | deleted. */
  status: BoundaryQueueStatus;
  /** Actionable geometry: the pending shape if one awaits review, else live. */
  geometry: PolygonGeometry;
  computedAreaSqm: number;
  computedAreaShotangsho: number;
  currentVersion: number;
  liveVersionId: number | null;
  pendingVersionId: number | null;
  liveReviewStatus: ReviewStatus | null;
  pendingReviewStatus: ReviewStatus | null;
  isDisputed: boolean;
  reviewNote: string | null;
  isDeleted: boolean;
  deletedReason: string | null;
  deletedAt: string | null;
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
  status: BoundaryQueueStatus;
  geometry: PolygonGeometry;
  computed_area_sqm: number;
  computed_area_shotangsho: number;
  current_version: number;
  live_version_id: number | null;
  pending_version_id: number | null;
  live_review_status: ReviewStatus | null;
  pending_review_status: ReviewStatus | null;
  is_disputed: boolean;
  review_note: string | null;
  is_deleted: boolean;
  deleted_reason: string | null;
  deleted_at: string | null;
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
    reviewStatus: api.review_status ?? api.status,
    isMine: api.is_mine,
    isDisputed: api.is_disputed ?? false,
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
    reviewStatus: api.review_status ?? api.status,
    isDisputed: api.is_disputed ?? false,
  };
}

export function toMyBoundary(api: MyBoundaryApiModel): MyBoundary {
  return {
    id: api.id,
    propertyId: api.property_id,
    hasPending: api.has_pending ?? false,
    reviewStatus: api.review_status ?? api.status,
    geometry: api.geometry,
    computedAreaSqm: api.computed_area_sqm,
    computedAreaShotangsho: api.computed_area_shotangsho,
    currentVersion: api.current_version,
    reviewNote: api.review_note,
    liveReviewStatus: api.live_review_status ?? null,
    liveGeometry: api.live_geometry ?? null,
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
    reviewStatus: api.review_status ?? api.status,
    changeType: api.change_type,
    submittedByRole: api.submitted_by_role ?? 'member',
    changedByMemberId: api.changed_by_member_id,
    changedByAdminId: api.changed_by_admin_id,
    reviewedAt: api.reviewed_at ?? null,
    reviewNote: api.review_note ?? null,
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
    liveVersionId: api.live_version_id ?? null,
    pendingVersionId: api.pending_version_id ?? null,
    liveReviewStatus: api.live_review_status ?? null,
    pendingReviewStatus: api.pending_review_status ?? null,
    isDisputed: api.is_disputed ?? false,
    reviewNote: api.review_note,
    isDeleted: api.is_deleted ?? false,
    deletedReason: api.deleted_reason ?? null,
    deletedAt: api.deleted_at ?? null,
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
