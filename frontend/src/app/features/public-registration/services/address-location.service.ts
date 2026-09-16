import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map, shareReplay } from 'rxjs';

export interface Division {
  id: string;
  name: string;
  bn_name: string;
}

export interface District {
  id: string;
  division_id: string;
  name: string;
  bn_name: string;
}

export interface Upazila {
  district_id: string;
  name: string;
  bn_name: string;
}

interface BdGeoData {
  divisions: Division[];
  districts: District[];
  upazilas: Upazila[];
}

@Injectable({ providedIn: 'root' })
export class AddressLocationService {
  private readonly http = inject(HttpClient);

  private readonly geoData$: Observable<BdGeoData> = this.http
    .get<BdGeoData>('/data/bd-geo.json')
    .pipe(shareReplay(1));

  getDivisions(): Observable<Division[]> {
    return this.geoData$.pipe(map((data) => data.divisions));
  }

  getDistricts(): Observable<District[]> {
    return this.geoData$.pipe(map((data) => data.districts));
  }

  getDistrictsByDivisionName(divisionName: string): Observable<District[]> {
    return this.geoData$.pipe(
      map((data) => {
        const division = data.divisions.find(
          (d) => d.bn_name === divisionName || d.name === divisionName,
        );
        if (!division) {
          return [];
        }
        return data.districts.filter((d) => d.division_id === division.id);
      }),
    );
  }

  getUpazilasByDistrictName(districtName: string): Observable<Upazila[]> {
    return this.geoData$.pipe(
      map((data) => {
        const district = data.districts.find(
          (d) => d.bn_name === districtName || d.name === districtName,
        );
        if (!district) {
          return [];
        }
        return data.upazilas.filter((u) => u.district_id === district.id);
      }),
    );
  }
}
