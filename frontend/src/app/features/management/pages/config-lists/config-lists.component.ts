import { ChangeDetectorRef, Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import type { ConfigListItem } from '../../../../core/models/admin.model';

const MANAGE_SYSTEM_CONFIG = 'manage_system_config';
const CATEGORIES = ['property_type', 'document_type', 'notice_category', 'event_category'];

@Component({
  selector: 'app-config-lists',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe],
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
}
