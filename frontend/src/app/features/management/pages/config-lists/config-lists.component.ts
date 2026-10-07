import { ChangeDetectorRef, Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import { IconComponent } from '../../../../shared/icon/icon.component';
import type { ConfigListItem } from '../../../../core/models/admin.model';

const MANAGE_SYSTEM_CONFIG = 'manage_system_config';
const CATEGORIES = [
  'property_type',
  'document_type',
  'notice_category',
  'event_category',
  'finance_income_category',
  'finance_expense_category',
];

@Component({
  selector: 'app-config-lists',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, IconComponent],
  templateUrl: './config-lists.component.html',
})
export class ConfigListsComponent implements OnInit {
  readonly categories = CATEGORIES;
  selectedCategory = CATEGORIES[0];
  items: ConfigListItem[] = [];
  loading = false;
  error = '';

  draftValue = '';
  draftLabel = '';
  saving = false;
  saveError = '';

  togglingId: string | null = null;

  // Inline label editing state.
  editingId: string | null = null;
  editLabel = '';

  constructor(
    private adminService: AdminService,
    public auth: AuthService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.load();
  }

  selectCategory(category: string): void {
    this.selectedCategory = category;
    this.editingId = null;
    this.load();
  }

  load(): void {
    this.loading = true;
    this.adminService.listConfigListItems(this.selectedCategory).subscribe({
      next: (data) => {
        this.items = data;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.configLists.errors.loadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  addItem(): void {
    if (!this.auth.hasPermission(MANAGE_SYSTEM_CONFIG)) return;
    if (!this.draftValue.trim()) return;

    this.saving = true;
    this.saveError = '';
    this.adminService
      .createConfigListItem({
        category: this.selectedCategory,
        value: this.draftValue.trim(),
        label: this.draftLabel.trim() || this.draftValue.trim(),
        sortOrder: this.items.length,
      })
      .subscribe({
        next: () => {
          this.saving = false;
          this.draftValue = '';
          this.draftLabel = '';
          this.load();
        },
        error: (err) => {
          this.saveError =
            err?.error?.detail ?? this.translate.instant('admin.configLists.errors.saveFailed');
          this.saving = false;
          this.cdr.markForCheck();
        },
      });
  }

  toggleActive(item: ConfigListItem): void {
    if (!this.auth.hasPermission(MANAGE_SYSTEM_CONFIG)) return;
    this.togglingId = item.id;
    this.adminService.updateConfigListItem(item.id, { isActive: !item.isActive }).subscribe({
      next: (updated) => {
        const idx = this.items.findIndex((i) => i.id === updated.id);
        if (idx >= 0) this.items[idx] = updated;
        this.togglingId = null;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.configLists.errors.saveFailed');
        this.togglingId = null;
        this.cdr.markForCheck();
      },
    });
  }

  startEdit(item: ConfigListItem): void {
    if (!this.auth.hasPermission(MANAGE_SYSTEM_CONFIG)) return;
    this.editingId = item.id;
    this.editLabel = item.label;
  }

  cancelEdit(): void {
    this.editingId = null;
    this.editLabel = '';
  }

  saveLabel(item: ConfigListItem): void {
    if (!this.auth.hasPermission(MANAGE_SYSTEM_CONFIG)) return;
    const label = this.editLabel.trim();
    if (!label || label === item.label) {
      this.cancelEdit();
      return;
    }
    this.togglingId = item.id;
    this.adminService.updateConfigListItem(item.id, { label }).subscribe({
      next: (updated) => {
        const idx = this.items.findIndex((i) => i.id === updated.id);
        if (idx >= 0) this.items[idx] = updated;
        this.togglingId = null;
        this.cancelEdit();
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.configLists.errors.saveFailed');
        this.togglingId = null;
        this.cdr.markForCheck();
      },
    });
  }

  /** Swaps sort_order with the neighbor in the given direction. */
  moveItem(index: number, direction: -1 | 1): void {
    if (!this.auth.hasPermission(MANAGE_SYSTEM_CONFIG)) return;
    const target = index + direction;
    if (target < 0 || target >= this.items.length) return;

    const current = this.items[index];
    const neighbor = this.items[target];
    this.togglingId = current.id;
    // Preserve immutability: build a new array instead of mutating this.items.
    const reordered = [...this.items];
    reordered[index] = neighbor;
    reordered[target] = current;

    this.adminService
      .updateConfigListItem(current.id, { sortOrder: neighbor.sortOrder })
      .subscribe({
        next: () => {
          this.adminService
            .updateConfigListItem(neighbor.id, { sortOrder: current.sortOrder })
            .subscribe({
              next: () => {
                this.items = reordered;
                this.togglingId = null;
                this.cdr.markForCheck();
              },
              error: () => {
                this.error = this.translate.instant('admin.configLists.errors.saveFailed');
                this.togglingId = null;
                // Reload to resync server-side sort order.
                this.load();
              },
            });
        },
        error: () => {
          this.error = this.translate.instant('admin.configLists.errors.saveFailed');
          this.togglingId = null;
          this.cdr.markForCheck();
        },
      });
  }
}
