import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  NgZone,
  computed,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import type { Subscription } from 'rxjs';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import * as L from 'leaflet';
import '@geoman-io/leaflet-geoman-free';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';
import { IconComponent, type IconName } from '../../../../shared/icon/icon.component';
import { AuthService } from '../../../../core/services/auth.service';
import { LanguageService } from '../../../../core/services/language.service';
import { MemberService, type MemberProperty } from '../../../../core/services/member.service';
import { localizeDigits } from '../../../../core/services/roadmap.service';
import { PlotMapService } from '../../../../core/services/plot-map.service';
import { LandDataService, type LandPlotFeature } from '../../../../core/services/land-data.service';
import { telHref, whatsAppHref } from '../../../../shared/phone-input/contact-links';
import { toAsciiDigits } from '../../../../core/services/digits.helper';
import {
  latLngsToGeometry,
  parseSocietyBbox,
} from '../../../../core/services/geo.helper';
import type {
  BoundaryOwner,
  MyBoundary,
  PlotFeature,
  PolygonGeometry,
} from '../../../../core/models/plot-boundary.model';
import { validateDrawing, type DrawValidation } from './boundary-validation';
import { environment } from '../../../../../environments/environment';

const MOVE_DEBOUNCE_MS = 300;
const SOCIETY_CENTER: L.LatLngTuple = [23.77, 90.39];
const DISCLAIMER_KEY = 'krmf_boundary_disclaimer_dismissed';
const MOUZA_CENTER: L.LatLngTuple = [23.7985, 90.3325];
const BDS_LABEL_MIN_ZOOM = 16;

export type PlotMapMode = 'boundaries' | 'bds' | 'rajuk';

/** Leaflet default marker/icons are unused; polygons only. */
const STATUS_COLORS: Record<string, string> = {
  pending: '#c9861e',
  approved: '#2e7d32',
  rejected: '#8a8a8a',
  superseded: '#b0a37f',
  withdrawn: '#8a8a8a',
  disputed: '#c0392b',
};
const MINE_COLOR = '#1e66d0';

const OWNER_ERROR_KEYS = {
  rateLimited: 'member.plotMap.owner.rateLimited',
  notApproved: 'member.plotMap.owner.notApproved',
  loadError: 'member.plotMap.owner.loadError',
} as const;

/** Maps owner-fetch failures to i18n keys - server text is never shown. */
export function ownerErrorKey(error: unknown): string {
  if (!(error instanceof HttpErrorResponse)) return OWNER_ERROR_KEYS.loadError;
  const code =
    (error.error as { detail?: { code?: string } } | null)?.detail?.code ?? null;
  if (error.status === 429 || code === 'BOUNDARY_OWNER_RATE_LIMITED')
    return OWNER_ERROR_KEYS.rateLimited;
  if (error.status === 403 && code === 'BOUNDARY_NOT_APPROVED') return OWNER_ERROR_KEYS.notApproved;
  return OWNER_ERROR_KEYS.loadError;
}

const SAVE_ERROR_CODES = [
  'INVALID_GEOMETRY',
  'SELF_INTERSECTING',
  'OUTSIDE_SOCIETY_AREA',
  'ZERO_AREA',
  'TOO_MANY_VERTICES',
  'NOT_YOUR_PROPERTY',
  'BOUNDARY_EXISTS',
] as const;

/** Maps a failed create/update to a specific i18n key (never a generic banner). */
export function saveErrorKey(error: unknown): string {
  const code =
    error instanceof HttpErrorResponse
      ? ((error.error as { detail?: { code?: string } } | null)?.detail?.code ?? null)
      : null;
  if (code && (SAVE_ERROR_CODES as readonly string[]).includes(code)) {
    return `member.plotMap.draw.errors.${code}`;
  }
  return 'member.plotMap.draw.errors.generic';
}

export function boundaryErrorKey(error: unknown): string {
  if (error instanceof HttpErrorResponse) {
    const code =
      (error.error as { detail?: { code?: string } } | null)?.detail?.code ?? null;
    if (error.status === 429 || code === 'BOUNDARY_OWNER_RATE_LIMITED') {
      return OWNER_ERROR_KEYS.rateLimited;
    }
  }
  return saveErrorKey(error);
}

