import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnDestroy,
  OnInit,
  inject,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { DatePickerComponent } from '../../../../shared/date-picker/date-picker.component';
import { DonutChartComponent } from '../../../../shared/charts/donut-chart.component';
import { TrendChartComponent } from '../../../../shared/charts/trend-chart.component';
import { SparklineComponent } from '../../../../shared/charts/sparkline.component';
import { AttachmentService } from '../../../../core/services/attachment.service';
import {
  FinanceService,
  formatFinanceAmount,
  formatPercent,
  formatTaka,
  formatTakaCompact,
  type FinanceCategoryBreakdown,
  type FinanceLedgerFilters,
  type FinanceLedgerPage,
  type FinancePeriod,
  type FinanceSummary,
  type FinanceTransaction,
  type FinanceType,
} from '../../../../core/services/finance.service';
import { monthNameKey } from '../../../../shared/constants/months';

const PAGE_SIZES = [10, 25, 50];

/** One "smart" observation derived from the summary numbers. */
interface Insight {
  key: string; // i18n key suffix: 'expenseSpike' | 'incomeUp' | ...
  params: Record<string, string | number>;
  tone: 'up' | 'down' | 'info';
}

@Component({
  selector: 'app-fund-transparency',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    FormsModule,
    TranslatePipe,
    IconComponent,
    DatePickerComponent,
    DonutChartComponent,
    TrendChartComponent,
    SparklineComponent,
  ],
  templateUrl: './fund-transparency.component.html',
  styleUrl: './fund-transparency.component.scss',
})
export class FundTransparencyComponent implements OnInit, OnDestroy {
  readonly pageSizes = PAGE_SIZES;
  readonly periodTypes: FinancePeriod[] = ['month', 'year', 'custom', 'all'];

  // ----- Period -----
  periodType: FinancePeriod = 'month';
  customFrom = '';
  customTo = '';
  periodError = '';

  // ----- Summary -----
  summary: FinanceSummary | null = null;
  summaryLoading = true;
  summaryError = '';

  // ----- Ledger filters (server-side; chips show the active ones) -----
  typeFilter: FinanceType | '' = '';
  categoryFilter = '';
  ledgerDateFrom = '';
  ledgerDateTo = '';
  minAmount: number | null = null;
  maxAmount: number | null = null;
  referenceFilter = '';
  approvedByName = '';
  searchText = '';

  // ----- Ledger -----
  ledger: FinanceLedgerPage | null = null;
  ledgerLoading = true;
  ledgerError = '';
  page = 1;
  pageSize = 25;

  expandedId: number | null = null;

  // ----- Attachment preview -----
  previewOpen = false;
  previewLoading = false;
  previewError = '';
  previewUrl: string | null = null;
  previewIsImage = false;
  private objectUrl: string | null = null;

  // ----- PDF -----
  pdfDownloading = false;
  pdfError = '';

  // Tabs for the income/expense summary section.
  trendTab: 'monthly' | 'yearly' = 'monthly';

  readonly pageSizeOptions = PAGE_SIZES;

  private readonly cdr = inject(ChangeDetectorRef);
  private readonly attachments = inject(AttachmentService);

  constructor(
    private finance: FinanceService,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.applyPeriod();
  }

  ngOnDestroy(): void {
    this.revokePreview();
  }

  get lang(): string {
    // ngx-translate v18: currentLang is a signal.
    return this.translate.currentLang() || 'bn';
  }

  abs(value: number): number {
    return Math.abs(value);
  }

  onPageSizeSelect(value: string | number): void {
    this.pageSize = Number(value);
    this.onPageSizeChange();
  }

  // ----- Period -----

  setPeriod(period: FinancePeriod): void {
    if (this.periodType === period) return;
    this.periodType = period;
    this.applyPeriod();
  }

  applyPeriod(): void {
    if (this.periodType === 'custom') {
      if (!this.customFrom || !this.customTo || this.customFrom > this.customTo) {
        this.periodError = this.translate.instant('member.fundTransparency.errors.customRange');
        this.cdr.markForCheck();
        return;
      }
    }
    this.periodError = '';
    this.loadSummary();
    // The period switch re-renders the whole page: the ledger's date filter
    // follows the new period so no stale numbers survive anywhere.
    this.loadLedgerWithPeriodDates();
  }

  private periodQuery(): { period: FinancePeriod; dateFrom?: string; dateTo?: string } {
    if (this.periodType === 'custom') {
      return { period: 'custom', dateFrom: this.customFrom, dateTo: this.customTo };
    }
    return { period: this.periodType };
  }

