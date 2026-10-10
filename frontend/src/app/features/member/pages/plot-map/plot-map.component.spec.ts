import { HttpErrorResponse } from '@angular/common/http';
import { provideTranslateService } from '@ngx-translate/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of, Subject, throwError, type Observable } from 'rxjs';
import { vi } from 'vitest';
import { AuthService } from '../../../../core/services/auth.service';
import { LanguageService } from '../../../../core/services/language.service';
import { MemberService } from '../../../../core/services/member.service';
import { PlotMapService } from '../../../../core/services/plot-map.service';
import { toBoundaryOwner, toPlotMapPage } from '../../../../core/models/plot-boundary.model';
import {
  PlotMapComponent,
  ownerErrorKey,
  saveErrorKey,
} from './plot-map.component';

// The vitest jsdom builder does not expose Web Storage; the component's
// disclaimer dismissal and the AuthService session reads both need it.
function memoryStorage(): Storage {
  const backing = new Map<string, string>();
  return {
    get length(): number {
      return backing.size;
    },
    clear: () => backing.clear(),
    getItem: (key: string) => (backing.has(key) ? backing.get(key)! : null),
    key: (index: number) => Array.from(backing.keys())[index] ?? null,
    removeItem: (key: string) => void backing.delete(key),
    setItem: (key: string, value: string) => void backing.set(key, value),
  };
}
Object.defineProperty(globalThis, 'localStorage', {
  configurable: true,
  value: memoryStorage(),
});
Object.defineProperty(globalThis, 'sessionStorage', {
  configurable: true,
  value: memoryStorage(),
});

/**
 * Leaflet + Geoman are replaced with a shared stub so the component suite
 * stays hermetic: no tiles, no real map, no canvas. Only the surface the
 * component touches is stubbed.
 */
export const L = vi.hoisted(() => {
  const layerStub = () => ({
    addTo: vi.fn().mockReturnThis(),
    on: vi.fn().mockReturnThis(),
    remove: vi.fn(),
    setStyle: vi.fn(),
    getBounds: vi.fn(() => ({ pad: vi.fn(() => ({})) })),
    getLatLngs: vi.fn(() => []),
    pm: { enable: vi.fn(), disable: vi.fn() },
  });
  const mapStub = {
    on: vi.fn(),
    off: vi.fn(),
    setView: vi.fn(),
    fitBounds: vi.fn(),
    removeLayer: vi.fn(),
    addLayer: vi.fn(),
    remove: vi.fn(),
    getBounds: vi.fn(() => ({ toBBoxString: () => '90.30,23.70,90.50,23.80' })),
    pm: { enableDraw: vi.fn(), disable: vi.fn() },
  };
  const stub = {
    map: vi.fn(() => mapStub),
    tileLayer: vi.fn(() => layerStub()),
    polygon: vi.fn(() => layerStub()),
    geoJSON: vi.fn(() => layerStub()),
    control: { layers: vi.fn(() => ({ addTo: vi.fn() })) },
  };
  return stub;
});

vi.mock('leaflet', () => L);
vi.mock('@geoman-io/leaflet-geoman-free', () => ({}));

export const SQUARE_GEOMETRY = {
  type: 'Polygon' as const,
  coordinates: [
    [
      [90.39, 23.77],
      [90.4, 23.77],
      [90.4, 23.78],
      [90.39, 23.78],
      [90.39, 23.77],
    ],
  ],
};

export function featurePatch(overrides: Record<string, unknown> = {}) {
  return {
    boundary_id: 7,
    property_id: 3,
    rs_dag: '830',
    cs_dag: '412',
    status: 'approved' as const,
    review_status: 'approved' as const,
    is_mine: false,
    is_disputed: false,
    geometry: SQUARE_GEOMETRY,
    ...overrides,
  };
}

export function httpError(status: number, code?: string): HttpErrorResponse {
  return new HttpErrorResponse({
    status,
    error: code ? { detail: { code, message: 'raw' } } : 'x',
  });
}

