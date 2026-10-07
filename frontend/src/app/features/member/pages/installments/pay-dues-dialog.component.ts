import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  HostListener,
  Input,
  OnInit,
  Output,
  computed,
  inject,
  signal,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import {
  InstallmentPaymentService,
  type InstallmentPayment,
  type PayableSummary,
  type PaymentAccount,
} from '../../../../core/services/installment-payment.service';
import { monthNameKey } from '../../../../shared/constants/months';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { DatePickerComponent } from '../../../../shared/date-picker/date-picker.component';

type Step = 1 | 2 | 3;

const MAX_PROOF_BYTES = 5 * 1024 * 1024;
const PROOF_TYPES = ['image/jpeg', 'image/png', 'application/pdf'];
const TRANSACTION_REF_PATTERN = /^[A-Za-z0-9\-_/ ]{4,64}$/;
const COPY_FEEDBACK_MS = 1500;

function todayIso(): string {
  const now = new Date();
  const offset = now.getTimezoneOffset() * 60_000;
  return new Date(now.getTime() - offset).toISOString().slice(0, 10);
}

/**
 * Three-step "pay dues" flow: pick months -> send money to a society account ->
 * report the transaction ID for committee verification.
 */
@Component({
  selector: 'app-pay-dues-dialog',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, IconComponent, DatePickerComponent],
  templateUrl: './pay-dues-dialog.component.html',
  styleUrl: './pay-dues-dialog.component.scss',
})
export class PayDuesDialogComponent implements OnInit {
  @Input({ required: true }) summary!: PayableSummary;
  @Output() closed = new EventEmitter<void>();
  @Output() submitted = new EventEmitter<InstallmentPayment>();

  private readonly paymentService = inject(InstallmentPaymentService);
  private readonly translate = inject(TranslateService);

  readonly today = todayIso();
  readonly step = signal<Step>(1);
  readonly selectedIds = signal<ReadonlySet<number>>(new Set());
  readonly method = signal('');
  readonly copied = signal('');
  readonly submitting = signal(false);
  readonly error = signal('');

  transactionRef = '';
  senderAccount = '';
  paidOn = todayIso();
  note = '';
  proof: File | null = null;
  proofError = '';
  refTouched = false;

  readonly payable = computed(() => {
    const pending = new Set(this.summary.pendingInstallmentIds);
    return this.summary.due.filter((i) => !pending.has(i.id));
  });

  readonly selectedTotal = computed(() =>
    this.payable()
      .filter((i) => this.selectedIds().has(i.id))
      .reduce((sum, i) => sum + i.amount, 0),
  );

  readonly selectedAccount = computed<PaymentAccount | undefined>(() =>
    this.summary.accounts.find((a) => a.method === this.method()),
  );

  ngOnInit(): void {
    // Smart default: every outstanding month pre-selected, first account chosen.
    this.selectedIds.set(new Set(this.payable().map((i) => i.id)));
    this.method.set(this.summary.accounts[0]?.method ?? '');
  }

  @HostListener('document:keydown.escape')
  onEscape(): void {
    if (!this.submitting()) this.closed.emit();
  }

  get refValid(): boolean {
    return TRANSACTION_REF_PATTERN.test(this.transactionRef.trim());
  }

  get canSubmit(): boolean {
    return this.refValid && !!this.paidOn && this.paidOn <= this.today && !this.proofError && !this.submitting();
  }

  get allSelected(): boolean {
    const all = this.payable();
    return all.length > 0 && all.every((i) => this.selectedIds().has(i.id));
  }

  toggle(id: number): void {
    const next = new Set(this.selectedIds());
    if (next.has(id)) next.delete(id);
    else next.add(id);
    this.selectedIds.set(next);
  }

  toggleAll(): void {
    this.selectedIds.set(new Set(this.allSelected ? [] : this.payable().map((i) => i.id)));
  }

  goTo(step: Step): void {
    this.error.set('');
    this.step.set(step);
  }

  async copy(text: string): Promise<void> {
    try {
      await navigator.clipboard.writeText(text);
      this.copied.set(text);
      setTimeout(() => this.copied.set(''), COPY_FEEDBACK_MS);
    } catch {
      this.copied.set('');
    }
  }

  onProofSelected(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0] ?? null;
    this.proofError = '';
    if (file && !PROOF_TYPES.includes(file.type)) {
      this.proofError = this.translate.instant('member.payDues.proofTypeError');
    } else if (file && file.size > MAX_PROOF_BYTES) {
      this.proofError = this.translate.instant('member.payDues.proofSizeError');
    }
    this.proof = this.proofError ? null : file;
  }

  submit(): void {
    this.refTouched = true;
    if (!this.canSubmit) return;
    this.submitting.set(true);
    this.error.set('');
    this.paymentService
      .submit({
        installmentIds: [...this.selectedIds()],
        method: this.method(),
        transactionRef: this.transactionRef,
        paidOn: this.paidOn,
        senderAccount: this.senderAccount,
        note: this.note,
        proof: this.proof,
      })
      .subscribe({
        next: (payment) => {
          this.submitting.set(false);
          this.submitted.emit(payment);
        },
        error: (err: HttpErrorResponse) => {
          this.submitting.set(false);
          const detail = typeof err.error?.detail === 'string' ? err.error.detail : '';
          this.error.set(detail || this.translate.instant('member.payDues.submitError'));
        },
      });
  }

  monthLabel(month: number): string {
    return monthNameKey(month);
  }

  formatAmount(amount: number): string {
    return amount.toLocaleString('en-IN');
  }
}