  loadSummary(): void {
    this.summaryLoading = true;
    this.summaryError = '';
    const { period, dateFrom, dateTo } = this.periodQuery();
    this.finance.getSummary(period, dateFrom, dateTo).subscribe({
      next: (summary) => {
        this.summary = summary;
        this.summaryLoading = false;
        this.trendTab = summary.granularity === 'year' ? 'yearly' : 'monthly';
        this.cdr.markForCheck();
      },
      error: () => {
        this.summaryLoading = false;
        this.summaryError = this.translate.instant('member.fundTransparency.errors.loadFailed');
        this.cdr.markForCheck();
      },
    });
  }

  // ----- Ledger -----

  private loadLedgerWithPeriodDates(): void {
    const summaryDates = this.summary?.period;
    if (summaryDates?.dateFrom) this.ledgerDateFrom = summaryDates.dateFrom;
    if (summaryDates?.dateTo) this.ledgerDateTo = summaryDates.dateTo;
    this.page = 1;
    this.loadLedger();
  }

  currentFilters(): FinanceLedgerFilters {
    return {
      type: this.typeFilter || undefined,
      categoryId: this.categoryFilter ? Number(this.categoryFilter) : undefined,
      dateFrom: this.ledgerDateFrom || undefined,
      dateTo: this.ledgerDateTo || undefined,
      minAmount: this.minAmount != null && this.minAmount > 0 ? this.minAmount : undefined,
      maxAmount: this.maxAmount != null && this.maxAmount > 0 ? this.maxAmount : undefined,
      reference: this.referenceFilter.trim() || undefined,
      approvedBy: undefined,
      search: this.searchText.trim() || undefined,
      limit: this.pageSize,
      offset: (this.page - 1) * this.pageSize,
    };
  }

  loadLedger(): void {
    this.ledgerLoading = true;
    this.ledgerError = '';
    this.finance.getTransactions(this.currentFilters()).subscribe({
      next: (ledger) => {
        this.ledger = ledger;
        this.ledgerLoading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.ledgerLoading = false;
        this.ledgerError = this.translate.instant('member.fundTransparency.errors.loadFailed');
        this.cdr.markForCheck();
      },
    });
  }

  applyFilters(): void {
    this.page = 1;
    this.loadLedger();
  }

  get activeChips(): { key: string; label: string }[] {
    const chips: { key: string; label: string }[] = [];
    const t = this.translate;
    if (this.typeFilter) {
      chips.push({
        key: 'type',
        label: `${t.instant('member.fundTransparency.type.' + this.typeFilter)}`,
      });
    }
    if (this.categoryFilter) {
      const category = this.ledgerCategoryLabel();
      if (category) chips.push({ key: 'category', label: category });
    }
    if (this.searchText.trim()) {
      chips.push({ key: 'search', label: `"${this.searchText.trim()}"` });
    }
    if (this.referenceFilter.trim()) {
      chips.push({ key: 'reference', label: this.referenceFilter.trim() });
    }
    if (this.minAmount != null && this.minAmount > 0) {
      chips.push({ key: 'minAmount', label: `≥ ${formatTakaCompact(this.minAmount, this.lang)}` });
    }
    if (this.maxAmount != null && this.maxAmount > 0) {
      chips.push({ key: 'maxAmount', label: `≤ ${formatTakaCompact(this.maxAmount, this.lang)}` });
    }
    if (this.approvedByName.trim()) {
      chips.push({
        key: 'approvedByName',
        label: `${t.instant('member.fundTransparency.filters.approvedBy')}: ${this.approvedByName.trim()}`,
      });
    }
    return chips;
  }

  private ledgerCategoryLabel(): string | null {
    const fromLedger = (this.ledger?.items ?? []).find(
      (item) => item.categoryId === Number(this.categoryFilter),
    );
    if (fromLedger?.categoryLabel) return fromLedger.categoryLabel;
    // Fallback: look in the summary breakdowns so the chip shows before the
    // first filtered page arrives.
    for (const row of [
      ...(this.summary?.incomeByCategory ?? []),
      ...(this.summary?.expenseByCategory ?? []),
    ]) {
      if (row.categoryId === Number(this.categoryFilter)) return row.category;
    }
    return null;
  }

  removeChip(key: string): void {
    switch (key) {
      case 'type':
        this.typeFilter = '';
        break;
      case 'category':
        this.categoryFilter = '';
        break;
      case 'search':
        this.searchText = '';
        break;
      case 'reference':
        this.referenceFilter = '';
        break;
      case 'minAmount':
        this.minAmount = null;
        break;
      case 'maxAmount':
        this.maxAmount = null;
        break;
      case 'approvedByName':
        this.approvedByName = '';
        break;
    }
    this.applyFilters();
  }

