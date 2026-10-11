import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  NgZone,
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
import '../../../../shared/map/leaflet-geoman-setup';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { PlotMapService } from '../../../../core/services/plot-map.service';
import { LanguageService } from '../../../../core/services/language.service';
import { localizeDigits } from '../../../../core/services/roadmap.service';
import { toAsciiDigits } from '../../../../core/services/digits.helper';
import { latLngsToGeometry } from '../../../../core/services/geo.helper';
import type {
  AdminBoundary,
  BoundaryDispute,
  BoundaryVersion,
  DisputeStatus,
  PolygonGeometry,
} from '../../../../core/models/plot-boundary.model';

/** Maps a failed review action to an i18n key (403 vs generic). */
export function reviewErrorKey(error: unknown): string {
  if (!(error instanceof HttpErrorResponse)) return 'admin.plotBoundaries.errors.generic';
  if (error.status === 403) return 'admin.plotBoundaries.errors.forbidden';
  return 'admin.plotBoundaries.errors.generic';
}

const STATUS_TABS = ['pending', 'approved', 'rejected', 'deleted'] as const;

/** Where the add-polygon map starts when there is no shape to fit yet. */
const SOCIETY_CENTER: L.LatLngTuple = [23.809, 90.323];

const DISPUTE_TABS: DisputeStatus[] = ['open', 'resolved', 'dismissed'];

/** Maps a failed admin save to an i18n key (overlap confirmation vs generic). */
export function saveErrorKey(error: unknown): string {
  if (!(error instanceof HttpErrorResponse)) return 'admin.plotBoundaries.errors.generic';
  const code =
    (error.error as { detail?: { code?: string } } | null)?.detail?.code ?? null;
  if (code === 'OVERLAP_CONFIRMATION_REQUIRED') return 'admin.plotBoundaries.errors.overlapConfirm';
  if (error.status === 403) return 'admin.plotBoundaries.errors.forbidden';
  return 'admin.plotBoundaries.errors.generic';
}

