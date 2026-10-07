import {
  Component,
  OnInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  inject,
} from '@angular/core';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { MemberService } from '../../../../core/services/member.service';
import type { Installment } from '../../../../core/models/admin.model';
import { monthNameKey } from '../../../../shared/constants/months';
import { IconComponent } from '../../../../shared/icon/icon.component';

type YearFilter = 'all' | number;

@Component({
  selector: 'app-member-installments',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, IconComponent],
  templateUrl: './installments.component.html',
  styleUrl: './installments.component.scss',
})
export class InstallmentsComponent implements OnInit {
  installments: Installment[] = [];
  selectedYear: YearFilter = 'all';
  loading = false;
  error = '';

  private readonly cdr = inject(ChangeDetectorRef);

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
