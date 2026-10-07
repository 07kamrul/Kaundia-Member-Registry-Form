import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, type Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { toFileUrl } from './admin.service';

export type FinanceType = 'income' | 'expense';
export type FinanceStatus = 'draft' | 'pending' | 'approved' | 'rejected';
export type FinancePeriod = 'month' | 'year' | 'custom' | 'all';
export type PaymentSourceType = 'installment' | 'picnic_payment' | 'cost_share';

export interface FinanceTransaction {
  id: number;
  txnDate: string;
  type: FinanceType;
  categoryId: number | null;
  categoryLabel: string | null;
  amount: number;
  description: string;
  referenceNo: string | null;
  attachmentUrl: string | null;
  status: FinanceStatus;
  approvedByName: string | null;
  approvedAt: string | null;
  reversalOfId: number | null;
  createdAt: string;
  // Admin projection only
  internalNotes?: string | null;
  rejectionReason?: string | null;
  linkedPaymentType?: PaymentSourceType | null;
  linkedPaymentId?: number | null;
  createdByName?: string | null;
  isActive?: boolean;
}

export interface FinanceTotals {
  income: number;
  expense: number;
  net: number;
}

export interface FinanceLedgerPage {
  items: FinanceTransaction[];
  total: number;
  totals: FinanceTotals;
}

export interface FinanceCategoryBreakdown {
  categoryId: number | null;
  category: string;
  amount: number;
  share: number;
}

export interface FinanceSeriesPoint {
  label: string; // "2026-03" (month) / "2026" (year)
  income: number;
  expense: number;
  net: number;
}

export interface FinanceSummary {
  period: { type: FinancePeriod; dateFrom: string | null; dateTo: string | null };
  totals: FinanceTotals;
  balance: number;
  previous: FinanceTotals | null;
  incomeByCategory: FinanceCategoryBreakdown[];
  expenseByCategory: FinanceCategoryBreakdown[];
  previousIncomeByCategory: FinanceCategoryBreakdown[];
  previousExpenseByCategory: FinanceCategoryBreakdown[];
  series: FinanceSeriesPoint[];
  granularity: 'month' | 'year';
  transactionCount: number;
  lastUpdated: string | null;
}

export interface FinanceOverview {
  pendingCount: number;
  monthIncome: number;
  monthExpense: number;
  monthNet: number;
  balance: number;
  recent: FinanceTransaction[];
}

export interface UnlinkedPayment {
  sourceType: PaymentSourceType;
  sourceId: number;
  memberName: string | null;
  memberDisplayId: string | null;
  amount: number;
  paidOn: string;
  receiptNo: string | null;
  detail: string;
}

export interface FinanceCategory {
  id: number;
  type: FinanceType;
  label: string;
  isActive: boolean;
}

export interface FinanceTransactionInput {
  txnDate: string;
  type: FinanceType;
  categoryId: number;
  amount: number;
  description: string;
  referenceNo?: string | null;
  internalNotes?: string | null;
  status?: 'draft' | 'pending';
  linkedPaymentType?: PaymentSourceType | null;
  linkedPaymentId?: number | null;
}

export interface FinanceLedgerFilters {
  type?: FinanceType;
  categoryId?: number;
  dateFrom?: string;
  dateTo?: string;
  minAmount?: number;
  maxAmount?: number;
  reference?: string;
  approvedBy?: number;
  search?: string;
  limit?: number;
  offset?: number;
}

// ---------------------------------------------------------------------------
// Bangla-first money/date formatting for the finance screens.
//
// The transparency dashboard is Bengali-facing: when the UI language is Bangla
// the digits are Bengali (৫০,০০০) with South-Asian lakh grouping; in English
// the same lakh grouping keeps the two locales visually aligned. Existing
// pages keep their Western-digit format - this is deliberately scoped to the
// finance module.
// ---------------------------------------------------------------------------

const BN_DIGIT_MAP: Record<string, string> = {
  '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
  '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
};

function toBanglaDigits(text: string): string {
  return text.replace(/[0-9]/g, (digit) => BN_DIGIT_MAP[digit]);
}