export interface OverlapInfo {
  boundary_id: number;
  overlap_area_sqm: number;
}

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
  private readonly zone = inject(NgZone);
  readonly lang = inject(LanguageService).lang;

  readonly tab = signal<'queue' | 'disputes'>('queue');
  readonly statusFilter = signal<string>('pending');
  readonly search = signal('');
  readonly loading = signal(false);
  readonly loadErrorKey = signal<string | null>(null);
  readonly boundaries = signal<AdminBoundary[]>([]);
  readonly disputes = signal<BoundaryDispute[]>([]);
  readonly disputeFilter = signal<DisputeStatus>('open');
  readonly includeDeleted = signal(false);
  /** Transient success/status banner shown above the tab row. */
  readonly statusMessage = signal<string | null>(null);
  /** Dashboard/nav badge: submissions awaiting review. */
  readonly pendingCount = signal(0);

  readonly statusTabs = STATUS_TABS;
  readonly disputeTabs = DISPUTE_TABS;

  // Detail preview (mini map + declared info + actions).
  readonly selected = signal<AdminBoundary | null>(null);
  private previewMap: L.Map | null = null;
  /** Keeps the preview map sized right when the panel is shown/hidden. */
  private previewResize: ResizeObserver | null = null;
  /** Debounce handle for the dag search box. */
  private searchTimer: ReturnType<typeof setTimeout> | null = null;
  /** Geoman vertex-dragging colors match the preview polygon. */
  private static readonly EDIT_COLOR = '#c9861e';

  constructor() {
    inject(DestroyRef).onDestroy(() => {
      if (this.searchTimer) clearTimeout(this.searchTimer);
      this.previewResize?.disconnect();
    });
  }

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

  /** Delete (soft, reason mandatory). */
  readonly deleteOpen = signal(false);
  readonly deleteReason = signal('');
  readonly deleting = signal(false);
  readonly deleteConfirmDisabled = computed(() => this.deleteReason().trim().length < 3);

  /** Add polygon on behalf of a member (drawn on the map, goes live immediately). */
  readonly addOpen = signal(false);
  readonly addMemberId = signal<number | null>(null);
  readonly addPropertyId = signal<number | null>(null);
  readonly addSaving = signal(false);
  readonly addErrorKey = signal<string | null>(null);
  readonly addOverlaps = signal<OverlapInfo[]>([]);
  readonly addConfirmOverlap = signal(false);

  /** Edit the selected polygon by drawing on the map; the JSON mirrors the shape. */
  readonly editOpen = signal(false);
  readonly editSaving = signal(false);
  readonly editErrorKey = signal<string | null>(null);
  readonly editOverlaps = signal<OverlapInfo[]>([]);
  readonly editConfirmOverlap = signal(false);

  // Shared draw-map for the add + edit modals. Which modal it serves decides
  // the hint text; the geometry mirror is the same in both.
  readonly shapeFor = signal<'add' | 'edit' | null>(null);
  readonly shapeGeometry = signal('');
  /** True while the admin is sketching a fresh polygon instead of dragging vertices. */
  readonly shapeDrawing = signal(false);
  private shapeMap: L.Map | null = null;
  private shapeLayer: L.Polygon | null = null;

  ngOnInit(): void {
    this.load();
    this.loadPendingCount();
  }

  loadPendingCount(): void {
    this.plotMapService
      .adminPendingCount()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({ next: (count) => this.pendingCount.set(count) });
  }

  load(): void {
    if (this.tab() === 'disputes') {
      this.loadDisputes();
      return;
    }
    this.loading.set(true);
    this.loadErrorKey.set(null);
    this.plotMapService
      .adminList(this.statusFilter() || undefined, this.search().trim() || undefined, this.includeDeleted())
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (rows) => {
          this.boundaries.set(rows);
          // A selection can outlive its filter entry (approve/delete moved it
          // out of this queue) - drop it so the panel never shows a stale
          // record next to "no boundaries found".
          const sel = this.selected();
          if (sel && !rows.some((row) => row.id === sel.id)) this.selected.set(null);
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
    this.statusMessage.set(null);
    this.load();
  }

  applyStatusFilter(status: string): void {
    this.statusFilter.set(status);
    this.statusMessage.set(null);
    this.load();
  }

  applyDisputeFilter(status: DisputeStatus): void {
    this.disputeFilter.set(status);
    this.statusMessage.set(null);
    this.load();
  }

  clearSelection(): void {
    this.selected.set(null);
    this.actionErrorKey.set(null);
  }

  onSearch(value: string): void {
    this.search.set(value);
    // Debounce: every keystroke re-queries the whole queue otherwise.
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => this.load(), 350);
  }

  select(boundary: AdminBoundary): void {
    this.selected.set(boundary);
    this.statusMessage.set(null);
    this.actionErrorKey.set(null);
    this.schedulePreviewRender(boundary);
  }

  /**
   * Renders the preview panel's mini map. The panel paints with change
   * detection, which event coalescing can defer past setTimeout(0) - so
   * poll briefly for the map container instead of assuming it is there.
   */
  private schedulePreviewRender(boundary: AdminBoundary): void {
    const tryRender = (attempt: number): void => {
      // A newer selection supersedes this pending render.
      if (this.selected()?.id !== boundary.id) return;
      if (document.querySelector('.preview-map')) {
        this.renderPreview(boundary);
        // On phones the detail swaps in for the list; bring its top into view.
        if (window.matchMedia('(max-width: 1023px)').matches) {
          document
            .querySelector('.pb-detail-panel')
            ?.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      } else if (attempt < 20) {
        setTimeout(() => tryRender(attempt + 1), 50);
      }
    };
    setTimeout(() => tryRender(0));
  }

  private renderPreview(boundary: AdminBoundary): void {
    if (this.previewMap) {
      this.previewMap.remove();
      this.previewMap = null;
    }
    this.previewResize?.disconnect();
    this.previewResize = null;
    // No shape drawn yet (or wiped) - the placeholder replaces the map.
    if ((boundary.geometry?.coordinates?.[0]?.length ?? 0) < 3) return;
    const el = document.querySelector('.preview-map') as HTMLElement | null;
    if (!el) return;
    // A passive preview: no panning/zooming - wheel events pass through so
    // the page (or the panel's own scroll) behaves normally over the map.
    const map = L.map(el, {
      attributionControl: false,
      dragging: false,
      touchZoom: false,
      scrollWheelZoom: false,
      doubleClickZoom: false,
      boxZoom: false,
      keyboard: false,
      zoomControl: false,
    });
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19 }).addTo(map);
    const layer = L.geoJSON(boundary.geometry as never, {
      style: { color: '#c9861e', weight: 2, fillOpacity: 0.3 },
    }).addTo(map);
    map.fitBounds(layer.getBounds().pad(0.4));
    this.previewMap = map;
    // Panels that paint hidden (mobile swap) leave the map zero-width;
    // observing the container re-measures Leaflet once it settles.
    this.previewResize = new ResizeObserver(() => map.invalidateSize());
    this.previewResize.observe(el);
  }

  openApprove(): void {
    this.approveOpen.set(true);
    this.approveNote.set('');
    this.actionErrorKey.set(null);
  }

  confirmApprove(): void {
    const boundary = this.selected();
    const versionId = boundary?.pendingVersionId;
    if (!boundary || !versionId || this.approving()) return;
    this.approving.set(true);
    this.actionErrorKey.set(null);
    this.plotMapService
      .adminApprove(versionId, this.approveNote().trim() || undefined)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (updated) => {
          this.approving.set(false);
          this.approveOpen.set(false);
          this.selected.set(updated);
          this.statusMessage.set('admin.plotBoundaries.success.approved');
          this.load();
          this.loadPendingCount();
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
    const versionId = boundary?.pendingVersionId;
    const note = this.rejectNote().trim();
    if (!boundary || !versionId || !note || this.rejecting()) return;
    this.rejecting.set(true);
    this.actionErrorKey.set(null);
    this.plotMapService
      .adminReject(versionId, note)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (updated) => {
          this.rejecting.set(false);
          this.rejectOpen.set(false);
          this.selected.set(updated);
          this.statusMessage.set('admin.plotBoundaries.success.rejected');
          this.load();
          this.loadPendingCount();
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

  // ---- Admin add / edit / delete -------------------------------------------

  openDelete(): void {
    this.deleteOpen.set(true);
    this.deleteReason.set('');
    this.actionErrorKey.set(null);
  }

  confirmDelete(): void {
    const boundary = this.selected();
    const reason = this.deleteReason().trim();
    if (!boundary || reason.length < 3 || this.deleting()) return;
    this.deleting.set(true);
    this.actionErrorKey.set(null);
    this.plotMapService
      .adminDelete(boundary.id, reason)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (updated) => {
          this.deleting.set(false);
          this.deleteOpen.set(false);
          this.selected.set(updated);
          this.statusMessage.set('admin.plotBoundaries.success.deleted');
          this.load();
        },
        error: (err: unknown) => {
          this.deleting.set(false);
          this.actionErrorKey.set(saveErrorKey(err));
        },
      });
  }

  openAdd(): void {
    this.addOpen.set(true);
    this.addMemberId.set(null);
    this.addPropertyId.set(null);
    this.addErrorKey.set(null);
    this.addOverlaps.set([]);
    this.addConfirmOverlap.set(false);
    this.openShapeMap('add', null);
  }

  /** Parse and sanity-check the pasted GeoJSON Polygon. */
  private parseGeometry(raw: string): PolygonGeometry | null {
    try {
      const parsed = JSON.parse(raw) as PolygonGeometry;
      if (parsed?.type !== 'Polygon' || !Array.isArray(parsed.coordinates?.[0])) return null;
      return parsed;
    } catch {
      return null;
    }
  }

  /** The 409 overlap confirmation carries the conflicting boundaries. */
  private overlapsOf(error: unknown): OverlapInfo[] {
    if (error instanceof HttpErrorResponse && error.status === 409) {
      return (
        (error.error as { detail?: { overlaps?: OverlapInfo[] } } | null)?.detail?.overlaps ?? []
      );
    }
    return [];
  }

  confirmAdd(confirmOverlap = false): void {
    const memberId = this.addMemberId();
    const propertyId = this.addPropertyId();
    const geometry = this.parseGeometry(this.shapeGeometry());
    if (!memberId || !propertyId || !geometry || this.addSaving()) return;
    this.addSaving.set(true);
    this.addErrorKey.set(null);
    this.plotMapService
      .adminCreate(memberId, propertyId, geometry, confirmOverlap)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (created) => {
          this.addSaving.set(false);
          this.addOpen.set(false);
          this.shapeFor.set(null);
          this.selected.set(created);
          this.statusMessage.set('admin.plotBoundaries.success.saved');
          this.load();
        },
        error: (err: unknown) => {
          this.addSaving.set(false);
          this.addOverlaps.set(this.overlapsOf(err));
          this.addConfirmOverlap.set(this.overlapsOf(err).length > 0);
          this.addErrorKey.set(saveErrorKey(err));
        },
      });
  }

  openEdit(): void {
    const boundary = this.selected();
    if (!boundary) return;
    this.editOpen.set(true);
    this.editErrorKey.set(null);
    this.editOverlaps.set([]);
    this.editConfirmOverlap.set(false);
    this.openShapeMap('edit', boundary.geometry);
  }

  // ---- Shared shape map (add + edit both draw here) ------------------------

  /**
   * Boots the modal's draw map. With a geometry the shape loads editable;
   * with null the admin sketches a fresh polygon right away (add mode).
   * The modal paints on the next change-detection cycle, which can land
   * after setTimeout(0) - poll briefly for the map container instead.
   */
  private openShapeMap(forModal: 'add' | 'edit', geometry: PolygonGeometry | null): void {
    this.shapeFor.set(forModal);
    this.shapeDrawing.set(false);
    this.shapeGeometry.set('');
    const tryInit = (attempt: number): void => {
      if (this.shapeFor() !== forModal || this.shapeMap) return;
      if (document.querySelector('.shape-map')) {
        this.initShapeMap(geometry);
      } else if (attempt < 20) {
        setTimeout(() => tryInit(attempt + 1), 50);
      }
    };
    setTimeout(() => tryInit(0));
  }

  private initShapeMap(geometry: PolygonGeometry | null): void {
    this.destroyShapeMap();
    const el = document.querySelector('.shape-map') as HTMLElement | null;
    if (!el) return;
    // Scroll-wheel zoom fights the modal's own scrolling, so it stays off.
    const map = L.map(el, { attributionControl: false, scrollWheelZoom: false });
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19 }).addTo(map);
    this.shapeMap = map;
    if (geometry) {
      this.mountShapeLayer(geometry);
    } else {
      map.setView(SOCIETY_CENTER, 14);
      this.startShapeDraw();
    }
  }

  /** Loads a geometry as a geoman-editable polygon and mirrors it to the JSON. */
  private mountShapeLayer(geometry: PolygonGeometry): void {
    const map = this.shapeMap;
    if (!map) return;
    this.shapeLayer?.remove();
    const layer = L.polygon(
      geometry.coordinates[0].map((pair) => [pair[1], pair[0]] as L.LatLngTuple),
      { color: PlotBoundariesComponent.EDIT_COLOR, weight: 2, fillOpacity: 0.3 },
    ).addTo(map);
    this.shapeLayer = layer;
    // Settle the view before enabling geoman - enabling while the fitBounds
    // zoom animation is in flight leaves the edit handles silently disabled.
    map.fitBounds(layer.getBounds().pad(0.3), { animate: false });
    this.watchShapeLayer(layer);
    layer.pm.enable({
      allowSelfIntersection: false,
      allowRemoval: false,
    } as never);
    this.syncShapeGeometry();
  }

  /** Mirrors a finished polygon to the JSON and switches to vertex-dragging. */
  private watchShapeLayer(layer: L.Polygon): void {
    layer.on('pm:edit pm:vertexadded pm:vertexremoved', () =>
      this.zone.run(() => this.syncShapeGeometry()),
    );
  }

  /** Wipes the shape so the admin can sketch a fresh polygon on the map. */
  startShapeDraw(): void {
    const map = this.shapeMap;
    if (!map) return;
    this.shapeLayer?.remove();
    this.shapeLayer = null;
    this.shapeGeometry.set('');
    this.shapeDrawing.set(true);
    map.pm.enableDraw('Polygon', {
      allowSelfIntersection: false,
      templineStyle: { color: PlotBoundariesComponent.EDIT_COLOR, weight: 3 },
      hintlineStyle: { color: PlotBoundariesComponent.EDIT_COLOR, dashArray: '6,6' },
    } as never);
    // The JSON fills in live while the sketch is drawn, then the finished
    // polygon switches back to vertex-dragging.
    map.on('pm:drawmove', (event) => {
      const working = (event as unknown as { workingLayer?: L.Polygon }).workingLayer;
      if (!working) return;
      this.zone.run(() => this.mirrorRing(working));
    });
    map.once('pm:create', (event) => {
      (map.pm as unknown as { disable: () => void }).disable();
      this.zone.run(() => {
        this.shapeDrawing.set(false);
        const layer = (event as unknown as { layer: L.Polygon }).layer;
        this.shapeLayer = layer;
        this.watchShapeLayer(layer);
        layer.pm.enable({ allowSelfIntersection: false, allowRemoval: false } as never);
        this.syncShapeGeometry();
      });
    });
  }

  /** Back to the previous shape after an aborted sketch (no-op in add mode). */
  cancelShapeDraw(): void {
    const map = this.shapeMap;
    (map?.pm as unknown as { disable?: () => void } | undefined)?.disable?.();
    this.shapeDrawing.set(false);
    if (this.shapeFor() === 'edit') {
      const boundary = this.selected();
      if (map && boundary) this.mountShapeLayer(boundary.geometry);
    } else {
      // Add mode has no previous shape - go straight back to drawing.
      this.startShapeDraw();
    }
  }

  private mirrorRing(layer: L.Polygon): void {
    const latlngs = layer.getLatLngs()[0] as L.LatLng[];
    if (!latlngs || latlngs.length < 3) return;
    const ring = latlngs.map((ll) => [ll.lat, ll.lng] as [number, number]);
    this.shapeGeometry.set(JSON.stringify(latLngsToGeometry(ring), null, 2));
  }

  private syncShapeGeometry(): void {
    if (this.shapeLayer) this.mirrorRing(this.shapeLayer);
  }

  private destroyShapeMap(): void {
    if (this.shapeMap) {
      this.shapeMap.remove();
      this.shapeMap = null;
    }
    this.shapeLayer = null;
  }

  /** Closes either modal and tears the draw map down with it. */
  closeShapeModal(): void {
    this.destroyShapeMap();
    this.shapeDrawing.set(false);
    this.shapeFor.set(null);
    if (this.editOpen()) this.editOpen.set(false);
    if (this.addOpen()) this.addOpen.set(false);
  }

  confirmEdit(confirmOverlap = false): void {
    const boundary = this.selected();
    const geometry = this.parseGeometry(this.shapeGeometry());
    if (!boundary || !geometry || this.editSaving()) return;
    this.editSaving.set(true);
    this.editErrorKey.set(null);
    this.plotMapService
      .adminEdit(boundary.id, geometry, confirmOverlap)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (updated) => {
          this.editSaving.set(false);
          this.closeShapeModal();
          this.selected.set(updated);
          this.statusMessage.set('admin.plotBoundaries.success.saved');
          this.load();
          this.schedulePreviewRender(updated);
        },
        error: (err: unknown) => {
          this.editSaving.set(false);
          this.editOverlaps.set(this.overlapsOf(err));
          this.editConfirmOverlap.set(this.overlapsOf(err).length > 0);
          this.editErrorKey.set(saveErrorKey(err));
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

  /** A map can only render from a closed ring - anything less shows a placeholder. */
  hasGeometry(boundary: AdminBoundary): boolean {
    return (boundary.geometry?.coordinates?.[0]?.length ?? 0) >= 3;
  }

  /** Up to two leading initials for the list avatar. */
  initials(name: string): string {
    const parts = name.trim().split(/\s+/).slice(0, 2);
    return parts.map((part) => part.charAt(0).toUpperCase()).join('') || '?';
  }
}
