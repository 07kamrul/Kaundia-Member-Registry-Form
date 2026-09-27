import { DatePipe, SlicePipe } from '@angular/common';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { ConfigListService } from '../../../core/services/config-list.service';
import { ContentService } from '../../../core/services/content.service';
import type { ConfigListItem } from '../../../core/models/admin.model';
import type { Notice } from '../../../core/models/content.model';

@Component({
  selector: 'app-notices-page',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, TranslatePipe, DatePipe, SlicePipe],
  templateUrl: './notices-page.component.html',
})
export class NoticesPageComponent implements OnInit {
  notices: Notice[] = [];
  categories: ConfigListItem[] = [];
  loading = true;
  error = '';

  constructor(
    private content: ContentService,
    private configLists: ConfigListService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.content.listNotices().subscribe({
      next: (rows) => {
        this.notices = rows;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('notices.errors.loadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });

    this.configLists.getItems('notice_category').subscribe({
      next: (items) => {
        this.categories = items;
        this.cdr.markForCheck();
      },
      error: () => {
        // The category chip is optional; the list renders without labels.
      },
    });
  }

  categoryLabel(categoryId: string | null): string {
    if (!categoryId) return '';
    return this.categories.find((item) => item.id === categoryId)?.label ?? '';
  }
}
