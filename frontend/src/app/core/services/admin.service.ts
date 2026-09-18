import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, type Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import type {
  Installment,
  Member,
  SubmissionDetail,
  SubmissionStatus,
  SubmissionSummary,
} from '../models/admin.model';

interface MemberApiModel {
  id: number;
  member_id: string | null;
  status: SubmissionStatus;
  full_name: string;
  mobile: string;
  email?: string;
  due_installments: number;
}

interface SubmissionSummaryApiModel {
  id: number;
  member_id: string | null;
  status: SubmissionStatus;
  full_name: string;
  mobile: string;
  created_at: string;
}

function toMember(api: MemberApiModel): Member {
  return {
    id: String(api.id),
    memberId: api.member_id,
    status: api.status,
    fullName: api.full_name,
    mobile: api.mobile,
    email: api.email,
    dueInstallments: api.due_installments,
  };
}

function toSubmissionSummary(api: SubmissionSummaryApiModel): SubmissionSummary {
  return {
    id: String(api.id),
    fullName: api.full_name,
    mobile: api.mobile,
    status: api.status,
    createdAt: api.created_at,
  };
}

@Injectable({ providedIn: 'root' })
export class AdminService {
  private base = `${environment.apiBaseUrl}/admin`;

  constructor(private http: HttpClient) {}

  listSubmissions(status?: SubmissionStatus): Observable<SubmissionSummary[]> {
    const url = status ? `${this.base}/submissions?status=${status}` : `${this.base}/submissions`;
    return this.http
      .get<SubmissionSummaryApiModel[]>(url)
      .pipe(map((rows) => rows.map(toSubmissionSummary)));
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
    return this.http
      .get<MemberApiModel[]>(`${this.base}/members`)
      .pipe(map((rows) => rows.map(toMember)));
  }

  getMemberInstallments(memberId: string): Observable<Installment[]> {
    return this.http.get<Installment[]>(`${this.base}/members/${memberId}/installments`);
  }

  deleteMember(memberId: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/members/${memberId}`);
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
