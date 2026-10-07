import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, type Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { toFileUrl } from './admin.service';

export type CostPaymentSource = 'society_fund' | 'member_billed';
export type SplitMethod = 'equal' | 'by_land_quantity' | 'manual';
export type ShareStatus = 'unpaid' | 'partial' | 'paid';

export interface CostSplitShare {
  id: number;
  costSplitId: number;
  memberId: number;
  memberName: string | null;
  memberDisplayId: string | null;
  costTitle: string | null;
  costIncurredDate: string | null;
  costCategory: string | null;
  amountDue: number;
  amountPaid: number;
  status: ShareStatus;
  paidAt: string | null;
  paymentMethodId: number | null;
  paymentMethodLabel: string | null;
  receiptNo: string | null;
}

export interface CostSplit {
  id: number;
  societyCostId: number;
  splitMethod: SplitMethod;
  createdAt: string;
  shares: CostSplitShare[];
}

export interface SocietyCost {
  id: number;
  title: string;
  description: string | null;
  categoryId: number | null;
  categoryLabel: string | null;
  totalAmount: number;
  incurredDate: string;
  paymentSource: CostPaymentSource;
  receiptFileUrl: string | undefined;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
  split: CostSplit | null;
}

export interface SocietyCostInput {
  title: string;
  description?: string | null;
  categoryId?: number | null;
  totalAmount: number;
  incurredDate: string;
  paymentSource: CostPaymentSource;
  notes?: string | null;
}

export interface SplitPreviewRow {
  memberId: number;
  memberName: string;
  amountDue: number;
}

export interface SocietyCostSummary {
  totalAmount: number;
  societyFundTotal: number;
  memberBilledTotal: number;
  outstandingTotal: number;
  collectedTotal: number;
  byCategory: { category: string; total: string }[];
}

interface ShareApiModel {
  id: number;
  cost_split_id: number;
  member_id: number;
  member_name: string | null;
  member_display_id: string | null;
  cost_title?: string | null;
  cost_incurred_date?: string | null;
  cost_category?: string | null;
  amount_due: string | number;
  amount_paid: string | number;
  status: ShareStatus;
  paid_at: string | null;
  payment_method_id: number | null;
  payment_method_label: string | null;
  receipt_no: string | null;
}

interface SplitApiModel {
  id: number;
  society_cost_id: number;
  split_method: SplitMethod;
  created_by: number | null;
  created_at: string;
  shares: ShareApiModel[];
}

interface CostApiModel {
  id: number;
  title: string;
  description: string | null;
  category_id: number | null;
  category_label: string | null;
  total_amount: string | number;
  incurred_date: string;
  payment_source: CostPaymentSource;
  receipt_file_url: string | null;
  notes: string | null;
  created_by: number | null;
  created_at: string;
  updated_at: string;
  split: SplitApiModel | null;
}

function toNumber(value: string | number): number {
  return typeof value === 'number' ? value : Number(value);
}

function toShare(api: ShareApiModel): CostSplitShare {
  return {
    id: api.id,
    costSplitId: api.cost_split_id,
    memberId: api.member_id,
    memberName: api.member_name,
    memberDisplayId: api.member_display_id,
    costTitle: api.cost_title ?? null,
    costIncurredDate: api.cost_incurred_date ?? null,
    costCategory: api.cost_category ?? null,
    amountDue: toNumber(api.amount_due),
    amountPaid: toNumber(api.amount_paid),
    status: api.status,
    paidAt: api.paid_at,
    paymentMethodId: api.payment_method_id,
    paymentMethodLabel: api.payment_method_label,
    receiptNo: api.receipt_no,
  };
}

function toCost(api: CostApiModel): SocietyCost {
  return {
    id: api.id,
    title: api.title,
    description: api.description,
    categoryId: api.category_id,
    categoryLabel: api.category_label,
    totalAmount: toNumber(api.total_amount),
    incurredDate: api.incurred_date,
    paymentSource: api.payment_source,
    receiptFileUrl: toFileUrl(api.receipt_file_url),
    notes: api.notes,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
    split: api.split
      ? {
          id: api.split.id,
          societyCostId: api.split.society_cost_id,
          splitMethod: api.split.split_method,
          createdAt: api.split.created_at,
          shares: api.split.shares.map(toShare),
        }
      : null,
  };
}

export interface CostListFilters {
  categoryId?: number;
  dateFrom?: string;
  dateTo?: string;
  paymentSource?: CostPaymentSource;
  billed?: boolean;
  search?: string;
}

