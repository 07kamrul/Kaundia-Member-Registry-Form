import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnDestroy,
  OnInit,
  inject,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { DatePipe } from '@angular/common';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { DatePickerComponent } from '../../../../shared/date-picker/date-picker.component';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import {
  SocietyCostService,
  type CostPaymentSource,
  type CostSplitShare,
  type ShareStatus,
  type SocietyCost,
  type SocietyCostSummary,
  type SplitMethod,
  type SplitPreviewRow,
} from '../../../../core/services/society-cost.service';
import type { ConfigListItem } from '../../../../core/models/admin.model';

interface ManualAmount {
  memberId: number;
  memberName: string;
  amount: number | null;
}

@Component({
  selector: 'app-society-costs',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, DatePipe, ConfirmModalComponent, IconComponent, DatePickerComponent],
  templateUrl: './society-costs.component.html',
  styleUrl: './society-costs.component.scss',
})
export class SocietyCostsComponent implements OnInit, OnDestroy {
  costs: SocietyCost[] = [];
  loading = false;
  error = '';
  summary: SocietyCostSummary | null = null;

  categories: ConfigListItem[] = [];
  readonly canManageConfig: boolean;

  // Filters
  categoryFilter = '';
  dateFrom = '';
  dateTo = '';
  sourceFilter = '';
  billedFilter = '';
  search = '';

  expandedId: number | null = null;

  // Create/edit modal
  showFormModal = false;
  editingCost: SocietyCost | null = null;
  formTitle = '';
  formCategory = '';
  formAmount: number | null = null;
  formDate = '';
  formSource: CostPaymentSource = 'society_fund';
  formDescription = '';
  formNotes = '';
  formReceipt: File | null = null;
  receiptPreviewUrl: string | null = null;
  formError = '';
  formFieldErrors: Record<string, string> = {};
  saving = false;

  // Split modal
  showSplitModal = false;
  splitCost: SocietyCost | null = null;
  splitMethod: SplitMethod = 'equal';
  splitPreview: SplitPreviewRow[] = [];
  manualAmounts: ManualAmount[] = [];
  splitError = '';
  splitLoading = false;
  splitSaving = false;
  allowMismatch = false;

  // Payment modal
  showPaymentModal = false;
  paymentShare: CostSplitShare | null = null;
  paymentAmount: number | null = null;
  paymentReceiptNo = '';
  paymentError = '';

  // Delete modal
  showDeleteModal = false;
  deleteTarget: SocietyCost | null = null;
  deleteError = '';

  private readonly cdr = inject(ChangeDetectorRef);

  constructor(
    private costService: SocietyCostService,
    private adminService: AdminService,
    private auth: AuthService,
    private translate: TranslateService,
  ) {
    this.canManageConfig = this.auth.hasPermission('manage_system_config');
  }

  ngOnInit(): void {
    this.loadCategories();
    this.load();
    this.loadSummary();
  }

  ngOnDestroy(): void {
    this.revokeReceiptPreview();
  }

  load(): void {
    this.loading = true;
    this.error = '';
    this.costService
      .listCosts({
        categoryId: this.categoryFilter ? Number(this.categoryFilter) : undefined,
        dateFrom: this.dateFrom || undefined,
        dateTo: this.dateTo || undefined,
        paymentSource: (this.sourceFilter || undefined) as CostPaymentSource | undefined,
        billed: this.billedFilter === '' ? undefined : this.billedFilter === 'true',
        search: this.search.trim() || undefined,
      })
      .subscribe({
        next: (costs) => {
          this.costs = costs;
          this.loading = false;
          this.cdr.markForCheck();
        },
        error: () => {
          this.error = this.translate.instant('admin.societyCosts.errors.loadFailed');
          this.loading = false;
          this.cdr.markForCheck();
        },
      });
  }

  loadSummary(): void {
    this.costService
      .getSummary({ dateFrom: this.dateFrom || undefined, dateTo: this.dateTo || undefined })
      .subscribe({
        next: (summary) => {
          this.summary = summary;
          this.cdr.markForCheck();
        },
        error: () => {
          this.summary = null;
          this.cdr.markForCheck();
        },
      });
  }

