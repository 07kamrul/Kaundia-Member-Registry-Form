import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { KeyValuePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import type {
  AdminFeeType,
  AdminFeeTypeVersion,
  FeeTypeCalculation,
} from '../../../../core/services/admin.service';
import { FEE_MANAGER_PERMISSION, AuthService } from '../../../../core/services/auth.service';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { DatePickerComponent } from '../../../../shared/date-picker/date-picker.component';

/** Fees seeded with the generic catalog whose display labels live in i18n;
 * committee-added fee types show their own bn/en labels instead. */
const SEEDED_FEE_KEYS: readonly string[] = [
  'monthly_subscription',
  'admission_fee',
  'picnic_fee',
];

const UNIT_OPTIONS: readonly string[] = ['taka', 'percent'];

interface FeeTypeDraft {
  labelBn: string;
  labelEn: string;
  key: string;
  calculationType: string;
  unit: string;
  isRecurring: boolean;
  isPayOnce: boolean;
  feeCategory: string;
}

const EMPTY_DRAFT: FeeTypeDraft = {
  labelBn: '',
  labelEn: '',
  key: '',
  calculationType: 'fixed',
  unit: 'taka',
  isRecurring: false,
  isPayOnce: false,
  feeCategory: 'other',
};

@Component({
  selector: 'app-fee-settings',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    KeyValuePipe,
    FormsModule,
    TranslatePipe,
    ConfirmModalComponent,
    IconComponent,
    DatePickerComponent,
  ],
  templateUrl: './fee-settings.component.html',
  styleUrl: './fee-settings.component.scss',
})
export class FeeSettingsComponent implements OnInit {
  private readonly cdr = inject(ChangeDetectorRef);
  private readonly adminService = inject(AdminService);
  private readonly translate = inject(TranslateService);
  private readonly route = inject(ActivatedRoute);
  private readonly auth = inject(AuthService);

  readonly unitOptions = UNIT_OPTIONS;
  readonly canManage = this.auth.hasPermission(FEE_MANAGER_PERMISSION);

  feeTypes: AdminFeeType[] = [];
  loading = false;
  error = '';
  search = '';

  successMessage = '';
  private successTimer: ReturnType<typeof setTimeout> | null = null;

  // --- Add New Version form -------------------------------------------------
  draftKey = '';
  draftValue: number | null = null;
  draftBaseAmount: number | null = null;
  draftAdditionalRate: number | null = null;
  draftBaseThreshold: number | null = null;
  draftHeadFee: number | null = null;
  draftAdditionalHeadFee: number | null = null;
  draftMinAmount: number | null = null;
  draftMaxAmount: number | null = null;
  draftUnit = '';
  draftStartDate = '';
  saving = false;
  saveError = '';
  confirmVersionOpen = false;

  // --- Versions table -------------------------------------------------------
  expandedKey: string | null = null;
  history: AdminFeeTypeVersion[] = [];
  loadingHistory = false;

  // --- New / edit fee type dialog -------------------------------------------
  dialogOpen = false;
  dialogMode: 'create' | 'edit' = 'create';
  editingKey: string | null = null;
  draft: FeeTypeDraft = { ...EMPTY_DRAFT };
  keyTouched = false;
  savingFeeType = false;
  feeTypeError = '';
  private originalDraft: FeeTypeDraft = { ...EMPTY_DRAFT };

  // --- Deactivate confirmation ----------------------------------------------
  pendingToggle: AdminFeeType | null = null;
  confirmDeactivateOpen = false;

  // --- Calculator -----------------------------------------------------------
  calcFeeKey = '';
  calcLandSize: number | null = null;
  calcAdditionalHeads: number | null = null;
  calcAmount: number | null = null;
  calcResult: FeeTypeCalculation | null = null;
  calcError = '';
  calcLoading = false;

  ngOnInit(): void {
    this.load();
    const preselect = this.route.snapshot.queryParamMap.get('key');
    if (preselect) {
      this.draftKey = preselect;
    }
  }

