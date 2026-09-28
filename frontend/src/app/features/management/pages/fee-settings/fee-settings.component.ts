import { ChangeDetectorRef, Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { forkJoin, Observable } from 'rxjs';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';
import { IconComponent } from '../../../../shared/icon/icon.component';
import type { FeeSetting } from '../../../../core/models/admin.model';

const MANAGE_FEE_SETTINGS = 'manage_fee_settings';

/** Virtual key selected in the form for the tiered monthly subscription rate;
 * it maps to three real fee-setting rows (see MONTHLY_SUBSCRIPTION_TIER_KEYS). */
const MONTHLY_SUBSCRIPTION_GROUP_KEY = 'monthly_subscription';

const MONTHLY_SUBSCRIPTION_TIER_KEYS = {
  base: 'monthly_subscription_base_amount',
  rate: 'monthly_subscription_additional_rate',
  threshold: 'monthly_subscription_base_threshold',
} as const;

/** Known fee keys the version form offers, in display order. */
const KNOWN_FEE_KEYS: readonly string[] = [
  'admission_fee',
  'picnic_head_fee',
  'picnic_additional_head_fee',
  MONTHLY_SUBSCRIPTION_GROUP_KEY,
];

/** Default unit per known key (i18n unit option); empty string when unknown. */
const DEFAULT_UNIT_BY_KEY: Record<string, string> = {
  admission_fee: 'taka',
  picnic_head_fee: 'taka',
  picnic_additional_head_fee: 'taka',
  [MONTHLY_SUBSCRIPTION_GROUP_KEY]: 'taka',
};

const UNIT_OPTIONS: readonly string[] = ['taka', 'percent'];

interface TieredFeeSummary {
  base: FeeSetting;
  rate: FeeSetting;
  threshold: FeeSetting;
}

interface TieredFeeHistory {
  base: FeeSetting[];
  rate: FeeSetting[];
  threshold: FeeSetting[];
}

@Component({
  selector: 'app-fee-settings',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, ConfirmModalComponent, IconComponent],
  templateUrl: './fee-settings.component.html',
})
export class FeeSettingsComponent implements OnInit {
  readonly unitOptions = UNIT_OPTIONS;

  active: FeeSetting[] = [];
  loading = false;
  error = '';

  expandedKey: string | null = null;
  history: FeeSetting[] = [];
  tieredHistory: TieredFeeHistory = { base: [], rate: [], threshold: [] };
  loadingHistory = false;

  draftKey = '';
  draftValue: number | null = null;
  draftUnit = '';
  draftStartDate = '';
  draftBaseAmount: number | null = null;
  draftAdditionalRate: number | null = null;
  draftBaseThreshold: number | null = null;
  saving = false;
  saveError = '';

  confirmOpen = false;

  calculatorLandSize: number | null = null;

  constructor(
    private adminService: AdminService,
    public auth: AuthService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.loadActive();
  }

  private readonly tierKeySet = new Set<string>(Object.values(MONTHLY_SUBSCRIPTION_TIER_KEYS));

  /** Known keys plus any extra keys already present in active settings,
   * excluding the raw tier rows (they're offered as the single grouped key). */
  get feeKeys(): string[] {
    const extra = this.active
      .map((s) => s.key)
      .filter((k) => !KNOWN_FEE_KEYS.includes(k) && !this.tierKeySet.has(k));
    return [...KNOWN_FEE_KEYS, ...extra];
  }

  /** Active rows for the generic table, with the three monthly-subscription
   * tier rows collapsed out (they're rendered as one summary row instead). */
  get tableRows(): FeeSetting[] {
    return this.active.filter((s) => !this.tierKeySet.has(s.key));
  }

  get isTieredKey(): boolean {
    return this.draftKey === MONTHLY_SUBSCRIPTION_GROUP_KEY;
  }

  get monthlySubscriptionTier(): TieredFeeSummary | null {
    const base = this.active.find((s) => s.key === MONTHLY_SUBSCRIPTION_TIER_KEYS.base);
    const rate = this.active.find((s) => s.key === MONTHLY_SUBSCRIPTION_TIER_KEYS.rate);
    const threshold = this.active.find((s) => s.key === MONTHLY_SUBSCRIPTION_TIER_KEYS.threshold);
    return base && rate && threshold ? { base, rate, threshold } : null;
  }

  get calculatorFee(): number | null {
    const tier = this.monthlySubscriptionTier;
    if (!tier || this.calculatorLandSize === null || this.calculatorLandSize < 0) return null;
    const { value: base } = tier.base;
    const { value: rate } = tier.rate;
    const { value: threshold } = tier.threshold;
    if (this.calculatorLandSize <= threshold) return base;
    return base + (this.calculatorLandSize - threshold) * rate;
  }

