import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import type { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import type { Installment } from '../models/admin.model';

export interface MemberProfile {
  memberId: string;
  fullName: string;
  fatherOrHusband: string;
  mother: string;
  dob: string;
  mobile: string;
  email?: string;
  permanentAddress?: string;
  currentAddress?: string;
  properties: unknown[];
  nominees: unknown[];
}

@Injectable({ providedIn: 'root' })
export class MemberService {
  private base = `${environment.apiBaseUrl}/member`;

  constructor(private http: HttpClient) {}

  changePassword(oldPassword: string, newPassword: string): Observable<void> {
    return this.http.post<void>(`${this.base}/change-password`, {
      old_password: oldPassword,
      new_password: newPassword,
    });
  }

  getProfile(): Observable<MemberProfile> {
    return this.http.get<MemberProfile>(`${this.base}/me`);
  }

  getInstallments(): Observable<Installment[]> {
    return this.http.get<Installment[]>(`${this.base}/installments`);
  }
}
