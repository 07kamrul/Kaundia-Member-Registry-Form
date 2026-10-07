import { ChangeDetectionStrategy, Component, OnInit, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslatePipe } from '@ngx-translate/core';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { DatePickerComponent } from '../../../../shared/date-picker/date-picker.component';
import { AuthService } from '../../../../core/services/auth.service';
import { LanguageService } from '../../../../core/services/language.service';
import {
  ResolutionBookService,
  formatRbDate,
  localizeDigits,
  meetingStatusLabel,
  meetingTypeLabel,
  type MeetingListItem,
  type MeetingStatus,
  type DashboardSummary,
} from '../../../../core/services/resolution-book.service';

type TypeFilter = '' | 'online' | 'offline';

@Component({
  selector: 'app-resolution-book',
  standalone: true,
  imports: [TranslatePipe, IconComponent, RouterLink, FormsModule, DatePickerComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './resolution-book.component.html',
  styleUrl: './resolution-book.component.scss',
})
export class ResolutionBookComponent implements OnInit {
  private readonly service = inject(ResolutionBookService);
  private readonly language = inject(LanguageService);
  readonly auth = inject(AuthService);

  readonly summary = signal<DashboardSummary | null>(null);
  readonly meetings = signal<MeetingListItem[]>([]);
  readonly total = signal(0);
  readonly loading = signal(true);
  readonly error = signal(false);

  // Filter state - narrows the list without a page reload.
  readonly query = signal('');
  readonly typeFilter = signal<TypeFilter>('');
  readonly statusFilter = signal<'' | MeetingStatus>('');
  readonly dateFrom = signal('');
  readonly dateTo = signal('');
  readonly page = signal(0);
  readonly pageSize = 10;

  readonly lang = this.language.lang;
  readonly canManage = computed(() => this.auth.hasPermission('manage_resolution_book'));

  readonly totalPages = computed(() => Math.max(1, Math.ceil(this.total() / this.pageSize)));
  readonly hasFilters = computed(
    () =>
      this.query().trim() !== '' ||
      this.typeFilter() !== '' ||
      this.statusFilter() !== '' ||
      this.dateFrom() !== '' ||
      this.dateTo() !== '',
  );

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set(false);
    this.service.summary().subscribe({
      next: (data) => {
        this.summary.set(data);
        this.loading.set(false);
      },
      error: () => {
        this.error.set(true);
        this.loading.set(false);
      },
    });
    this.loadMeetings();
  }

  loadMeetings(): void {
    this.service
      .listMeetings({
        q: this.query().trim() || undefined,
        meeting_type: this.typeFilter() || undefined,
        meeting_status: this.statusFilter() || undefined,
        date_from: this.dateFrom() || undefined,
        date_to: this.dateTo() || undefined,
        limit: this.pageSize,
        offset: this.page() * this.pageSize,
      })
      .subscribe({
        next: (page) => {
          this.meetings.set(page.items);
          this.total.set(page.total);
        },
        error: () => this.error.set(true),
      });
  }

  applyFilters(): void {
    this.page.set(0);
    this.loadMeetings();
  }

  clearFilters(): void {
    this.query.set('');
    this.typeFilter.set('');
    this.statusFilter.set('');
    this.dateFrom.set('');
    this.dateTo.set('');
    this.applyFilters();
  }

  goToPage(target: number): void {
    const clamped = Math.min(Math.max(target, 0), this.totalPages() - 1);
    this.page.set(clamped);
    this.loadMeetings();
  }

  // ----- view helpers -----

  digits(value: number | string): string {
    return localizeDigits(value, this.lang());
  }

  date(iso: string | null): string {
    return formatRbDate(iso, this.lang());
  }

  typeLabel(type: MeetingListItem['meetingType']): string {
    return meetingTypeLabel(type, this.lang());
  }

  statusLabel(status: MeetingListItem['status']): string {
    return meetingStatusLabel(status, this.lang());
  }
}

