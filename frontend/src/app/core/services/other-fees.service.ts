import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

/** One payable, non-installment fee type as offered on the Other Fees page.
 * The catalog is API data (driven by Fee Settings + fee_category), never a
 * hard-coded list - newly configured types appear automatically. */
export interface OtherFeeType {
  key: string;
  label: string;
  calculation: 'fixed' | 'variable' | 'picnic';
  amount: number | null;
  unit: string | null;
  payOnce: boolean;
  alreadyPaid: boolean | null;
  headFee: number | null;
  additionalHeadFee: number | null;
}

export interface OtherFeePayment {
  id: number;
  source: string;
  feeType: string;
  amount: number;
  paymentDate: string;
  additionalHeads: number | null;
  receiptNo: string | null;
  paymentMethod: string | null;
  note: string | null;
  createdAt: string;
}

export interface OtherFeeHistorySummary {
  totalPaid: number;
  byType: Record<string, number>;
}

export interface OtherFeeHistoryPage {
  items: OtherFeePayment[];
  total: number;
  page: number;
  pageSize: number;
  summary: OtherFeeHistorySummary;
}

export interface OtherFeePaymentPayload {
  feeType: string;
  paymentDate: string;
  paymentMethod?: string;
  receiptNo?: string;
  note?: string;
  /** Variable (custom-amount) types only - fixed and picnic totals are
   * recomputed server-side and any client value is ignored. */
  amount?: number;
  /** Picnic only. */
  additionalHeads?: number;
  additionalPeople?: { name: string; relation: string }[];
}

interface OtherFeeTypeApi {
  key: string;
  label: string;
  calculation: string;
  amount: number | null;
  unit: string | null;
  pay_once: boolean;
  already_paid: boolean | null;
  head_fee: number | null;
  additional_head_fee: number | null;
}

interface OtherFeePaymentApi {
  id: number;
  source: string;
  fee_type: string;
  amount: string | number;
  payment_date: string;
  additional_heads: number | null;
  receipt_no: string | null;
  payment_method: string | null;
  note: string | null;
  created_at: string;
}

interface OtherFeeHistoryPageApi {
  items: OtherFeePaymentApi[];
  total: number;
  page: number;
  page_size: number;
  summary: { total_paid: number; by_type: Record<string, number> };
}

function toFeeType(api: OtherFeeTypeApi): OtherFeeType {
  return {
    key: api.key,
    label: api.label,
    calculation: api.calculation as OtherFeeType['calculation'],
    amount: api.amount,
    unit: api.unit,
    payOnce: api.pay_once,
    alreadyPaid: api.already_paid,
    headFee: api.head_fee,
    additionalHeadFee: api.additional_head_fee,
  };
}

function toPayment(api: OtherFeePaymentApi): OtherFeePayment {
  return {
    id: api.id,
    source: api.source,
    feeType: api.fee_type,
    amount: Number(api.amount),
    paymentDate: api.payment_date,
    additionalHeads: api.additional_heads,
    receiptNo: api.receipt_no,
    paymentMethod: api.payment_method,
    note: api.note,
    createdAt: api.created_at,
  };
}

@Injectable({ providedIn: 'root' })
export class OtherFeesService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiBaseUrl}/member/other-fees`;

  getFeeTypes(paymentDate?: string): Observable<OtherFeeType[]> {
    const options = paymentDate ? { params: { payment_date: paymentDate } } : {};
    return this.http
      .get<OtherFeeTypeApi[]>(`${this.base}/types`, options)
      .pipe(map((rows) => rows.map(toFeeType)));
  }

  getPayments(filters: {
    feeType?: string;
    dateFrom?: string;
    dateTo?: string;
    page?: number;
    pageSize?: number;
  }): Observable<OtherFeeHistoryPage> {
    const params: Record<string, string> = {};
    if (filters.feeType) params['fee_type'] = filters.feeType;
    if (filters.dateFrom) params['date_from'] = filters.dateFrom;
    if (filters.dateTo) params['date_to'] = filters.dateTo;
    if (filters.page != null) params['page'] = String(filters.page);
    if (filters.pageSize != null) params['page_size'] = String(filters.pageSize);
    return this.http.get<OtherFeeHistoryPageApi>(`${this.base}/payments`, { params }).pipe(
      map((page) => ({
        items: page.items.map(toPayment),
        total: page.total,
        page: page.page,
        pageSize: page.page_size,
        summary: { totalPaid: page.summary.total_paid, byType: page.summary.by_type },
      })),
    );
  }

  createPayment(payload: OtherFeePaymentPayload): Observable<OtherFeePayment> {
    return this.http
      .post<OtherFeePaymentApi>(`${this.base}/payments`, {
        fee_type: payload.feeType,
        payment_date: payload.paymentDate,
        payment_method: payload.paymentMethod || null,
        receipt_no: payload.receiptNo || null,
        note: payload.note || null,
        amount: payload.amount ?? null,
        additional_heads: payload.additionalHeads ?? null,
        additional_people: payload.additionalPeople?.length ? payload.additionalPeople : null,
      })
      .pipe(map(toPayment));
  }
}
