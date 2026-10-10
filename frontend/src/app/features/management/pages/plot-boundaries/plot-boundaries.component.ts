import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  OnInit,
  computed,
  inject,
  signal,
} from '@angular/core';
import { DatePipe } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import * as L from 'leaflet';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { PlotMapService } from '../../../../core/services/plot-map.service';
import { LanguageService } from '../../../../core/services/language.service';
import { localizeDigits } from '../../../../core/services/roadmap.service';
import { toAsciiDigits } from '../../../../core/services/digits.helper';
import type {
  AdminBoundary,
  BoundaryDispute,
  BoundaryVersion,
  DisputeStatus,
} from '../../../../core/models/plot-boundary.model';

/** Maps a failed review action to an i18n key (403 vs generic). */
export function reviewErrorKey(error: unknown): string {
  if (!(error instanceof HttpErrorResponse)) return 'admin.plotBoundaries.errors.generic';
  if (error.status === 403) return 'admin.plotBoundaries.errors.forbidden';
  return 'admin.plotBoundaries.errors.generic';
}

const STATUS_TABS = [
  'pending_review',
  'approved',
  'rejected',
  'disputed',
] as const;

const DISPUTE_TABS: DisputeStatus[] = ['open', 'resolved', 'dismissed'];

@Component({
  selector: 'app-plot-boundaries',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, IconComponent, DatePipe],
  templateUrl: './plot-boundaries.component.html',
  styleUrl: './plot-boundaries.component.scss',
})
export class PlotBoundariesComponent implements OnInit {
  private readonly plotMapService = inject(PlotMapService);
  private readonly translate = inject(TranslateService);
  private readonly destroyRef = inject(DestroyRef);
  readonly lang = inject(LanguageService).lang;

  readonly tab = signal<'queue' | 'disputes'>('queue');
  readonly statusFilter = signal<string>('pending_review');
  readonly search = signal('');
  readonly loading = signal(false);
  readonly loadErrorKey = signal<string | null>(null);
  readonly boundaries = signal<AdminBoundary[]>([]);
  readonly disputes = signal<BoundaryDispute[]>([]);
  readonly disputeFilter = signal<DisputeStatus>('open');

  readonly statusTabs = STATUS_TABS;
  readonly disputeTabs = DISPUTE_TABS;

  // Detail preview (mini map + declared info + actions).
  readonly selected = signal<AdminBoundary | null>(null);
  private previewMap: L.Map | null = null;

  readonly approveOpen = signal(false);
  readonly approveNote = signal('');
  readonly rejecting = signal(false);
  readonly approving = signal(false);
  readonly actionErrorKey = signal<string | null>(null);

  readonly versionsOpen = signal(false);
  readonly versions = signal<BoundaryVersion[]>([]);
  readonly versionsLoading = signal(false);
  readonly evidenceExporting = signal(false);

  readonly disputeResolveTarget = signal<BoundaryDispute | null>(null);
  readonly disputeNote = signal('');
  readonly disputeDismiss = signal(false);
  readonly disputeSaving = signal(false);
  readonly disputeErrorKey = signal<string | null>(null);

