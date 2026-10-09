import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  inject,
  OnInit,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import type { AdminFeePayment } from '../../../../core/services/admin.service';
import { DatePickerComponent } from '../../../../shared/date-picker/date-picker.component';

const FEE_TYPE_KEYS = [
  'installment',
  'picnic',
  'maintenance',
  'development',
  'donation',
  'extra',
] as const;

@Component({
  selector: 'app-fees-management',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, DatePickerComponent],
  templateUrl: './fees-management.component.html',
})
export class FeesManagementComponent implements OnInit {
  readonly feeTypeKeys = FEE_TYPE_KEYS;

  payments: AdminFeePayment[] = [];
  totalCollected = 0;
  count = 0;
  loading = false;
  error = '';

  feeTypeFilter = '';
  dateFrom = '';
  dateTo = '';

  private readonly cdr = inject(ChangeDetectorRef);
  private readonly adminService = inject(AdminService);
  private readonly translate = inject(TranslateService);

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.error = '';
    this.adminService
      .getFeePayments({
        feeType: this.feeTypeFilter || undefined,
        dateFrom: this.dateFrom || undefined,
        dateTo: this.dateTo || undefined,
      })
      .subscribe({
        next: (page) => {
          this.payments = page.items;
          this.totalCollected = page.totalCollected;
          this.count = page.count;
          this.loading = false;
          this.cdr.markForCheck();
        },
        error: () => {
          this.error = this.translate.instant('admin.feesManagement.loadError');
          this.loading = false;
          this.cdr.markForCheck();
        },
      });
  }

  resetFilters(): void {
    this.feeTypeFilter = '';
    this.dateFrom = '';
    this.dateTo = '';
    this.load();
  }
}
