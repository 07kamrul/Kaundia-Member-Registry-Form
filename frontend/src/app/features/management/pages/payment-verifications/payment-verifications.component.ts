import { ChangeDetectionStrategy, Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import {
  InstallmentPaymentService,
  type AdminInstallmentPayment,
  type PaymentStatus,
} from '../../../../core/services/installment-payment.service';
import { monthNameKey } from '../../../../shared/constants/months';
import { IconComponent } from '../../../../shared/icon/icon.component';

const FILTERS: readonly PaymentStatus[] = ['pending', 'approved', 'rejected'];
const MIN_REASON_LENGTH = 3;

/** Committee queue: verify member-reported installment payments. */
@Component({
  selector: 'app-payment-verifications',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, IconComponent],
  templateUrl: './payment-verifications.component.html',
  styleUrl: './payment-verifications.component.scss',
})
export class PaymentVerificationsComponent implements OnInit {
  private readonly service = inject(InstallmentPaymentService);
  private readonly translate = inject(TranslateService);

  readonly filters = FILTERS;
  readonly filter = signal<PaymentStatus>('pending');
  readonly payments = signal<AdminInstallmentPayment[]>([]);
  readonly loading = signal(false);
  readonly error = signal('');
  readonly busyId = signal<number | null>(null);
  readonly rejecting = signal<AdminInstallmentPayment | null>(null);
  rejectReason = '';

  ngOnInit(): void {
    this.load();
  }

  setFilter(status: PaymentStatus): void {
    this.filter.set(status);
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.listForAdmin(this.filter()).subscribe({
      next: (rows) => {
        this.payments.set(rows);
        this.loading.set(false);
      },
      error: () => {
        this.error.set(this.translate.instant('admin.paymentVerifications.loadError'));
        this.loading.set(false);
      },
    });
  }

  approve(payment: AdminInstallmentPayment): void {
    this.error.set('');
    this.busyId.set(payment.id);
    this.service.approve(payment.id).subscribe({
      next: () => this.afterReview(payment.id),
      error: (err: HttpErrorResponse) => this.onActionError(err),
    });
  }

  openReject(payment: AdminInstallmentPayment): void {
    this.rejectReason = '';
    this.rejecting.set(payment);
  }

  get canReject(): boolean {
    return this.rejectReason.trim().length >= MIN_REASON_LENGTH && this.busyId() === null;
  }

  confirmReject(): void {
    const payment = this.rejecting();
    if (!payment || !this.canReject) return;
    this.error.set('');
    this.busyId.set(payment.id);
    this.service.reject(payment.id, this.rejectReason.trim()).subscribe({
      next: () => {
        this.rejecting.set(null);
        this.afterReview(payment.id);
      },
      error: (err: HttpErrorResponse) => {
        this.rejecting.set(null);
        this.onActionError(err);
      },
    });
  }

  months(payment: AdminInstallmentPayment): string {
    return payment.installments
      .map((i) => `${this.translate.instant(monthNameKey(i.month))} ${i.year}`)
      .join(', ');
  }

  formatAmount(amount: number): string {
    return amount.toLocaleString('en-IN');
  }

  private afterReview(id: number): void {
    this.busyId.set(null);
    this.payments.set(this.payments().filter((p) => p.id !== id));
  }

  private onActionError(err: HttpErrorResponse): void {
    this.busyId.set(null);
    const detail = typeof err.error?.detail === 'string' ? err.error.detail : '';
    this.error.set(detail || this.translate.instant('admin.paymentVerifications.actionError'));
    this.load();
  }
}
