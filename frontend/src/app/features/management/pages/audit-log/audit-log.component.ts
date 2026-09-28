import { ChangeDetectorRef, Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import { RbacService } from '../../../../core/services/rbac.service';
import { IconComponent } from '../../../../shared/icon/icon.component';
import type { AuditLogEntry } from '../../../../core/models/admin.model';

const PAGE_SIZES: readonly number[] = [10, 25, 50];
const DATE_TIME_FORMAT = 'dd MMM YYYY, hh:mm a';

interface DetailPair {
  key: string;
  value: string;
}

@Component({
  selector: 'app-audit-log',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [DatePipe, FormsModule, TranslatePipe, IconComponent],
  templateUrl: './audit-log.component.html',
})
export class AuditLogComponent implements OnInit {
  readonly pageSizes = PAGE_SIZES;
  readonly dateTimeFormat = DATE_TIME_FORMAT;

  entries: AuditLogEntry[] = [];
  loading = false;
  error = '';

  /** admin id -> "Name (role)" for actor resolution. */
  actorNames = new Map<string, string>();

  // Filters (all client-side; endpoint has no query params).
  filterDateFrom = '';
  filterDateTo = '';
  filterAction = '';
  filterActor = '';
  filterEntityType = '';

  page = 1;
  pageSize = 25;

  detailEntry: AuditLogEntry | null = null;
  detailPairs: DetailPair[] = [];

  constructor(
    private adminService: AdminService,
    private rbacService: RbacService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.loadActors();
    this.load();
  }

  private loadActors(): void {
    // Best-effort enrichment; a failure just leaves raw IDs visible.
    this.rbacService.listUsers().subscribe({
      next: (users) => {
        this.actorNames = new Map(
          users.map((u) => [String(u.id), u.role ? `${u.name} (${u.role})` : u.name]),
        );
        this.cdr.markForCheck();
      },
      error: () => undefined,
    });
  }

  private load(): void {
    this.loading = true;
    this.adminService.listAuditLog().subscribe({
      next: (rows) => {
        this.entries = rows;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.auditLog.errors.loadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  get distinctActions(): string[] {
    return [...new Set(this.entries.map((e) => e.action))].sort();
  }

  get distinctActors(): string[] {
    return [
      ...new Set(this.entries.map((e) => e.actorAdminId).filter((a): a is string => a !== null)),
    ].sort((a, b) => Number(a) - Number(b));
  }

  get distinctEntityTypes(): string[] {
    return [...new Set(this.entries.map((e) => e.entityType))].sort();
  }

  actorLabel(id: string | null): string {
    if (id === null) return '—';
    return this.actorNames.get(id) ?? `#${id}`;
  }

  get filtered(): AuditLogEntry[] {
    return this.entries.filter((e) => {
      if (this.filterAction && e.action !== this.filterAction) return false;
      if (this.filterActor && e.actorAdminId !== this.filterActor) return false;
      if (this.filterEntityType && e.entityType !== this.filterEntityType) return false;
      const created = new Date(e.createdAt).getTime();
      if (this.filterDateFrom && created < new Date(this.filterDateFrom).getTime()) return false;
      // End date is inclusive: allow the whole day.
      if (this.filterDateTo) {
        const to = new Date(this.filterDateTo);
        to.setHours(23, 59, 59, 999);
        if (created > to.getTime()) return false;
      }
      return true;
    });
  }

  get hasActiveFilters(): boolean {
    return !!(
      this.filterDateFrom ||
      this.filterDateTo ||
      this.filterAction ||
      this.filterActor ||
      this.filterEntityType
    );
  }

  get total(): number {
    return this.filtered.length;
  }

  get totalPages(): number {
    return Math.max(1, Math.ceil(this.total / this.pageSize));
  }

  get pageEntries(): AuditLogEntry[] {
    const start = (this.page - 1) * this.pageSize;
    return this.filtered.slice(start, start + this.pageSize);
  }

  get rangeFrom(): number {
    return this.total === 0 ? 0 : (this.page - 1) * this.pageSize + 1;
  }

  get rangeTo(): number {
    return Math.min(this.page * this.pageSize, this.total);
  }

  onFiltersChanged(): void {
    this.page = 1;
  }

  prevPage(): void {
    if (this.page > 1) this.page--;
  }

  nextPage(): void {
    if (this.page < this.totalPages) this.page++;
  }

  /** Badge modifier for the action verb (approve/reject/create/update/delete). */
  actionClass(action: string): string {
    const verb = action.split(/[._]/)[0];
    return ['approve', 'reject', 'create', 'update', 'delete'].includes(verb) ? verb : '';
  }

  truncate(text: string, max = 40): string {
    return text.length > max ? `${text.slice(0, max)}…` : text;
  }

  openDetail(entry: AuditLogEntry): void {
    this.detailEntry = entry;
    this.detailPairs = this.parseDetail(entry.detail);
  }

  closeDetail(): void {
    this.detailEntry = null;
    this.detailPairs = [];
  }

  /** Parses the detail column as JSON into key-value pairs, raw fallback. */
  private parseDetail(detail: string | null): DetailPair[] {
    if (!detail) return [];
    try {
      const parsed: unknown = JSON.parse(detail);
      if (parsed !== null && typeof parsed === 'object' && !Array.isArray(parsed)) {
        return Object.entries(parsed as Record<string, unknown>).map(([key, value]) => ({
          key,
          value: typeof value === 'object' ? JSON.stringify(value) : String(value),
        }));
      }
      return [{ key: 'detail', value: JSON.stringify(parsed) }];
    } catch {
      return [{ key: 'detail', value: detail }];
    }
  }
}
