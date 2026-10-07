import { ChangeDetectionStrategy, Component, OnInit, inject, signal } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import type { Observable } from 'rxjs';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { DatePickerComponent } from '../../../../shared/date-picker/date-picker.component';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';
import { LanguageService } from '../../../../core/services/language.service';
import {
  ROADMAP_STATUSES,
  RoadmapService,
  formatRoadmapDate,
  localizeDigits,
  timeframeName,
  timeframeWindow,
  type Roadmap,
  type RoadmapArchivedCycle,
  type RoadmapItem,
  type RoadmapStatus,
  type RoadmapTimeframe,
} from '../../../../core/services/roadmap.service';

const TEXT_MAX = 500;
const OWNER_MAX = 120;
const NOTE_MAX = 1000;

interface ItemForm {
  timeframeId: number | null;
  text: string;
  status: RoadmapStatus;
  targetDate: string;
  owner: string;
  note: string;
  notify: boolean;
}

function emptyForm(timeframeId: number | null): ItemForm {
  return { timeframeId, text: '', status: 'planned', targetDate: '', owner: '', note: '', notify: true };
}

/** Returns the i18n key of the first validation problem, or '' when valid. */
export function validateRoadmapForm(form: ItemForm): string {
  if (form.timeframeId === null) return 'admin.roadmap.errors.timeframe';
  const text = form.text.trim();
  if (!text) return 'admin.roadmap.errors.textRequired';
  if (text.length > TEXT_MAX) return 'admin.roadmap.errors.textTooLong';
  if (form.owner.trim().length > OWNER_MAX) return 'admin.roadmap.errors.ownerTooLong';
  if (form.note.trim().length > NOTE_MAX) return 'admin.roadmap.errors.noteTooLong';
  return '';
}

@Component({
  selector: 'app-roadmap-management',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, RouterLink, TranslatePipe, IconComponent, DatePickerComponent, ConfirmModalComponent],
  templateUrl: './roadmap-management.component.html',
  styleUrl: './roadmap-management.component.scss',
})
export class RoadmapManagementComponent implements OnInit {
  private readonly roadmapService = inject(RoadmapService);
  private readonly translate = inject(TranslateService);
  private readonly language = inject(LanguageService);

  readonly statuses = ROADMAP_STATUSES;
  readonly textMax = TEXT_MAX;
  readonly ownerMax = OWNER_MAX;
  readonly noteMax = NOTE_MAX;
  readonly lang = this.language.lang;

  readonly roadmap = signal<Roadmap | null>(null);
  readonly loading = signal(true);
  readonly loadError = signal(false);
  readonly busyItemId = signal<number | null>(null);
  readonly actionError = signal('');
  readonly notifyOnDone = signal(true);

  // Add / edit modal
  readonly formOpen = signal(false);
  readonly editing = signal<RoadmapItem | null>(null);
  readonly formError = signal('');
  readonly formBusy = signal(false);
  form: ItemForm = emptyForm(null);

  // Delete confirm
  readonly deleteTarget = signal<RoadmapItem | null>(null);
  readonly deleteBusy = signal(false);

