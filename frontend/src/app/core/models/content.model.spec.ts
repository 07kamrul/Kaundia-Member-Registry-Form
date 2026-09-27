import {
  toDatetimeLocal,
  toEventItem,
  toIso,
  toNotice,
  type EventApiModel,
  type NoticeApiModel,
} from './content.model';

describe('content model mappers', () => {
  it('maps a notice row to the view model', () => {
    const api: NoticeApiModel = {
      id: 7,
      title: 'Water supply off',
      body: 'No water on Friday.',
      category_id: 3,
      is_published: true,
      is_members_only: false,
      publish_at: '2026-09-01T06:00:00+00:00',
      created_by: 1,
      created_at: '2026-08-30T10:00:00+00:00',
      updated_at: '2026-08-30T10:00:00+00:00',
    };

    const notice = toNotice(api);
    expect(notice.id).toBe('7');
    expect(notice.categoryId).toBe('3');
    expect(notice.isPublished).toBe(true);
    expect(notice.isMembersOnly).toBe(false);
    expect(notice.publishAt).toBe('2026-09-01T06:00:00+00:00');
  });

  it('keeps a null category null instead of the string "null"', () => {
    const notice = toNotice({
      id: 1,
      title: 't',
      body: 'b',
      category_id: null,
      is_published: false,
      is_members_only: false,
      publish_at: null,
      created_by: null,
      created_at: '2026-01-01T00:00:00+00:00',
      updated_at: '2026-01-01T00:00:00+00:00',
    });
    expect(notice.categoryId).toBeNull();
    expect(notice.publishAt).toBeNull();
  });

  it('maps an event row to the view model', () => {
    const api: EventApiModel = {
      id: 12,
      title: 'AGM',
      description: 'Annual general meeting',
      location: 'Community hall',
      category_id: null,
      start_at: '2030-05-01T10:00:00+00:00',
      end_at: null,
      is_published: true,
      is_members_only: true,
      created_by: 2,
      created_at: '2026-01-01T00:00:00+00:00',
      updated_at: '2026-01-01T00:00:00+00:00',
    };

    const event = toEventItem(api);
    expect(event.id).toBe('12');
    expect(event.startAt).toBe('2030-05-01T10:00:00+00:00');
    expect(event.endAt).toBeNull();
    expect(event.isMembersOnly).toBe(true);
    expect(event.categoryId).toBeNull();
  });
});

describe('datetime-local <-> ISO conversion', () => {
  it('round-trips the wall-clock value the admin typed', () => {
    const typed = '2030-05-01T10:30';
    const iso = toIso(typed);

    expect(iso).toMatch(/^\d{4}-05-01T\d{2}:30:00(\.\d+)?Z$/);
    expect(toDatetimeLocal(iso)).toBe(typed);
  });

  it('treats an offset-less value as local time, not UTC', () => {
    // Guard against the naive-UTC interpretation: 10:30 local must not come
    // back as 10:30Z when the viewer's zone is not UTC.
    const typed = '2030-05-01T10:30';
    const iso = toIso(typed);
    const roundTrippedLocalHour = new Date(iso).getHours();
    expect(roundTrippedLocalHour).toBe(new Date(typed).getHours());
  });

  it('returns empty strings for missing or unparseable input', () => {
    expect(toIso('')).toBe('');
    expect(toIso('not-a-date')).toBe('');
    expect(toDatetimeLocal(null)).toBe('');
    expect(toDatetimeLocal(undefined)).toBe('');
    expect(toDatetimeLocal('not-a-date')).toBe('');
  });
});
