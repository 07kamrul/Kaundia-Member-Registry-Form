import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, shareReplay } from 'rxjs';
import { environment } from '../../../environments/environment';
import type { Installment } from '../models/admin.model';

export interface MemberProfile {
  memberId: string;
  fullName: string;
  fatherOrHusband: string;
  mother: string;
  dob: string;
  nid?: string;
  mobile: string;
  email?: string;
  occupation?: string;
  permanentHouse?: string;
  permanentRoad?: string;
  permanentPostOffice?: string;
  permanentUpazila?: string;
  permanentDistrict?: string;
  currentHouse?: string;
  currentRoad?: string;
  currentPostOffice?: string;
  currentUpazila?: string;
  currentDistrict?: string;
  properties: unknown[];
  nominees: unknown[];
}

@Injectable({ providedIn: 'root' })
export class MemberService {
  private base = `${environment.apiBaseUrl}/member`;
  private profileCache: Observable<MemberProfile> | null = null;

  constructor(private http: HttpClient) {}

  changePassword(oldPassword: string, newPassword: string): Observable<void> {
    return this.http.post<void>(`${this.base}/change-password`, {
      old_password: oldPassword,
      new_password: newPassword,
    });
  }

  getProfile(): Observable<MemberProfile> {
    if (!this.profileCache) {
      this.profileCache = this.http
        .get<MemberProfile>(`${this.base}/me`)
        .pipe(shareReplay({ bufferSize: 1, refCount: false }));
    }
    return this.profileCache;
  }

  clearProfileCache(): void {
    this.profileCache = null;
  }

  getInstallments(): Observable<Installment[]> {
    return this.http.get<Installment[]>(`${this.base}/installments`);
  }
}
