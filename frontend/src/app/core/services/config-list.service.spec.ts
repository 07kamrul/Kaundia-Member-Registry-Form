import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ConfigListService } from './config-list.service';

const API_ROWS = [
  { id: 1, category: 'property_type', value: 'জমি', label: 'জমি', sort_order: 2, is_active: 1 },
  { id: 2, category: 'property_type', value: 'বাড়ি', label: 'বাড়ি', sort_order: 1, is_active: 0 },
];

const LIST_URL = (r: { url: string }) => r.url.endsWith('/public/config-lists/property_type');

describe('ConfigListService', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('getValues returns the raw values of whatever the public endpoint returns', () => {
    let values: string[] | undefined;
    TestBed.inject(ConfigListService)
      .getValues('property_type', ['fallback'])
      .subscribe((v) => (values = v));
    http.expectOne(LIST_URL).flush(API_ROWS);
    expect(values).toEqual(['জমি', 'বাড়ি']);
  });

  it('getItems maps snake_case API fields to camelCase and boolean-ises is_active', () => {
    let items: ReturnType<ConfigListService['getItems']> extends never ? never : any[] = [];
    TestBed.inject(ConfigListService)
      .getItems('property_type')
      .subscribe((rows) => (items = rows as never));
    http.expectOne(LIST_URL).flush(API_ROWS);
    expect(items[0]).toEqual({
      id: '1',
      category: 'property_type',
      value: 'জমি',
      label: 'জমি',
      sortOrder: 2,
      isActive: true,
    });
    expect(items[1]).toEqual({
      id: '2',
      category: 'property_type',
      value: 'বাড়ি',
      label: 'বাড়ি',
      sortOrder: 1,
      isActive: false,
    });
  });

  it('falls back to the provided defaults when the API is unreachable', () => {
    let values: string[] | undefined;
    TestBed.inject(ConfigListService)
      .getValues('property_type', ['fallback-a', 'fallback-b'])
      .subscribe((v) => (values = v));
    http.expectOne(LIST_URL).flush('error', { status: 500, statusText: 'Server Error' });
    expect(values).toEqual(['fallback-a', 'fallback-b']);
  });
});