  clearAllFilters(): void {
    this.typeFilter = '';
    this.categoryFilter = '';
    this.minAmount = null;
    this.maxAmount = null;
    this.referenceFilter = '';
    this.approvedByName = '';
    this.searchText = '';
    this.applyPeriod(); // also restores the period's date range
  }

  get totalPages(): number {
    return Math.max(1, Math.ceil((this.ledger?.total ?? 0) / this.pageSize));
  }

  changePage(delta: number): void {
    const next = this.page + delta;
    if (next < 1 || next > this.totalPages) return;
    this.page = next;
    this.loadLedger();
  }

  onPageSizeChange(): void {
    this.page = 1;
    this.loadLedger();
  }

  toggleExpanded(id: number): void {
    this.expandedId = this.expandedId === id ? null : id;
    this.cdr.markForCheck();
  }

  // ----- Smart insights (computed from the summary, phrased via i18n) -----

  private pctChange(current: number, previous: number): number | null {
    if (previous <= 0) return current > 0 ? null : 0;
    return Math.round(((current - previous) / previous) * 100);
  }

  /** e.g. "এই মাসে আয় হয়েছে ৫০,০০০ টাকা, ব্যয় হয়েছে ৩২,০০০ টাকা, নিট জমা ১৮,০০০ টাকা" */
  get summaryLineParams(): Record<string, string> {
    const totals = this.summary?.totals ?? { income: 0, expense: 0, net: 0 };
    return {
      income: formatTakaCompact(totals.income, this.lang),
      expense: formatTakaCompact(totals.expense, this.lang),
      net: formatTakaCompact(totals.net, this.lang),
    };
  }

  get incomeDelta(): number | null {
    if (!this.summary?.previous) return null;
    return this.pctChange(this.summary.totals.income, this.summary.previous.income);
  }

  get expenseDelta(): number | null {
    if (!this.summary?.previous) return null;
    return this.pctChange(this.summary.totals.expense, this.summary.previous.expense);
  }

  get netDelta(): number | null {
    if (!this.summary?.previous) return null;
    return this.pctChange(this.summary.totals.net, this.summary.previous.net);
  }

  /** Top 2-3 expense categories, automatically highlighted. */
  get topExpenseCategories(): FinanceCategoryBreakdown[] {
    return (this.summary?.expenseByCategory ?? []).slice(0, 3);
  }

  get topIncomeCategories(): FinanceCategoryBreakdown[] {
    return (this.summary?.incomeByCategory ?? []).slice(0, 3);
  }

  /** Categories whose expense jumped >= 25% vs the previous window. */
  get expenseSpikes(): { category: string; pct: number }[] {
    const summary = this.summary;
    if (!summary || !summary.previous) return [];
    const previous = new Map(
      summary.previousExpenseByCategory.map((row) => [row.category, row.amount]),
    );
    const spikes: { category: string; pct: number }[] = [];
    for (const row of summary.expenseByCategory) {
      const before = previous.get(row.category) ?? 0;
      if (before <= 0) continue;
      const pct = Math.round(((row.amount - before) / before) * 100);
      if (pct >= 25 && row.amount - before >= 500) {
        spikes.push({ category: row.category, pct });
      }
    }
    return spikes.slice(0, 3);
  }

  get visibleSeries(): { label: string; income: number; expense: number; net: number }[] {
    const summary = this.summary;
    if (!summary) return [];
    if (summary.granularity === 'year') return summary.series;
    // Monthly tab shows 12 months; yearly tab (only when month data exists
    // across years) aggregates client-side is overkill - the series already
    // matches the summary's granularity, so both tabs use it as-is.
    return summary.series;
  }

  get seriesLabels(): string[] {
    return this.visibleSeries.map((point) => this.formatSeriesLabel(point.label));
  }

  formatSeriesLabel(label: string): string {
    if (/^\d{4}-\d{2}$/.test(label)) {
      const [year, month] = label.split('-');
      const monthLabel = this.translate.instant(monthNameKey(Number(month)));
      const yearText = this.lang === 'bn' ? this.toBangla(year) : year;
      return this.lang === 'bn' ? `${monthLabel} ${yearText}` : `${monthLabel} ${year}`;
    }
    return this.lang === 'bn' ? this.toBangla(label) : label;
  }

  private toBangla(text: string): string {
    return text.replace(/[0-9]/g, (d) => '০১২৩৪৫৬৭৮৯'[Number(d)]);
  }

