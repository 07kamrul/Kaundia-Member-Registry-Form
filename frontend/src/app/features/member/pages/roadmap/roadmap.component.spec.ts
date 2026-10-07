import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { provideTranslateService } from '@ngx-translate/core';
import { of, throwError } from 'rxjs';
import { vi } from 'vitest';
import {
  RoadmapService,
  currentTimeframeIndex,
  localizeDigits,
  toRoadmap,
  type Roadmap,
  type RoadmapApi,
} from '../../../../core/services/roadmap.service';
import {
  RoadmapManagementComponent,
  validateRoadmapForm,
} from '../../../management/pages/roadmap-management/roadmap-management.component';
import { RoadmapComponent } from './roadmap.component';
import { buildSlides } from './roadmap-slides.component';

type ApiStatus = 'planned' | 'in_progress' | 'done';

function item(id: number, timeframeId: number, status: ApiStatus) {
  return {
    id,
    timeframe_id: timeframeId,
    text: `item ${id}`,
    status,
    target_date: null,
    owner: null,
    note: null,
    sort_order: id,
    completed_at: status === 'done' ? '2026-10-01' : null,
    updated_at: '2026-10-08T10:00:00Z',
  };
}

const api: RoadmapApi = {
  last_updated: '2026-10-08T10:00:00Z',
  totals: { total: 4, done: 2, in_progress: 1, planned: 1, percent: 50 },
  timeframes: [
    {
      id: 1,
      key: 'short',
      name_bn: 'স্বল্পমেয়াদি পরিকল্পনা',
      name_en: 'Short Term',
      target_window_bn: 'আগামী ১ মাস',
      target_window_en: 'Next 1 month',
      sort_order: 0,
      total: 2,
      done: 2,
      in_progress: 0,
      planned: 0,
      percent: 100,
      items: [item(1, 1, 'done'), item(2, 1, 'done')],
    },
    {
      id: 2,
      key: 'mid',
      name_bn: 'মধ্যমেয়াদি পরিকল্পনা',
      name_en: 'Mid Term',
      target_window_bn: 'আগামী ৪ মাস',
      target_window_en: 'Next 4 months',
      sort_order: 1,
      total: 2,
      done: 0,
      in_progress: 1,
      planned: 1,
      percent: 0,
      items: [item(3, 2, 'in_progress'), item(4, 2, 'planned')],
    },
    {
      id: 3,
      key: 'long',
      name_bn: 'দীর্ঘমেয়াদি পরিকল্পনা',
      name_en: 'Long Term',
      target_window_bn: 'আগামী ১ বছর',
      target_window_en: 'Next 1 year',
      sort_order: 2,
      total: 0,
      done: 0,
      in_progress: 0,
      planned: 0,
      percent: 0,
      items: [],
    },
  ],
};

const roadmap: Roadmap = toRoadmap(api);

describe('roadmap helpers', () => {
  it('maps the snake_case API payload to the view model', () => {
    expect(roadmap.totals.inProgress).toBe(1);
    expect(roadmap.timeframes[0].windowBn).toBe('আগামী ১ মাস');
    expect(roadmap.timeframes[1].items[0].timeframeId).toBe(2);
    expect(roadmap.timeframes[0].items[0].completedAt).toBe('2026-10-01');
  });

  it('localizes digits only in Bangla', () => {
    expect(localizeDigits(38, 'bn')).toBe('৩৮');
    expect(localizeDigits(38, 'en')).toBe('38');
  });

  it('points "where we are now" at the first unfinished timeframe', () => {
    expect(currentTimeframeIndex(roadmap)).toBe(1);
  });

  it('falls back to the last timeframe when nothing is unfinished', () => {
    const empty = toRoadmap({
      ...api,
      timeframes: api.timeframes.map((tf) => ({ ...tf, items: [], total: 0, done: 0 })),
    });
    expect(currentTimeframeIndex(empty)).toBe(2);
  });

  it('builds an overview slide plus one slide per short timeframe', () => {
    const slides = buildSlides(roadmap);
    expect(slides[0].kind).toBe('overview');
    expect(slides.length).toBe(4);
  });

  it('paginates long timeframes across several slides', () => {
    const many = toRoadmap({
      ...api,
      timeframes: [
        { ...api.timeframes[0], items: Array.from({ length: 13 }, (_, i) => item(i + 1, 1, 'planned')) },
      ],
    });
    expect(buildSlides(many).filter((s) => s.kind === 'timeframe').length).toBe(3);
  });

  it('validates the admin form', () => {
    const base = {
      timeframeId: 1,
      text: 'x',
      status: 'planned' as const,
      targetDate: '',
      owner: '',
      note: '',
      notify: true,
    };
    expect(validateRoadmapForm(base)).toBe('');
    expect(validateRoadmapForm({ ...base, timeframeId: null })).toBe('admin.roadmap.errors.timeframe');
    expect(validateRoadmapForm({ ...base, text: '   ' })).toBe('admin.roadmap.errors.textRequired');
    expect(validateRoadmapForm({ ...base, text: 'x'.repeat(501) })).toBe('admin.roadmap.errors.textTooLong');
  });
});

