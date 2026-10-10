import { HttpErrorResponse } from '@angular/common/http';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { TranslateService, provideTranslateService } from '@ngx-translate/core';
import { Subject, of, throwError } from 'rxjs';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { LanguageService } from '../../../../../core/services/language.service';
import { LandDataService, type DagDetails } from '../../../../../core/services/land-data.service';
import { DagInfoDialogComponent } from './dag-info-dialog.component';

// The vitest jsdom builder does not expose Web Storage (LanguageService reads it).
const storage = new Map<string, string>();
Object.defineProperty(globalThis, 'localStorage', {
  configurable: true,
  value: {
    getItem: (k: string) => storage.get(k) ?? null,
    setItem: (k: string, v: string) => void storage.set(k, v),
    removeItem: (k: string) => void storage.delete(k),
    clear: () => storage.clear(),
  },
});

const BN = {
  title: 'প্লট/দাগ নাম্বার {{dag}} তথ্য বিবরণঃ',
  landSection: 'ভূমি তথ্য বিবরণঃ',
  khatianSection: 'খতিয়ানের তথ্যঃ',
  dagNo: 'প্লট/দাগ নাম্বার',
  totalLand: 'মোট জমি',
  khatianNo: 'খতিয়ান নং',
  close: 'বন্ধ করুন',
  retry: 'আবার চেষ্টা করুন',
  approx: '(≈ {{value}} শতাংশ)',
  noKhatians: 'এই দাগের খতিয়ান তথ্য পাওয়া যায়নি',
  source: 'তথ্যসূত্র: settlement.gov.bd · সংগৃহীত: {{date}}',
  survey: { bds: 'বিডিএস' },
  unit: { acre: 'একর' },
  stage: { objection: 'আপত্তি স্তর' },
  error: { generic: 'ত্রুটি', notFound: 'নেই', rateLimited: 'অনেক অনুরোধ' },
};
const EN = {
  ...BN,
  title: 'Plot/Dag No. {{dag}} — Details',
  landSection: 'Land Information',
  khatianSection: 'Khatian Information',
  dagNo: 'Plot/Dag No.',
  totalLand: 'Total Land',
  khatianNo: 'Khatian No.',
  close: 'Close',
  approx: '(≈ {{value}} shatak)',
  survey: { bds: 'BDS' },
  unit: { acre: 'acre' },
  stage: { objection: 'Objection stage' },
};

function details(overrides: Partial<DagDetails> = {}): DagDetails {
  return {
    survey: 'bds',
    sheet: '022',
    dag: '22',
    mouza: {
      name_bn: 'উত্তর কাউন্দিয়া',
      name_en: 'Uttar Kaundia',
      upazila_bn: 'সাভার',
      upazila_en: 'Savar',
      district_bn: 'ঢাকা',
      district_en: 'Dhaka',
    },
    total_land: { value: 0.7649, unit: 'acre' },
    khatians: [
      { khatian_no: '12012', owners: ['টেস্ট এক', 'টেস্ট দুই', 'টেস্ট তিন'], stage_code: 'objection', stage_bn: 'আপত্তি স্তর' },
      { khatian_no: '99', owners: ['টেস্ট চার'], stage_code: null, stage_bn: 'অন্য স্তর' },
    ],
    source_note: null,
    source: { name: 'settlement.gov.bd', fetched_at: '2026-10-11T00:00:00+00:00', dataset_version: 'test' },
    ...overrides,
  };
}