interface SelectedFeature {
  feature: PlotFeature;
  owner: BoundaryOwner | null;
  loading: boolean;
  errorKey: string | null;
  reported: boolean;
}

type DrawStep = 'idle' | 'pick' | 'draw';

@Component({
  selector: 'app-plot-map',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, IconComponent, ConfirmModalComponent],
  templateUrl: './plot-map.component.html',
  styleUrl: './plot-map.component.scss',
})
export class PlotMapComponent implements AfterViewInit {
  private readonly plotMapService = inject(PlotMapService);
  private readonly landDataService = inject(LandDataService);
  private readonly memberService = inject(MemberService);
  private readonly auth = inject(AuthService);
  private readonly translate = inject(TranslateService);
  private readonly zone = inject(NgZone);
  private readonly destroyRef = inject(DestroyRef);
  readonly lang = inject(LanguageService).lang;

  readonly mapContainer = viewChild.required<ElementRef<HTMLDivElement>>('mapEl');

  readonly features = signal<PlotFeature[]>([]);
  readonly mapLoading = signal(true);
  readonly disclaimer = signal<{ en: string; bn: string } | null>(null);
  readonly disclaimerDismissed = signal(this.readDisclaimerDismissed());
  readonly search = signal('');
  readonly myLocationError = signal(false);

  // Polygon details sheet ("popup" rendered by Angular so it can be a bottom
  // sheet on touch screens and is fully testable).
  readonly selected = signal<SelectedFeature | null>(null);
  /** Container point of the clicked location; anchors the sheet on desktop. */
  readonly sheetPos = signal<{ x: number; y: number } | null>(null);
  private anchorLatLng: L.LatLng | null = null;

  // Draw flow.
  readonly canDraw = computed(() => this.auth.hasPermission('boundary.draw_own'));
  readonly drawStep = signal<DrawStep>('idle');
  readonly myBoundaries = signal<MyBoundary[]>([]);
  readonly availableProperties = computed(() => {
    const claimed = new Set(this.myBoundaries().map((b) => b.propertyId));
    return this.properties().filter((p) => !claimed.has(p.id));
  });
  readonly selectedPropertyId = signal<number | null>(null);
  readonly drawnGeometry = signal<PolygonGeometry | null>(null);
  readonly validation = computed(() =>
    validateDrawing(
      this.drawnGeometry(),
      this.declaredQuantity(),
      environment.societyBbox,
    ),
  );
  readonly saving = signal(false);
  readonly saveErrorKey = signal<string | null>(null);
  readonly editingBoundary = signal<MyBoundary | null>(null);
  /** Set when saving an edit while a review is already pending — saving replaces it. */
  readonly replaceTarget = signal<MyBoundary | null>(null);
  /** Boundary whose pending submission the member is withdrawing. */
  readonly withdrawTarget = signal<MyBoundary | null>(null);
  readonly withdrawing = signal(false);

  readonly reportOpen = signal(false);
  readonly reportNote = signal('');
  readonly reportSending = signal(false);
  readonly reportErrorKey = signal<string | null>(null);
  readonly reportSent = signal(false);

  readonly showDrawPanel = signal(false);

  // Map view modes: member boundaries (default), official BDS mouza map,
  // RAJUK DAP masterplan.
  readonly mapMode = signal<PlotMapMode>('boundaries');
  readonly viewsOpen = signal(false);
  readonly externalLoading = signal(false);
  readonly externalError = signal(false);
  readonly mapModes: Array<{ mode: PlotMapMode; labelKey: string; icon: IconName }> = [
    { mode: 'boundaries', labelKey: 'member.plotMap.views.boundaries', icon: 'edit' },
    { mode: 'bds', labelKey: 'member.plotMap.views.bds', icon: 'map' },
    { mode: 'rajuk', labelKey: 'member.plotMap.views.rajuk', icon: 'doc' },
  ];

  private map: L.Map | null = null;
  private readonly featureLayers = new Map<string, L.Polygon>();
  private moveDebounce: ReturnType<typeof setTimeout> | null = null;
  private featuresSub: Subscription | null = null;
  private drawnLayer: L.Polygon | null = null;
  private bdsLayer: L.GeoJSON | null = null;
  private rajukLayer: L.GeoJSON | null = null;
  private rajukSub: Subscription | null = null;