  get canSave(): boolean {
    if (!this.auth.hasPermission(MANAGE_FEE_SETTINGS) || this.saving || !this.draftKey)
      return false;
    if (this.isTieredKey) {
      return (
        this.draftBaseAmount !== null &&
        this.draftBaseAmount >= 0 &&
        this.draftAdditionalRate !== null &&
        this.draftAdditionalRate >= 0 &&
        this.draftBaseThreshold !== null &&
        this.draftBaseThreshold > 0
      );
    }
    return this.draftValue !== null;
  }

  loadActive(): void {
    this.loading = true;
    this.adminService.getActiveFeeSettings().subscribe({
      next: (data) => {
        this.active = data;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.feeSettings.errors.loadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  toggleHistory(key: string): void {
    if (this.expandedKey === key) {
      this.expandedKey = null;
      this.history = [];
      this.tieredHistory = { base: [], rate: [], threshold: [] };
      return;
    }
    this.expandedKey = key;
    this.loadingHistory = true;

    if (key === MONTHLY_SUBSCRIPTION_GROUP_KEY) {
      forkJoin({
        base: this.adminService.getFeeSettingHistory(MONTHLY_SUBSCRIPTION_TIER_KEYS.base),
        rate: this.adminService.getFeeSettingHistory(MONTHLY_SUBSCRIPTION_TIER_KEYS.rate),
        threshold: this.adminService.getFeeSettingHistory(MONTHLY_SUBSCRIPTION_TIER_KEYS.threshold),
      }).subscribe({
        next: (data) => {
          this.tieredHistory = data;
          this.loadingHistory = false;
          this.cdr.markForCheck();
        },
        error: () => {
          this.error = this.translate.instant('admin.feeSettings.errors.loadHistoryFailed');
          this.loadingHistory = false;
          this.cdr.markForCheck();
        },
      });
      return;
    }

    this.adminService.getFeeSettingHistory(key).subscribe({
      next: (data) => {
        this.history = data;
        this.loadingHistory = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.feeSettings.errors.loadHistoryFailed');
        this.loadingHistory = false;
        this.cdr.markForCheck();
      },
    });
  }

  onKeyChange(): void {
    // Unit auto-fills from the selected key but stays editable.
    this.draftUnit = DEFAULT_UNIT_BY_KEY[this.draftKey] ?? '';
  }

  openConfirm(): void {
    if (!this.canSave) return;
    this.confirmOpen = true;
  }

  cancelConfirm(): void {
    this.confirmOpen = false;
  }

  createVersion(): void {
    this.confirmOpen = false;
    if (!this.auth.hasPermission(MANAGE_FEE_SETTINGS) || !this.canSave || !this.draftKey) return;

    this.saving = true;
    this.saveError = '';
    const key = this.draftKey;
    const startDate = this.draftStartDate || undefined;
    const unit = this.draftUnit || undefined;

    const save$: Observable<unknown> = this.isTieredKey
      ? forkJoin([
          this.adminService.createFeeSettingVersion({
            key: MONTHLY_SUBSCRIPTION_TIER_KEYS.base,
            value: this.draftBaseAmount as number,
            unit,
            startDate,
          }),
          this.adminService.createFeeSettingVersion({
            key: MONTHLY_SUBSCRIPTION_TIER_KEYS.rate,
            value: this.draftAdditionalRate as number,
            unit,
            startDate,
          }),
          this.adminService.createFeeSettingVersion({
            key: MONTHLY_SUBSCRIPTION_TIER_KEYS.threshold,
            value: this.draftBaseThreshold as number,
            startDate,
          }),
        ])
      : this.adminService.createFeeSettingVersion({
          key,
          value: this.draftValue as number,
          unit,
          startDate,
        });

    save$.subscribe({
      next: () => {
        this.saving = false;
        this.draftKey = '';
        this.draftValue = null;
        this.draftUnit = '';
        this.draftStartDate = '';
        this.draftBaseAmount = null;
        this.draftAdditionalRate = null;
        this.draftBaseThreshold = null;
        this.loadActive();
        if (this.expandedKey === key) {
          this.expandedKey = null;
          this.toggleHistory(key);
        }
        this.cdr.markForCheck();
      },
      error: (err: unknown) => {
        this.saveError =
          (err as { error?: { detail?: string } })?.error?.detail ??
          this.translate.instant('admin.feeSettings.errors.saveFailed');
        this.saving = false;
        this.cdr.markForCheck();
      },
    });
  }
}
