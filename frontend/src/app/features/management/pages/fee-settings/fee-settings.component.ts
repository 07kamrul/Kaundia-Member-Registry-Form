import { ChangeDetectorRef, Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';
import { IconComponent } from '../../../../shared/icon/icon.component';
import type { FeeSetting } from '../../../../core/models/admin.model';

const MANAGE_FEE_SETTINGS = 'manage_fee_settings';

/** Known fee keys the version form offers, in display order. */
const KNOWN_FEE_KEYS: readonly string[] = ['admission_fee', 'monthly_subscription'];

/** Default unit per known key (i18n unit option); empty string when unknown. */
const DEFAULT_UNIT_BY_KEY: Record<string, string> = {
  admission_fee: 'taka',
  monthly_subscription: 'taka',
};

const UNIT_OPTIONS: readonly string[] = ['taka', 'percent'];

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
  loadingHistory = false;

  draftKey = '';
  draftValue: number | null = null;
  draftUnit = '';
  draftStartDate = '';
  saving = false;
  saveError = '';

  confirmOpen = false;

  constructor(
    private adminService: AdminService,
    public auth: AuthService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.loadActive();
  }

  /** Known keys plus any extra keys already present in active settings. */
  get feeKeys(): string[] {
    const extra = this.active.map((s) => s.key).filter((k) => !KNOWN_FEE_KEYS.includes(k));
    return [...KNOWN_FEE_KEYS, ...extra];
  }

  get canSave(): boolean {
    return (
      this.auth.hasPermission(MANAGE_FEE_SETTINGS) &&
      !this.saving &&
      !!this.draftKey &&
      this.draftValue !== null
    );
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
      return;
    }
    this.expandedKey = key;
    this.loadingHistory = true;
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
    if (!this.auth.hasPermission(MANAGE_FEE_SETTINGS)) return;
    if (!this.draftKey || this.draftValue === null) return;

    this.saving = true;
    this.saveError = '';
    const key = this.draftKey;
    this.adminService
      .createFeeSettingVersion({
        key,
        value: this.draftValue,
        unit: this.draftUnit || undefined,
        startDate: this.draftStartDate || undefined,
      })
      .subscribe({
        next: () => {
          this.saving = false;
          this.draftKey = '';
          this.draftValue = null;
          this.draftUnit = '';
          this.draftStartDate = '';
          this.loadActive();
          if (this.expandedKey === key) {
            this.expandedKey = null;
            this.toggleHistory(key);
          }
          this.cdr.markForCheck();
        },
        error: (err) => {
          this.saveError =
            err?.error?.detail ?? this.translate.instant('admin.feeSettings.errors.saveFailed');
          this.saving = false;
          this.cdr.markForCheck();
        },
      });
  }
}
