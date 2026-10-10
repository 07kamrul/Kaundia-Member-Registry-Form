import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

/** Minimal GeoJSON shapes as served by our /api/land endpoints. */
export interface LandPlotFeature {
  type: 'Feature';
  properties: {
    dag?: string;
    label_bn?: string;
    sheet?: string;
    survey?: string;
    area_sqm?: number;
    plot_no?: number;
    rs_plot_no?: string;
    address_search?: string;
    [key: string]: unknown;
  };
  geometry: { type: string; coordinates: number[][][] | number[][][][] };
}

export interface LandFeatureCollection {
  type: 'FeatureCollection';
  count: number;
  truncated?: boolean;
  features: LandPlotFeature[];
}

/**
 * Local land dataset (ingested BDS mouza map + RAJUK DAP overlay) served
 * through our own authenticated /api/land endpoints. No external map sites
 * are contacted at runtime.
 */
@Injectable({ providedIn: 'root' })
export class LandDataService {
  constructor(private http: HttpClient) {}

  /** BDS dag polygons for the viewport (minLng,minLat,maxLng,maxLat order). */
  dagsInBbox(bbox: string): Observable<LandFeatureCollection> {
    return this.http.get<LandFeatureCollection>(`${environment.apiBaseUrl}/land/dags`, {
      params: { bbox },
    });
  }

  /** Every sheet containing a BDS dag number (Bangla digits accepted). */
  lookupDag(survey: string, dagNo: string): Observable<LandFeatureCollection> {
    return this.http.get<LandFeatureCollection>(
      `${environment.apiBaseUrl}/land/dag/${survey}/lookup/${encodeURIComponent(dagNo)}`,
    );
  }

  /** RAJUK DAP 2022–2035 RS plots for the viewport. */
  masterplanInBbox(bbox: string): Observable<LandFeatureCollection> {
    return this.http.get<LandFeatureCollection>(`${environment.apiBaseUrl}/land/masterplan`, {
      params: { bbox },
    });
  }

  /** RS plots matching a dag number ("4611", "RS-4611", Bangla digits). */
  lookupRsPlot(rsPlotNo: string): Observable<LandFeatureCollection> {
    return this.http.get<LandFeatureCollection>(
      `${environment.apiBaseUrl}/land/masterplan/lookup/${encodeURIComponent(rsPlotNo)}`,
    );
  }
}
