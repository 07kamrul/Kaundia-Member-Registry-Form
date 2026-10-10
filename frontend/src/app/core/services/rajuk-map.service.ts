import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface RajukPlotFeature {
  type: 'Feature';
  properties: {
    plot_no?: number;
    rs_plot_no?: string;
    address_search?: string;
    [key: string]: unknown;
  };
  geometry: { type: string; coordinates: number[][][] };
}

export interface RajukFeatureCollection {
  type: 'FeatureCollection';
  features: RajukPlotFeature[];
}

/** RAJUK DAP masterplan RS plots (masterplan.rajuk.gov.bd) via backend proxy. */
@Injectable({ providedIn: 'root' })
export class RajukMapService {
  constructor(private http: HttpClient) {}

  listPlots(bbox: string): Observable<RajukFeatureCollection> {
    return this.http.get<RajukFeatureCollection>(
      `${environment.apiBaseUrl}/member/external-maps/rajuk/plots`,
      { params: { bbox } },
    );
  }
}
