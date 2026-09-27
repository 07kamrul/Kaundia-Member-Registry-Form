import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { provideTranslateService } from '@ngx-translate/core';
import { of } from 'rxjs';
import { vi } from 'vitest';
import { ConfigListService } from '../../../core/services/config-list.service';
import { ContentService } from '../../../core/services/content.service';
import type { EventItem } from '../../../core/models/content.model';
import { EventsPageComponent } from './events-page.component';

function event(id: string, title: string, startAt: string): EventItem {
  return {
    id,
    title,
    description: null,
    location: 'Community hall',
    categoryId: null,
    startAt,
    endAt: null,
    isPublished: true,
    isMembersOnly: false,
    createdAt: '2026-01-01T00:00:00+00:00',
    updatedAt: '2026-01-01T00:00:00+00:00',
  };
}

describe('EventsPageComponent', () => {
  function setup(rows: EventItem[] | 'error') {
    const listEvents =
      rows === 'error'
        ? vi.fn(() => ({ subscribe: ({ error }: { error: () => void }) => error() }))
        : vi.fn(() => of(rows));

    TestBed.configureTestingModule({
      imports: [EventsPageComponent],
      providers: [
        provideRouter([]),
        provideTranslateService(),
        { provide: ContentService, useValue: { listEvents } },
        { provide: ConfigListService, useValue: { getItems: () => of([]) } },
      ],
    });
    const fixture = TestBed.createComponent(EventsPageComponent);
    fixture.detectChanges();
    return fixture;
  }

  it('splits the feed into upcoming then past, keeping the server order', () => {
    const now = Date.now();
    const soon = new Date(now + 60_000).toISOString();
    const later = new Date(now + 3_600_000).toISOString();
    const past = new Date(now - 3_600_000).toISOString();

    // The endpoint returns upcoming rows first, past rows last.
    const fixture = setup([
      event('2', 'Later', later),
      event('1', 'Sooner', soon),
      event('3', 'Old', past),
    ]);

    expect(fixture.componentInstance.upcoming.map((row) => row.id)).toEqual(['2', '1']);
    expect(fixture.componentInstance.past.map((row) => row.id)).toEqual(['3']);
    expect(fixture.componentInstance.loading).toBe(false);
    expect(fixture.componentInstance.error).toBe('');
  });

  it('reports an error state when the feed cannot be loaded', () => {
    const fixture = setup('error');
    expect(fixture.componentInstance.loading).toBe(false);
    expect(fixture.componentInstance.error).not.toBe('');
    expect(fixture.componentInstance.upcoming).toEqual([]);
    expect(fixture.componentInstance.past).toEqual([]);
  });

  it('renders an upcoming event once the feed is loaded', () => {
    const fixture = setup([event('1', 'Sooner', new Date(Date.now() + 60_000).toISOString())]);
    const text: string = fixture.nativeElement.textContent;
    expect(text).toContain('Sooner');
    expect(fixture.componentInstance.loading).toBe(false);
  });
});
