import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  computed,
  inject,
  OnInit,
  signal,
} from '@angular/core';
import { KeyValuePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { DatePickerComponent } from '../../../../shared/date-picker/date-picker.component';
import { IconComponent } from '../../../../shared/icon/icon.component';
import {
  OtherFeesService,
  OtherFeeHistoryPage,
  OtherFeePayment,
  OtherFeeType,
} from '../../../../core/services/other-fees.service';

const MAX_ADDITIONAL_HEADS = 20;
const RELATIONS = ['spouse', 'child', 'guest'] as const;
const PAYMENT_METHOD_OPTIONS = ['Cash', 'bKash', 'Nagad', 'Bank Transfer', 'Other'] as const;
const PAGE_SIZE = 10;

type ErrorKind = 'not_configured' | 'access' | 'generic' | null;

interface HeadLabel {
  name: string;
  relation: (typeof RELATIONS)[number];
}

@Component({
  selector: 'app-member-other-fees',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [KeyValuePipe, FormsModule, TranslatePipe, DatePickerComponent, IconComponent],
  templateUrl: './other-fees.component.html',
  styleUrl: './other-fees.component.css',
})
export class OtherFeesComponent implements OnInit {
  readonly relations = RELATIONS;
  readonly paymentMethodOptions = PAYMENT_METHOD_OPTIONS;
  readonly maxAdditionalHeads = MAX_ADDITIONAL_HEADS;

  loading = false;
  feeLoading = true;
  saving = false;
  typesError: ErrorKind = null;
  historyError = '';
  formError = '';
  success = '';

  feeTypes = signal<OtherFeeType[]>([]);
  selectedType = signal<string | null>(null);
  rates = signal<OtherFeeType | null>(null);

  additionalHeads = signal(0);
  labels: HeadLabel[] = [];

  paymentDate = '';
  receiptNo = '';
  paymentMethod: string = PAYMENT_METHOD_OPTIONS[0];
  amount: number | null = null;
  note = '';

  history = signal<OtherFeeHistoryPage | null>(null);
  historyPage = 1;
  filterFeeType = '';
  filterFrom = '';
  filterTo = '';

  private readonly cdr = inject(ChangeDetectorRef);
  private readonly translate = inject(TranslateService);
  private readonly otherFeesService = inject(OtherFeesService);
  private readonly route = inject(ActivatedRoute);

  readonly selectedTypeInfo = computed(
    () => this.feeTypes().find((t) => t.key === this.selectedType()) ?? null,
  );

  /** Per-mode form visibility driven by the type's calculation, which is API
   * data - a newly configured fee type needs no component change. */
  readonly calculation = computed(() => this.selectedTypeInfo()?.calculation ?? null);

  readonly isPayOncePaid = computed(
    () => this.selectedTypeInfo()?.payOnce === true && this.selectedTypeInfo()?.alreadyPaid === true,
  );

  readonly breakdown = computed(() => {
    const type = this.rates();
    if (!type) return null;
    if (type.calculation === 'picnic') {
      if (type.headFee == null || type.additionalHeadFee == null) return null;
      const count = this.additionalHeads();
      const additionalAmount = type.additionalHeadFee * count;
      return {
        mode: 'picnic' as const,
        count,
        headFee: type.headFee,
        additionalHeadFee: type.additionalHeadFee,
        additionalAmount,
        total: type.headFee + additionalAmount,
      };
    }
    if (type.calculation === 'fixed' && type.amount != null) {
      return { mode: 'fixed' as const, count: null, total: type.amount, headFee: type.amount, additionalHeadFee: null, additionalAmount: null };
    }
    return null;
  });

  readonly summary = computed(() => this.history()?.summary ?? null);

  readonly totalPages = computed(() =>
    this.history() ? Math.max(1, Math.ceil(this.history()!.total / PAGE_SIZE)) : 1,
  );

  ngOnInit(): void {
    this.paymentDate = new Date().toISOString().slice(0, 10);
    // Deep link from the retired Picnic Fee page (?type=picnic).
    const preselect = this.route.snapshot.queryParamMap.get('type');
    this.loadFeeTypes(preselect);
    this.loadHistory();
  }

  loadFeeTypes(preselect?: string | null): void {
    this.feeLoading = true;
    this.typesError = null;
    this.otherFeesService.getFeeTypes(this.paymentDate).subscribe({
      next: (types) => {
        this.feeTypes.set(types);
        const wanted = preselect && types.some((t) => t.key === preselect) ? preselect : types[0]?.key ?? null;
        if (wanted) this.selectType(wanted);
        this.feeLoading = false;
        this.cdr.markForCheck();
      },
      error: (err: unknown) => {
        this.feeTypes.set([]);
        this.rates.set(null);
        this.feeLoading = false;
        this.typesError = this.classifyRatesError(err);
        this.cdr.markForCheck();
      },
    });
  }

  retryRates(): void {
    this.loadFeeTypes();
  }

  private classifyRatesError(err: unknown): ErrorKind {
    const status = (err as { status?: number })?.status;
    if (status === 404) return 'not_configured';
    if (status === 403) return 'access';
    return 'generic';
  }

  selectType(key: string): void {
    this.selectedType.set(key);
    this.success = '';
    this.formError = '';
    const type = this.feeTypes().find((t) => t.key === key) ?? null;
    this.rates.set(type);
    this.additionalHeads.set(0);
    this.labels = [];
    this.note = '';
    // Fixed types show a read-only amount; variable types start empty.
    this.amount = type?.calculation === 'variable' ? null : (type?.amount ?? null);
    this.cdr.markForCheck();
  }

  onDateChange(value: string): void {
    this.paymentDate = value;
    if (value) this.loadFeeTypes();
  }

  incrementHeads(): void {
    this.setHeads(this.additionalHeads() + 1);
  }

  decrementHeads(): void {
    this.setHeads(this.additionalHeads() - 1);
  }

  onHeadsInput(value: string): void {
    const parsed = Number(value);
    this.setHeads(Number.isFinite(parsed) ? Math.trunc(parsed) : 0);
  }

  setHeads(count: number): void {
    const clamped = Math.min(Math.max(Math.trunc(count) || 0, 0), MAX_ADDITIONAL_HEADS);
    if (clamped === this.additionalHeads()) return;
    this.additionalHeads.set(clamped);
    while (this.labels.length < clamped) {
      this.labels.push({ name: '', relation: 'guest' });
    }
    this.labels = this.labels.slice(0, clamped);
    this.cdr.markForCheck();
  }

  get labelsValid(): boolean {
    return this.calculation() !== 'picnic' || this.labels.every((label) => label.name.trim().length > 0);
  }

  get amountValid(): boolean {
    const type = this.rates();
    if (!type) return false;
    if (type.calculation === 'variable') return this.amount !== null && this.amount > 0;
    return true; // fixed/picnic amounts are server-computed
  }

  get canSubmit(): boolean {
    return (
      !this.saving &&
      !this.feeLoading &&
      this.rates() !== null &&
      !this.isPayOncePaid() &&
      !!this.paymentDate &&
      !!this.paymentMethod &&
      this.amountValid &&
      this.labelsValid
    );
  }

  submit(): void {
    const type = this.rates();
    if (!type || !this.canSubmit) return;
    this.saving = true;
    this.formError = '';
    this.success = '';
    this.otherFeesService
      .createPayment({
        feeType: type.key,
        paymentDate: this.paymentDate,
        paymentMethod: this.paymentMethod,
        receiptNo: this.receiptNo.trim() || undefined,
        note: this.note.trim() || undefined,
        amount: type.calculation === 'variable' ? (this.amount ?? undefined) : undefined,
        additionalHeads: type.calculation === 'picnic' ? this.additionalHeads() : undefined,
        additionalPeople:
          type.calculation === 'picnic'
            ? this.labels.map((label) => ({ name: label.name.trim(), relation: label.relation }))
            : undefined,
      })
      .subscribe({
        next: (payment) => {
          this.saving = false;
          this.success = this.translate.instant('member.otherFees.saveSuccess', {
            total: payment.amount,
          });
          this.additionalHeads.set(0);
          this.labels = [];
          this.receiptNo = '';
          this.note = '';
          if (type.calculation === 'variable') this.amount = null;
          this.historyPage = 1;
          this.loadHistory();
          this.cdr.markForCheck();
        },
        error: (err: unknown) => {
          this.saving = false;
          const detail = (err as { error?: { detail?: string | { message?: string } } })?.error?.detail;
          const message =
            typeof detail === 'string' ? detail : (detail?.message ?? undefined);
          this.formError = message ?? this.translate.instant('member.otherFees.saveError');
          this.cdr.markForCheck();
        },
      });
  }

  loadHistory(): void {
    this.loading = true;
    this.historyError = '';
    this.otherFeesService
      .getPayments({
        feeType: this.filterFeeType || undefined,
        dateFrom: this.filterFrom || undefined,
        dateTo: this.filterTo || undefined,
        page: this.historyPage,
        pageSize: PAGE_SIZE,
      })
      .subscribe({
        next: (page) => {
          this.history.set(page);
          this.loading = false;
          this.cdr.markForCheck();
        },
        error: () => {
          this.historyError = this.translate.instant('member.otherFees.historyLoadFailed');
          this.loading = false;
          this.cdr.markForCheck();
        },
      });
  }

  applyFilters(): void {
    this.historyPage = 1;
    this.loadHistory();
  }

  resetFilters(): void {
    this.filterFeeType = '';
    this.filterFrom = '';
    this.filterTo = '';
    this.applyFilters();
  }

  goToPage(page: number): void {
    if (page < 1 || page > this.totalPages() || page === this.historyPage) return;
    this.historyPage = page;
    this.loadHistory();
  }

  feeTypeLabel(key: string): string {
    const translated = this.translate.instant('member.otherFees.types.' + key);
    if (translated !== 'member.otherFees.types.' + key) return translated;
    return key.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
  }

  detailsText(payment: OtherFeePayment): string {
    if (payment.feeType === 'admission') {
      return this.translate.instant('member.otherFees.detailsAdmission');
    }
    if (payment.additionalHeads != null && payment.additionalHeads > 0) {
      return this.translate.instant('member.otherFees.detailsHeads', {
        n: payment.additionalHeads,
      });
    }
    return payment.note || '—';
  }
}
