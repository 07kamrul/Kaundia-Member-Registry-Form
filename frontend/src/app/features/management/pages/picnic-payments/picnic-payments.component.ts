import {
  Component,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  inject,
  OnInit,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import type { AdminPicnicPayment } from '../../../../core/services/admin.service';

@Component({
  selector: 'app-picnic-payments-management',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe],
  templateUrl: './picnic-payments.component.html',
})
export class PicnicPaymentsComponent implements OnInit {
  payments: AdminPicnicPayment[] = [];
  totalCollected = 0;
  count = 0;
  loading = false;
  error = '';

  memberFilter: number | null = null;
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
    this.adminService.getPicnicPayments({
      memberId: this.memberFilter ?? undefined,
      dateFrom: this.dateFrom || undefined,
      dateTo: this.dateTo || undefined,
    }).subscribe({
      next: (page) => {
        this.payments = page.items;
        this.totalCollected = page.totalCollected;
        this.count = page.count;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.picnicPayments.loadError');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  resetFilters(): void {
    this.memberFilter = null;
    this.dateFrom = '';
    this.dateTo = '';
    this.load();
  }
}
