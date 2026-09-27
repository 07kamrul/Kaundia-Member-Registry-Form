import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService, type NoticeInput } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import type { ConfigListItem } from '../../../../core/models/admin.model';
import { toDatetimeLocal, toIso, type Notice } from '../../../../core/models/content.model';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';

const MANAGE_NOTICES = 'manage_notices';

export type NoticeStatus = 'draft' | 'scheduled' | 'published';
export type StatusFilter = 'all' | 'draft' | 'published';

@Component({
  selector: 'app-notices',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, ConfirmModalComponent, DatePipe],
  templateUrl: './notices.component.html',
})
export class NoticesComponent implements OnInit {
  notices: Notice[] = [];
  categories: ConfigListItem[] = [];
  loading = false;
  error = '';

  statusFilter: StatusFilter = 'all';
  categoryFilter = '';
  readonly statusFilters: StatusFilter[] = ['all', 'published', 'draft'];

  formOpen = false;
  editingId: string | null = null;
  formTitle = '';
  formBody = '';
  formCategoryId = '';
  formPublishAt = '';
  formPublished = false;
  formMembersOnly = false;
  saving = false;
  saveError = '';

  deleteTarget: Notice | null = null;
  deleting = false;
  togglingId: string | null = null;

  constructor(
    private adminService: AdminService,
    public auth: AuthService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.adminService.listConfigListItems('notice_category').subscribe({
      next: (items) => {
        this.categories = items.filter((item) => item.isActive);
        this.cdr.markForCheck();
      },
      error: () => {
        // Categories are only decoration on this screen; the list still loads.
      },
    });
    this.load();
  }

  load(): void {
    this.loading = true;
    this.adminService
      .listNotices({
        published: this.statusFilter === 'all' ? undefined : this.statusFilter === 'published',
        categoryId: this.categoryFilter || undefined,
      })
      .subscribe({
        next: (rows) => {
          this.notices = rows;
          this.loading = false;
          this.cdr.markForCheck();
        },
        error: () => {
          this.error = this.translate.instant('admin.notices.errors.loadFailed');
          this.loading = false;
          this.cdr.markForCheck();
        },
      });
  }

  setStatusFilter(filter: StatusFilter): void {
    this.statusFilter = filter;
    this.load();
  }

  onCategoryFilter(): void {
    this.load();
  }

  statusOf(notice: Notice): NoticeStatus {
    if (!notice.isPublished) return 'draft';
    if (notice.publishAt && new Date(notice.publishAt).getTime() > Date.now()) return 'scheduled';
    return 'published';
  }

  categoryLabel(categoryId: string | null): string {
    if (!categoryId) return '—';
    return this.categories.find((item) => item.id === categoryId)?.label ?? '—';
  }

  openCreate(): void {
    if (!this.auth.hasPermission(MANAGE_NOTICES)) return;
    this.editingId = null;
    this.formTitle = '';
    this.formBody = '';
    this.formCategoryId = '';
    this.formPublishAt = '';
    this.formPublished = false;
    this.formMembersOnly = false;
    this.saveError = '';
    this.formOpen = true;
  }

  edit(notice: Notice): void {
    if (!this.auth.hasPermission(MANAGE_NOTICES)) return;
    this.editingId = notice.id;
    this.formTitle = notice.title;
    this.formBody = notice.body;
    this.formCategoryId = notice.categoryId ?? '';
    this.formPublishAt = toDatetimeLocal(notice.publishAt);
    this.formPublished = notice.isPublished;
    this.formMembersOnly = notice.isMembersOnly;
    this.saveError = '';
    this.formOpen = true;
  }

  cancelForm(): void {
    this.formOpen = false;
    this.editingId = null;
    this.saveError = '';
  }

  save(): void {
    if (!this.auth.hasPermission(MANAGE_NOTICES)) return;
    if (!this.formTitle.trim() || !this.formBody.trim()) return;

    const payload: NoticeInput = {
      title: this.formTitle.trim(),
      body: this.formBody.trim(),
      categoryId: this.formCategoryId || null,
      isPublished: this.formPublished,
      isMembersOnly: this.formMembersOnly,
      publishAt: this.formPublishAt ? toIso(this.formPublishAt) : null,
    };

    this.saving = true;
    this.saveError = '';
    const request =
      this.editingId === null
        ? this.adminService.createNotice(payload)
        : this.adminService.updateNotice(this.editingId, payload);

    request.subscribe({
      next: () => {
        this.saving = false;
        this.formOpen = false;
        this.editingId = null;
        this.load();
      },
      error: (err) => {
        this.saveError =
          err?.error?.detail ?? this.translate.instant('admin.notices.errors.saveFailed');
        this.saving = false;
        this.cdr.markForCheck();
      },
    });
  }

  togglePublished(notice: Notice): void {
    if (!this.auth.hasPermission(MANAGE_NOTICES)) return;
    this.togglingId = notice.id;
    this.adminService
      .updateNotice(notice.id, {
        title: notice.title,
        body: notice.body,
        categoryId: notice.categoryId,
        isPublished: !notice.isPublished,
        isMembersOnly: notice.isMembersOnly,
        publishAt: notice.publishAt,
      })
      .subscribe({
        next: () => {
          this.togglingId = null;
          this.load();
        },
        error: () => {
          this.error = this.translate.instant('admin.notices.errors.saveFailed');
          this.togglingId = null;
          this.cdr.markForCheck();
        },
      });
  }

  askDelete(notice: Notice): void {
    if (!this.auth.hasPermission(MANAGE_NOTICES)) return;
    this.deleteTarget = notice;
  }

  confirmDelete(): void {
    if (!this.deleteTarget) return;
    this.deleting = true;
    this.adminService.deleteNotice(this.deleteTarget.id).subscribe({
      next: () => {
        this.notices = this.notices.filter((row) => row.id !== this.deleteTarget!.id);
        if (this.editingId === this.deleteTarget!.id) this.cancelForm();
        this.deleteTarget = null;
        this.deleting = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.notices.errors.deleteFailed');
        this.deleteTarget = null;
        this.deleting = false;
        this.cdr.markForCheck();
      },
    });
  }
}
