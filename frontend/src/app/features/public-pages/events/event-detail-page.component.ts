import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { TranslatePipe } from '@ngx-translate/core';
import { ConfigListService } from '../../../core/services/config-list.service';
import { ContentService } from '../../../core/services/content.service';
import type { ConfigListItem } from '../../../core/models/admin.model';
import type { EventItem } from '../../../core/models/content.model';

@Component({
  selector: 'app-event-detail-page',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, TranslatePipe, DatePipe],
  templateUrl: './event-detail-page.component.html',
})
export class EventDetailPageComponent implements OnInit {
  event: EventItem | null = null;
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
    // Same list endpoint as the events page - there is no single-row public
    // read, so the detail view picks its row out of the feed.
    this.content.listEvents().subscribe({
      next: (rows) => {
        this.event = rows.find((row) => row.id === id) ?? null;
        this.notFound = this.event === null;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.notFound = true;
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

  get categoryLabel(): string {
    const categoryId = this.event?.categoryId;
    if (!categoryId) return '';
    return this.categories.find((item) => item.id === categoryId)?.label ?? '';
  }

  get isPast(): boolean {
    return this.event !== null && new Date(this.event.startAt).getTime() < Date.now();
  }
}
