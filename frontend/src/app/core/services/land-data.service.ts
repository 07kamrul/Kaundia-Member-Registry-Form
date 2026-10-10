import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

/** One khatian row of a dag, as served by GET /land/dag/{survey}/{sheet}/{dag}. */
export interface DagKhatian {
  /** Khatian number (ASCII digits). */
  khatian_no: string;
  /** Recorded owner names, top to bottom as printed on the portal (verbatim). */
  owners: string[];
  /** Known stage code ("objection" | "appeal"), null when the source stage is unmapped. */
  stage_code: string | null;
  /** Stage text exactly as published (Bangla). */
  stage_bn: string;
}

export interface DagDetails {
  survey: string;
  sheet: string;
  dag: string;
  mouza: {
    name_bn: string;
    name_en: string;
    upazila_bn: string;
    upazila_en: string;
    district_bn: string;
    district_en: string;
  };
  /** Official "মোট জমি" number as published, with its verified unit. */
  total_land: { value: number; unit: string };
  khatians: DagKhatian[];
  /** "hidden_by_source" when the portal withholds this dag's khatians. */
  source_note: string | null;
  source: { name: string; fetched_at: string; dataset_version: string };
}

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

  /**
   * Land details + khatian/owner rows for one dag. Members only, rate-limited
   * and audited server-side, so it is fetched lazily per opened dialog and
   * never cached or prefetched.
   */
  dagDetails(survey: string, sheet: string, dag: string): Observable<DagDetails> {
    return this.http.get<DagDetails>(
      `${environment.apiBaseUrl}/land/dag/${encodeURIComponent(survey)}/${encodeURIComponent(sheet)}/${encodeURIComponent(dag)}`,
    );
  }

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