export interface SetupOptions {
  owner$?: Observable<unknown>;
  listFeatures$?: Observable<unknown>;
  permissions?: string[];
}

const OWNER_OK = {
  boundary_id: 7,
  owner_name: 'Rahim',
  mobile: '01712345678',
  contact_hidden: false,
  rs_dag: '830',
  cs_dag: '412',
  land_quantity: '5',
  computed_area_sqm: 1234,
  computed_area_shotangsho: 30,
  status: 'approved' as const,
  review_status: 'approved' as const,
  is_disputed: false,
};

export function setup(options: SetupOptions = {}) {
  const listFeatures = vi.fn(() =>
    options.listFeatures$ ??
    of(
      toPlotMapPage({
        disclaimer_en: 'Disclaimer EN',
        disclaimer_bn: 'ডিসক্লেইমার',
        count: 1,
        features: [featurePatch()],
      }),
    ),
  );
  // Subject-backed so the skeleton state is observable before the response.
  const ownerSubject = new Subject<ReturnType<typeof toBoundaryOwner>>();
  const getOwner = vi.fn(() => options.owner$ ?? ownerSubject);
  const plotMapService = {
    listFeatures,
    getOwner,
    listMine: vi.fn(() => of([])),
    create: vi.fn(() => of({})),
    update: vi.fn(() => of({})),
    withdraw: vi.fn(() => of({})),
    report: vi.fn(() => of({ received: true, dispute_id: null })),
  };
  const memberService = {
    getProfile: vi.fn(() =>
      of({
        properties: [
          { id: 3, dagNoRs: '830', dagNoCs: '412', landQuantity: '5' },
          { id: 9, dagNoRs: '999', dagNoCs: null, landQuantity: null },
        ],
      }),
    ),
  };
  const permissions = options.permissions ?? ['boundary.view', 'boundary.draw_own'];

  TestBed.configureTestingModule({
    imports: [PlotMapComponent],
    providers: [
      provideTranslateService(),
      { provide: PlotMapService, useValue: plotMapService },
      { provide: MemberService, useValue: memberService },
      { provide: LanguageService, useValue: { lang: vi.fn(() => 'en'), setLang: vi.fn() } },
      {
        provide: AuthService,
        useValue: { hasPermission: (key: string) => permissions.includes(key) },
      },
    ],
  });
  const fixture = TestBed.createComponent(PlotMapComponent);
  const component = fixture.componentInstance;
  fixture.detectChanges();
  const el = fixture.nativeElement as HTMLElement;
  return { fixture, component, el, plotMapService, ownerSubject, OWNER_OK };
}