describe('RoadmapComponent', () => {
  function setup(getRoadmap = vi.fn(() => of(roadmap))) {
    TestBed.configureTestingModule({
      imports: [RoadmapComponent],
      providers: [
        provideRouter([]),
        provideTranslateService(),
        { provide: RoadmapService, useValue: { getRoadmap, downloadPdf: vi.fn() } },
      ],
    });
    const fixture = TestBed.createComponent(RoadmapComponent);
    fixture.detectChanges();
    return { fixture, getRoadmap };
  }

  it('renders the three timeframe sections, the stepper and the current focus', () => {
    const { fixture } = setup();
    expect(fixture.nativeElement.querySelectorAll('.tf-section').length).toBe(3);
    expect(fixture.nativeElement.querySelectorAll('.step').length).toBe(3);
    expect(fixture.componentInstance.currentTimeframe()?.key).toBe('mid');
  });

  it('filters items by status and counts per filter', () => {
    const { fixture } = setup();
    const component = fixture.componentInstance;
    const mid = component.roadmap()!.timeframes[1];
    component.filter.set('done');
    expect(component.visibleItems(mid)).toEqual([]);
    component.filter.set('in_progress');
    expect(component.visibleItems(mid).map((i) => i.id)).toEqual([3]);
    expect(component.filterCount('all')).toBe(4);
    expect(component.filterCount('planned')).toBe(1);
  });

  it('collapses and expands a section', () => {
    const { fixture } = setup();
    const component = fixture.componentInstance;
    const short = component.roadmap()!.timeframes[0];
    component.toggleSection(short);
    expect(component.isCollapsed(short)).toBe(true);
    component.toggleSection(short);
    expect(component.isCollapsed(short)).toBe(false);
  });

  it('shows a retryable error when loading fails', () => {
    const { fixture } = setup(vi.fn(() => throwError(() => new Error('down'))));
    fixture.detectChanges();
    expect(fixture.componentInstance.error()).toBe(true);
    expect(fixture.nativeElement.querySelector('.error-box')).not.toBeNull();
  });
});

describe('RoadmapManagementComponent', () => {
  function setup() {
    const service = {
      getRoadmap: vi.fn(() => of(roadmap)),
      setStatus: vi.fn(() => of(roadmap)),
      reorder: vi.fn(() => of(roadmap)),
      createItem: vi.fn(() => of(roadmap)),
      updateItem: vi.fn(() => of(roadmap)),
      deleteItem: vi.fn(() => of(roadmap)),
    };
    TestBed.configureTestingModule({
      imports: [RoadmapManagementComponent],
      providers: [provideRouter([]), provideTranslateService(), { provide: RoadmapService, useValue: service }],
    });
    const fixture = TestBed.createComponent(RoadmapManagementComponent);
    fixture.detectChanges();
    return { fixture, service };
  }

  it('sends status changes with the notify preference', () => {
    const { fixture, service } = setup();
    const component = fixture.componentInstance;
    component.notifyOnDone.set(false);
    component.setStatus(component.roadmap()!.timeframes[1].items[1], 'done');
    expect(service.setStatus).toHaveBeenCalledWith(4, 'done', false);
  });

  it('ignores a click on the status the item already has', () => {
    const { fixture, service } = setup();
    const component = fixture.componentInstance;
    component.setStatus(component.roadmap()!.timeframes[1].items[0], 'in_progress');
    expect(service.setStatus).not.toHaveBeenCalled();
  });

  it('reorders by swapping neighbours and refuses to move past the edge', () => {
    const { fixture, service } = setup();
    const component = fixture.componentInstance;
    const mid = component.roadmap()!.timeframes[1];
    component.move(mid, 0, 1);
    expect(service.reorder).toHaveBeenCalledWith(2, [4, 3]);
    service.reorder.mockClear();
    component.move(mid, 0, -1);
    expect(service.reorder).not.toHaveBeenCalled();
  });

  it('moves an item between timeframes through the edit form', () => {
    const { fixture, service } = setup();
    const component = fixture.componentInstance;
    component.openEdit(component.roadmap()!.timeframes[1].items[0]);
    component.form.timeframeId = 3;
    component.saveForm();
    expect(service.updateItem).toHaveBeenCalledWith(3, expect.objectContaining({ timeframeId: 3 }));
    expect(component.formOpen()).toBe(false);
  });

  it('blocks saving an empty plan', () => {
    const { fixture, service } = setup();
    const component = fixture.componentInstance;
    component.openCreate(component.roadmap()!.timeframes[0]);
    component.saveForm();
    expect(service.createItem).not.toHaveBeenCalled();
    expect(component.formError()).not.toBe('');
  });
});