  private properties = signal<MemberProperty[]>([]);

  readonly legendItems: Array<{ status: string; color: string }> = [
    { status: 'approved', color: STATUS_COLORS['approved'] },
    { status: 'mine', color: MINE_COLOR },
    { status: 'pending', color: STATUS_COLORS['pending'] },
    { status: 'rejected', color: STATUS_COLORS['rejected'] },
    { status: 'disputed', color: STATUS_COLORS['disputed'] },
  ];

  ngAfterViewInit(): void {
    this.zone.runOutsideAngular(() => this.initMap());
    this.loadProperties();
    this.loadFeatures();
  }

  private initMap(): void {
    const map = L.map(this.mapContainer().nativeElement, {
      center: SOCIETY_CENTER,
      zoom: 15,
      touchZoom: true,
    });

    const street = L.tileLayer(environment.mapTileUrl, {
      maxZoom: 19,
      attribution: '© OpenStreetMap contributors',
    });
    const satellite = L.tileLayer(environment.satelliteTileUrl, {
      maxZoom: 19,
      attribution: '© Esri World Imagery',
    });
    street.addTo(map);
    L.control
      .layers(
        { Street: street, Satellite: satellite },
        {},
        { position: 'topright' },
      )
      .addTo(map);

    map.on('moveend', () => {
      if (this.moveDebounce) clearTimeout(this.moveDebounce);
      this.moveDebounce = setTimeout(() => this.zone.run(() => this.onViewMoved()), MOVE_DEBOUNCE_MS);
    });
    map.on('zoomend', () => this.zone.runOutsideAngular(() => this.updateBdsLabels()));
    map.on('move', () => this.updateSheetPos());

    map.on('pm:drawmove', () => this.zone.run(() => this.syncDrawnGeometry()));
    map.on('pm:vertexadded', () => this.zone.run(() => this.syncDrawnGeometry()));
    map.on('pm:change', () => this.zone.run(() => this.syncDrawnGeometry()));
    map.on('pm:create', (event: { layer: L.Layer }) => {
      this.zone.run(() => {
        this.drawnLayer = event.layer as L.Polygon;
        this.syncDrawnGeometry();
        this.attachEditListeners(this.drawnLayer);
      });
    });

    this.map = map;
  }

  // ---- Data loading -------------------------------------------------------

  /** Reload whichever layer the active map view needs. */
  private onViewMoved(): void {
    if (this.mapMode() === 'rajuk') {
      this.loadRajukPlots();
    } else if (this.mapMode() === 'bds') {
      this.loadBdsMouza();
    } else if (this.mapMode() === 'boundaries') {
      this.loadFeatures();
    }
  }

  private bboxString(): string {
    return this.map
      ? this.map.getBounds().toBBoxString()
      : parseSocietyBbox(environment.societyBbox).join(',');
  }

