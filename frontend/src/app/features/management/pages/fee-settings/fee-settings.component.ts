import { ChangeDetectorRef, Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import type { FeeSetting } from '../../../../core/models/admin.model';

const MANAGE_FEE_SETTINGS = 'manage_fee_settings';

@Component({
  selector: 'app-fee-settings',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe],
  templateUrl: './fee-settings.component.html',
})
export class FeeSettingsComponent implements OnInit {
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

  constructor(
    private adminService: AdminService,
    public auth: AuthService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.loadActive();
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

  createVersion(): void {
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
