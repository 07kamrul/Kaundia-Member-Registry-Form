import { TestBed } from '@angular/core/testing';
import { HttpErrorResponse } from '@angular/common/http';
import { provideTranslateService } from '@ngx-translate/core';
import { of, throwError } from 'rxjs';
import { vi } from 'vitest';
import { MemberService } from '../../../../core/services/member.service';
import {
  toNeighbourDirectory,
  type NeighbourDirectory,
  type NeighbourOwnerApiModel,
} from '../../../../core/models/neighbour.model';
import { NeighboursComponent, neighbourErrorKey } from './neighbours.component';

function owner(name: string, position: string, mobile: string | null = '01712345678'): NeighbourOwnerApiModel {
  return {
    owner_name: name,
    mobile,
    contact_hidden: mobile === null,
    land_quantity: '5',
    rs_dag: '830',
    cs_dag: '412',
    position_label: position,
  };
}

const DIRECTORY: NeighbourDirectory = toNeighbourDirectory({
  dag_type: 'rs',
  plot_limit: 5,
  properties: [
    {
      own: { property_id: 12, rs_dag: '830', cs_dag: '412', land_quantity: '5', dag_number: 830 },
      same_dag_owners: [owner('Same Owner', 'same_dag')],
      neighbours: [owner('Adjacent Owner', 'adjacent'), owner('Hidden Owner', 'near', null)],
    },
  ],
});

function httpError(status: number, code?: string): HttpErrorResponse {
  return new HttpErrorResponse({ status, error: code ? { detail: { code, message: 'raw' } } : 'x' });
}

function setup(getNeighbours = vi.fn((_type?: string) => of(DIRECTORY))) {
  TestBed.configureTestingModule({
    imports: [NeighboursComponent],
    providers: [provideTranslateService(), { provide: MemberService, useValue: { getNeighbours } }],
  });
  const fixture = TestBed.createComponent(NeighboursComponent);
  fixture.detectChanges();
  const el = fixture.nativeElement as HTMLElement;
  return { fixture, el, getNeighbours };
}

describe('NeighboursComponent', () => {
  it('requests without a dag type first and selects the echoed one', () => {
    const { fixture, getNeighbours } = setup();
    expect(getNeighbours).toHaveBeenCalledWith(undefined);
    expect(fixture.componentInstance.dagType()).toBe('rs');
  });

  it('renders same-dag owners before neighbours with position badges', () => {
    const { el } = setup();
    const rows = Array.from(el.querySelectorAll('.neighbour-table tbody tr'));
    expect(rows.map((r) => r.querySelector('.owner-name')?.textContent?.trim())).toEqual([
      'Same Owner',
      'Adjacent Owner',
      'Hidden Owner',
    ]);
    const badges = rows.map((r) => r.querySelector('.position-badge')!);
    expect(badges[0].classList).toContain('position-same_dag');
    expect(badges[0].textContent).toContain('member.neighbours.position.same_dag');
    expect(badges[1].classList).toContain('position-adjacent');
  });

  it('builds Call and WhatsApp links', () => {
    const { el } = setup();
    const first = el.querySelector('.neighbour-table tbody tr')!;
    expect(first.querySelector('a.call-link')!.getAttribute('href')).toBe('tel:+8801712345678');
    const wa = first.querySelector('a.whatsapp-link')!;
    expect(wa.getAttribute('href')).toBe('https://wa.me/8801712345678');
    expect(wa.getAttribute('rel')).toBe('noopener noreferrer');
    expect(wa.getAttribute('target')).toBe('_blank');
  });

  it('shows private text and no buttons for a hidden contact', () => {
    const { el } = setup();
    const hidden = el.querySelectorAll('.neighbour-table tbody tr')[2];
    expect(hidden.querySelector('.contact-hidden')!.textContent).toContain('member.neighbours.contactHidden');
    expect(hidden.querySelector('a')).toBeNull();
  });

  it('shows the no-properties empty state', () => {
    const { el } = setup(vi.fn(() => of({ dagType: 'rs', plotLimit: 5, properties: [] } as NeighbourDirectory)));
    expect(el.querySelector('.no-properties')!.textContent).toContain('member.neighbours.noProperties');
  });

  it('shows per-group empty and no-dag hints', () => {
    const data = toNeighbourDirectory({
      dag_type: 'cs',
      plot_limit: 5,
      properties: [
        { own: { property_id: 1, rs_dag: '830', cs_dag: null, land_quantity: null, dag_number: null }, same_dag_owners: [], neighbours: [] },
        { own: { property_id: 2, rs_dag: null, cs_dag: '7', land_quantity: null, dag_number: 7 }, same_dag_owners: [], neighbours: [] },
      ],
    });
    const { el } = setup(vi.fn(() => of(data)));
    expect(el.querySelector('.no-dag')!.textContent).toContain('member.neighbours.noDag');
    expect(el.querySelector('.no-owners')!.textContent).toContain('member.neighbours.emptyState');
  });

  it.each([
    [429, 'NEIGHBOUR_LOOKUP_RATE_LIMITED', 'member.neighbours.rateLimited'],
    [403, 'NEIGHBOUR_DIRECTORY_APPROVED_ONLY', 'member.neighbours.approvedOnly'],
    [500, undefined, 'member.neighbours.loadError'],
  ])('maps a %s error to its message', (status, code, key) => {
    const { el } = setup(vi.fn(() => throwError(() => httpError(status, code))));
    const box = el.querySelector('.error-box')!;
    expect(box.textContent).toContain(key);
    expect(box.textContent).not.toContain('raw');
  });

  it('treats a 403 without the approved-only code as a load error', () => {
    expect(neighbourErrorKey(httpError(403))).toBe('member.neighbours.loadError');
    expect(neighbourErrorKey(new Error('x'))).toBe('member.neighbours.loadError');
  });

  it('retries after an error', () => {
    const getNeighbours = vi.fn((_type?: string) => throwError(() => httpError(500)));
    const { fixture, el } = setup(getNeighbours);
    getNeighbours.mockImplementation(() => of(DIRECTORY));
    (el.querySelector('.retry-btn') as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(getNeighbours).toHaveBeenCalledTimes(2);
    expect(el.querySelector('.neighbour-table')).not.toBeNull();
  });

  it('switching to CS re-requests with cs', () => {
    const { fixture, el, getNeighbours } = setup();
    const buttons = el.querySelectorAll<HTMLButtonElement>('.dag-toggle-btn');
    expect(buttons[0].getAttribute('aria-pressed')).toBe('true');
    buttons[1].click();
    fixture.detectChanges();
    expect(getNeighbours).toHaveBeenLastCalledWith('cs');
  });
});
