import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, shareReplay } from 'rxjs';
import { environment } from '../../../environments/environment';

/** Minimal GeoJSON shapes as served by the backend BDS proxy. */
export interface BdsPlotFeature {
  type: 'Feature';
  properties: { Dag_No?: string; [key: string]: unknown };
  geometry: { type: string; coordinates: number[][][] | number[][][][] };
}

export interface BdsFeatureCollection {
  type: 'FeatureCollection';
  features: BdsPlotFeature[];
}

/**
 * Official BDS mouza map (settlement.gov.bd) via the backend proxy.
 * The whole Uttar Kaundia mouza comes back as one cached FeatureCollection.
 */
@Injectable({ providedIn: 'root' })
export class BdsMapService {
  private mouza$: Observable<BdsFeatureCollection> | null = null;

  constructor(private http: HttpClient) {}

  fetchMouza(): Observable<BdsFeatureCollection> {
    if (!this.mouza$) {
      this.mouza$ = this.http
        .get<BdsFeatureCollection>(`${environment.apiBaseUrl}/member/external-maps/bds/mouza`)
        .pipe(shareReplay(1));
    }
    return this.mouza$;
  }
}