describe('DagInfoDialogComponent', () => {
  let fixture: ComponentFixture<DagInfoDialogComponent>;
  let dagDetails: ReturnType<typeof vi.fn>;

  async function setup(response: unknown, language: 'bn' | 'en' = 'bn'): Promise<void> {
    dagDetails = vi.fn().mockReturnValue(response);
    TestBed.configureTestingModule({
      imports: [DagInfoDialogComponent],
      providers: [provideTranslateService(), { provide: LandDataService, useValue: { dagDetails } }],
    });
    const translate = TestBed.inject(TranslateService);
    translate.setTranslation('bn', { member: { plotMap: { dagInfo: BN } } });
    translate.setTranslation('en', { member: { plotMap: { dagInfo: EN } } });
    TestBed.inject(LanguageService).setLang(language);
    fixture = TestBed.createComponent(DagInfoDialogComponent);
    fixture.componentRef.setInput('target', { survey: 'bds', sheet: '022', dag: '22' });
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
  }

  const root = (): HTMLElement => fixture.nativeElement as HTMLElement;
  const q = <T extends Element>(selector: string): T | null => root().querySelector<T>(selector);

  beforeEach(() => storage.clear());

  it('shows the header at once and a skeleton while loading', async () => {
    await setup(new Subject<DagDetails>());

    expect(q('.dag-title')?.textContent).toContain('প্লট/দাগ নাম্বার ২২ তথ্য বিবরণঃ');
    expect(q('.dag-skeleton')).not.toBeNull();
    expect(q('.dag-khatian')).toBeNull();
    expect(dagDetails).toHaveBeenCalledWith('bds', '022', '22');
  });

  it('renders the land table and groups khatians with spanning cells', async () => {
    await setup(of(details()));

    const land = q('.dag-land')?.textContent ?? '';
    expect(land).toContain('মোট জমি');
    expect(land).toContain('০.৭৬৪৯ একর');
    expect(land).toContain('৭৬.৪৯ শতাংশ');
    expect(land).toContain('উত্তর কাউন্দিয়া, সাভার, ঢাকা');
    expect(land).toContain('বিডিএস');

    const rows = root().querySelectorAll('.dag-khatian tbody tr');
    expect(rows).toHaveLength(4);
    const spans = rows[0].querySelectorAll('td[rowspan="3"]');
    expect(spans).toHaveLength(2);
    expect(spans[0].textContent?.trim()).toBe('১২০১২');
    expect(spans[1].textContent?.trim()).toBe('আপত্তি স্তর');
    expect(rows[1].querySelectorAll('td')).toHaveLength(1);
    expect(Array.from(rows).map((r) => r.classList.contains('row-odd'))).toEqual([true, false, true, false]);
  });

  it('shows an unmapped stage exactly as stored', async () => {
    await setup(of(details()));

    const lastRow = root().querySelectorAll('.dag-khatian tbody tr')[3];
    expect(lastRow.textContent).toContain('অন্য স্তর');
  });

  it('uses English labels and ASCII digits in English mode', async () => {
    await setup(of(details()), 'en');

    expect(q('.dag-title')?.textContent).toContain('Plot/Dag No. 22 — Details');
    expect(q('.dag-land')?.textContent).toContain('0.7649 acre');
    expect(q('.dag-land')?.textContent).toContain('Uttar Kaundia, Savar, Dhaka');
    expect(q('.dag-close-btn')?.textContent?.trim()).toBe('Close');
    expect(q('.dag-khatian tbody tr td')?.textContent?.trim()).toBe('12012');
    expect(q('.dag-khatian')?.textContent).toContain('Objection stage');
    expect(q('.dag-khatian')?.textContent).toContain('টেস্ট এক'); // names are never translated
  });

  it('shows a single note row when the dag has no khatians', async () => {
    await setup(of(details({ khatians: [], source_note: 'hidden_by_source' })));

    const rows = root().querySelectorAll('.dag-khatian tbody tr');
    expect(rows).toHaveLength(1);
    expect(rows[0].textContent).toContain('এই দাগের খতিয়ান তথ্য পাওয়া যায়নি');
  });

  it('shows an inline error with retry that reloads', async () => {
    await setup(throwError(() => new HttpErrorResponse({ status: 500 })));

    expect(q('.dag-error')?.textContent).toContain('ত্রুটি');
    dagDetails.mockReturnValue(of(details()));
    q<HTMLButtonElement>('.dag-retry')?.click();
    fixture.detectChanges();

    expect(dagDetails).toHaveBeenCalledTimes(2);
    expect(q('.dag-khatian')).not.toBeNull();
  });

  it('offers no retry for an unknown dag (404)', async () => {
    await setup(throwError(() => new HttpErrorResponse({ status: 404 })));

    expect(q('.dag-error')?.textContent).toContain('নেই');
    expect(q('.dag-retry')).toBeNull();
  });

  it('declares itself an accessible modal dialog', async () => {
    await setup(of(details()));

    const dialog = q('.dag-dialog');
    expect(dialog?.getAttribute('role')).toBe('dialog');
    expect(dialog?.getAttribute('aria-modal')).toBe('true');
    const labelledBy = dialog?.getAttribute('aria-labelledby') ?? '';
    expect(q(`#${labelledBy}`)?.textContent).toContain('২২');
  });

  it.each([
    ['the × button', '.dag-close-x'],
    ['the footer button', '.dag-close-btn'],
  ])('closes from %s', async (_name, selector) => {
    await setup(of(details()));
    const closed = vi.fn();
    fixture.componentInstance.closed.subscribe(closed);

    q<HTMLButtonElement>(selector)?.click();

    expect(closed).toHaveBeenCalledTimes(1);
  });

  it('closes on Escape and on overlay click, but not on dialog click', async () => {
    await setup(of(details()));
    const closed = vi.fn();
    fixture.componentInstance.closed.subscribe(closed);

    q('.dag-dialog')?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    expect(closed).not.toHaveBeenCalled();

    q('.dag-overlay')?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    q('.dag-overlay')?.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));

    expect(closed).toHaveBeenCalledTimes(2);
  });

  it('traps Tab inside the dialog', async () => {
    await setup(of(details()));
    const closeButton = q<HTMLButtonElement>('.dag-close-btn')!;
    const firstFocusable = q<HTMLElement>('.dag-close-x')!;
    closeButton.focus();

    const forward = new KeyboardEvent('keydown', { key: 'Tab', bubbles: true, cancelable: true });
    q('.dag-overlay')?.dispatchEvent(forward);

    expect(forward.defaultPrevented).toBe(true);
    expect(document.activeElement).toBe(firstFocusable);

    const backward = new KeyboardEvent('keydown', { key: 'Tab', shiftKey: true, bubbles: true, cancelable: true });
    q('.dag-overlay')?.dispatchEvent(backward);

    expect(document.activeElement).toBe(closeButton);
  });
});
