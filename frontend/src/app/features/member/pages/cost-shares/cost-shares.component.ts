import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnInit,
  inject,
} from '@angular/core';
import { DatePipe } from '@angular/common';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { IconComponent } from '../../../../shared/icon/icon.component';
import {
  SocietyCostService,
  type CostSplitShare,
} from '../../../../core/services/society-cost.service';

@Component({
  selector: 'app-member-cost-shares',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, DatePipe, IconComponent],
  templateUrl: './cost-shares.component.html',
  styleUrl: './cost-shares.component.scss',
})
export class CostSharesComponent implements OnInit {
  shares: CostSplitShare[] = [];
  loading = false;
  error = '';

  private readonly cdr = inject(ChangeDetectorRef);

  constructor(
    private costService: SocietyCostService,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.loading = true;
    this.costService.myCostShares().subscribe({
      next: (shares) => {
        this.shares = shares;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('member.costShares.loadError');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  get outstandingTotal(): number {
    return this.shares
      .filter((s) => s.status !== 'paid')
      .reduce((sum, s) => sum + (s.amountDue - s.amountPaid), 0);
  }

  get hasOutstanding(): boolean {
    return this.shares.some((s) => s.status !== 'paid');
  }

  formatAmount(amount: number): string {
    return amount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }
}