  /** Reject needs a note - the confirm button stays locked while empty. */
  readonly rejectNote = signal('');
  readonly rejectOpen = signal(false);
  readonly rejectConfirmDisabled = computed(() => !this.rejectNote().trim());

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    if (this.tab() === 'disputes') {
      this.loadDisputes();
      return;
    }
    this.loading.set(true);
    this.loadErrorKey.set(null);
    this.plotMapService
      .adminList(this.statusFilter() || undefined, this.search().trim() || undefined)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (rows) => {
          this.boundaries.set(rows);
          this.loading.set(false);
        },
        error: () => {
          this.loadErrorKey.set('admin.plotBoundaries.errors.loadFailed');
          this.loading.set(false);
        },
      });
  }

  private loadDisputes(): void {
    this.loading.set(true);
    this.loadErrorKey.set(null);
    this.plotMapService
      .listDisputes(this.disputeFilter())
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (rows) => {
          this.disputes.set(rows);
          this.loading.set(false);
        },
        error: () => {
          this.loadErrorKey.set('admin.plotBoundaries.errors.loadFailed');
          this.loading.set(false);
        },
      });
  }

  selectTab(tab: 'queue' | 'disputes'): void {
    if (this.tab() === tab) return;
    this.tab.set(tab);
    this.selected.set(null);
    this.load();
  }

  onSearch(value: string): void {
    this.search.set(value);
    this.load();
  }

  select(boundary: AdminBoundary): void {
    this.selected.set(boundary);
    this.actionErrorKey.set(null);
    // Mini preview map - rendered after the panel paints.
    setTimeout(() => this.renderPreview(boundary));
  }

  private renderPreview(boundary: AdminBoundary): void {
    const el = document.querySelector('.preview-map') as HTMLElement | null;
    if (!el) return;
    if (this.previewMap) {
      this.previewMap.remove();
      this.previewMap = null;
    }
    const map = L.map(el, { attributionControl: false, dragging: false, touchZoom: false });
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19 }).addTo(map);
    const layer = L.geoJSON(boundary.geometry as never, {
      style: { color: '#c9861e', weight: 2, fillOpacity: 0.3 },
    }).addTo(map);
    map.fitBounds(layer.getBounds().pad(0.4));
    this.previewMap = map;
  }

  openApprove(): void {
    this.approveOpen.set(true);
    this.approveNote.set('');
    this.actionErrorKey.set(null);
  }

  confirmApprove(): void {
    const boundary = this.selected();
    if (!boundary || this.approving()) return;
    this.approving.set(true);
    this.actionErrorKey.set(null);
    this.plotMapService
      .adminApprove(boundary.id, this.approveNote().trim() || undefined)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (updated) => {
          this.approving.set(false);
          this.approveOpen.set(false);
          this.selected.set(updated);
          this.load();
        },
        error: (err: unknown) => {
          this.approving.set(false);
          this.actionErrorKey.set(reviewErrorKey(err));
        },
      });
  }

  openReject(): void {
    this.rejectOpen.set(true);
    this.rejectNote.set('');
    this.actionErrorKey.set(null);
  }

  confirmReject(): void {
    const boundary = this.selected();
    const note = this.rejectNote().trim();
    if (!boundary || !note || this.rejecting()) return;
    this.rejecting.set(true);
    this.actionErrorKey.set(null);
    this.plotMapService
      .adminReject(boundary.id, note)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (updated) => {
          this.rejecting.set(false);
          this.rejectOpen.set(false);
          this.selected.set(updated);
          this.load();
        },
        error: (err: unknown) => {
          this.rejecting.set(false);
          this.actionErrorKey.set(
            (err instanceof HttpErrorResponse && err.status === 422)
              ? 'admin.plotBoundaries.errors.noteRequired'
              : reviewErrorKey(err),
          );
        },
      });
  }

  openVersions(): void {
    const boundary = this.selected();
    if (!boundary) return;
    this.versionsOpen.set(true);
    this.versionsLoading.set(true);
    this.versions.set([]);
    this.plotMapService
      .adminVersions(boundary.id)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (rows) => {
          this.versions.set(rows);
          this.versionsLoading.set(false);
        },
        error: () => this.versionsLoading.set(false),
      });
  }

  exportEvidence(): void {
    const boundary = this.selected();
    if (!boundary || this.evidenceExporting()) return;
    this.evidenceExporting.set(true);
    this.plotMapService
      .evidence(boundary.id)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (bundle) => {
          this.evidenceExporting.set(false);
          const blob = new Blob([JSON.stringify(bundle, null, 2)], {
            type: 'application/geo+json',
          });
          const url = URL.createObjectURL(blob);
          const anchor = document.createElement('a');
          anchor.href = url;
          anchor.download = `boundary-${boundary.id}-evidence.geojson`;
          anchor.click();
          URL.revokeObjectURL(url);
        },
        error: () => {
          this.evidenceExporting.set(false);
          this.actionErrorKey.set('admin.plotBoundaries.errors.generic');
        },
      });
  }

  openDisputeResolve(dispute: BoundaryDispute, dismiss: boolean): void {
    this.disputeResolveTarget.set(dispute);
    this.disputeDismiss.set(dismiss);
    this.disputeNote.set('');
    this.disputeErrorKey.set(null);
  }

  confirmDisputeResolve(): void {
    const dispute = this.disputeResolveTarget();
    const note = this.disputeNote().trim();
    if (!dispute || !note || this.disputeSaving()) return;
    this.disputeSaving.set(true);
    this.disputeErrorKey.set(null);
    this.plotMapService
      .resolveDispute(dispute.id, note, this.disputeDismiss())
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: () => {
          this.disputeSaving.set(false);
          this.disputeResolveTarget.set(null);
          this.loadDisputes();
        },
        error: (err: unknown) => {
          this.disputeSaving.set(false);
          this.disputeErrorKey.set(reviewErrorKey(err));
        },
      });
  }

  // ---- Template helpers ---------------------------------------------------

  digits(value: string | number | null | undefined): string {
    if (value === null || value === undefined || value === '') return '—';
    return localizeDigits(toAsciiDigits(String(value)), this.lang());
  }

  dagSummary(boundary: AdminBoundary): string {
    const parts: string[] = [];
    if (boundary.rsDag) parts.push(`RS ${boundary.rsDag}`);
    if (boundary.csDag) parts.push(`CS ${boundary.csDag}`);
    return parts.join(' · ') || '—';
  }
}
