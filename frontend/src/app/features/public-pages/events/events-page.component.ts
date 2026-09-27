import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { ConfigListService } from '../../../core/services/config-list.service';
import { ContentService } from '../../../core/services/content.service';
import type { ConfigListItem } from '../../../core/models/admin.model';
import type { EventItem } from '../../../core/models/content.model';

@Component({
  selector: 'app-events-page',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, TranslatePipe, DatePipe],
  templateUrl: './events-page.component.html',
})
export class EventsPageComponent implements OnInit {
  upcoming: EventItem[] = [];
  past: EventItem[] = [];
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
    this.content.listEvents().subscribe({
      next: (rows) => {
        // The endpoint returns upcoming rows first, so a single pass over the
        // response keeps both sections in the server's order.
        const now = Date.now();
        this.upcoming = rows.filter((row) => new Date(row.startAt).getTime() >= now);
        this.past = rows.filter((row) => new Date(row.startAt).getTime() < now);
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('events.errors.loadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });

    this.configLists.getItems('event_category').subscribe({
      next: (items) => {
        this.categories = items;
        this.cdr.markForCheck();
      },
      error: () => {
        // The category chip is optional.
      },
    });
  }

  categoryLabel(categoryId: string | null): string {
    if (!categoryId) return '';
    return this.categories.find((item) => item.id === categoryId)?.label ?? '';
  }
}
