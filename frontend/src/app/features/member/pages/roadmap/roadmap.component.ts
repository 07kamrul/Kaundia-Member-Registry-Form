import { ChangeDetectionStrategy, Component, OnInit, computed, inject, signal } from '@angular/core';
import { TranslatePipe } from '@ngx-translate/core';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { LanguageService } from '../../../../core/services/language.service';
import {
  RoadmapService,
  currentTimeframeIndex,
  formatRoadmapDate,
  localizeDigits,
  timeframeName,
  timeframeWindow,
  type Roadmap,
  type RoadmapItem,
  type RoadmapStatus,
  type RoadmapTimeframe,
} from '../../../../core/services/roadmap.service';
import { RoadmapSlidesComponent } from './roadmap-slides.component';
import { renderRoadmapShareImage } from './roadmap-share-image';

type StatusFilter = 'all' | RoadmapStatus;
const STATUS_FILTERS: StatusFilter[] = ['all', 'in_progress', 'done', 'planned'];
const OBJECT_URL_REVOKE_MS = 1000;

function saveBlob(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  setTimeout(() => URL.revokeObjectURL(url), OBJECT_URL_REVOKE_MS);
}

@Component({
  selector: 'app-roadmap',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, IconComponent, RoadmapSlidesComponent],
  templateUrl: './roadmap.component.html',
  styleUrl: './roadmap.component.scss',
})
export class RoadmapComponent implements OnInit {
  private readonly roadmapService = inject(RoadmapService);
  private readonly language = inject(LanguageService);

  readonly statusFilters = STATUS_FILTERS;
  readonly roadmap = signal<Roadmap | null>(null);
  readonly loading = signal(true);
  readonly error = signal(false);
  readonly filter = signal<StatusFilter>('all');
  readonly collapsed = signal<ReadonlySet<number>>(new Set());
  readonly slidesOpen = signal(false);
  readonly pdfBusy = signal(false);
  readonly imageBusy = signal(false);
  readonly exportError = signal('');

  readonly lang = this.language.lang;
  readonly currentIndex = computed(() => {
    const data = this.roadmap();
    return data ? currentTimeframeIndex(data) : 0;
  });
  readonly currentTimeframe = computed(() => this.roadmap()?.timeframes[this.currentIndex()] ?? null);
  readonly inProgressItems = computed(() =>
    (this.roadmap()?.timeframes ?? []).flatMap((tf) => tf.items.filter((i) => i.status === 'in_progress')),
  );

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set(false);
    this.roadmapService.getRoadmap().subscribe({
      next: (data) => {
        this.roadmap.set(data);
        this.loading.set(false);
      },
      error: () => {
        this.error.set(true);
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

  visibleItems(tf: RoadmapTimeframe): RoadmapItem[] {
    const active = this.filter();
    return active === 'all' ? tf.items : tf.items.filter((i) => i.status === active);
  }

  filterCount(status: StatusFilter): number {
    const totals = this.roadmap()?.totals;
    if (!totals) return 0;
    if (status === 'all') return totals.total;
    if (status === 'done') return totals.done;
    if (status === 'in_progress') return totals.inProgress;
    return totals.planned;
  }

  isCollapsed(tf: RoadmapTimeframe): boolean {
    return this.collapsed().has(tf.id);
  }

  toggleSection(tf: RoadmapTimeframe): void {
    const next = new Set(this.collapsed());
    if (next.has(tf.id)) next.delete(tf.id);
    else next.add(tf.id);
    this.collapsed.set(next);
  }

  jumpTo(tf: RoadmapTimeframe): void {
    if (this.isCollapsed(tf)) this.toggleSection(tf);
    // Let the section expand before scrolling to it.
    requestAnimationFrame(() =>
      document
        .getElementById(`roadmap-tf-${tf.key}`)
        ?.scrollIntoView({ behavior: 'smooth', block: 'start' }),
    );
  }

  // ----- exports (all from the same live payload) -----

  downloadPdf(): void {
    if (this.pdfBusy()) return;
    this.pdfBusy.set(true);
    this.exportError.set('');
    this.roadmapService.downloadPdf().subscribe({
      next: (blob) => {
        this.pdfBusy.set(false);
        saveBlob(blob, `roadmap-${new Date().toISOString().slice(0, 10)}.pdf`);
      },
      error: () => {
        this.pdfBusy.set(false);
        this.exportError.set('member.roadmap.exportError');
      },
    });
  }

  async downloadImage(): Promise<void> {
    const data = this.roadmap();
    if (!data || this.imageBusy()) return;
    this.imageBusy.set(true);
    this.exportError.set('');
    try {
      const blob = await renderRoadmapShareImage(data, this.lang());
      saveBlob(blob, `roadmap-${new Date().toISOString().slice(0, 10)}.png`);
    } catch {
      this.exportError.set('member.roadmap.exportError');
    } finally {
      this.imageBusy.set(false);
    }
  }
}
