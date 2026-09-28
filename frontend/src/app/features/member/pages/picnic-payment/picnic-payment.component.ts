import {
  Component,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  computed,
  inject,
  OnInit,
  signal,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { FEE_MANAGER_PERMISSION, AuthService } from '../../../../core/services/auth.service';
import { MemberService } from '../../../../core/services/member.service';
import type {
  PicnicPayment,
  PicnicPaymentAdditionalHead,
  PicnicRates,
} from '../../../../core/services/member.service';
import { DatePickerComponent } from '../../../../shared/date-picker/date-picker.component';

const MAX_ADDITIONAL_HEADS = 20;
const RELATIONS = ['spouse', 'child', 'guest'] as const;
const PAYMENT_METHOD_OPTIONS = ['Cash', 'bKash', 'Nagad', 'Bank Transfer', 'Other'] as const;

type ErrorKind = 'not_configured' | 'access' | 'generic' | null;

@Component({
  selector: 'app-member-picnic-payment',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, RouterLink, DatePickerComponent],
  templateUrl: './picnic-payment.component.html',
})
export class PicnicPaymentComponent implements OnInit {
  readonly relations = RELATIONS;
  readonly paymentMethodOptions = PAYMENT_METHOD_OPTIONS;
  readonly maxAdditionalHeads = MAX_ADDITIONAL_HEADS;

  loading = false;
  feeLoading = true;
  saving = false;
  ratesError: ErrorKind = null;
  historyError = '';
  formError = '';
  success = '';

  additionalHeads = signal(0);
  rates = signal<PicnicRates | null>(null);

  paymentDate = '';
  receiptNo = '';
  paymentMethod = PAYMENT_METHOD_OPTIONS[0];
  labels: PicnicPaymentAdditionalHead[] = [];

  payments: PicnicPayment[] = [];

  private readonly cdr = inject(ChangeDetectorRef);
  private readonly translate = inject(TranslateService);
  private readonly memberService = inject(MemberService);
  private readonly auth = inject(AuthService);

  // Fee managers (Super Admin, Executive Committee, Administrator - anyone
  // holding the shared fee permission) get the "Go to Fee Settings" shortcut;
  // ordinary members only see the "contact the committee" message.
  readonly canManageFees = computed(() => this.auth.hasPermission(FEE_MANAGER_PERMISSION));

  readonly breakdown = computed(() => {
    const rates = this.rates();
    if (!rates) return null;
    const count = this.additionalHeads();
    const additionalAmount = rates.additionalHeadFee * count;
    return {
      count,
      headFee: rates.headFee,
      additionalHeadFee: rates.additionalHeadFee,
      additionalAmount,
      total: rates.headFee + additionalAmount,
      unit: rates.unit,
    };
  });

  ngOnInit(): void {
    this.paymentDate = new Date().toISOString().slice(0, 10);
    this.loadPayments();
    this.loadRates();
  }

  /** Rates must be re-resolved whenever the payment date changes - the
   * effective version may differ (see Fee Settings version history). */
  onDateChange(value: string): void {
    this.paymentDate = value;
    if (value) this.loadRates();
  }

  loadPayments(): void {
    this.loading = true;
    this.historyError = '';
    this.memberService.getPicnicPayments().subscribe({
      next: (data) => {
        this.payments = data;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: (err: unknown) => {
        this.historyError = this.picnicError(err, 'historyLoadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  private loadRates(): void {
    this.feeLoading = true;
    this.ratesError = null;
    this.memberService.getPicnicRates(this.paymentDate).subscribe({
      next: (rates) => {
        this.rates.set(rates);
        this.feeLoading = false;
        this.cdr.markForCheck();
      },
      error: (err: unknown) => {
        this.rates.set(null);
        this.feeLoading = false;
        this.ratesError = this.classifyRatesError(err);
        this.cdr.markForCheck();
      },
    });
  }

  retryRates(): void {
    this.loadRates();
  }

  private classifyRatesError(err: unknown): ErrorKind {
    const status = (err as { status?: number })?.status;
    if (status === 404) return 'not_configured';
    if (status === 403) return 'access';
    return 'generic';
  }

  private picnicError(err: unknown, fallbackKey: string): string {
    const status = (err as { status?: number })?.status;
    const detail = (err as { error?: { detail?: string } })?.error?.detail;
    if (status === 403 && detail) return detail;
    return this.translate.instant(`member.picnic.${fallbackKey}`);
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
    this.syncLabels(clamped);
    this.cdr.markForCheck();
  }

  private syncLabels(count: number): void {
    while (this.labels.length < count) {
      this.labels.push({ name: '', relation: 'guest' });
    }
    this.labels = this.labels.slice(0, count);
  }

  get labelsValid(): boolean {
    return this.labels.every((label) => label.name.trim().length > 0);
  }

  get canSubmit(): boolean {
    return (
      !this.saving &&
      !this.feeLoading &&
      this.rates() !== null &&
      !!this.paymentDate &&
      !!this.paymentMethod &&
      this.labelsValid
    );
  }

  submit(): void {
    if (!this.canSubmit) return;
    this.saving = true;
    this.formError = '';
    this.success = '';
    this.memberService
      .createPicnicPayment({
        additionalHeads: this.additionalHeads(),
        additionalPeople: this.labels.map((label) => ({
          name: label.name.trim(),
          relation: label.relation,
        })),
        paymentDate: this.paymentDate,
        receiptNo: this.receiptNo,
        paymentMethod: this.paymentMethod,
      })
      .subscribe({
        next: (payment) => {
          this.saving = false;
          this.success = this.translate.instant('member.picnic.saveSuccess', {
            total: payment.total,
          });
          this.additionalHeads.set(0);
          this.labels = [];
          this.receiptNo = '';
          this.loadPayments();
          this.cdr.markForCheck();
        },
        error: (err: unknown) => {
          const detail = (err as { error?: { detail?: string } })?.error?.detail;
          this.formError = detail ?? this.translate.instant('member.picnic.saveError');
          this.saving = false;
          this.cdr.markForCheck();
        },
      });
  }
}
