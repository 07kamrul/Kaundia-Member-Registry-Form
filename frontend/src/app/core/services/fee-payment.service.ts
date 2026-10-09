import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface FeeTypeInfo {
  key: string;
  /** Suggested amount from Fee Settings, null when the committee has not
   * configured one (the member then types the amount themselves). */
  defaultAmount: number | null;
  unit: string | null;
}

export interface FeePayment {
  id: number;
  feeType: string;
  amount: number;
  paymentDate: string;
  receiptNo: string | null;
  paymentMethod: string | null;
  note: string | null;
  createdAt: string;
}

export interface FeePaymentPayload {
  feeType: string;
  amount: number;
  paymentDate: string;
  receiptNo?: string;
  paymentMethod?: string;
  note?: string;
}

interface FeeTypeInfoApi {
  key: string;
  default_amount: number | null;
  unit: string | null;
}

interface FeePaymentApi {
  id: number;
  fee_type: string;
  amount: string | number;
  payment_date: string;
  receipt_no: string | null;
  payment_method: string | null;
  note: string | null;
  created_at: string;
}

function toFeeTypeInfo(api: FeeTypeInfoApi): FeeTypeInfo {
  return { key: api.key, defaultAmount: api.default_amount, unit: api.unit };
}

function toFeePayment(api: FeePaymentApi): FeePayment {
  return {
    id: api.id,
    feeType: api.fee_type,
    amount: Number(api.amount),
    paymentDate: api.payment_date,
    receiptNo: api.receipt_no,
    paymentMethod: api.payment_method,
    note: api.note,
    createdAt: api.created_at,
  };
}

@Injectable({ providedIn: 'root' })
export class FeePaymentService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiBaseUrl}/member`;

  getFeeTypes(paymentDate?: string): Observable<FeeTypeInfo[]> {
    const options = paymentDate ? { params: { payment_date: paymentDate } } : {};
    return this.http
      .get<FeeTypeInfoApi[]>(`${this.base}/fee-types`, options)
      .pipe(map((rows) => rows.map(toFeeTypeInfo)));
  }

  getFeePayments(): Observable<FeePayment[]> {
    return this.http
      .get<FeePaymentApi[]>(`${this.base}/fee-payments`)
      .pipe(map((rows) => rows.map(toFeePayment)));
  }

  createFeePayment(payload: FeePaymentPayload): Observable<FeePayment> {
    return this.http
      .post<FeePaymentApi>(`${this.base}/fee-payments`, {
        fee_type: payload.feeType,
        amount: payload.amount,
        payment_date: payload.paymentDate,
        receipt_no: payload.receiptNo || null,
        payment_method: payload.paymentMethod || null,
        note: payload.note || null,
      })
      .pipe(map(toFeePayment));
  }
}