  loadCategories(): void {
    this.adminService.listConfigListItems('cost_category').subscribe({
      next: (items) => {
        this.categories = items.filter((i) => i.isActive);
        this.cdr.markForCheck();
      },
      error: () => {
        this.categories = [];
        this.cdr.markForCheck();
      },
    });
  }

  addCategory(value: string): void {
    const label = value.trim();
    if (!label) return;
    this.adminService
      .createConfigListItem({ category: 'cost_category', value: label, label })
      .subscribe({
        next: (item) => {
          this.categories = [...this.categories, item].sort((a, b) => a.sortOrder - b.sortOrder);
          this.formCategory = item.id;
          this.cdr.markForCheck();
        },
        error: () => {
          this.formError = this.translate.instant('admin.societyCosts.errors.categoryAddFailed');
          this.cdr.markForCheck();
        },
      });
  }

  resetFilters(): void {
    this.categoryFilter = '';
    this.dateFrom = '';
    this.dateTo = '';
    this.sourceFilter = '';
    this.billedFilter = '';
    this.search = '';
    this.load();
    this.loadSummary();
  }

  applyFilters(): void {
    this.load();
    this.loadSummary();
  }

  toggleExpanded(id: number): void {
    this.expandedId = this.expandedId === id ? null : id;
    this.cdr.markForCheck();
  }

  // ----- Create / edit -----

  openCreateForm(): void {
    this.editingCost = null;
    this.formTitle = '';
    this.formCategory = '';
    this.formAmount = null;
    this.formDate = new Date().toISOString().slice(0, 10);
    this.formSource = 'society_fund';
    this.formDescription = '';
    this.formNotes = '';
    this.clearReceipt();
    this.formError = '';
    this.formFieldErrors = {};
    this.showFormModal = true;
    this.cdr.markForCheck();
  }

  openEditForm(cost: SocietyCost): void {
    this.editingCost = cost;
    this.formTitle = cost.title;
    this.formCategory = cost.categoryId ? String(cost.categoryId) : '';
    this.formAmount = cost.totalAmount;
    this.formDate = cost.incurredDate;
    this.formSource = cost.paymentSource;
    this.formDescription = cost.description ?? '';
    this.formNotes = cost.notes ?? '';
    this.clearReceipt();
    this.formError = '';
    this.formFieldErrors = {};
    this.showFormModal = true;
    this.cdr.markForCheck();
  }

  closeFormModal(): void {
    this.showFormModal = false;
    this.cdr.markForCheck();
  }

  onReceiptSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    this.formReceipt = file;
    this.revokeReceiptPreview();
    this.receiptPreviewUrl = file.type.startsWith('image/') ? URL.createObjectURL(file) : null;
    this.cdr.markForCheck();
  }

  clearReceipt(): void {
    this.formReceipt = null;
    this.revokeReceiptPreview();
  }

  private revokeReceiptPreview(): void {
    if (this.receiptPreviewUrl) {
      URL.revokeObjectURL(this.receiptPreviewUrl);
      this.receiptPreviewUrl = null;
    }
  }

  saveCost(): void {
    this.formError = '';
    this.formFieldErrors = {};
    if (!this.formTitle.trim()) {
      this.formFieldErrors['title'] = this.translate.instant('admin.societyCosts.errors.titleRequired');
    }
    if (this.formAmount == null || this.formAmount <= 0) {
      this.formFieldErrors['totalAmount'] = this.translate.instant('admin.societyCosts.errors.amountRequired');
    }
    if (!this.formDate) {
      this.formFieldErrors['incurredDate'] = this.translate.instant('admin.societyCosts.errors.dateRequired');
    }
    if (Object.keys(this.formFieldErrors).length) {
      this.cdr.markForCheck();
      return;
    }

    const input = {
      title: this.formTitle.trim(),
      description: this.formDescription.trim() || null,
      categoryId: this.formCategory ? Number(this.formCategory) : null,
      totalAmount: this.formAmount!,
      incurredDate: this.formDate,
      paymentSource: this.formSource,
      notes: this.formNotes.trim() || null,
    };
    this.saving = true;
    const request$ = this.editingCost
      ? this.costService.updateCost(this.editingCost.id, input)
      : this.costService.createCost(input);

    request$.subscribe({
      next: (cost) => {
        if (this.formReceipt) {
          this.costService.uploadReceipt(cost.id, this.formReceipt).subscribe({
            next: () => this.finishSave(),
            error: (err) => {
              // The cost itself saved; only the receipt upload failed.
              this.saving = false;
              this.formError =
                (typeof err?.error?.detail === 'string' && err.error.detail) ||
                this.translate.instant('admin.societyCosts.errors.receiptUploadFailed');
              this.cdr.markForCheck();
            },
          });
        } else {
          this.finishSave();
        }
      },
      error: (err) => {
        this.saving = false;
        this.formError =
          (typeof err?.error?.detail === 'string' && err.error.detail) ||
          this.translate.instant('admin.societyCosts.errors.saveFailed');
        this.cdr.markForCheck();
      },
    });
  }

  private finishSave(): void {
    this.saving = false;
    this.showFormModal = false;
    this.clearReceipt();
    this.load();
    this.loadSummary();
    this.cdr.markForCheck();
  }

  // ----- Split -----

  openSplitModal(cost: SocietyCost): void {
    this.splitCost = cost;
    this.splitMethod = cost.split?.splitMethod ?? 'equal';
    this.splitError = '';
    this.splitPreview = [];
    this.manualAmounts = [];
    this.allowMismatch = false;
    this.showSplitModal = true;
    void this.refreshSplitPreview();
    this.cdr.markForCheck();
  }

  onSplitMethodChange(): void {
    void this.refreshSplitPreview();
  }

  refreshSplitPreview(): Promise<void> {
    const cost = this.splitCost;
    if (!cost) return Promise.resolve();
    this.splitLoading = true;
    this.splitError = '';
    this.cdr.markForCheck();

    const payload: Parameters<SocietyCostService['splitCost']>[1] = {
      split_method: this.splitMethod,
      dry_run: true,
    };
    if (this.splitMethod === 'manual') {
      payload.manual_shares = this.manualAmounts
        .filter((m) => m.amount != null && m.amount >= 0)
        .map((m) => ({ member_id: m.memberId, amount_due: m.amount! }));
      if (payload.manual_shares.length === 0) {
        // Nothing entered yet: seed the member list via an equal-split preview.
        payload.split_method = 'equal';
      }
    }

    return new Promise((resolve) => {
      this.costService.splitCost(cost.id, payload).subscribe({
        next: (result) => {
          this.splitLoading = false;
          if (Array.isArray(result)) {
            if (this.splitMethod === 'manual' && payload.split_method === 'manual') {
              this.splitPreview = result;
            } else {
              this.splitPreview = [];
              this.manualAmounts = result.map((row) => ({
                memberId: row.memberId,
                memberName: row.memberName,
                amount: null,
              }));
            }
          }
          this.cdr.markForCheck();
          resolve();
        },
        error: (err) => {
          this.splitLoading = false;
          this.splitError =
            (typeof err?.error?.detail === 'string' && err.error.detail) ||
            this.translate.instant('admin.societyCosts.errors.splitPreviewFailed');
          this.cdr.markForCheck();
          resolve();
        },
      });
    });
  }

  get manualTotal(): number {
    return this.manualAmounts.reduce((sum, m) => sum + (m.amount ?? 0), 0);
  }

  setManualAmount(entry: ManualAmount, value: string | number | null): void {
    entry.amount = value == null || value === '' ? null : Number(value);
    this.cdr.markForCheck();
  }

  get manualMismatch(): boolean {
    if (this.splitMethod !== 'manual' || !this.splitCost) return false;
    return Math.abs(this.manualTotal - this.splitCost.totalAmount) >= 0.005;
  }

  confirmSplit(): void {
    const cost = this.splitCost;
    if (!cost) return;
    this.splitSaving = true;
    this.splitError = '';
    const payload: Parameters<SocietyCostService['splitCost']>[1] = {
      split_method: this.splitMethod,
    };
    if (this.splitMethod === 'manual') {
      payload.manual_shares = this.manualAmounts
        .filter((m) => m.amount != null)
        .map((m) => ({ member_id: m.memberId, amount_due: m.amount! }));
      payload.allow_mismatch = this.allowMismatch;
    }
    this.costService.splitCost(cost.id, payload).subscribe({
      next: () => {
        this.splitSaving = false;
        this.showSplitModal = false;
        this.load();
        this.loadSummary();
        this.cdr.markForCheck();
      },
      error: (err) => {
        this.splitSaving = false;
        this.splitError =
          (typeof err?.error?.detail === 'string' && err.error.detail) ||
          this.translate.instant('admin.societyCosts.errors.splitFailed');
        this.cdr.markForCheck();
      },
    });
  }

  closeSplitModal(): void {
    this.showSplitModal = false;
    this.cdr.markForCheck();
  }

  cancelDelete(): void {
    this.showDeleteModal = false;
    this.cdr.markForCheck();
  }

  // ----- Payment -----

  openPaymentModal(share: CostSplitShare): void {
    this.paymentShare = share;
    this.paymentAmount = share.amountDue - share.amountPaid;
    this.paymentReceiptNo = share.receiptNo ?? '';
    this.paymentError = '';
    this.showPaymentModal = true;
    this.cdr.markForCheck();
  }

  savePayment(): void {
    const share = this.paymentShare;
    if (!share || this.paymentAmount == null || this.paymentAmount < 0) return;
    this.paymentError = '';
    this.costService
      .recordSharePayment(share.id, {
        amount_paid: share.amountPaid + this.paymentAmount,
        receipt_no: this.paymentReceiptNo.trim() || null,
      })
      .subscribe({
        next: () => {
          this.showPaymentModal = false;
          this.load();
          this.loadSummary();
          this.cdr.markForCheck();
        },
        error: (err) => {
          this.paymentError =
            (typeof err?.error?.detail === 'string' && err.error.detail) ||
            this.translate.instant('admin.societyCosts.errors.paymentFailed');
          this.cdr.markForCheck();
        },
      });
  }

  closePaymentModal(): void {
    this.showPaymentModal = false;
    this.cdr.markForCheck();
  }

  // ----- Delete -----

  openDeleteModal(cost: SocietyCost): void {
    this.deleteTarget = cost;
    this.deleteError = '';
    this.showDeleteModal = true;
    this.cdr.markForCheck();
  }

  confirmDelete(): void {
    const cost = this.deleteTarget;
    if (!cost) return;
    this.costService.deleteCost(cost.id).subscribe({
      next: () => {
        this.showDeleteModal = false;
        this.load();
        this.loadSummary();
        this.cdr.markForCheck();
      },
      error: (err) => {
        this.deleteError =
          (typeof err?.error?.detail === 'string' && err.error.detail) ||
          this.translate.instant('admin.societyCosts.errors.deleteFailed');
        this.cdr.markForCheck();
      },
    });
  }

  statusLabel(status: ShareStatus): string {
    return this.translate.instant(`admin.societyCosts.shareStatus.${status}`);
  }

  methodLabel(method: SplitMethod): string {
    return this.translate.instant(`admin.societyCosts.splitMethod.${method}`);
  }

  formatAmount(amount: number): string {
    return amount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }

  exportCsv(): void {
    const header = [
      this.translate.instant('admin.societyCosts.table.title'),
      this.translate.instant('admin.societyCosts.table.category'),
      this.translate.instant('admin.societyCosts.table.amount'),
      this.translate.instant('admin.societyCosts.table.date'),
      this.translate.instant('admin.societyCosts.table.source'),
      this.translate.instant('admin.societyCosts.table.split'),
    ];
    const rows = this.costs.map((c) => [
      c.title,
      c.categoryLabel ?? '',
      c.totalAmount.toFixed(2),
      c.incurredDate,
      this.translate.instant(`admin.societyCosts.source.${c.paymentSource}`),
      c.split
        ? `${this.methodLabel(c.split.splitMethod)} (${c.split.shares.length})`
        : this.translate.instant('admin.societyCosts.notBilled'),
    ]);
    const csv = [header, ...rows]
      .map((row) => row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(','))
      .join('\n');
    // BOM keeps Excel happy with the Bengali text below.
    const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = `society-costs-${new Date().toISOString().slice(0, 10)}.csv`;
    anchor.click();
    URL.revokeObjectURL(url);
  }
}
