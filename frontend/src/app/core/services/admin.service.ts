import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import type { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import type {
  Installment,
  Member,
  SubmissionDetail,
  SubmissionStatus,
  SubmissionSummary,
} from '../models/admin.model';

@Injectable({ providedIn: 'root' })
export class AdminService {
  private base = `${environment.apiBaseUrl}/admin`;

  constructor(private http: HttpClient) {}

  listSubmissions(status?: SubmissionStatus): Observable<SubmissionSummary[]> {
    const url = status ? `${this.base}/submissions?status=${status}` : `${this.base}/submissions`;
    return this.http.get<SubmissionSummary[]>(url);
  }

  getSubmission(id: string): Observable<SubmissionDetail> {
    return this.http.get<SubmissionDetail>(`${this.base}/submissions/${id}`);
  }

  approveSubmission(id: string): Observable<{ member_id: string }> {
    return this.http.post<{ member_id: string }>(`${this.base}/submissions/${id}/approve`, {});
  }

  rejectSubmission(id: string, reason: string): Observable<void> {
    return this.http.post<void>(`${this.base}/submissions/${id}/reject`, { reason });
  }

  listMembers(): Observable<Member[]> {
    return this.http.get<Member[]>(`${this.base}/members`);
  }

  addInstallment(
    memberId: string,
    installment: { year: number; month: number; amount: number },
  ): Observable<Installment> {
    return this.http.post<Installment>(
      `${this.base}/members/${memberId}/installments`,
      installment,
    );
  }

  updateInstallment(id: string, status: 'paid' | 'due'): Observable<Installment> {
    return this.http.patch<Installment>(`${this.base}/installments/${id}`, { status });
  }
}
