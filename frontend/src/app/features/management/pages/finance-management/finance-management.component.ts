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
import type { Observable } from 'rxjs';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { DatePickerComponent } from '../../../../shared/date-picker/date-picker.component';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import {
  FinanceService,
  formatTaka,
  type FinanceCategory,
  type FinanceLedgerPage,
  type FinanceOverview,
  type FinancePeriod,
  type FinanceStatus,
  type FinanceTransaction,
  type FinanceType,
  type PaymentSourceType,
  type UnlinkedPayment,
} from '../../../../core/services/finance.service';
import { monthNameKey } from '../../../../shared/constants/months';

const STATUS_FILTERS: (FinanceStatus | 'all')[] = [
  'all',
  'pending',
  'draft',
  'approved',
  'rejected',
];

/** Mirrors the backend's APPROVED_EDIT_WINDOW_DAYS. */
const APPROVED_EDIT_WINDOW_DAYS = 7;

const PAYMENT_SOURCE_LABELS: Record<PaymentSourceType, string> = {
  installment: 'admin.financeManagement.source.installment',
  picnic_payment: 'admin.financeManagement.source.picnic_payment',
  cost_share: 'admin.financeManagement.source.cost_share',
};

@Component({
  selector: 'app-finance-management',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, DatePipe, IconComponent, DatePickerComponent],
  templateUrl: './finance-management.component.html',
  styleUrl: './finance-management.component.scss',
})
export class FinanceManagementComponent implements OnInit, OnDestroy {
  readonly statusFilters = STATUS_FILTERS;

  // ----- Overview widget -----
  overview: FinanceOverview | null = null;

  // ----- Filters -----
  statusFilter: FinanceStatus | 'all' = 'all';
  typeFilter: FinanceType | '' = '';
  categoryFilter = '';
  dateFrom = '';
  dateTo = '';
  search = '';

  categories: FinanceCategory[] = [];

  // ----- Ledger -----
  ledger: FinanceLedgerPage | null = null;
  loading = false;
  error = '';
  page = 1;
  pageSize = 25;
  expandedId: number | null = null;

  // ----- Create / edit modal -----
  showFormModal = false;
  editing: FinanceTransaction | null = null;
  formType: FinanceType = 'income';
  formDate = '';
  formCategoryId: number | null = null;
  formAmount: number | null = null;
  formDescription = '';
  formReference = '';
  formInternalNotes = '';
  formAttachment: File | null = null;
  attachmentPreviewUrl: string | null = null;
  formError = '';
  formFieldErrors: Record<string, string> = {};
  saving = false;

  // Searchable category picker state
  categoryQuery = '';
  categoryDropdownOpen = false;

  // Payment linking (income only)
  paymentLinkEnabled = false;
  paymentSourceFilter: PaymentSourceType | '' = '';
  paymentSearch = '';
  paymentOptions: UnlinkedPayment[] = [];
  paymentLoading = false;
  selectedPayment: UnlinkedPayment | null = null;

  // ----- Action modals -----
  actionTarget: FinanceTransaction | null = null;
  actionReason = '';
  actionError = '';
  actionBusy = false;
  modal: 'reject' | 'reverse' | 'delete' | 'approve' | null = null;

  // ----- Report notice -----
  noticePeriod: FinancePeriod = 'month';
  noticeBusy = false;
  noticeDone = false;

  readonly canManageConfig: boolean;

  private readonly cdr = inject(ChangeDetectorRef);

  constructor(
    private finance: FinanceService,
    private adminService: AdminService,
    private auth: AuthService,
    private translate: TranslateService,
  ) {
    this.canManageConfig = this.auth.hasPermission('manage_system_config');
  }

  ngOnInit(): void {
    this.loadCategories();
    this.load();
    this.loadOverview();
  }

  ngOnDestroy(): void {
    this.revokeAttachmentPreview();
  }

  get lang(): string {
    return this.translate.currentLang() || 'bn';
  }

  taka(value: number): string {
    return formatTaka(value, this.lang);
  }

  formatDate(iso: string | null): string {
    if (!iso) return '—';
    const parts = iso.slice(0, 10).split('-');
    if (parts.length !== 3) return iso;
    const monthLabel = this.translate.instant(monthNameKey(Number(parts[1])));
    const digits = (text: string) =>
      this.lang === 'bn' ? text.replace(/[0-9]/g, (d) => '০১২৩৪৫৬৭৮৯'[Number(d)]) : text;
    return `${digits(parts[2])} ${monthLabel} ${digits(parts[0])}`;
  }

  // ----- Data loading -----

