import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  computed,
  inject,
  OnInit,
  signal,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { DatePickerComponent } from '../../../../shared/date-picker/date-picker.component';
import { IconComponent, type IconName } from '../../../../shared/icon/icon.component';
import {
  FeePayment,
  FeePaymentService,
  FeeTypeInfo,
} from '../../../../core/services/fee-payment.service';

const PAYMENT_METHOD_OPTIONS = ['Cash', 'bKash', 'Nagad', 'Bank Transfer', 'Other'] as const;

const FEE_TYPE_ICONS: Record<string, IconName> = {
  installment: 'wallet',
  picnic: 'sun',
  maintenance: 'shield',
  development: 'chart',
  donation: 'sparkle',
  extra: 'coin',
};

type ErrorKind = 'access' | 'generic' | null;

@Component({
  selector: 'app-member-fees',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, DatePickerComponent, IconComponent],
  templateUrl: './fees.component.html',
  styleUrl: './fees.component.css',
})
export class FeesComponent implements OnInit {
  readonly paymentMethodOptions = PAYMENT_METHOD_OPTIONS;
  readonly typeIcons: Record<string, IconName> = FEE_TYPE_ICONS;

  loading = true;
  saving = false;
  typesError: ErrorKind = null;
  historyError = '';
  formError = '';
  success = '';

  feeTypes = signal<FeeTypeInfo[]>([]);
  selectedType = signal<string | null>(null);
  payments = signal<FeePayment[]>([]);

  amount: number | null = null;
  paymentDate = '';
  paymentMethod: string = PAYMENT_METHOD_OPTIONS[0];
  receiptNo = '';
  note = '';

  private readonly cdr = inject(ChangeDetectorRef);
  private readonly translate = inject(TranslateService);
  private readonly feePaymentService = inject(FeePaymentService);

  readonly selectedTypeInfo = computed(
    () => this.feeTypes().find((t) => t.key === this.selectedType()) ?? null,
  );

  readonly suggestedAmount = computed(() => this.selectedTypeInfo()?.defaultAmount ?? null);

  readonly summary = computed(() => {
    const payments = this.payments();
    const year = new Date().getFullYear();
    const totalPaid = payments.reduce((sum, p) => sum + p.amount, 0);
    const thisYear = payments
      .filter((p) => Number(p.paymentDate.slice(0, 4)) === year)
      .reduce((sum, p) => sum + p.amount, 0);
    const last = payments[0] ?? null;
    return { totalPaid, thisYear, count: payments.length, last };
  });

  readonly canSubmit = computed(
    () => this.selectedType() !== null && this.amount !== null && this.amount > 0 && !this.saving,
  );

  ngOnInit(): void {
    this.paymentDate = new Date().toISOString().slice(0, 10);
    this.loadFeeTypes();
    this.loadPayments();
  }

  loadFeeTypes(): void {
    this.typesError = null;
    this.feePaymentService.getFeeTypes(this.paymentDate).subscribe({
      next: (types) => {
        this.feeTypes.set(types);
        // Keep the current selection valid; otherwise preselect the first
        // type so the form is ready without an extra click.
        const current = this.selectedType();
        if ((!current || !types.some((t) => t.key === current)) && types.length > 0) {
          this.selectType(types[0].key);
        }
        this.cdr.markForCheck();
      },
      error: () => {
        this.typesError = 'generic';
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  loadPayments(): void {
    this.loading = true;
    this.historyError = '';
    this.feePaymentService.getFeePayments().subscribe({
      next: (data) => {
        this.payments.set(data);
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.historyError = this.translate.instant('member.fees.historyLoadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  selectType(key: string): void {
    this.selectedType.set(key);
    this.success = '';
    // Prefill with the configured rate; the member can still override it -
    // one-off fees (extra, donation) rarely have a fixed rate.
    const suggested = this.feeTypes().find((t) => t.key === key)?.defaultAmount ?? null;
    this.amount = suggested;
    this.cdr.markForCheck();
  }

  onDateChange(value: string): void {
    this.paymentDate = value;
    if (value) this.loadFeeTypes();
  }

  submit(): void {
    const type = this.selectedType();
    if (!type || !this.amount || this.amount <= 0) return;
    this.saving = true;
    this.formError = '';
    this.success = '';
    this.feePaymentService
      .createFeePayment({
        feeType: type,
        amount: this.amount,
        paymentDate: this.paymentDate,
        receiptNo: this.receiptNo.trim() || undefined,
        paymentMethod: this.paymentMethod,
        note: this.note.trim() || undefined,
      })
      .subscribe({
        next: () => {
          this.saving = false;
          this.success = this.translate.instant('member.fees.success');
          this.receiptNo = '';
          this.note = '';
          this.loadPayments();
          this.cdr.markForCheck();
        },
        error: (err: unknown) => {
          this.saving = false;
          const status = (err as { status?: number })?.status;
          const detail = (err as { error?: { detail?: string } })?.error?.detail;
          if (status === 403 && detail) this.formError = detail;
          else this.formError = this.translate.instant('member.fees.submitFailed');
          this.cdr.markForCheck();
        },
      });
  }
}