@Injectable({ providedIn: 'root' })
export class SocietyCostService {
  private adminBase = `${environment.apiBaseUrl}/admin`;
  private memberBase = `${environment.apiBaseUrl}/member`;

  constructor(private http: HttpClient) {}

  listCosts(filters: CostListFilters = {}): Observable<SocietyCost[]> {
    const params: Record<string, string> = {};
    if (filters.categoryId != null) params['category_id'] = String(filters.categoryId);
    if (filters.dateFrom) params['date_from'] = filters.dateFrom;
    if (filters.dateTo) params['date_to'] = filters.dateTo;
    if (filters.paymentSource) params['payment_source'] = filters.paymentSource;
    if (filters.billed !== undefined) params['billed'] = String(filters.billed);
    if (filters.search) params['search'] = filters.search;
    return this.http
      .get<CostApiModel[]>(`${this.adminBase}/society-costs`, { params })
      .pipe(map((rows) => rows.map(toCost)));
  }

  createCost(input: SocietyCostInput): Observable<SocietyCost> {
    return this.http.post<CostApiModel>(`${this.adminBase}/society-costs`, this.costBody(input)).pipe(map(toCost));
  }

  updateCost(id: number, input: SocietyCostInput): Observable<SocietyCost> {
    return this.http
      .patch<CostApiModel>(`${this.adminBase}/society-costs/${id}`, this.costBody(input))
      .pipe(map(toCost));
  }

  deleteCost(id: number): Observable<void> {
    return this.http.delete<void>(`${this.adminBase}/society-costs/${id}`);
  }

  uploadReceipt(id: number, file: File): Observable<SocietyCost> {
    const body = new FormData();
    body.append('file', file);
    return this.http
      .put<CostApiModel>(`${this.adminBase}/society-costs/${id}/receipt`, body)
      .pipe(map(toCost));
  }

  /** dry_run=true returns the computed shares without saving anything. */
  splitCost(
    id: number,
    payload: {
      split_method: SplitMethod;
      manual_shares?: { member_id: number; amount_due: number }[];
      allow_mismatch?: boolean;
      dry_run?: boolean;
    },
  ): Observable<SocietyCost | SplitPreviewRow[]> {
    return this.http
      .post<CostApiModel | { member_id: number; member_name: string; amount_due: string }[]>(
        `${this.adminBase}/society-costs/${id}/split`,
        payload,
      )
      .pipe(
        map((res) =>
          Array.isArray(res)
            ? res.map((row) => ({
                memberId: row.member_id,
                memberName: row.member_name,
                amountDue: toNumber(row.amount_due),
              }))
            : toCost(res),
        ),
      );
  }

  recordSharePayment(
    shareId: number,
    payload: { amount_paid: number; receipt_no?: string | null },
  ): Observable<CostSplitShare> {
    return this.http
      .patch<ShareApiModel>(`${this.adminBase}/cost-split-shares/${shareId}`, payload)
      .pipe(map(toShare));
  }

  getSummary(filters: { dateFrom?: string; dateTo?: string } = {}): Observable<SocietyCostSummary> {
    const params: Record<string, string> = {};
    if (filters.dateFrom) params['date_from'] = filters.dateFrom;
    if (filters.dateTo) params['date_to'] = filters.dateTo;
    return this.http
      .get<{
        total_amount: string;
        society_fund_total: string;
        member_billed_total: string;
        outstanding_total: string;
        collected_total: string;
        by_category: { category: string; total: string }[];
      }>(`${this.adminBase}/society-costs/summary`, { params })
      .pipe(
        map((res) => ({
          totalAmount: toNumber(res.total_amount),
          societyFundTotal: toNumber(res.society_fund_total),
          memberBilledTotal: toNumber(res.member_billed_total),
          outstandingTotal: toNumber(res.outstanding_total),
          collectedTotal: toNumber(res.collected_total),
          byCategory: res.by_category,
        })),
      );
  }

  /** The signed-in member's own shares only (server-enforced scoping). */
  myCostShares(): Observable<CostSplitShare[]> {
    return this.http
      .get<ShareApiModel[]>(`${this.memberBase}/cost-shares`)
      .pipe(map((rows) => rows.map(toShare)));
  }

  private costBody(input: SocietyCostInput): Record<string, unknown> {
    return {
      title: input.title,
      description: input.description ?? null,
      category_id: input.categoryId ?? null,
      total_amount: input.totalAmount,
      incurred_date: input.incurredDate,
      payment_source: input.paymentSource,
      notes: input.notes ?? null,
    };
  }
}