  load(): void {
    this.loading = true;
    this.error = '';
    this.finance
      .adminTransactions({
        status: this.statusFilter === 'all' ? undefined : this.statusFilter,
        type: this.typeFilter || undefined,
        categoryId: this.categoryFilter ? Number(this.categoryFilter) : undefined,
        dateFrom: this.dateFrom || undefined,
        dateTo: this.dateTo || undefined,
        search: this.search.trim() || undefined,
        limit: this.pageSize,
        offset: (this.page - 1) * this.pageSize,
      })
      .subscribe({
        next: (ledger) => {
          this.ledger = ledger;
          this.loading = false;
          this.cdr.markForCheck();
        },
        error: () => {
          this.loading = false;
          this.error = this.translate.instant('admin.financeManagement.errors.loadFailed');
          this.cdr.markForCheck();
        },
      });
  }

  loadOverview(): void {
    this.finance.overview().subscribe({
      next: (overview) => {
        this.overview = overview;
        this.cdr.markForCheck();
      },
      error: () => {
        this.overview = null;
        this.cdr.markForCheck();
      },
    });
  }

  loadCategories(): void {
    this.finance.categories().subscribe({
      next: (categories) => {
        this.categories = categories;
        this.cdr.markForCheck();
      },
      error: () => {
        this.categories = [];
        this.cdr.markForCheck();
      },
    });
  }

  applyFilters(): void {
    this.page = 1;
    this.load();
  }

  setStatusFilter(status: FinanceStatus | 'all'): void {
    this.statusFilter = status;
    this.applyFilters();
  }

  resetFilters(): void {
    this.statusFilter = 'all';
    this.typeFilter = '';
    this.categoryFilter = '';
    this.dateFrom = '';
    this.dateTo = '';
    this.search = '';
    this.applyFilters();
  }

  get totalPages(): number {
    return Math.max(1, Math.ceil((this.ledger?.total ?? 0) / this.pageSize));
  }

  changePage(delta: number): void {
    const next = this.page + delta;
    if (next < 1 || next > this.totalPages) return;
    this.page = next;
    this.load();
  }

  toggleExpanded(id: number): void {
    this.expandedId = this.expandedId === id ? null : id;
    this.cdr.markForCheck();
  }

  statusClass(status: FinanceStatus): string {
    switch (status) {
      case 'approved':
        return 'status-approved';
      case 'pending':
        return 'status-pending';
      case 'rejected':
        return 'status-rejected';
      default:
        return 'status-inactive'; // draft
    }
  }

  // Mirrors the server's edit window so the UI hides impossible edits.
  editable(txn: FinanceTransaction): boolean {
    if (txn.status !== 'approved' || !txn.approvedAt) return true;
    const approvedAt = new Date(txn.approvedAt).getTime();
    if (Number.isNaN(approvedAt)) return true;
    return Date.now() - approvedAt < APPROVED_EDIT_WINDOW_DAYS * 24 * 60 * 60 * 1000;
  }

  // ----- Create / edit -----

  openCreateForm(): void {
    this.editing = null;
    this.formType = 'income';
    this.formDate = new Date().toISOString().slice(0, 10);
    this.formCategoryId = null;
    this.formAmount = null;
    this.formDescription = '';
    this.formReference = '';
    this.formInternalNotes = '';
    this.clearAttachment();
    this.paymentLinkEnabled = false;
    this.selectedPayment = null;
    this.paymentSourceFilter = '';
    this.paymentSearch = '';
    this.paymentOptions = [];
    this.categoryQuery = '';
    this.formError = '';
    this.formFieldErrors = {};
    this.showFormModal = true;
    this.cdr.markForCheck();
  }

  openEditForm(txn: FinanceTransaction): void {
    this.editing = txn;
    this.formType = txn.type;
    this.formDate = txn.txnDate;
    this.formCategoryId = txn.categoryId;
    this.categoryQuery = txn.categoryLabel ?? '';
    this.formAmount = txn.amount;
    this.formDescription = txn.description;
    this.formReference = txn.referenceNo ?? '';
    this.formInternalNotes = txn.internalNotes ?? '';
    this.clearAttachment();
    this.paymentLinkEnabled = false;
    this.selectedPayment = null;
    this.paymentOptions = [];
    this.formError = '';
    this.formFieldErrors = {};
    this.showFormModal = true;
    this.cdr.markForCheck();
  }

  closeFormModal(): void {
    this.showFormModal = false;
    this.categoryDropdownOpen = false;
    this.cdr.markForCheck();
  }

  onTypeChange(): void {
    // Categories are type-specific; an expense cannot carry a payment link.
    this.formCategoryId = null;
    this.categoryQuery = '';
    if (this.formType === 'expense') {
      this.paymentLinkEnabled = false;
      this.selectedPayment = null;
    }
    this.cdr.markForCheck();
  }

  get activeCategories(): FinanceCategory[] {
    return this.categories.filter((c) => c.type === this.formType && c.isActive);
  }

