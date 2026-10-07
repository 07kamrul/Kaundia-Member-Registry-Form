import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, type Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { toFileUrl } from './admin.service';

export type PaymentStatus = 'pending' | 'approved' | 'rejected';

export interface PayableInstallment {
  id: number;
  year: number;
  month: number;
  amount: number;
}

export interface PaymentAccount {
  method: string;
  details: string;
}

export interface InstallmentPayment {
  id: number;
  method: string;
  transactionRef: string;
  senderAccount: string | null;
  amount: number;
  paidOn: string;
  proofUrl: string | null;
  note: string | null;
  status: PaymentStatus;
  rejectionReason: string | null;
  reviewedAt: string | null;
  createdAt: string;
  installments: PayableInstallment[];
}

export interface AdminInstallmentPayment extends InstallmentPayment {
  memberId: number;
  memberName: string | null;
  memberDisplayId: string | null;
}

export interface PayableSummary {
  due: PayableInstallment[];
  pendingInstallmentIds: number[];
  totalDue: number;
  accounts: PaymentAccount[];
  payments: InstallmentPayment[];
}

export interface PaymentSubmission {
  installmentIds: number[];
  method: string;
  transactionRef: string;
  paidOn: string;
  senderAccount?: string;
  note?: string;
  proof?: File | null;
}

interface InstallmentApi {
  id: number;
  year: number;
  month: number;
  amount: number | string;
}

interface PaymentApi {
  id: number;
  method: string;
  transaction_ref: string;
  sender_account: string | null;
  amount: number | string;
  paid_on: string;
  proof_url: string | null;
  note: string | null;
  status: PaymentStatus;
  rejection_reason: string | null;
  reviewed_at: string | null;
  created_at: string;
  installments: InstallmentApi[];
}

interface AdminPaymentApi extends PaymentApi {
  member_id: number;
  member_name: string | null;
  member_display_id: string | null;
}

interface PayableSummaryApi {
  due: InstallmentApi[];
  pending_installment_ids: number[];
  total_due: number | string;
  accounts: PaymentAccount[];
  payments: PaymentApi[];
}

const toInstallment = (row: InstallmentApi): PayableInstallment => ({
  id: row.id,
  year: row.year,
  month: row.month,
  amount: Number(row.amount),
});

const toPayment = (api: PaymentApi): InstallmentPayment => ({
  id: api.id,
  method: api.method,
  transactionRef: api.transaction_ref,
  senderAccount: api.sender_account,
  amount: Number(api.amount),
  paidOn: api.paid_on,
  proofUrl: toFileUrl(api.proof_url) ?? null,
  note: api.note,
  status: api.status,
  rejectionReason: api.rejection_reason,
  reviewedAt: api.reviewed_at,
  createdAt: api.created_at,
  installments: api.installments.map(toInstallment),
});

const toAdminPayment = (api: AdminPaymentApi): AdminInstallmentPayment => ({
  ...toPayment(api),
  memberId: api.member_id,
  memberName: api.member_name,
  memberDisplayId: api.member_display_id,
});

@Injectable({ providedIn: 'root' })
export class InstallmentPaymentService {
  private readonly memberBase = `${environment.apiBaseUrl}/member/installment-payments`;
  private readonly adminBase = `${environment.apiBaseUrl}/admin/installment-payments`;

  constructor(private http: HttpClient) {}

  getPayable(): Observable<PayableSummary> {
    return this.http.get<PayableSummaryApi>(`${this.memberBase}/payable`).pipe(
      map((api) => ({
        due: api.due.map(toInstallment),
        pendingInstallmentIds: api.pending_installment_ids,
        totalDue: Number(api.total_due),
        accounts: api.accounts,
        payments: api.payments.map(toPayment),
      })),
    );
  }

  submit(payload: PaymentSubmission): Observable<InstallmentPayment> {
    const form = new FormData();
    form.append('installment_ids', payload.installmentIds.join(','));
    form.append('method', payload.method);
    form.append('transaction_ref', payload.transactionRef.trim());
    form.append('paid_on', payload.paidOn);
    if (payload.senderAccount?.trim()) form.append('sender_account', payload.senderAccount.trim());
    if (payload.note?.trim()) form.append('note', payload.note.trim());
    if (payload.proof) form.append('proof', payload.proof);
    return this.http.post<PaymentApi>(this.memberBase, form).pipe(map(toPayment));
  }

  listForAdmin(status?: PaymentStatus): Observable<AdminInstallmentPayment[]> {
    const params: Record<string, string> = status ? { status } : {};
    return this.http
      .get<AdminPaymentApi[]>(this.adminBase, { params })
      .pipe(map((rows) => rows.map(toAdminPayment)));
  }

  pendingCount(): Observable<number> {
    return this.http.get<{ count: number }>(`${this.adminBase}/pending-count`).pipe(map((r) => r.count));
  }

  approve(id: number): Observable<AdminInstallmentPayment> {
    return this.http.post<AdminPaymentApi>(`${this.adminBase}/${id}/approve`, {}).pipe(map(toAdminPayment));
  }

  reject(id: number, reason: string): Observable<AdminInstallmentPayment> {
    return this.http
      .post<AdminPaymentApi>(`${this.adminBase}/${id}/reject`, { reason })
      .pipe(map(toAdminPayment));
  }
}