  formatDate(iso: string | null): string {
    if (!iso) return '—';
    const parts = iso.slice(0, 10).split('-');
    if (parts.length !== 3) return iso;
    const [, month, day] = parts;
    const monthLabel = this.translate.instant(monthNameKey(Number(month)));
    const digits = (text: string) => (this.lang === 'bn' ? this.toBangla(text) : text);
    return `${digits(day)} ${monthLabel} ${digits(parts[0])}`;
  }

  formatTimestamp(iso: string | null): string {
    if (!iso) return '—';
    const date = new Date(iso);
    if (Number.isNaN(date.getTime())) return '—';
    const hh = String(date.getHours()).padStart(2, '0');
    const mm = String(date.getMinutes()).padStart(2, '0');
    return `${this.formatDate(iso)} ${this.lang === 'bn' ? this.toBangla(`${hh}:${mm}`) : `${hh}:${mm}`}`;
  }

  amount(value: number): string {
    return formatFinanceAmount(value, this.lang);
  }

  taka(value: number): string {
    return formatTaka(value, this.lang);
  }

  percent(value: number): string {
    return formatPercent(value, this.lang);
  }

  /** Signed, right-aligned ledger amount: "+ ৳ ৫০,০০০.০০" / "− ৳ ৮,০০০.০০". */
  signedAmount(txn: FinanceTransaction): string {
    const sign = txn.type === 'income' ? '+' : '−';
    return `${sign} ${this.taka(txn.amount)}`;
  }

  breakdownBarWidth(share: number): string {
    return `${Math.max(2, Math.min(100, Math.round(share)))}%`;
  }

  get expenseDonutSegments(): { label: string; value: number }[] {
    return (this.summary?.expenseByCategory ?? []).map((row) => ({
      label: row.category,
      value: row.amount,
    }));
  }

  get incomeSparkline(): number[] {
    return this.visibleSeries.map((point) => point.income);
  }

  get expenseSparkline(): number[] {
    return this.visibleSeries.map((point) => point.expense);
  }

  get netSparkline(): number[] {
    return this.visibleSeries.map((point) => point.net);
  }

  get isEmptyState(): boolean {
    return (
      !this.summaryLoading &&
      this.summary != null &&
      this.summary.transactionCount === 0 &&
      this.periodType === 'all' &&
      this.activeChips.length === 0
    );
  }

  // ----- Attachment preview (never a raw download link) -----

  async openPreview(txn: FinanceTransaction): Promise<void> {
    if (!txn.attachmentUrl) return;
    this.previewOpen = true;
    this.previewLoading = true;
    this.previewError = '';
    this.revokePreview();
    try {
      const blob = await this.attachments.load(txn.attachmentUrl);
      this.objectUrl = URL.createObjectURL(blob);
      this.previewUrl = this.objectUrl;
      this.previewIsImage = blob.type.startsWith('image/');
      this.previewLoading = false;
    } catch {
      this.previewLoading = false;
      this.previewError = this.translate.instant('member.fundTransparency.preview.missing');
    }
    this.cdr.markForCheck();
  }

  closePreview(): void {
    this.previewOpen = false;
    this.revokePreview();
    this.cdr.markForCheck();
  }

  private revokePreview(): void {
    if (this.objectUrl) {
      URL.revokeObjectURL(this.objectUrl);
      this.objectUrl = null;
      this.previewUrl = null;
    }
  }

  // ----- PDF -----

  downloadPdf(): void {
    if (this.pdfDownloading) return;
    this.pdfDownloading = true;
    this.pdfError = '';
    const { period, dateFrom, dateTo } = this.periodQuery();
    const filters = {
      ...this.currentFilters(),
      period,
      dateFrom: this.periodType === 'custom' ? dateFrom : undefined,
      dateTo: this.periodType === 'custom' ? dateTo : undefined,
    };
    this.finance.downloadReport(filters).subscribe({
      next: (blob) => {
        this.pdfDownloading = false;
        const url = URL.createObjectURL(blob);
        const anchor = document.createElement('a');
        anchor.href = url;
        anchor.download = `fund-transparency-${new Date().toISOString().slice(0, 10)}.pdf`;
        document.body.appendChild(anchor);
        anchor.click();
        anchor.remove();
        setTimeout(() => URL.revokeObjectURL(url), 1000);
        this.cdr.markForCheck();
      },
      error: () => {
        this.pdfDownloading = false;
        this.pdfError = this.translate.instant('member.fundTransparency.errors.pdfFailed');
        this.cdr.markForCheck();
      },
    });
  }
}
