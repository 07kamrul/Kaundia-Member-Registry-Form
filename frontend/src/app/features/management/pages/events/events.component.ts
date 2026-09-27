import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService, type EventInput } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import type { ConfigListItem } from '../../../../core/models/admin.model';
import { toDatetimeLocal, toIso, type EventItem } from '../../../../core/models/content.model';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';

const MANAGE_NOTICES = 'manage_notices';

export type EventStatusFilter = 'all' | 'published' | 'draft';

@Component({
  selector: 'app-events',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, ConfirmModalComponent, DatePipe],
  templateUrl: './events.component.html',
})
export class EventsComponent implements OnInit {
  events: EventItem[] = [];
  categories: ConfigListItem[] = [];
  loading = false;
  error = '';

  statusFilter: EventStatusFilter = 'all';
  categoryFilter = '';
  readonly statusFilters: EventStatusFilter[] = ['all', 'published', 'draft'];

  formOpen = false;
  editingId: string | null = null;
  formTitle = '';
  formDescription = '';
  formLocation = '';
  formCategoryId = '';
  formStartAt = '';
  formEndAt = '';
  formPublished = false;
  formMembersOnly = false;
  saving = false;
  saveError = '';

  deleteTarget: EventItem | null = null;
  deleting = false;
  togglingId: string | null = null;

  constructor(
    private adminService: AdminService,
    public auth: AuthService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.adminService.listConfigListItems('event_category').subscribe({
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
      .listEvents({
        published: this.statusFilter === 'all' ? undefined : this.statusFilter === 'published',
        categoryId: this.categoryFilter || undefined,
      })
      .subscribe({
        next: (rows) => {
          this.events = rows;
          this.loading = false;
          this.cdr.markForCheck();
        },
        error: () => {
          this.error = this.translate.instant('admin.events.errors.loadFailed');
          this.loading = false;
          this.cdr.markForCheck();
        },
      });
  }

  setStatusFilter(filter: EventStatusFilter): void {
    this.statusFilter = filter;
    this.load();
  }

  onCategoryFilter(): void {
    this.load();
  }

  categoryLabel(categoryId: string | null): string {
    if (!categoryId) return '—';
    return this.categories.find((item) => item.id === categoryId)?.label ?? '—';
  }

  openCreate(): void {
    if (!this.auth.hasPermission(MANAGE_NOTICES)) return;
    this.editingId = null;
    this.formTitle = '';
    this.formDescription = '';
    this.formLocation = '';
    this.formCategoryId = '';
    this.formStartAt = '';
    this.formEndAt = '';
    this.formPublished = false;
    this.formMembersOnly = false;
    this.saveError = '';
    this.formOpen = true;
  }

  edit(event: EventItem): void {
    if (!this.auth.hasPermission(MANAGE_NOTICES)) return;
    this.editingId = event.id;
    this.formTitle = event.title;
    this.formDescription = event.description ?? '';
    this.formLocation = event.location ?? '';
    this.formCategoryId = event.categoryId ?? '';
    this.formStartAt = toDatetimeLocal(event.startAt);
    this.formEndAt = toDatetimeLocal(event.endAt);
    this.formPublished = event.isPublished;
    this.formMembersOnly = event.isMembersOnly;
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
    if (!this.formTitle.trim() || !this.formStartAt) return;

    const payload: EventInput = {
      title: this.formTitle.trim(),
      description: this.formDescription.trim() || null,
      location: this.formLocation.trim() || null,
      categoryId: this.formCategoryId || null,
      startAt: toIso(this.formStartAt),
      endAt: this.formEndAt ? toIso(this.formEndAt) : null,
      isPublished: this.formPublished,
      isMembersOnly: this.formMembersOnly,
    };

    this.saving = true;
    this.saveError = '';
    const request =
      this.editingId === null
        ? this.adminService.createEvent(payload)
        : this.adminService.updateEvent(this.editingId, payload);

    request.subscribe({
      next: () => {
        this.saving = false;
        this.formOpen = false;
        this.editingId = null;
        this.load();
      },
      error: (err) => {
        this.saveError =
          err?.error?.detail ?? this.translate.instant('admin.events.errors.saveFailed');
        this.saving = false;
        this.cdr.markForCheck();
      },
    });
  }

  togglePublished(event: EventItem): void {
    if (!this.auth.hasPermission(MANAGE_NOTICES)) return;
    this.togglingId = event.id;
    this.adminService
      .updateEvent(event.id, {
        title: event.title,
        description: event.description,
        location: event.location,
        categoryId: event.categoryId,
        startAt: event.startAt,
        endAt: event.endAt,
        isPublished: !event.isPublished,
        isMembersOnly: event.isMembersOnly,
      })
      .subscribe({
        next: () => {
          this.togglingId = null;
          this.load();
        },
        error: () => {
          this.error = this.translate.instant('admin.events.errors.saveFailed');
          this.togglingId = null;
          this.cdr.markForCheck();
        },
      });
  }

  askDelete(event: EventItem): void {
    if (!this.auth.hasPermission(MANAGE_NOTICES)) return;
    this.deleteTarget = event;
  }

  confirmDelete(): void {
    if (!this.deleteTarget) return;
    this.deleting = true;
    this.adminService.deleteEvent(this.deleteTarget.id).subscribe({
      next: () => {
        this.events = this.events.filter((row) => row.id !== this.deleteTarget!.id);
        if (this.editingId === this.deleteTarget!.id) this.cancelForm();
        this.deleteTarget = null;
        this.deleting = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.events.errors.deleteFailed');
        this.deleteTarget = null;
        this.deleting = false;
        this.cdr.markForCheck();
      },
    });
  }
}
