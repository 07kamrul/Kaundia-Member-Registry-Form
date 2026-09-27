import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { provideTranslateService } from '@ngx-translate/core';
import { of } from 'rxjs';
import { vi } from 'vitest';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import type { Notice } from '../../../../core/models/content.model';
import { NoticesComponent } from './notices.component';

const publishedNotice: Notice = {
  id: '5',
  title: 'Water supply off',
  body: 'No water on Friday morning.',
  categoryId: '2',
  isPublished: true,
  isMembersOnly: false,
  publishAt: null,
  createdAt: '2026-09-01T06:00:00+00:00',
  updatedAt: '2026-09-01T06:00:00+00:00',
};

describe('NoticesComponent', () => {
  function setup(options: { canManage?: boolean } = {}) {
    const canManage = options.canManage ?? true;
    const listNotices = vi.fn(() => of([publishedNotice]));
    const listConfigListItems = vi.fn(() => of([]));
    const createNotice = vi.fn(() => of(publishedNotice));
    const updateNotice = vi.fn(() => of(publishedNotice));

    TestBed.configureTestingModule({
      imports: [NoticesComponent],
      providers: [
        provideRouter([]),
        provideTranslateService(),
        {
          provide: AdminService,
          useValue: {
            listNotices,
            listConfigListItems,
            createNotice,
            updateNotice,
            deleteNotice: vi.fn(() => of(undefined)),
          },
        },
        {
          provide: AuthService,
          useValue: { hasPermission: (key: string) => canManage && key === 'manage_notices' },
        },
      ],
    });

    const fixture = TestBed.createComponent(NoticesComponent);
    fixture.detectChanges();
    return { fixture, listNotices, createNotice, updateNotice };
  }

  it('loads the list on init without any filter', () => {
    const { fixture, listNotices } = setup();
    expect(listNotices).toHaveBeenCalledWith({ published: undefined, categoryId: undefined });
    expect(fixture.componentInstance.notices.length).toBe(1);
  });

  it('passes the draft/published and category filters to the API', () => {
    const { fixture, listNotices } = setup();
    listNotices.mockClear();

    fixture.componentInstance.setStatusFilter('draft');
    expect(listNotices).toHaveBeenLastCalledWith({ published: false, categoryId: undefined });

    fixture.componentInstance.categoryFilter = '9';
    fixture.componentInstance.onCategoryFilter();
    expect(listNotices).toHaveBeenLastCalledWith({ published: false, categoryId: '9' });

    fixture.componentInstance.setStatusFilter('published');
    expect(listNotices).toHaveBeenLastCalledWith({ published: true, categoryId: '9' });
  });

  it('classifies a notice as draft, scheduled or published', () => {
    const { fixture } = setup();
    const statusOf = (notice: Notice) => fixture.componentInstance.statusOf(notice);

    expect(statusOf({ ...publishedNotice, isPublished: false })).toBe('draft');
    expect(statusOf({ ...publishedNotice, publishAt: '2999-01-01T00:00:00+00:00' })).toBe(
      'scheduled',
    );
    expect(statusOf(publishedNotice)).toBe('published');
  });

  it('does not open the create form without manage_notices', () => {
    const { fixture } = setup({ canManage: false });
    fixture.componentInstance.openCreate();
    expect(fixture.componentInstance.formOpen).toBe(false);

    fixture.componentInstance.edit(publishedNotice);
    expect(fixture.componentInstance.formOpen).toBe(false);
  });

  it('creates a notice with the form values mapped to API fields', () => {
    const { fixture, createNotice } = setup();
    fixture.componentInstance.openCreate();
    expect(fixture.componentInstance.formOpen).toBe(true);

    fixture.componentInstance.formTitle = '  AGM notice  ';
    fixture.componentInstance.formBody = '  The AGM is on 5 May.  ';
    fixture.componentInstance.formPublished = true;
    fixture.componentInstance.save();

    expect(createNotice).toHaveBeenCalledWith({
      title: 'AGM notice',
      body: 'The AGM is on 5 May.',
      categoryId: null,
      isPublished: true,
      isMembersOnly: false,
      publishAt: null,
    });
    expect(fixture.componentInstance.formOpen).toBe(false);
  });

  it('toggles publication by sending the whole notice back', () => {
    const { fixture, updateNotice } = setup();
    fixture.componentInstance.togglePublished(publishedNotice);

    expect(updateNotice).toHaveBeenCalledWith('5', {
      title: publishedNotice.title,
      body: publishedNotice.body,
      categoryId: publishedNotice.categoryId,
      isPublished: false,
      isMembersOnly: publishedNotice.isMembersOnly,
      publishAt: publishedNotice.publishAt,
    });
  });
});