/** 1250000.5 -> "12,50,000.50" (en) / "১২,৫০,০০০.৫০" (bn). */
export function formatFinanceAmount(value: number, lang: string): string {
  const grouped = (Number.isFinite(value) ? value : 0).toLocaleString('en-IN', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  return lang === 'bn' ? toBanglaDigits(grouped) : grouped;
}

/** 1250000.5 -> "৳ 12,50,000.50" / "৳ ১২,৫০,০০০.৫০". */
export function formatTaka(value: number, lang: string): string {
  return `৳ ${formatFinanceAmount(value, lang)}`;
}

/** Amount with no decimals when it is a whole taka: "৳ ৫০,০০০". */
export function formatTakaCompact(value: number, lang: string): string {
  const rounded = Math.round(Number.isFinite(value) ? value : 0);
  const grouped = rounded.toLocaleString('en-IN');
  return `৳ ${lang === 'bn' ? toBanglaDigits(grouped) : grouped}`;
}

/** Percent with one decimal, Bangla digits in Bangla: 42.3 -> "৪২.৩%". */
export function formatPercent(value: number, lang: string): string {
  const text = (Number.isFinite(value) ? value : 0).toFixed(1);
  return `${lang === 'bn' ? toBanglaDigits(text) : text}%`;
}

interface TransactionApiModel {
  id: number;
  txn_date: string;
  type: FinanceType;
  category_id: number | null;
  category_label: string | null;
  amount: string;
  description: string;
  reference_no: string | null;
  attachment_url: string | null;
  status: FinanceStatus;
  approved_by_name: string | null;
  approved_at: string | null;
  reversal_of_id: number | null;
  created_at: string;
  internal_notes?: string | null;
  rejection_reason?: string | null;
  linked_payment_type?: PaymentSourceType | null;
  linked_payment_id?: number | null;
  created_by_name?: string | null;
  is_active?: boolean;
}

interface LedgerApiModel {
  items: TransactionApiModel[];
  total: number;
  totals: { income: string; expense: string; net: string };
}

interface SummaryApiModel {
  period: { type: FinancePeriod; date_from: string | null; date_to: string | null };
  totals: { income: string; expense: string; net: string };
  balance: string;
  previous: { income: string; expense: string; net: string } | null;
  income_by_category: { category_id: number | null; category: string; amount: string; share: string }[];
  expense_by_category: { category_id: number | null; category: string; amount: string; share: string }[];
  previous_income_by_category: { category_id: number | null; category: string; amount: string; share: string }[];
  previous_expense_by_category: { category_id: number | null; category: string; amount: string; share: string }[];
  series: { label: string; income: string; expense: string; net: string }[];
  granularity: 'month' | 'year';
  transaction_count: number;
  last_updated: string | null;
}

function toNumber(value: string | number | undefined | null): number {
  return typeof value === 'number' ? value : Number(value ?? 0);
}

function toBreakdown(row: {
  category_id: number | null;
  category: string;
  amount: string;
  share: string;
}): FinanceCategoryBreakdown {
  return {
    categoryId: row.category_id,
    category: row.category,
    amount: toNumber(row.amount),
    share: toNumber(row.share),
  };
}

function toTransaction(api: TransactionApiModel): FinanceTransaction {
  return {
    id: api.id,
    txnDate: api.txn_date,
    type: api.type,
    categoryId: api.category_id,
    categoryLabel: api.category_label,
    amount: toNumber(api.amount),
    description: api.description,
    referenceNo: api.reference_no,
    attachmentUrl: api.attachment_url ? (toFileUrl(api.attachment_url) ?? null) : null,
    status: api.status,
    approvedByName: api.approved_by_name,
    approvedAt: api.approved_at,
    reversalOfId: api.reversal_of_id,
    createdAt: api.created_at,
    internalNotes: api.internal_notes ?? null,
    rejectionReason: api.rejection_reason ?? null,
    linkedPaymentType: api.linked_payment_type ?? null,
    linkedPaymentId: api.linked_payment_id ?? null,
    createdByName: api.created_by_name ?? null,
    isActive: api.is_active ?? true,
  };
}

function toLedgerPage(api: LedgerApiModel): FinanceLedgerPage {
  return {
    items: api.items.map(toTransaction),
    total: api.total,
    totals: {
      income: toNumber(api.totals.income),
      expense: toNumber(api.totals.expense),
      net: toNumber(api.totals.net),
    },
  };
}

function toSummary(api: SummaryApiModel): FinanceSummary {
  return {
    period: { type: api.period.type, dateFrom: api.period.date_from, dateTo: api.period.date_to },
    totals: {
      income: toNumber(api.totals.income),
      expense: toNumber(api.totals.expense),
      net: toNumber(api.totals.net),
    },
    balance: toNumber(api.balance),
    previous: api.previous
      ? {
          income: toNumber(api.previous.income),
          expense: toNumber(api.previous.expense),
          net: toNumber(api.previous.net),
        }
      : null,
    incomeByCategory: api.income_by_category.map(toBreakdown),
    expenseByCategory: api.expense_by_category.map(toBreakdown),
    previousIncomeByCategory: api.previous_income_by_category.map(toBreakdown),
    previousExpenseByCategory: api.previous_expense_by_category.map(toBreakdown),
    series: api.series.map((point) => ({
      label: point.label,
      income: toNumber(point.income),
      expense: toNumber(point.expense),
      net: toNumber(point.net),
    })),
    granularity: api.granularity,
    transactionCount: api.transaction_count,
    lastUpdated: api.last_updated,
  };
}

function filterParams(filters: FinanceLedgerFilters): Record<string, string> {
  const params: Record<string, string> = {};
  if (filters.type) params['type'] = filters.type;
  if (filters.categoryId != null) params['category_id'] = String(filters.categoryId);
  if (filters.dateFrom) params['date_from'] = filters.dateFrom;
  if (filters.dateTo) params['date_to'] = filters.dateTo;
  if (filters.minAmount != null) params['min_amount'] = String(filters.minAmount);
  if (filters.maxAmount != null) params['max_amount'] = String(filters.maxAmount);
  if (filters.reference) params['reference'] = filters.reference;
  if (filters.approvedBy != null) params['approved_by'] = String(filters.approvedBy);
  if (filters.search) params['search'] = filters.search;
  if (filters.limit != null) params['limit'] = String(filters.limit);
  if (filters.offset != null) params['offset'] = String(filters.offset);
  return params;
}

@Injectable({ providedIn: 'root' })
export class FinanceService {
  private readonly adminBase = `${environment.apiBaseUrl}/admin`;
  private readonly memberBase = `${environment.apiBaseUrl}/member`;

  constructor(private http: HttpClient) {}

  // ----- Member (read-only) -----

  getSummary(period: FinancePeriod, dateFrom?: string, dateTo?: string): Observable<FinanceSummary> {
    const params: Record<string, string> = { period };
    if (period === 'custom') {
      if (dateFrom) params['date_from'] = dateFrom;
      if (dateTo) params['date_to'] = dateTo;
    }
    return this.http
      .get<SummaryApiModel>(`${this.memberBase}/finance/summary`, { params })
      .pipe(map(toSummary));
  }

  getTransactions(filters: FinanceLedgerFilters = {}): Observable<FinanceLedgerPage> {
    return this.http
      .get<LedgerApiModel>(`${this.memberBase}/finance/transactions`, {
        params: filterParams(filters),
      })
      .pipe(map(toLedgerPage));
  }

  /** Server-rendered PDF as a blob; the caller saves it via an object URL. */
  downloadReport(filters: FinanceLedgerFilters & { period: FinancePeriod }): Observable<Blob> {
    const { period, ...rest } = filters;
    return this.http.get(`${this.memberBase}/finance/report.pdf`, {
      params: { ...filterParams(rest), period },
      responseType: 'blob',
    });
  }

  // ----- Admin: workflow -----

  adminTransactions(
    filters: FinanceLedgerFilters & { status?: FinanceStatus; includeInactive?: boolean },
  ): Observable<FinanceLedgerPage> {
    const { status, includeInactive, ...rest } = filters;
    const params = filterParams(rest);
    if (status) params['status'] = status;
    if (includeInactive) params['include_inactive'] = 'true';
    return this.http
      .get<LedgerApiModel>(`${this.adminBase}/finance/transactions`, { params })
      .pipe(map(toLedgerPage));
  }

  createTransaction(input: FinanceTransactionInput): Observable<FinanceTransaction> {
    return this.http
      .post<TransactionApiModel>(`${this.adminBase}/finance/transactions`, this.body(input))
      .pipe(map(toTransaction));
  }

  updateTransaction(id: number, changes: Partial<FinanceTransactionInput>): Observable<FinanceTransaction> {
    return this.http
      .patch<TransactionApiModel>(`${this.adminBase}/finance/transactions/${id}`, this.body(changes))
      .pipe(map(toTransaction));
  }

  private body(input: Partial<FinanceTransactionInput>): Record<string, unknown> {
    const payload: Record<string, unknown> = {};
    if (input.txnDate !== undefined) payload['txn_date'] = input.txnDate;
    if (input.type !== undefined) payload['type'] = input.type;
    if (input.categoryId !== undefined) payload['category_id'] = input.categoryId;
    if (input.amount !== undefined) payload['amount'] = input.amount;
    if (input.description !== undefined) payload['description'] = input.description;
    if (input.referenceNo !== undefined) payload['reference_no'] = input.referenceNo || null;
    if (input.internalNotes !== undefined) payload['internal_notes'] = input.internalNotes || null;
    if (input.status !== undefined) payload['status'] = input.status;
    if (input.linkedPaymentType !== undefined) payload['linked_payment_type'] = input.linkedPaymentType ?? null;
    if (input.linkedPaymentId !== undefined) payload['linked_payment_id'] = input.linkedPaymentId ?? null;
    return payload;
  }

  uploadAttachment(id: number, file: File): Observable<FinanceTransaction> {
    const body = new FormData();
    body.append('file', file);
    return this.http
      .put<TransactionApiModel>(`${this.adminBase}/finance/transactions/${id}/attachment`, body)
      .pipe(map(toTransaction));
  }

  submitTransaction(id: number): Observable<FinanceTransaction> {
    return this.http
      .post<TransactionApiModel>(`${this.adminBase}/finance/transactions/${id}/submit`, {})
      .pipe(map(toTransaction));
  }

  approveTransaction(id: number): Observable<FinanceTransaction> {
    return this.http
      .post<TransactionApiModel>(`${this.adminBase}/finance/transactions/${id}/approve`, {})
      .pipe(map(toTransaction));
  }

  rejectTransaction(id: number, reason: string): Observable<FinanceTransaction> {
    return this.http
      .post<TransactionApiModel>(`${this.adminBase}/finance/transactions/${id}/reject`, { reason })
      .pipe(map(toTransaction));
  }

  reverseTransaction(id: number, reason: string): Observable<FinanceTransaction> {
    return this.http
      .post<TransactionApiModel>(`${this.adminBase}/finance/transactions/${id}/reverse`, { reason })
      .pipe(map(toTransaction));
  }

  deleteTransaction(id: number, reason: string): Observable<void> {
    return this.http.request<void>('DELETE', `${this.adminBase}/finance/transactions/${id}`, {
      body: { reason },
    });
  }

  // ----- Admin: supporting data -----

  categories(): Observable<FinanceCategory[]> {
    return this.http
      .get<{ id: number; type: FinanceType; label: string; is_active: boolean }[]>(
        `${this.adminBase}/finance/categories`,
      )
      .pipe(
        map((rows) =>
          rows.map((row) => ({
            id: row.id,
            type: row.type,
            label: row.label,
            isActive: row.is_active,
          })),
        ),
      );
  }

  overview(): Observable<FinanceOverview> {
    return this.http
      .get<{
        pending_count: number;
        month_income: string;
        month_expense: string;
        month_net: string;
        balance: string;
        recent: TransactionApiModel[];
      }>(`${this.adminBase}/finance/overview`)
      .pipe(
        map((api) => ({
          pendingCount: api.pending_count,
          monthIncome: toNumber(api.month_income),
          monthExpense: toNumber(api.month_expense),
          monthNet: toNumber(api.month_net),
          balance: toNumber(api.balance),
          recent: api.recent.map(toTransaction),
        })),
      );
  }

  unlinkedPayments(
    sourceType?: PaymentSourceType,
    search?: string,
    limit = 50,
  ): Observable<UnlinkedPayment[]> {
    const params: Record<string, string> = { limit: String(limit) };
    if (sourceType) params['source_type'] = sourceType;
    if (search) params['search'] = search;
    return this.http
      .get<
        {
          source_type: PaymentSourceType;
          source_id: number;
          member_name: string | null;
          member_display_id: string | null;
          amount: string;
          paid_on: string;
          receipt_no: string | null;
          detail: string;
        }[]
      >(`${this.adminBase}/finance/unlinked-payments`, { params })
      .pipe(
        map((rows) =>
          rows.map((row) => ({
            sourceType: row.source_type,
            sourceId: row.source_id,
            memberName: row.member_name,
            memberDisplayId: row.member_display_id,
            amount: toNumber(row.amount),
            paidOn: row.paid_on,
            receiptNo: row.receipt_no,
            detail: row.detail,
          })),
        ),
      );
  }

  publishReportNotice(
    period: FinancePeriod,
    dateFrom?: string,
    dateTo?: string,
  ): Observable<{ id: number; title: string }> {
    return this.http.post<{ id: number; title: string }>(
      `${this.adminBase}/finance/publish-report-notice`,
      { period, date_from: dateFrom ?? null, date_to: dateTo ?? null },
    );
  }
}
