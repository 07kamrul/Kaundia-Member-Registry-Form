import { HttpErrorResponse } from '@angular/common/http';
import { provideTranslateService } from '@ngx-translate/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';
import { vi } from 'vitest';
import { LanguageService } from '../../../../core/services/language.service';
import { PlotMapService } from '../../../../core/services/plot-map.service';
import {
  toAdminBoundary,
  toBoundaryDispute,
} from '../../../../core/models/plot-boundary.model';
import {
  PlotBoundariesComponent,
  reviewErrorKey,
} from './plot-boundaries.component';

// The preview mini-map never runs in tests - stub Leaflet out entirely.
const L = vi.hoisted(() => {
  const layerStub = () => ({
    addTo: vi.fn().mockReturnThis(),
    getBounds: vi.fn(() => ({ pad: vi.fn(() => ({})) })),
  });
  return {
    map: vi.fn(() => ({
      remove: vi.fn(),
      fitBounds: vi.fn(),
      on: vi.fn(),
    })),
    tileLayer: vi.fn(() => layerStub()),
    geoJSON: vi.fn(() => layerStub()),
  };
});

vi.mock('leaflet', () => L);

const BOUNDARY = {
  id: 11,
  property_id: 3,
  status: 'pending_review' as const,
  geometry: {
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
  },
  computed_area_sqm: 1234,
  computed_area_shotangsho: 30,
  current_version: 2,
  review_note: null,
  rs_dag: '830',
  cs_dag: '412',
  land_quantity: '5',
  khatian_no: '102',
  member_name: 'Karim',
  member_mobile: '01712345678',
};

const DISPUTE = {
  id: 4,
  boundary_id: 11,
  other_boundary_id: 12,
  overlap_area_sqm: 55.5,
  note: 'overlaps neighbour',
  status: 'open' as const,
  resolution_note: null,
};

function httpError(status: number): HttpErrorResponse {
  return new HttpErrorResponse({ status, error: 'x' });
}

function setup() {
  const adminApprove = vi.fn(() => of(toAdminBoundary({ ...BOUNDARY, status: 'approved' })));
  const adminReject = vi.fn(() => of(toAdminBoundary({ ...BOUNDARY, status: 'rejected' })));
  const adminList = vi.fn(() => of([toAdminBoundary(BOUNDARY)]));
  const listDisputes = vi.fn(() => of([toBoundaryDispute(DISPUTE)]));
  const resolveDispute = vi.fn(() => of({ ...DISPUTE, status: 'resolved' }));
  const adminVersions = vi.fn(() => of([]));
  const evidence = vi.fn(() => of({ type: 'FeatureCollection' }));
  const plotMapService = {
    adminList,
    adminApprove,
    adminReject,
    adminVersions,
    evidence,
    listDisputes,
    resolveDispute,
  };

  TestBed.configureTestingModule({
    imports: [PlotBoundariesComponent],
    providers: [
      provideTranslateService(),
      { provide: PlotMapService, useValue: plotMapService },
      { provide: LanguageService, useValue: { lang: vi.fn(() => 'en'), setLang: vi.fn() } },
    ],
  });
  const fixture = TestBed.createComponent(PlotBoundariesComponent);
  fixture.detectChanges();
  const el = fixture.nativeElement as HTMLElement;
  const component = fixture.componentInstance;
  return { fixture, component, el, plotMapService };
}

describe('PlotBoundariesComponent', () => {
  it('loads the pending queue and lists boundaries', () => {
    const { fixture, el, plotMapService } = setup();
    expect(plotMapService.adminList).toHaveBeenCalledWith('pending_review', undefined);
    fixture.detectChanges();
    expect(el.querySelector('.pb-list')?.textContent).toContain('Karim');
  });

  it('approves with an optional note via the service', () => {
    const { component, plotMapService } = setup();
    component.select(BOUNDARY as never);
    component.openApprove();
    component.approveNote.set('Looks right');
    component.confirmApprove();
    expect(plotMapService.adminApprove).toHaveBeenCalledWith(11, 'Looks right');
  });

  it('locks reject until a note is typed, then calls the service', () => {
    const { component, plotMapService } = setup();
    component.select(BOUNDARY as never);
    component.openReject();
    expect(component.rejectConfirmDisabled()).toBe(true);
    component.confirmReject();
    expect(plotMapService.adminReject).not.toHaveBeenCalled();
    component.rejectNote.set('Outline does not match khatian');
    expect(component.rejectConfirmDisabled()).toBe(false);
    component.confirmReject();
    expect(plotMapService.adminReject).toHaveBeenCalledWith(11, 'Outline does not match khatian');
  });

  it('shows a dedicated error when reject comes back 422 NOTE_REQUIRED', () => {
    const { component, plotMapService } = setup();
    component.select(BOUNDARY as never);
    component.openReject();
    component.rejectNote.set('x');
    plotMapService.adminReject = vi.fn(() => throwError(() => httpError(422)));
    component.confirmReject();
    expect(component.actionErrorKey()).toBe('admin.plotBoundaries.errors.noteRequired');
  });

  it('switches to the disputes tab, lists overlaps, resolves with a note', () => {
    const { fixture, component, el, plotMapService } = setup();
    component.selectTab('disputes');
    component.disputeFilter.set('open');
    component.load();
    fixture.detectChanges();
    expect(plotMapService.listDisputes).toHaveBeenCalledWith('open');
    expect(el.querySelector('.pb-list')?.textContent).toContain('55.5');
    component.openDisputeResolve(DISPUTE as never, false);
    component.disputeNote.set('Survey confirms');
    component.confirmDisputeResolve();
    expect(plotMapService.resolveDispute).toHaveBeenCalledWith(4, 'Survey confirms', false);
  });

  it('opens version history through the admin endpoint', () => {
    const { component, plotMapService } = setup();
    component.select(BOUNDARY as never);
    component.openVersions();
    expect(plotMapService.adminVersions).toHaveBeenCalledWith(11);
    expect(component.versionsOpen()).toBe(true);
  });

  it('fetches the evidence bundle for export', () => {
    const { component, plotMapService } = setup();
    component.select(BOUNDARY as never);
    component.exportEvidence();
    expect(plotMapService.evidence).toHaveBeenCalledWith(11);
    expect(component.evidenceExporting()).toBe(false);
  });

  it('maps review errors: 403 forbidden, other generic', () => {
    expect(reviewErrorKey(httpError(403))).toBe('admin.plotBoundaries.errors.forbidden');
    expect(reviewErrorKey(httpError(500))).toBe('admin.plotBoundaries.errors.generic');
    expect(reviewErrorKey(new Error('x'))).toBe('admin.plotBoundaries.errors.generic');
  });
});