  // Archive
  readonly archiveOpen = signal(false);
  readonly archiveBusy = signal(false);
  readonly archiveError = signal('');
  archiveOnlyDone = true;
  readonly archiveDone = signal<number | null>(null);
  readonly history = signal<RoadmapArchivedCycle[] | null>(null);
  readonly historyOpen = signal(false);

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set(false);
    this.roadmapService.getRoadmap().subscribe({
      next: (data) => {
        this.roadmap.set(data);
        this.loading.set(false);
      },
      error: () => {
        this.loadError.set(true);
        this.loading.set(false);
      },
    });
  }

  // ----- view helpers -----

  digits(value: number | string): string {
    return localizeDigits(value, this.lang());
  }

  date(iso: string | null): string {
    return formatRoadmapDate(iso, this.lang());
  }

  name(tf: RoadmapTimeframe): string {
    return timeframeName(tf, this.lang());
  }

  windowLabel(tf: RoadmapTimeframe): string {
    return timeframeWindow(tf, this.lang());
  }

  private errorMessage(err: unknown): string {
    if (err instanceof HttpErrorResponse && typeof err.error?.detail === 'string') return err.error.detail;
    return this.translate.instant('admin.roadmap.errors.generic');
  }

  /** Every mutation returns the full roadmap, so percentages refresh from the server. */
  private mutate(itemId: number, request: Observable<Roadmap>): void {
    this.busyItemId.set(itemId);
    this.actionError.set('');
    request.subscribe({
      next: (data) => {
        this.roadmap.set(data);
        this.busyItemId.set(null);
      },
      error: (err: unknown) => {
        this.busyItemId.set(null);
        this.actionError.set(this.errorMessage(err));
      },
    });
  }

  // ----- inline actions -----

  setStatus(item: RoadmapItem, status: RoadmapStatus): void {
    if (item.status === status || this.busyItemId() !== null) return;
    this.mutate(item.id, this.roadmapService.setStatus(item.id, status, this.notifyOnDone()));
  }

  move(tf: RoadmapTimeframe, index: number, delta: -1 | 1): void {
    const target = index + delta;
    if (target < 0 || target >= tf.items.length || this.busyItemId() !== null) return;
    const ids = tf.items.map((i) => i.id);
    [ids[index], ids[target]] = [ids[target], ids[index]];
    this.mutate(tf.items[index].id, this.roadmapService.reorder(tf.id, ids));
  }

  // ----- add / edit -----

  openCreate(tf?: RoadmapTimeframe): void {
    this.editing.set(null);
    this.form = emptyForm(tf?.id ?? this.roadmap()?.timeframes[0]?.id ?? null);
    this.formError.set('');
    this.formOpen.set(true);
  }

  openEdit(item: RoadmapItem): void {
    this.editing.set(item);
    this.form = {
      timeframeId: item.timeframeId,
      text: item.text,
      status: item.status,
      targetDate: item.targetDate ?? '',
      owner: item.owner ?? '',
      note: item.note ?? '',
      notify: false,
    };
    this.formError.set('');
    this.formOpen.set(true);
  }

  closeForm(): void {
    if (this.formBusy()) return;
    this.formOpen.set(false);
  }

  saveForm(): void {
    const invalidKey = validateRoadmapForm(this.form);
    if (invalidKey) {
      this.formError.set(this.translate.instant(invalidKey));
      return;
    }
    const editing = this.editing();
    const payload = {
      timeframeId: this.form.timeframeId as number,
      text: this.form.text.trim(),
      targetDate: this.form.targetDate || null,
      owner: this.form.owner.trim() || null,
      note: this.form.note.trim() || null,
    };
    const request = editing
      ? this.roadmapService.updateItem(editing.id, payload)
      : this.roadmapService.createItem({ ...payload, status: this.form.status, notify: this.form.notify });

    this.formBusy.set(true);
    this.formError.set('');
    request.subscribe({
      next: (data) => {
        this.roadmap.set(data);
        this.formBusy.set(false);
        this.formOpen.set(false);
      },
      error: (err: unknown) => {
        this.formBusy.set(false);
        this.formError.set(this.errorMessage(err));
      },
    });
  }

  // ----- delete -----

  confirmDelete(): void {
    const target = this.deleteTarget();
    if (!target) return;
    this.deleteBusy.set(true);
    this.roadmapService.deleteItem(target.id).subscribe({
      next: (data) => {
        this.roadmap.set(data);
        this.deleteBusy.set(false);
        this.deleteTarget.set(null);
      },
      error: (err: unknown) => {
        this.deleteBusy.set(false);
        this.deleteTarget.set(null);
        this.actionError.set(this.errorMessage(err));
      },
    });
  }

  // ----- archive -----

  openArchive(): void {
    this.archiveOnlyDone = true;
    this.archiveError.set('');
    this.archiveOpen.set(true);
  }

  confirmArchive(): void {
    this.archiveBusy.set(true);
    this.archiveError.set('');
    this.roadmapService.archive(this.archiveOnlyDone).subscribe({
      next: ({ archived }) => {
        this.archiveBusy.set(false);
        this.archiveOpen.set(false);
        this.archiveDone.set(archived);
        this.history.set(null);
        this.historyOpen.set(false);
        this.load();
      },
      error: (err: unknown) => {
        this.archiveBusy.set(false);
        this.archiveError.set(this.errorMessage(err));
      },
    });
  }

  toggleHistory(): void {
    const open = !this.historyOpen();
    this.historyOpen.set(open);
    if (!open || this.history() !== null) return;
    this.roadmapService.getArchive().subscribe({
      next: (cycles) => this.history.set(cycles),
      error: (err: unknown) => {
        this.history.set([]);
        this.actionError.set(this.errorMessage(err));
      },
    });
  }
}
