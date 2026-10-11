import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  inject,
  OnInit,
} from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import type { AdminFeePayment, AdminFeeType } from '../../../../core/services/admin.service';
import { DatePickerComponent } from '../../../../shared/date-picker/date-picker.component';

/** Legacy member-catalog fee types whose labels come from i18n; catalog
 * types added through Fee Settings are appended to this list dynamically. */
const LEGACY_FEE_TYPE_KEYS = [
  'installment',
  'picnic',
  'maintenance',
  'development',
  'donation',
  'extra',
] as const;

interface FeeTypeOption {
  value: string;
  label: string;
  custom: boolean;
}

type AdminFeeTypeOption = Pick<AdminFeeType, 'key' | 'labelBn' | 'labelEn'>;

@Component({
  selector: 'app-fees-management',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [DecimalPipe, FormsModule, TranslatePipe, DatePickerComponent],
  templateUrl: './fees-management.component.html',
  styleUrl: './fees-management.component.scss',
})
export class FeesManagementComponent implements OnInit {
  feeTypeOptions: FeeTypeOption[] = LEGACY_FEE_TYPE_KEYS.map((key): FeeTypeOption => ({
    value: key,
    label: key,
    custom: false,
  }));

  payments: AdminFeePayment[] = [];
  totalCollected = 0;
  count = 0;
  loading = false;
  error = '';

  feeTypeFilter = '';
  memberFilter: number | null = null;
  dateFrom = '';
  dateTo = '';
  private catalogFeeTypes: AdminFeeTypeOption[] = [];

  private readonly cdr = inject(ChangeDetectorRef);
  private readonly adminService = inject(AdminService);
  private readonly translate = inject(TranslateService);
  private readonly route = inject(ActivatedRoute);

  ngOnInit(): void {
    // Deep link from the retired Picnic Payments page (?feeType=picnic).
    this.feeTypeFilter = this.route.snapshot.queryParamMap.get('feeType') ?? '';
    this.load();
    this.loadCatalog();
  }

  /** Catalog-defined label when the fee type was added through Fee Settings;
   * legacy keys resolve through the reactive translate pipe in the template
   * (instant() can run before the translation file is applied). */
  customFeeLabel(feeType: string): string | null {
    const option = this.feeTypeOptions.find((o) => o.value === feeType);
    return option && option.custom ? option.label : null;
  }

  /** Render a payment method without ever showing a raw i18n key. The i18n
   * keys are capitalized ('Cash', 'bKash'); ledger rows may store lowercase. */
  methodLabel(method: string | null): string {
    if (!method) return '—';
    const candidates = [method, method.charAt(0).toUpperCase() + method.slice(1)];
    for (const candidate of candidates) {
      const key = 'member.fees.methods.' + candidate;
      const translated = this.translate.instant(key);
      if (translated !== key) return translated;
    }
    return method;
  }

  /** Merge the legacy i18n keys with any fee types from the Fee Settings
   * catalog and the loaded ledger rows, so committee-added types show up
   * automatically. */
  private syncFeeTypeOptions(payments: AdminFeePayment[]): void {
    const options: FeeTypeOption[] = LEGACY_FEE_TYPE_KEYS.map((key) => ({
      value: key,
      label: '',
      custom: false,
    }));
    const add = (value: string, label: string) => {
      if (value && !options.some((o) => o.value === value)) {
        options.push({ value, label, custom: true });
      }
    };
    for (const ft of this.catalogFeeTypes) {
      const lang = this.translate.currentLang() || 'bn';
      add(ft.key, lang === 'bn' ? ft.labelBn : ft.labelEn);
    }
    for (const payment of payments) {
      add(payment.feeType, this.humanizeKey(payment.feeType));
    }
    this.feeTypeOptions = options;
  }

  private humanizeKey(key: string): string {
    return key.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
  }

  private loadCatalog(): void {
    this.adminService.getFeeTypes().subscribe({
      next: (feeTypes) => {
        this.catalogFeeTypes = feeTypes;
        this.syncFeeTypeOptions(this.payments);
        this.cdr.markForCheck();
      },
      error: () => {
        // Ledger-derived options still work without the catalog.
      },
    });
  }

  load(): void {
    this.loading = true;
    this.error = '';
    this.adminService
      .getFeePayments({
        feeType: this.feeTypeFilter || undefined,
        memberId: this.memberFilter ?? undefined,
        dateFrom: this.dateFrom || undefined,
        dateTo: this.dateTo || undefined,
      })
      .subscribe({
        next: (page) => {
          this.payments = page.items;
          this.totalCollected = page.totalCollected;
          this.count = page.count;
          this.syncFeeTypeOptions(page.items);
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
    this.memberFilter = null;
    this.dateFrom = '';
    this.dateTo = '';
    this.load();
  }
}