describe('PlotMapComponent', () => {
  it('shows the standing disclaimer banner after features load', () => {
    const { el } = setup();
    const banner = el.querySelector('.disclaimer-banner')!;
    expect(banner).not.toBeNull();
    expect(banner.textContent).toContain('Disclaimer EN');
  });

  it('keeps the banner visible when dismissed within the session flag check', () => {
    const { component } = setup();
    component.dismissDisclaimer();
    expect(component.disclaimerDismissed()).toBe(true);
    try {
      expect(sessionStorage.getItem('krmf_boundary_disclaimer_dismissed')).toBe('1');
    } finally {
      sessionStorage.removeItem('krmf_boundary_disclaimer_dismissed');
    }
  });

  it('renders the legend chips for every status colour', () => {
    const { el } = setup();
    const chips = el.querySelectorAll('.legend-chip');
    expect(chips.length).toBe(5);
  });

  it('fetches the owner on polygon click: skeleton first, then details', () => {
    const { fixture, component, el, ownerSubject, OWNER_OK } = setup();
    component.onFeatureClick({ boundaryId: 7 } as never);
    fixture.detectChanges();
    expect(component.selected()?.loading).toBe(true);
    expect(el.querySelector('.details-sheet .owner-skeleton')).not.toBeNull();
    ownerSubject.next(toBoundaryOwner(OWNER_OK));
    fixture.detectChanges();
    const sheet = el.querySelector('.details-sheet')!;
    expect(sheet.querySelector('.owner-name')?.textContent).toContain('Rahim');
    const call = sheet.querySelector('a.call-link')!;
    expect(call.getAttribute('href')).toBe('tel:+8801712345678');
    expect(sheet.querySelector('a.whatsapp-link')).not.toBeNull();
  });

  it('shows the hidden-contact chip instead of buttons when opted out', () => {
    const { fixture, component, el } = setup({
      owner$: of({
        boundary_id: 7,
        owner_name: 'Hidden',
        mobile: null,
        contact_hidden: true,
        rs_dag: '830',
        cs_dag: null,
        land_quantity: null,
        computed_area_sqm: 0,
        computed_area_shotangsho: 0,
        status: 'approved',
        review_status: 'approved',
        is_disputed: false,
      }),
    });
    component.onFeatureClick({ boundaryId: 7 } as never);
    fixture.detectChanges();
    const sheet = el.querySelector('.details-sheet')!;
    expect(sheet.querySelector('.contact-hidden')!.textContent).toContain(
      'member.plotMap.details.contactHidden',
    );
    expect(sheet.querySelector('a.call-link')).toBeNull();
  });

  it('maps owner-fetch errors to their keys, never the server text', () => {
    const { fixture, component, el } = setup({ owner$: throwError(() => httpError(500)) });
    component.onFeatureClick({ boundaryId: 7 } as never);
    fixture.detectChanges();
    const box = el.querySelector('.details-sheet .error-box')!;
    expect(box.textContent).toContain('member.plotMap.owner.loadError');
    expect(box.textContent).not.toContain('raw');
  });

  it('shows the draw button with boundary.draw_own', () => {
    const { el } = setup();
    expect(el.querySelector('.draw-btn')).not.toBeNull();
  });

  it('hides the draw button without boundary.draw_own', () => {
    const { el } = setup({ permissions: ['boundary.view'] });
    expect(el.querySelector('.draw-btn')).toBeNull();
  });

  it('opens the report modal, requires a note, and posts the report', () => {
    const { fixture, component, el, plotMapService } = setup({
      owner$: of(toBoundaryOwner(OWNER_OK)),
    });
    component.onFeatureClick({ boundaryId: 7 } as never);
    fixture.detectChanges();
    component.openReport();
    fixture.detectChanges();
    expect((el.querySelector('.modal-card .btn.btn-primary') as HTMLButtonElement).disabled).toBe(
      true,
    );
    component.reportNote.set('Fence is wrong');
    fixture.detectChanges();
    const send = el.querySelector<HTMLButtonElement>('.modal-card .btn.btn-primary')!;
    expect(send.disabled).toBe(false);
    send.click();
    expect(plotMapService.report).toHaveBeenCalledWith(7, 'Fence is wrong');
  });
});

describe('plot-map error key mapping', () => {
  it('maps owner rate-limit and not-approved codes', () => {
    expect(ownerErrorKey(httpError(429, 'BOUNDARY_OWNER_RATE_LIMITED'))).toBe(
      'member.plotMap.owner.rateLimited',
    );
    expect(ownerErrorKey(httpError(403, 'BOUNDARY_NOT_APPROVED'))).toBe(
      'member.plotMap.owner.notApproved',
    );
    expect(ownerErrorKey(httpError(500))).toBe('member.plotMap.owner.loadError');
  });

  it('maps every documented save error code to its own key', () => {
    for (const code of [
      'INVALID_GEOMETRY',
      'SELF_INTERSECTING',
      'OUTSIDE_SOCIETY_AREA',
      'ZERO_AREA',
      'TOO_MANY_VERTICES',
      'NOT_YOUR_PROPERTY',
      'BOUNDARY_EXISTS',
    ]) {
      expect(saveErrorKey(httpError(400, code))).toBe(`member.plotMap.draw.errors.${code}`);
    }
    expect(saveErrorKey(httpError(500))).toBe('member.plotMap.draw.errors.generic');
  });
});
