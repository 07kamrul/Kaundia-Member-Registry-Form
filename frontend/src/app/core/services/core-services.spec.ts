import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { RbacService } from './rbac.service';
import { PublicStatsService } from './public-stats.service';
import { LanguageService } from './language.service';
import { ThemeService } from './theme.service';
import { TranslateService } from '@ngx-translate/core';

import { vi } from 'vitest';

class MemoryStorage {
  private readonly entries = new Map<string, string>();
  get length(): number { return this.entries.size; }
  clear(): void { this.entries.clear(); }
  getItem(key: string): string | null { return this.entries.get(key) ?? null; }
  key(index: number): string | null { return [...this.entries.keys()][index] ?? null; }
  removeItem(key: string): void { this.entries.delete(key); }
  setItem(key: string, value: string): void { this.entries.set(key, String(value)); }
}

function installMemoryStorage(): void {
  Object.defineProperty(globalThis, 'localStorage', {
    value: new MemoryStorage(), configurable: true, writable: true,
  });
}

describe('RbacService', () => {
  let http: HttpTestingController;
  let service: RbacService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    http = TestBed.inject(HttpTestingController);
    service = TestBed.inject(RbacService);
  });
  afterEach(() => http.verify());

  it('listPermissions/listRoles hit the rbac base', () => {
    let perms: unknown[] = [];
    let roles: unknown[] = [];
    service.listPermissions().subscribe((r) => (perms = r));
    service.listRoles().subscribe((r) => (roles = r));
    http.expectOne((r) => r.url.endsWith('/admin/rbac/permissions')).flush([]);
    http.expectOne((r) => r.url.endsWith('/admin/rbac/roles')).flush([]);
    expect(perms).toEqual([]);
    expect(roles).toEqual([]);
  });

  it('updateRolePermissions sends permission_keys', () => {
    let body: unknown;
    service.updateRolePermissions(3, ['a', 'b']).subscribe((r) => (body = r));
    const req = http.expectOne((r) => r.url.endsWith('/admin/rbac/roles/3/permissions'));
    expect(req.request.method).toBe('PUT');
    expect(req.request.body).toEqual({ permission_keys: ['a', 'b'] });
    req.flush({});
    expect(body).toEqual({});
  });

  it('listUserOverrides and setUserOverrides target the user id', () => {
    let got: unknown;
    service.listUserOverrides(7).subscribe((r) => (got = r));
    http.expectOne((r) => r.url.endsWith('/admin/rbac/users/7/overrides')).flush([
      { permission_key: 'x', granted: true },
    ]);
    expect(got).toEqual([{ permission_key: 'x', granted: true }]);

    let put: unknown;
    service.setUserOverrides(7, [{ permission_key: 'x', granted: false }]).subscribe((r) => (put = r));
    const req = http.expectOne((r) => r.url.endsWith('/admin/rbac/users/7/overrides'));
    expect(req.request.method).toBe('PUT');
    req.flush([]);
    expect(put).toEqual([]);
  });

  it('createUser posts and updateUserRole patches with snake_case role_id', () => {
    let created: unknown;
    service
      .createUser({ name: 'N', email: 'n@e.com', password: 'p', role: 'administrator', role_id: null })
      .subscribe((r) => (created = r));
    const post = http.expectOne((r) => r.url.endsWith('/admin/rbac/users'));
    expect(post.request.method).toBe('POST');
    post.flush({ id: 1 });
    expect(created).toEqual({ id: 1 });

    let patched: unknown;
    service.updateUserRole(1, 'administrator', 4).subscribe((r) => (patched = r));
    const patch = http.expectOne((r) => r.url.endsWith('/admin/rbac/users/1/role'));
    expect(patch.request.method).toBe('PATCH');
    expect(patch.request.body).toEqual({ role: 'administrator', role_id: 4 });
    patch.flush({});
    expect(patched).toEqual({});
  });
});

describe('PublicStatsService', () => {
  let http: HttpTestingController;
  let service: PublicStatsService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    http = TestBed.inject(HttpTestingController);
    service = TestBed.inject(PublicStatsService);
  });
  afterEach(() => http.verify());

  it('maps snake_case stats to camelCase', () => {
    let stats: unknown;
    service.getStats().subscribe((s) => (stats = s));
    http.expectOne((r) => r.url.endsWith('/public/stats')).flush({
      pending_count: 2,
      approved_count: 10,
      monthly_subscription_total: 1234.5,
    });
    expect(stats).toEqual({
      pendingCount: 2,
      approvedCount: 10,
      monthlySubscriptionTotal: 1234.5,
    });
  });
});

describe('LanguageService', () => {
  let translate: { addLangs: ReturnType<typeof vi.fn>; use: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    installMemoryStorage();
    translate = {
      addLangs: vi.fn(),
      use: vi.fn(),
    };
    TestBed.configureTestingModule({
      providers: [{ provide: TranslateService, useValue: translate }],
    });
  });

  it('defaults to Bangla and applies it to the TranslateService', () => {
    const service = TestBed.inject(LanguageService);
    expect(service.lang()).toBe('bn');
    expect(translate.use).toHaveBeenCalledWith('bn');
  });

  it('toggle switches bn<->en and persists the choice', () => {
    const service = TestBed.inject(LanguageService);
    service.toggle();
    expect(service.lang()).toBe('en');
    expect(localStorage.getItem('krmf_lang')).toBe('en');
    service.toggle();
    expect(service.lang()).toBe('bn');
    expect(localStorage.getItem('krmf_lang')).toBe('bn');
  });

  it('setLang writes through', () => {
    const service = TestBed.inject(LanguageService);
    service.setLang('en');
    expect(service.lang()).toBe('en');
    expect(translate.use).toHaveBeenCalledWith('en');
  });
});

describe('ThemeService', () => {
  beforeEach(() => {
    installMemoryStorage();
    document.documentElement.removeAttribute('data-theme');
    window.matchMedia = window.matchMedia || (() => ({ matches: false } as MediaQueryList));
  });

  it('applies the stored theme attribute and toggles', () => {
    localStorage.setItem('krmf_theme', 'dark');
    const service = TestBed.inject(ThemeService);
    expect(service.theme()).toBe('dark');
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');

    service.toggle();
    expect(service.theme()).toBe('light');
    expect(document.documentElement.getAttribute('data-theme')).toBe('light');
    expect(localStorage.getItem('krmf_theme')).toBe('light');
  });
});