  get filteredCategoryOptions(): FinanceCategory[] {
    const query = this.categoryQuery.trim().toLowerCase();
    const options = this.activeCategories;
    if (!query) return options;
    return options.filter((c) => c.label.toLowerCase().includes(query));
  }

  selectCategory(category: FinanceCategory): void {
    this.formCategoryId = category.id;
    this.categoryQuery = category.label;
    this.categoryDropdownOpen = false;
    this.cdr.markForCheck();
  }

  categoryLabelFor(id: number | null): string {
    return this.categories.find((c) => c.id === id)?.label ?? '—';
  }

  addCategory(value: string): void {
    const label = value.trim();
    if (!label) return;
    const listKey = this.formType === 'income' ? 'finance_income_category' : 'finance_expense_category';
    this.adminService.createConfigListItem({ category: listKey, value: label, label }).subscribe({
      next: (item) => {
        const category: FinanceCategory = {
          id: Number(item.id),
          type: this.formType,
          label: item.label,
          isActive: true,
        };
        this.categories = [...this.categories, category];
        this.selectCategory(category);
      },
      error: () => {
        this.formError = this.translate.instant('admin.financeManagement.errors.categoryAddFailed');
        this.cdr.markForCheck();
      },
    });
  }

  get amountPreview(): string {
    if (this.formAmount == null || this.formAmount <= 0) return '';
    return this.taka(this.formAmount);
  }

  onAttachmentSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    this.formAttachment = file;
    this.revokeAttachmentPreview();
    this.attachmentPreviewUrl = file.type.startsWith('image/') ? URL.createObjectURL(file) : null;
    this.cdr.markForCheck();
  }

  clearAttachment(): void {
    this.formAttachment = null;
    this.revokeAttachmentPreview();
  }

  private revokeAttachmentPreview(): void {
    if (this.attachmentPreviewUrl) {
      URL.revokeObjectURL(this.attachmentPreviewUrl);
      this.attachmentPreviewUrl = null;
    }
  }

  // ----- Payment linking -----

  togglePaymentLink(): void {
    this.paymentLinkEnabled = !this.paymentLinkEnabled;
    if (!this.paymentLinkEnabled) {
      this.selectedPayment = null;
    } else {
      this.loadPaymentOptions();
    }
    this.cdr.markForCheck();
  }

  loadPaymentOptions(): void {
    this.paymentLoading = true;
    this.finance
      .unlinkedPayments(this.paymentSourceFilter || undefined, this.paymentSearch.trim() || undefined)
      .subscribe({
        next: (options) => {
          this.paymentOptions = options;
          this.paymentLoading = false;
          this.cdr.markForCheck();
        },
        error: () => {
          this.paymentOptions = [];
          this.paymentLoading = false;
          this.cdr.markForCheck();
        },
      });
  }

  pickPayment(payment: UnlinkedPayment): void {
    this.selectedPayment = payment;
    // Pre-fill from the payment record so nothing is re-typed (or mis-typed).
    this.formAmount = payment.amount;
    this.formDate = payment.paidOn.slice(0, 10);
    this.formDescription = `${payment.detail} — ${payment.memberName ?? ''}`.trim();
    this.cdr.markForCheck();
  }

  paymentSourceLabel(source: PaymentSourceType): string {
    return this.translate.instant(PAYMENT_SOURCE_LABELS[source]);
  }

  // ----- Save -----

  save(status: 'draft' | 'pending'): void {
    this.formError = '';
    this.formFieldErrors = {};
    if (!this.formDate) {
      this.formFieldErrors['txnDate'] = this.translate.instant('admin.financeManagement.errors.dateRequired');
    }
    if (this.formAmount == null || this.formAmount <= 0) {
      this.formFieldErrors['amount'] = this.translate.instant('admin.financeManagement.errors.amountRequired');
    }
    if (!this.formDescription.trim()) {
      this.formFieldErrors['description'] = this.translate.instant('admin.financeManagement.errors.descriptionRequired');
    }
    if (this.formCategoryId == null) {
      this.formFieldErrors['categoryId'] = this.translate.instant('admin.financeManagement.errors.categoryRequired');
    }
    if (Object.keys(this.formFieldErrors).length) {
      this.cdr.markForCheck();
      return;
    }

    this.saving = true;
    const linkType = this.selectedPayment && this.formType === 'income' ? this.selectedPayment.sourceType : null;
    const linkId = this.selectedPayment && this.formType === 'income' ? this.selectedPayment.sourceId : null;

    if (this.editing) {
      // Editing: only send what changed; a link that existed before is kept.
      this.finance
        .updateTransaction(this.editing.id, {
          txnDate: this.formDate,
          type: this.formType,
          categoryId: this.formCategoryId!,
          amount: this.formAmount!,
          description: this.formDescription.trim(),
          referenceNo: this.formReference.trim() || null,
          internalNotes: this.formInternalNotes.trim() || null,
          linkedPaymentType: linkType ?? this.editing.linkedPaymentType ?? null,
          linkedPaymentId: linkId ?? this.editing.linkedPaymentId ?? null,
        })
        .subscribe({
          next: (txn) => this.finishSave(txn),
          error: (err) => this.saveFailed(err),
        });
    } else {
      this.finance
        .createTransaction({
          txnDate: this.formDate,
          type: this.formType,
          categoryId: this.formCategoryId!,
          amount: this.formAmount!,
          description: this.formDescription.trim(),
          referenceNo: this.formReference.trim() || null,
          internalNotes: this.formInternalNotes.trim() || null,
          status,
          linkedPaymentType: linkType,
          linkedPaymentId: linkId,
        })
        .subscribe({
          next: (txn) => this.finishSave(txn),
          error: (err) => this.saveFailed(err),
        });
    }
  }

  private finishSave(txn: FinanceTransaction): void {
    if (this.formAttachment) {
      this.finance.uploadAttachment(txn.id, this.formAttachment).subscribe({
        next: () => this.closeAfterSave(),
        error: (err) => {
          // The transaction itself saved; only the attachment upload failed.
          this.saving = false;
          this.formError =
            (typeof err?.error?.detail === 'string' && err.error.detail) ||
            this.translate.instant('admin.financeManagement.errors.attachmentFailed');
          this.cdr.markForCheck();
        },
      });
    } else {
      this.closeAfterSave();
    }
  }

  private closeAfterSave(): void {
    this.saving = false;
    this.showFormModal = false;
    this.load();
    this.loadOverview();
    this.cdr.markForCheck();
  }

  private saveFailed(err: unknown): void {
    this.saving = false;
    this.formError =
      (typeof (err as { error?: { detail?: string } })?.error?.detail === 'string' &&
        (err as { error: { detail: string } }).error.detail) ||
      this.translate.instant('admin.financeManagement.errors.saveFailed');
    this.cdr.markForCheck();
  }

  // ----- Workflow actions -----

  openAction(modal: 'approve' | 'reject' | 'reverse' | 'delete', txn: FinanceTransaction): void {
    this.modal = modal;
    this.actionTarget = txn;
    this.actionReason = '';
    this.actionError = '';
    this.cdr.markForCheck();
  }

  closeAction(): void {
    this.modal = null;
    this.actionTarget = null;
    this.actionError = '';
    this.cdr.markForCheck();
  }

  get actionNeedsReason(): boolean {
    return this.modal === 'reject' || this.modal === 'reverse' || this.modal === 'delete';
  }

  confirmAction(): void {
    const txn = this.actionTarget;
    if (!txn) return;
    if (this.actionNeedsReason && !this.actionReason.trim()) {
      this.actionError = this.translate.instant('admin.financeManagement.errors.reasonRequired');
      this.cdr.markForCheck();
      return;
    }
    this.actionBusy = true;
    const reason = this.actionReason.trim();

    const request$: Observable<unknown> =
      this.modal === 'approve'
        ? this.finance.approveTransaction(txn.id)
        : this.modal === 'reject'
          ? this.finance.rejectTransaction(txn.id, reason)
          : this.modal === 'reverse'
            ? this.finance.reverseTransaction(txn.id, reason)
            : this.finance.deleteTransaction(txn.id, reason);

    request$.subscribe({
      next: () => {
        this.actionBusy = false;
        this.closeAction();
        this.load();
        this.loadOverview();
      },
      error: (err) => {
        this.actionBusy = false;
        this.actionError =
          (typeof err?.error?.detail === 'string' && err.error.detail) ||
          this.translate.instant('admin.financeManagement.errors.actionFailed');
        this.cdr.markForCheck();
      },
    });
  }

  submitDraft(txn: FinanceTransaction): void {
    this.finance.submitTransaction(txn.id).subscribe({
      next: () => this.load(),
      error: (err) => {
        this.error =
          (typeof err?.error?.detail === 'string' && err.error.detail) ||
          this.translate.instant('admin.financeManagement.errors.actionFailed');
        this.cdr.markForCheck();
      },
    });
  }

  // ----- Report notice -----

  publishNotice(): void {
    if (this.noticeBusy) return;
    this.noticeBusy = true;
    this.noticeDone = false;
    this.finance.publishReportNotice(this.noticePeriod).subscribe({
      next: () => {
        this.noticeBusy = false;
        this.noticeDone = true;
        this.cdr.markForCheck();
      },
      error: () => {
        this.noticeBusy = false;
        this.noticeDone = false;
        this.cdr.markForCheck();
      },
    });
  }

  signedAmount(txn: FinanceTransaction): string {
    const sign = txn.type === 'income' ? '+' : '−';
    return `${sign} ${this.taka(txn.amount)}`;
  }
}
