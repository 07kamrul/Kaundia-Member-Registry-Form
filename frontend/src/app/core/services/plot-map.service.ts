import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  toAdminBoundary,
  toBoundaryDispute,
  toBoundaryOwner,
  toBoundaryVersion,
  toMyBoundary,
  toPlotMapPage,
  type AdminBoundary,
  type AdminBoundaryApiModel,
  type BoundaryDispute,
  type BoundaryDisputeApiModel,
  type BoundaryOwner,
  type BoundaryOwnerApiModel,
  type BoundaryVersion,
  type BoundaryVersionApiModel,
  type MyBoundary,
  type MyBoundaryApiModel,
  type PlotMapPage,
  type PlotMapPageApiModel,
  type PolygonGeometry,
} from '../models/plot-boundary.model';

/**
 * Plot-boundary endpoints - contract in docs/plot-boundary-api.md.
 * Member calls need boundary.view (map) / boundary.draw_own (draw);
 * admin calls need boundary.review (boundary.manage for disputes/evidence).
 */
@Injectable({ providedIn: 'root' })
export class PlotMapService {
  constructor(private http: HttpClient) {}

  private memberUrl(path: string): string {
    return `${environment.apiBaseUrl}/member/${path}`;
  }

  private adminUrl(path: string): string {
    return `${environment.apiBaseUrl}/admin/${path}`;
  }

  /** Approved + disputed polygons for everyone; own polygons of any status. */
  listFeatures(bbox: string): Observable<PlotMapPage> {
    return this.http
      .get<PlotMapPageApiModel>(this.memberUrl('plot-map'), { params: { bbox } })
      .pipe(map(toPlotMapPage));
  }

  getOwner(boundaryId: number): Observable<BoundaryOwner> {
    return this.http
      .get<BoundaryOwnerApiModel>(this.memberUrl(`plot-map/${boundaryId}/owner`))
      .pipe(map(toBoundaryOwner));
  }

  listMine(): Observable<MyBoundary[]> {
    return this.http
      .get<MyBoundaryApiModel[]>(this.memberUrl('plot-boundaries/mine'))
      .pipe(map((rows) => rows.map(toMyBoundary)));
  }

  create(propertyId: number, geometry: PolygonGeometry): Observable<MyBoundary> {
    return this.http
      .post<MyBoundaryApiModel>(this.memberUrl('plot-boundaries'), {
        property_id: propertyId,
        geometry,
      })
      .pipe(map(toMyBoundary));
  }

  update(id: number, geometry: PolygonGeometry): Observable<MyBoundary> {
    return this.http
      .put<MyBoundaryApiModel>(this.memberUrl(`plot-boundaries/${id}`), { geometry })
      .pipe(map(toMyBoundary));
  }

  /** Withdraw the pending submission; the live shape is untouched. */
  withdraw(id: number): Observable<MyBoundary> {
    return this.http
      .post<MyBoundaryApiModel>(this.memberUrl(`plot-boundaries/${id}/withdraw`), {})
      .pipe(map(toMyBoundary));
  }

  listVersions(id: number): Observable<BoundaryVersion[]> {
    return this.http
      .get<BoundaryVersionApiModel[]>(this.memberUrl(`plot-boundaries/${id}/versions`))
      .pipe(map((rows) => rows.map(toBoundaryVersion)));
  }

  report(id: number, note: string): Observable<{ received: boolean; dispute_id: number | null }> {
    return this.http.post<{ received: boolean; dispute_id: number | null }>(
      this.memberUrl(`plot-boundaries/${id}/report`),
      { note },
    );
  }

  // ---- Admin (boundary.review; boundary.manage for disputes/evidence) ----

  adminList(status?: string, search?: string, includeDeleted = false): Observable<AdminBoundary[]> {
    const params: Record<string, string> = {};
    if (status) params['status'] = status;
    if (search) params['search'] = search;
    if (includeDeleted) params['include_deleted'] = 'true';
    return this.http
      .get<AdminBoundaryApiModel[]>(this.adminUrl('plot-boundaries'), { params })
      .pipe(map((rows) => rows.map(toAdminBoundary)));
  }

  adminPendingCount(): Observable<number> {
    return this.http
      .get<{ count: number }>(this.adminUrl('plot-boundaries/pending/count'))
      .pipe(map((body) => body.count));
  }

  /** Approve/reject a pending VERSION (not the boundary). */
  adminApprove(versionId: number, note?: string): Observable<AdminBoundary> {
    return this.http
      .post<AdminBoundaryApiModel>(this.adminUrl(`plot-boundary-versions/${versionId}/approve`), {
        note: note ?? null,
      })
      .pipe(map(toAdminBoundary));
  }

  adminReject(versionId: number, note: string): Observable<AdminBoundary> {
    return this.http
      .post<AdminBoundaryApiModel>(this.adminUrl(`plot-boundary-versions/${versionId}/reject`), { note })
      .pipe(map(toAdminBoundary));
  }

  /** Add a polygon on behalf of a member - goes live immediately. */
  adminCreate(
    memberId: number,
    propertyId: number,
    geometry: PolygonGeometry,
    confirmOverlap = false,
  ): Observable<AdminBoundary> {
    return this.http
      .post<AdminBoundaryApiModel>(this.adminUrl('plot-boundaries'), {
        member_id: memberId,
        property_id: propertyId,
        geometry,
        confirm_overlap: confirmOverlap,
      })
      .pipe(map(toAdminBoundary));
  }

  /** Edit any member's polygon - goes live immediately. */
  adminEdit(id: number, geometry: PolygonGeometry, confirmOverlap = false): Observable<AdminBoundary> {
    return this.http
      .put<AdminBoundaryApiModel>(this.adminUrl(`plot-boundaries/${id}`), {
        geometry,
        confirm_overlap: confirmOverlap,
      })
      .pipe(map(toAdminBoundary));
  }

  /** Soft delete with a mandatory reason; the version history is kept. */
  adminDelete(id: number, reason: string): Observable<AdminBoundary> {
    return this.http
      .request<AdminBoundaryApiModel>('DELETE', this.adminUrl(`plot-boundaries/${id}`), {
        body: { reason },
      })
      .pipe(map(toAdminBoundary));
  }

  adminVersions(id: number): Observable<BoundaryVersion[]> {
    return this.http
      .get<BoundaryVersionApiModel[]>(this.adminUrl(`plot-boundaries/${id}/versions`))
      .pipe(map((rows) => rows.map(toBoundaryVersion)));
  }

  /** Evidence GeoJSON bundle - downloaded as a file via anchor/blob. */
  evidence(id: number): Observable<unknown> {
    return this.http.get(this.adminUrl(`plot-boundaries/${id}/evidence`));
  }

  listDisputes(status?: string): Observable<BoundaryDispute[]> {
    const params: Record<string, string> = {};
    if (status) params['status'] = status;
    return this.http
      .get<BoundaryDisputeApiModel[]>(this.adminUrl('boundary-disputes'), { params })
      .pipe(map((rows) => rows.map(toBoundaryDispute)));
  }

  resolveDispute(id: number, resolutionNote: string, dismiss: boolean): Observable<BoundaryDispute> {
    return this.http
      .post<BoundaryDisputeApiModel>(this.adminUrl(`boundary-disputes/${id}/resolve`), {
        resolution_note: resolutionNote,
        dismiss,
      })
      .pipe(map(toBoundaryDispute));
  }
}