  loadFeatures(): void {
    this.featuresSub?.unsubscribe();
    this.featuresSub = this.plotMapService
      .listFeatures(this.bboxString())
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (page) => {
          this.disclaimer.set({ en: page.disclaimerEn, bn: page.disclaimerBn });
          this.features.set(page.features);
          this.mapLoading.set(false);
          this.renderFeatures();
        },
        error: () => {
          this.mapLoading.set(false);
        },
      });
  }

  private loadProperties(): void {
    this.memberService
      .getProfile()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (profile) => {
          this.properties.set(profile.properties);
          if (this.drawStep() !== 'idle') this.plotMapService.listMine().subscribe({
            next: (mine) => this.myBoundaries.set(mine),
          });
        },
        error: () => this.properties.set([]),
      });
  }

  private renderFeatures(): void {
    const map = this.map;
    if (!map) return;
    for (const layer of this.featureLayers.values()) {
      map.removeLayer(layer);
    }
    this.featureLayers.clear();

    for (const feature of this.features()) {
      if (!this.featureLayerVisible(feature)) continue;
      // Live shapes are solid; the owner's pending/rejected proposal is dashed.
      const isProposal = feature.isMine && feature.reviewStatus !== 'approved';
      const layer = L.polygon(this.geoRingToLatLngs(feature.geometry), {
        color: this.featureColor(feature),
        weight: 2,
        fillOpacity: 0.25,
        dashArray: isProposal ? '6,6' : undefined,
      });
      layer.on('click', (event) =>
        this.zone.run(() => this.onFeatureClick(feature, (event as L.LeafletMouseEvent).latlng)),
      );
      layer.addTo(map);
      this.featureLayers.set(`${feature.boundaryId}:${feature.reviewStatus}`, layer);
    }
  }

  // ---- Map view modes (boundaries / BDS / RAJUK) ---------------------------

  selectMapMode(mode: PlotMapMode): void {
    if (this.mapMode() === mode) {
      this.viewsOpen.set(false);
      return;
    }
    this.viewsOpen.set(false);
    this.cancelDraw();
    this.closeSheet();
    this.externalError.set(false);
    this.mapMode.set(mode);

    const map = this.map;
    if (!map) return;

    // Search and draw only apply to the member boundary view.
    if (mode !== 'boundaries') {
      this.search.set('');
      this.renderFeatures(); // hides member polygons filtered by cleared search
    }

    if (mode === 'bds') {
      this.removeRajukLayer();
      this.loadBdsMouza();
    } else {
      this.removeBdsLayer();
    }

    if (mode === 'rajuk') {
      this.loadRajukPlots();
    } else {
      this.removeRajukLayer();
      if (this.rajukSub) {
        this.rajukSub.unsubscribe();
        this.rajukSub = null;
      }
    }
  }

  toggleViews(): void {
    this.viewsOpen.update((open) => !open);
  }

  private loadBdsMouza(): void {
    const map = this.map;
    if (!map) return;
    this.externalLoading.set(true);
    this.landDataService
      .dagsInBbox(this.bboxString())
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (collection) => {
          this.externalLoading.set(false);
          if (this.mapMode() !== 'bds' || !this.map) return;
          this.removeBdsLayer();
          this.bdsLayer = L.geoJSON(collection as never, {
            style: { color: '#1a3fd4', weight: 2, fillColor: '#2b50e0', fillOpacity: 0.2 },
            onEachFeature: (feature, layer) =>
              layer.bindPopup(this.bdsPopupHtml(feature as LandPlotFeature, layer as L.Polygon)),
          }).addTo(this.map);
          this.updateBdsLabels();
        },
        error: () => {
          this.externalLoading.set(false);
          this.externalError.set(true);
        },
      });
  }

  /** Permanent dag labels only when zoomed in enough to read them. */
  private updateBdsLabels(): void {
    const map = this.map;
    const layer = this.bdsLayer;
    if (!map || !layer) return;
    const show = map.getZoom() >= BDS_LABEL_MIN_ZOOM;
    layer.eachLayer((child: L.Layer) => {
      const polygon = child as L.Polygon & { __dagLabel?: L.Marker };
      const dag = (polygon.feature as { properties?: { dag?: string } })?.properties?.dag;
      if (!dag) return;
      if (show && !polygon.__dagLabel) {
        const label = L.marker(polygon.getBounds().getCenter(), {
          icon: L.divIcon({ className: 'bds-dag-label', html: String(dag), iconSize: null as never }),
          interactive: false,
          keyboard: false,
        });
        label.addTo(map);
        polygon.__dagLabel = label;
      } else if (!show && polygon.__dagLabel) {
        map.removeLayer(polygon.__dagLabel);
        polygon.__dagLabel = undefined;
      }
    });
  }

  private removeBdsLayer(): void {
    const map = this.map;
    if (!map || !this.bdsLayer) return;
    this.bdsLayer.eachLayer((child: L.Layer) => {
      const label = (child as L.Polygon & { __dagLabel?: L.Marker }).__dagLabel;
      if (label) map.removeLayer(label);
    });
    map.removeLayer(this.bdsLayer);
    this.bdsLayer = null;
  }

  private bdsPopupHtml(feature: LandPlotFeature, layer: L.Polygon): string {
    const dag = this.digits(feature.properties?.dag ?? feature.properties?.label_bn ?? '');
    const center = layer.getBounds().getCenter();
    const streetView = `https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${center.lat},${center.lng}`;
    return `
      <div class="bds-popup">
        <strong>${this.translate.instant('member.plotMap.views.bdsDag')} ${dag}</strong>
        <p>${this.translate.instant('member.plotMap.views.bdsSurvey')}</p>
        <p>${this.translate.instant('member.plotMap.views.mouzaLabel')}</p>
        <a href="${streetView}" target="_blank" rel="noopener noreferrer">
          ${this.translate.instant('member.plotMap.views.streetView')}
        </a>
      </div>`;
  }

  private loadRajukPlots(): void {
    if (!this.map) return;
    this.externalLoading.set(true);
    this.rajukSub?.unsubscribe();
    this.rajukSub = this.landDataService
      .masterplanInBbox(this.bboxString())
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (collection) => {
          this.externalLoading.set(false);
          if (this.mapMode() !== 'rajuk' || !this.map) return;
          this.removeRajukLayer();
          this.rajukLayer = L.geoJSON(collection as never, {
            style: { color: '#7a8b12', weight: 1.5, fillColor: '#b7c94a', fillOpacity: 0.3 },
            onEachFeature: (feature, layer) =>
              layer.bindPopup(this.rajukPopupHtml(feature as LandPlotFeature, layer as L.Polygon)),
          }).addTo(this.map);
        },
        error: () => {
          this.externalLoading.set(false);
          this.externalError.set(true);
        },
      });
  }

  private rajukPopupHtml(feature: LandPlotFeature, layer: L.Polygon): string {
    const props = feature.properties ?? {};
    const center = layer.getBounds().getCenter();
    const streetView = `https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${center.lat},${center.lng}`;
    return `
      <div class="rajuk-popup">
        <strong>${this.translate.instant('member.plotMap.views.rsPlotNo')}: ${this.digits(props.rs_plot_no ?? props.plot_no ?? '')}</strong>
        <p>${this.translate.instant('member.plotMap.views.rsJlNo')}: 245</p>
        <p>${this.translate.instant('member.plotMap.views.mouzaLabel')}</p>
        <p>${this.translate.instant('member.plotMap.views.thanaLabel')}</p>
        <a href="${streetView}" target="_blank" rel="noopener noreferrer">
          ${this.translate.instant('member.plotMap.views.streetView')}
        </a>
      </div>`;
  }

  private removeRajukLayer(): void {
    if (this.map && this.rajukLayer) {
      this.map.removeLayer(this.rajukLayer);
      this.rajukLayer = null;
    }
  }

  private featureLayerVisible(feature: PlotFeature): boolean {
    const query = toAsciiDigits(this.search().trim()).toLowerCase();
    if (!query) return true;
    const dags = [feature.rsDag, feature.csDag]
      .filter((d): d is string => !!d)
      .map((d) => toAsciiDigits(d).toLowerCase());
    return dags.some((d) => d.includes(query));
  }

  private featureColor(feature: PlotFeature): string {
    if (feature.isMine && feature.reviewStatus === 'approved') return MINE_COLOR;
    return STATUS_COLORS[feature.reviewStatus] ?? STATUS_COLORS['approved'];
  }

  private geoRingToLatLngs(geometry: PolygonGeometry): L.LatLngTuple[] {
    return geometry.coordinates[0].map(
      (pair) => [pair[1], pair[0]] as L.LatLngTuple,
    );
  }

  // ---- Details sheet ------------------------------------------------------

  onFeatureClick(feature: PlotFeature, latlng?: L.LatLng): void {
    if (latlng) {
      this.anchorLatLng = latlng;
      this.updateSheetPos();
    }
    this.selected.set({ feature, owner: null, loading: true, errorKey: null, reported: false });
    this.plotMapService
      .getOwner(feature.boundaryId)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (owner) =>
          this.selected.update((sel) =>
            sel && sel.feature.boundaryId === feature.boundaryId
              ? { ...sel, owner, loading: false }
              : sel,
          ),
        error: (err: unknown) =>
          this.selected.update((sel) =>
            sel && sel.feature.boundaryId === feature.boundaryId
              ? { ...sel, loading: false, errorKey: ownerErrorKey(err) }
              : sel,
          ),
      });
  }

  closeSheet(): void {
    this.selected.set(null);
    this.anchorLatLng = null;
    this.sheetPos.set(null);
  }

  /** Keeps the anchored sheet glued to the clicked point as the map moves. */
  private updateSheetPos(): void {
    if (!this.map || !this.anchorLatLng) return;
    const point = this.map.latLngToContainerPoint(this.anchorLatLng);
    this.sheetPos.set({ x: point.x + 12, y: point.y + 12 });
  }

  openReport(): void {
    this.reportOpen.set(true);
    this.reportNote.set('');
    this.reportErrorKey.set(null);
    this.reportSent.set(false);
  }

  sendReport(): void {
    const selected = this.selected();
    if (!selected || !this.reportNote().trim()) return;
    this.reportSending.set(true);
    this.reportErrorKey.set(null);
    this.plotMapService
      .report(selected.feature.boundaryId, this.reportNote().trim())
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: () => {
          this.reportSending.set(false);
          this.reportSent.set(true);
          this.selected.update((sel) => (sel ? { ...sel, reported: true } : sel));
        },
        error: () => {
          this.reportSending.set(false);
          this.reportErrorKey.set('member.plotMap.report.error');
        },
      });
  }

  // ---- Search / locate ----------------------------------------------------

  onSearchInput(value: string): void {
    this.search.set(value);
    this.renderFeatures();
    const query = toAsciiDigits(value.trim()).toLowerCase();
    if (!query) return;
    const match = this.features().find((f) =>
      [f.rsDag, f.csDag]
        .filter((d): d is string => !!d)
        .some((d) => toAsciiDigits(d).toLowerCase() === query),
    );
    if (match) this.highlightFeature(match);
  }

  private highlightFeature(feature: PlotFeature): void {
    const layer = this.featureLayers.get(`${feature.boundaryId}:${feature.reviewStatus}`);
    if (!layer || !this.map) return;
    this.map.fitBounds(layer.getBounds().pad(0.5));
    layer.setStyle({ weight: 5, fillOpacity: 0.5 });
    setTimeout(() => layer.setStyle({ weight: 2, fillOpacity: 0.25 }), 2500);
  }

  locateMe(): void {
    if (!navigator.geolocation) {
      this.myLocationError.set(true);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (position) =>
        this.zone.run(() => {
          this.myLocationError.set(false);
          this.map?.setView([position.coords.latitude, position.coords.longitude], 17);
        }),
      () => this.zone.run(() => this.myLocationError.set(true)),
    );
  }

  // ---- Disclaimer ---------------------------------------------------------

  dismissDisclaimer(): void {
    this.disclaimerDismissed.set(true);
    try {
      sessionStorage.setItem(DISCLAIMER_KEY, '1');
    } catch {
      // private mode - banner just returns next reload
    }
  }

  private readDisclaimerDismissed(): boolean {
    try {
      return sessionStorage.getItem(DISCLAIMER_KEY) === '1';
    } catch {
      return false;
    }
  }

  // ---- Draw flow ----------------------------------------------------------

  openDrawPanel(): void {
    this.showDrawPanel.set(true);
    if (this.drawStep() === 'idle') this.drawStep.set('pick');
    this.plotMapService
      .listMine()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({ next: (mine) => this.myBoundaries.set(mine) });
  }

  closeDrawPanel(): void {
    this.cancelDraw();
    this.showDrawPanel.set(false);
  }

  startDrawing(): void {
    const propertyId = this.selectedPropertyId();
    if (!propertyId || !this.map) return;
    this.editingBoundary.set(null);
    this.drawStep.set('draw');
    this.saveErrorKey.set(null);
    this.drawnGeometry.set(null);
    this.map.pm.enableDraw('Polygon', {
      allowSelfIntersection: false,
      // touch-friendly defaults (geoman enables them with touch support on).
      templineStyle: { color: MINE_COLOR, weight: 3 },
      hintlineStyle: { color: MINE_COLOR, dashArray: '6,6' },
    } as never);
  }

  startEditing(boundary: MyBoundary): void {
    if (!this.map) return;
    this.editingBoundary.set(boundary);
    this.drawStep.set('draw');
    this.saveErrorKey.set(null);
    this.drawnGeometry.set(boundary.geometry);
    this.showDrawPanel.set(true);
    const layer = L.polygon(this.geoRingToLatLngs(boundary.geometry), {
      color: MINE_COLOR,
    }).addTo(this.map);
    this.drawnLayer = layer;
    layer.pm.enable({ allowSelfIntersection: false, allowRemoval: false } as never);
    this.attachEditListeners(layer);
  }

  private attachEditListeners(layer: L.Polygon): void {
    layer.on('pm:edit', () => this.zone.run(() => this.syncDrawnGeometry()));
    layer.on('pm:vertexadded', () => this.zone.run(() => this.syncDrawnGeometry()));
    layer.on('pm:vertexremoved', () => this.zone.run(() => this.syncDrawnGeometry()));
  }

  private syncDrawnGeometry(): void {
    const layer = this.drawnLayer;
    if (!layer) return;
    const latlngs = layer.getLatLngs()[0] as L.LatLng[];
    const ring = latlngs.map((ll) => [ll.lat, ll.lng] as [number, number]);
    this.drawnGeometry.set(latLngsToGeometry(ring));
  }

  cancelDraw(): void {
    const pm = this.map?.pm as unknown as { disable?: () => void } | undefined;
    pm?.disable?.();
    this.drawnLayer?.remove();
    this.drawnLayer = null;
    this.drawnGeometry.set(null);
    this.drawStep.set(this.showDrawPanel() ? 'pick' : 'idle');
    this.selectedPropertyId.set(null);
    this.saveErrorKey.set(null);
  }

  private declaredQuantity(): string | null {
    const propertyId = this.editingBoundary()?.propertyId ?? this.selectedPropertyId();
    return this.properties().find((p) => p.id === propertyId)?.landQuantity ?? null;
  }

  /** Save is gated by a confirm when it replaces an already-pending review. */
  requestSave(): void {
    const editing = this.editingBoundary();
    if (editing?.hasPending) {
      this.replaceTarget.set(editing);
      return;
    }
    this.saveDrawn();
  }

  saveDrawn(): void {
    if (!this.validation().valid || this.saving()) return;
    const geometry = this.drawnGeometry();
    if (!geometry) return;
    this.saving.set(true);
    this.saveErrorKey.set(null);
    this.replaceTarget.set(null);
    const editing = this.editingBoundary();
    const request$ = editing
      ? this.plotMapService.update(editing.id, geometry)
      : this.plotMapService.create(this.selectedPropertyId()!, geometry);
    request$.pipe(takeUntilDestroyed(this.destroyRef)).subscribe({
      next: () => {
        this.saving.set(false);
        this.cancelDraw();
        this.closeDrawPanel();
        this.loadFeatures();
      },
      error: (err: unknown) => {
        this.saving.set(false);
        this.saveErrorKey.set(saveErrorKey(err));
      },
    });
  }

  /** Members cannot delete; they can only withdraw a pending submission. */
  confirmWithdraw(): void {
    const target = this.withdrawTarget();
    if (!target || this.withdrawing()) return;
    this.withdrawing.set(true);
    this.plotMapService
      .withdraw(target.id)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: () => {
          this.withdrawing.set(false);
          this.withdrawTarget.set(null);
          this.loadFeatures();
          this.plotMapService
            .listMine()
            .pipe(takeUntilDestroyed(this.destroyRef))
            .subscribe({ next: (mine) => this.myBoundaries.set(mine) });
        },
        error: () => {
          this.withdrawing.set(false);
          this.withdrawTarget.set(null);
        },
      });
  }

  cancelWithdraw(): void {
    if (!this.withdrawing()) this.withdrawTarget.set(null);
  }

  // ---- Template helpers ---------------------------------------------------

  digits(value: string | number | null | undefined): string {
    if (value === null || value === undefined || value === '') return '—';
    return localizeDigits(toAsciiDigits(String(value)), this.lang());
  }

  disclaimerText(): string {
    const d = this.disclaimer();
    return d ? (this.lang() === 'bn' ? d.bn : d.en) : '';
  }

  ownerContactLinks(owner: BoundaryOwner): { tel: string | null; wa: string | null } {
    return { tel: telHref(owner.mobile), wa: whatsAppHref(owner.mobile) };
  }

  propertyLabel(property: MemberProperty): string {
    const dags = [property.dagNoRs, property.dagNoCs].filter(Boolean).join(' / ');
    return dags ? `দাগ ${dags}` : `#${property.id}`;
  }

  boundaryLabel(boundary: MyBoundary): string {
    const dags = [boundary.rsDag, boundary.csDag].filter(Boolean).join(' / ');
    return dags ? `দাগ ${dags}` : `#${boundary.propertyId}`;
  }
}
