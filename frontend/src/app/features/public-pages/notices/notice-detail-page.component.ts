import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { TranslatePipe } from '@ngx-translate/core';
import { ConfigListService } from '../../../core/services/config-list.service';
import { ContentService } from '../../../core/services/content.service';
import type { ConfigListItem } from '../../../core/models/admin.model';
import type { Notice } from '../../../core/models/content.model';

@Component({
  selector: 'app-notice-detail-page',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, TranslatePipe, DatePipe],
  templateUrl: './notice-detail-page.component.html',
})
export class NoticeDetailPageComponent implements OnInit {
  notice: Notice | null = null;
  categories: ConfigListItem[] = [];
  loading = true;
  notFound = false;

  constructor(
    private content: ContentService,
    private configLists: ConfigListService,
    private route: ActivatedRoute,
    private cdr: ChangeDetectorRef,
  ) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    // No single-row public endpoint: the detail view reads the same list the
    // list page does and picks the row out of it.
    this.content.listNotices().subscribe({
      next: (rows) => {
        this.notice = rows.find((row) => row.id === id) ?? null;
        this.notFound = this.notice === null;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.notFound = true;
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
        // The category chip is optional.
      },
    });
  }

  get categoryLabel(): string {
    const categoryId = this.notice?.categoryId;
    if (!categoryId) return '';
    return this.categories.find((item) => item.id === categoryId)?.label ?? '';
  }
}