  load(): void {
    this.loading = true;
    this.adminService.getFeeTypes().subscribe({
      next: (data) => {
        this.feeTypes = data;
        this.loading = false;
        if (!this.calcFeeKey) {
          const tiered = data.find((ft) => ft.calculationType === 'tiered' && ft.currentVersion);
          this.calcFeeKey = tiered?.key ?? data.find((ft) => ft.currentVersion)?.key ?? '';
        }
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.feeSettings.errors.loadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  // --- Display helpers ------------------------------------------------------

  feeLabel(ft: AdminFeeType): string {
    if (SEEDED_FEE_KEYS.includes(ft.key)) {
      const translated = this.translate.instant('admin.feeSettings.keys.' + ft.key);
      if (translated !== 'admin.feeSettings.keys.' + ft.key) return translated;
    }
    const lang = this.translate.currentLang() || 'bn';
    return lang === 'bn' ? ft.labelBn : ft.labelEn;
  }

  get activeFeeTypes(): AdminFeeType[] {
    return this.feeTypes.filter((ft) => ft.isActive);
  }

  get filteredGroups(): { key: 'installment' | 'other'; fees: AdminFeeType[] }[] {
    const term = this.search.trim().toLowerCase();
    const matches = this.feeTypes.filter(
      (ft) =>
        !term ||
        ft.key.toLowerCase().includes(term) ||
        ft.labelBn.toLowerCase().includes(term) ||
        ft.labelEn.toLowerCase().includes(term),
    );
    const groups: { key: 'installment' | 'other'; fees: AdminFeeType[] }[] = [
      { key: 'installment', fees: matches.filter((ft) => ft.feeCategory === 'installment') },
      { key: 'other', fees: matches.filter((ft) => ft.feeCategory === 'other') },
    ];
    return groups.filter((group) => group.fees.length > 0);
  }

  get selectedFeeType(): AdminFeeType | null {
    return this.activeFeeTypes.find((ft) => ft.key === this.draftKey) ?? null;
  }

  get selectedCalc(): string {
    return this.selectedFeeType?.calculationType ?? '';
  }

  /** "ভার্সন নেই" - the fee type exists but has no active version, so member
   * payment for it would fail; surfaced here instead of at the payment page. */
  missingVersion(ft: AdminFeeType): boolean {
    if (ft.calculationType === 'variable') return false;
    return ft.currentVersion === null;
  }

  /** Human summary of the active version, per calculation type. */
  summary(ft: AdminFeeType): string {
    const version = ft.currentVersion;
    if (ft.calculationType === 'variable') {
      if (!version) return this.translate.instant('admin.feeSettings.calcTypes.variable');
      const min = version.values[`${ft.key}_min`];
      const max = version.values[`${ft.key}_max`];
      if (min !== undefined && max !== undefined) {
        return this.translate.instant('admin.feeSettings.variableRange', { min, max });
      }
      if (min !== undefined) {
        return this.translate.instant('admin.feeSettings.variableMin', { min });
      }
      if (max !== undefined) {
        return this.translate.instant('admin.feeSettings.variableMax', { max });
      }
      return this.translate.instant('admin.feeSettings.calcTypes.variable');
    }
    if (!version) return '—';
    if (ft.calculationType === 'fixed') {
      return this.translate.instant('admin.feeSettings.fixedSummary', {
        value: version.values[ft.key] ?? Object.values(version.values)[0],
      });
    }
    if (ft.calculationType === 'tiered') {
      const keys = Object.keys(version.values);
      const [base, rate, threshold] = keys.map((k) => version.values[k]);
      return this.translate.instant('admin.feeSettings.tieredSummary', {
        base,
        threshold: threshold ?? '',
        rate,
      });
    }
    // head_additional - identify the head key explicitly; JSON key order is
    // not guaranteed (the legacy picnic keys don't follow the derived pattern).
    const keys = Object.keys(version.values);
    const headKey = keys.find((k) => !k.endsWith('_additional_head')) ?? keys[0];
    const additionalKey = keys.find((k) => k.endsWith('_additional_head')) ?? keys[1];
    return this.translate.instant('admin.feeSettings.headSummary', {
      head: version.values[headKey],
      additional: additionalKey !== undefined ? version.values[additionalKey] : '',
    });
  }

  formatTaka(value: number | null | undefined): string {
    if (value === null || value === undefined) return '—';
    return `৳ ${Number(value).toLocaleString('en-IN', { maximumFractionDigits: 2 })}`;
  }

  versionValueLabel(key: string): string {
    const known: Record<string, string> = {
      _base_amount: 'admin.feeSettings.form.baseAmount',
      _additional_rate: 'admin.feeSettings.form.additionalRate',
      _base_threshold: 'admin.feeSettings.form.baseThreshold',
      _min: 'admin.feeSettings.calc.min',
      _max: 'admin.feeSettings.calc.max',
      _additional_head: 'admin.feeSettings.form.additionalHeadFee',
    };
    const suffix = Object.keys(known).find((s) => key.endsWith(s));
    if (suffix) return this.translate.instant(known[suffix]);
    return this.translate.instant('admin.feeSettings.form.headFee');
  }

  // --- Add New Version ------------------------------------------------------

  get canSaveVersion(): boolean {
    if (!this.canManage || this.saving || !this.selectedFeeType) return false;
    switch (this.selectedCalc) {
      case 'tiered':
        return (
          this.draftBaseAmount !== null &&
          this.draftBaseAmount >= 0 &&
          this.draftAdditionalRate !== null &&
          this.draftAdditionalRate >= 0 &&
          this.draftBaseThreshold !== null &&
          this.draftBaseThreshold > 0
        );
      case 'head_additional':
        return (
          this.draftHeadFee !== null &&
          this.draftHeadFee >= 0 &&
          this.draftAdditionalHeadFee !== null &&
          this.draftAdditionalHeadFee >= 0
        );
      case 'variable':
        return (
          (this.draftMinAmount !== null && this.draftMinAmount >= 0) ||
          (this.draftMaxAmount !== null && this.draftMaxAmount >= 0)
        );
      default:
        return this.draftValue !== null && this.draftValue >= 0;
    }
  }

  onDraftKeyChange(): void {
    const selected = this.selectedFeeType;
    this.draftValue = null;
    this.draftBaseAmount = null;
    this.draftAdditionalRate = null;
    this.draftBaseThreshold = null;
    this.draftHeadFee = null;
    this.draftAdditionalHeadFee = null;
    this.draftMinAmount = null;
    this.draftMaxAmount = null;
    // Unit auto-fills from the fee type but stays editable.
    this.draftUnit = selected?.unit ?? '';
    this.saveError = '';
  }

  openVersionConfirm(): void {
    if (!this.canSaveVersion) return;
    this.confirmVersionOpen = true;
  }

  saveVersion(): void {
    this.confirmVersionOpen = false;
    const feeType = this.selectedFeeType;
    if (!feeType || !this.canSaveVersion) return;

    this.saving = true;
    this.saveError = '';
    const payload: Parameters<AdminService['createFeeTypeVersion']>[1] = {
      unit: this.draftUnit || undefined,
      startDate: this.draftStartDate || undefined,
    };
    switch (feeType.calculationType) {
      case 'tiered':
        payload.baseAmount = this.draftBaseAmount ?? undefined;
        payload.additionalRate = this.draftAdditionalRate ?? undefined;
        payload.baseThreshold = this.draftBaseThreshold ?? undefined;
        break;
      case 'head_additional':
        payload.headFee = this.draftHeadFee ?? undefined;
        payload.additionalHeadFee = this.draftAdditionalHeadFee ?? undefined;
        break;
      case 'variable':
        payload.minAmount = this.draftMinAmount ?? undefined;
        payload.maxAmount = this.draftMaxAmount ?? undefined;
        break;
      default:
        payload.value = this.draftValue ?? undefined;
    }

    this.adminService.createFeeTypeVersion(feeType.key, payload).subscribe({
      next: () => {
        this.saving = false;
        this.draftKey = '';
        this.onDraftKeyChange();
        this.draftUnit = '';
        this.draftStartDate = '';
        this.flashSuccess(this.translate.instant('admin.feeSettings.versionSaved'));
        this.load();
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

  // --- History --------------------------------------------------------------

  toggleHistory(ft: AdminFeeType): void {
    if (this.expandedKey === ft.key) {
      this.expandedKey = null;
      this.history = [];
      return;
    }
    this.expandedKey = ft.key;
    this.loadingHistory = true;
    this.adminService.getFeeTypeVersions(ft.key).subscribe({
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

  // --- New / edit fee type dialog -------------------------------------------

  openNewFeeDialog(): void {
    this.dialogMode = 'create';
    this.editingKey = null;
    this.draft = { ...EMPTY_DRAFT };
    this.keyTouched = false;
    this.feeTypeError = '';
    this.dialogOpen = true;
  }

  openEditFeeDialog(ft: AdminFeeType): void {
    this.dialogMode = 'edit';
    this.editingKey = ft.key;
    this.draft = {
      labelBn: ft.labelBn,
      labelEn: ft.labelEn,
      key: ft.key,
      calculationType: ft.calculationType,
      unit: ft.unit,
      isRecurring: ft.isRecurring,
      isPayOnce: ft.isPayOnce,
      feeCategory: ft.feeCategory,
    };
    this.originalDraft = { ...this.draft };
    this.keyTouched = true;
    this.feeTypeError = '';
    this.dialogOpen = true;
  }

  closeFeeDialog(): void {
    this.dialogOpen = false;
  }

  /** Key auto-slugged from the English label until the admin edits it. */
  onLabelEnChange(): void {
    if (this.dialogMode === 'create' && !this.keyTouched) {
      this.draft.key = this.draft.labelEn
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '_')
        .replace(/^_+|_+$/g, '')
        .slice(0, 64);
    }
  }

  onKeyInput(): void {
    this.keyTouched = true;
  }

  get keyError(): string {
    if (!this.draft.key) return '';
    if (!/^[a-z][a-z0-9_]*$/.test(this.draft.key)) {
      return this.translate.instant('admin.feeSettings.newFee.keyInvalid');
    }
    const taken = this.feeTypes.some(
      (ft) => ft.key === this.draft.key && ft.key !== this.editingKey,
    );
    if (taken) return this.translate.instant('admin.feeSettings.newFee.keyTaken');
    return '';
  }

  /** The subset of draft fields an edit can actually change (key and
   * calculation type are fixed once created). */
  private editable(draft: FeeTypeDraft): Record<string, unknown> {
    return {
      labelBn: draft.labelBn,
      labelEn: draft.labelEn,
      unit: draft.unit,
      isRecurring: draft.isRecurring,
      isPayOnce: draft.isPayOnce,
      feeCategory: draft.feeCategory,
    };
  }

  get dialogChanged(): boolean {
    if (this.dialogMode === 'create') {
      return !!(this.draft.labelBn && this.draft.labelEn && this.draft.key && !this.keyError);
    }
    return (
      JSON.stringify(this.editable(this.draft)) !==
      JSON.stringify(this.editable(this.originalDraft))
    );
  }

  get canSubmitFeeType(): boolean {
    return this.canManage && !this.savingFeeType && this.dialogChanged && !this.keyError;
  }

  submitFeeType(): void {
    if (!this.canSubmitFeeType) return;
    this.savingFeeType = true;
    this.feeTypeError = '';

    const done = () => {
      this.savingFeeType = false;
      this.dialogOpen = false;
      this.cdr.markForCheck();
    };

    if (this.dialogMode === 'create') {
      this.adminService
        .createFeeType({
          key: this.draft.key,
          labelBn: this.draft.labelBn,
          labelEn: this.draft.labelEn,
          calculationType: this.draft.calculationType,
          unit: this.draft.unit,
          isRecurring: this.draft.isRecurring,
          isPayOnce: this.draft.isPayOnce,
          feeCategory: this.draft.feeCategory,
        })
        .subscribe({
          next: () => {
            done();
            this.flashSuccess(this.translate.instant('admin.feeSettings.feeTypeCreated'));
            this.draftKey = this.draft.key;
            this.load();
          },
          error: (err: unknown) => {
            this.feeTypeError =
              (err as { error?: { detail?: string } })?.error?.detail ??
              this.translate.instant('admin.feeSettings.errors.saveFailed');
            this.savingFeeType = false;
            this.cdr.markForCheck();
          },
        });
      return;
    }

    const changed: Record<string, unknown> = {};
    const before = this.editable(this.originalDraft);
    const after = this.editable(this.draft);
    for (const field of Object.keys(before)) {
      if (before[field] !== after[field]) changed[field] = after[field];
    }
    this.adminService.updateFeeType(this.editingKey ?? '', changed).subscribe({
      next: () => {
        done();
        this.flashSuccess(this.translate.instant('admin.feeSettings.feeTypeUpdated'));
        this.load();
      },
      error: (err: unknown) => {
        this.feeTypeError =
          (err as { error?: { detail?: string } })?.error?.detail ??
          this.translate.instant('admin.feeSettings.errors.saveFailed');
        this.savingFeeType = false;
        this.cdr.markForCheck();
      },
    });
  }

  // --- Active toggle ----------------------------------------------------------

  requestToggleActive(ft: AdminFeeType): void {
    if (!this.canManage) return;
    if (ft.isActive && ft.paymentCount > 0) {
      this.pendingToggle = ft;
      this.confirmDeactivateOpen = true;
      return;
    }
    this.toggleActive(ft);
  }

  confirmDeactivate(): void {
    this.confirmDeactivateOpen = false;
    if (this.pendingToggle) this.toggleActive(this.pendingToggle);
    this.pendingToggle = null;
  }

  cancelDeactivate(): void {
    this.confirmDeactivateOpen = false;
    this.pendingToggle = null;
  }

  private toggleActive(ft: AdminFeeType): void {
    this.adminService.updateFeeType(ft.key, { isActive: !ft.isActive }).subscribe({
      next: () => {
        this.flashSuccess(
          this.translate.instant(
            ft.isActive ? 'admin.feeSettings.feeDeactivated' : 'admin.feeSettings.feeActivated',
          ),
        );
        this.load();
      },
      error: () => {
        this.error = this.translate.instant('admin.feeSettings.errors.saveFailed');
        this.cdr.markForCheck();
      },
    });
  }

  // --- Calculator -------------------------------------------------------------

  get calcFeeType(): AdminFeeType | null {
    return this.feeTypes.find((ft) => ft.key === this.calcFeeKey) ?? null;
  }

  onCalcFeeChange(): void {
    this.calcLandSize = null;
    this.calcAdditionalHeads = null;
    this.calcAmount = null;
    this.calcResult = null;
    this.calcError = '';
  }

  calculate(): void {
    const feeType = this.calcFeeType;
    if (!feeType) return;
    this.calcLoading = true;
    this.calcError = '';
    const payload: Parameters<AdminService['calculateFeeType']>[1] = {};
    if (feeType.calculationType === 'tiered') payload.landSize = this.calcLandSize ?? undefined;
    if (feeType.calculationType === 'head_additional') {
      payload.additionalHeads = this.calcAdditionalHeads ?? 0;
    }
    if (feeType.calculationType === 'variable') payload.amount = this.calcAmount ?? undefined;

    this.adminService.calculateFeeType(feeType.key, payload).subscribe({
      next: (result) => {
        this.calcResult = result;
        this.calcLoading = false;
        this.cdr.markForCheck();
      },
      error: (err: unknown) => {
        const detail = (err as { error?: { detail?: string | { message?: string } } })?.error
          ?.detail;
        this.calcError =
          (typeof detail === 'string' ? detail : detail?.message) ??
          this.translate.instant('admin.feeSettings.calc.unavailable');
        this.calcResult = null;
        this.calcLoading = false;
        this.cdr.markForCheck();
      },
    });
  }

  // --- Misc ---------------------------------------------------------------------

  private flashSuccess(message: string): void {
    this.successMessage = message;
    if (this.successTimer) clearTimeout(this.successTimer);
    this.successTimer = setTimeout(() => {
      this.successMessage = '';
      this.cdr.markForCheck();
    }, 4000);
  }
}
