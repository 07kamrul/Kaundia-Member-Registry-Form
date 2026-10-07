import {
  Component,
  OnInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  inject,
} from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { MemberService } from '../../../../core/services/member.service';
import {
  InstallmentPaymentService,
  type InstallmentPayment,
  type PayableSummary,
} from '../../../../core/services/installment-payment.service';
import { PayDuesDialogComponent } from './pay-dues-dialog.component';
import type { Installment } from '../../../../core/models/admin.model';
import { monthNameKey } from '../../../../shared/constants/months';
import { IconComponent } from '../../../../shared/icon/icon.component';

type YearFilter = 'all' | number;

@Component({
  selector: 'app-member-installments',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, IconComponent, PayDuesDialogComponent],
  templateUrl: './installments.component.html',
  styleUrl: './installments.component.scss',
})
export class InstallmentsComponent implements OnInit {
  installments: Installment[] = [];
  selectedYear: YearFilter = 'all';
  loading = false;
  error = '';
  payable: PayableSummary | null = null;
  payDialogOpen = false;
  successMessage = '';

  private readonly cdr = inject(ChangeDetectorRef);
  private readonly paymentService = inject(InstallmentPaymentService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  constructor(
    private memberService: MemberService,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.loading = true;
    this.memberService.getInstallments().subscribe({
      next: (data) => {
        this.installments = [...data].sort(
          (a, b) => b.year - a.year || b.month - a.month,
        );
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('member.installments.loadError');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
    this.loadPayable(this.route.snapshot.queryParamMap.get('pay') === '1');
  }

  /** Online pay is optional: if it fails to load, the history still shows. */
  private loadPayable(openDialog = false): void {
    this.paymentService.getPayable().subscribe({
      next: (summary) => {
        this.payable = summary;
        this.payDialogOpen = openDialog && this.canPay;
        this.cdr.markForCheck();
      },
      error: () => {
        this.payable = null;
        this.cdr.markForCheck();
      },
    });
  }

  get pendingIds(): ReadonlySet<number> {
    return new Set(this.payable?.pendingInstallmentIds ?? []);
  }

  get payableCount(): number {
    const pending = this.pendingIds;
    return (this.payable?.due ?? []).filter((i) => !pending.has(i.id)).length;
  }

  get canPay(): boolean {
    return !!this.payable && this.payable.accounts.length > 0 && this.payableCount > 0;
  }

  get recentPayments(): InstallmentPayment[] {
    return (this.payable?.payments ?? []).slice(0, 5);
  }

  isPending(id: string): boolean {
    return this.pendingIds.has(Number(id));
  }

  openPayDialog(): void {
    this.successMessage = '';
    this.payDialogOpen = true;
    this.cdr.markForCheck();
  }

  closePayDialog(): void {
    this.payDialogOpen = false;
    if (this.route.snapshot.queryParamMap.has('pay')) {
      this.router.navigate([], { queryParams: { pay: null }, queryParamsHandling: 'merge', replaceUrl: true });
    }
    this.cdr.markForCheck();
  }

  onPaymentSubmitted(): void {
    this.closePayDialog();
    this.successMessage = this.translate.instant('member.payDues.submitted');
    this.loadPayable();
  }

  paymentMonths(payment: InstallmentPayment): string {
    return payment.installments
      .map((i) => `${this.translate.instant(monthNameKey(i.month))} ${i.year}`)
      .join(', ');
  }

  get years(): number[] {
    return [...new Set(this.installments.map((i) => i.year))].sort(
      (a, b) => b - a,
    );
  }

  get filtered(): Installment[] {
    return this.selectedYear === 'all'
      ? this.installments
      : this.installments.filter((i) => i.year === this.selectedYear);
  }

  get paidTotal(): number {
    return this.sumBy((i) => i.status === 'paid');
  }

  get dueTotal(): number {
    return this.sumBy((i) => i.status !== 'paid');
  }

  get paidCount(): number {
    return this.filtered.filter((i) => i.status === 'paid').length;
  }

  selectYear(year: YearFilter): void {
    this.selectedYear = year;
    this.cdr.markForCheck();
  }

  monthLabel(month: number): string {
    return monthNameKey(month);
  }

  formatAmount(amount: number): string {
    return amount.toLocaleString('en-IN');
  }

  /** Human-readable date in the active language; digits stay Western to match the amounts. */
  formatDate(iso: string): string {
    const date = new Date(iso);
    if (Number.isNaN(date.getTime())) return iso;
    const month = this.translate.instant(monthNameKey(date.getMonth() + 1));
    return `${date.getDate()} ${month} ${date.getFullYear()}`;
  }

  private sumBy(predicate: (i: Installment) => boolean): number {
    return this.filtered.filter(predicate).reduce((sum, i) => sum + i.amount, 0);
  }
}
