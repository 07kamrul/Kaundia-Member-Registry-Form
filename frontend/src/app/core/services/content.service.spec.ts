import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { ContentService } from './content.service';

const NOTICE_ROW = {
  id: 1,
  title: 'T',
  body: 'B',
  category_id: 4,
  is_published: true,
  publish_at: '2026-01-01T00:00:00Z',
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-02T00:00:00Z',
};

const EVENT_ROW = {
  id: 2,
  title: 'E',
  description: 'D',
  location: 'L',
  category_id: null,
  start_at: '2026-11-01T10:00:00Z',
  end_at: '2026-11-01T12:00:00Z',
  is_published: true,
  is_members_only: false,
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
};

describe('ContentService (public notices/events feed)', () => {
  let http: HttpTestingController;
  let service: ContentService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    http = TestBed.inject(HttpTestingController);
    service = TestBed.inject(ContentService);
  });
  afterEach(() => http.verify());

  it('listNotices maps rows to camelCase items', () => {
    let notices: unknown;
    service.listNotices().subscribe((n) => (notices = n));
    http.expectOne((r) => r.url.endsWith('/public/notices')).flush([NOTICE_ROW]);
    expect(notices).toEqual([
      {
        id: '1',
        title: 'T',
        body: 'B',
        categoryId: '4',
        isPublished: true,
        publishAt: '2026-01-01T00:00:00Z',
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-02T00:00:00Z',
      },
    ]);
  });

  it('listEvents maps rows, keeping a null category as null', () => {
    let events: unknown;
    service.listEvents().subscribe((e) => (events = e));
    http.expectOne((r) => r.url.endsWith('/public/events')).flush([EVENT_ROW]);
    expect(events).toEqual([
      {
        id: '2',
        title: 'E',
        description: 'D',
        location: 'L',
        categoryId: null,
        startAt: '2026-11-01T10:00:00Z',
        endAt: '2026-11-01T12:00:00Z',
        isPublished: true,
        isMembersOnly: false,
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-01T00:00:00Z',
      },
    ]);
  });
});
