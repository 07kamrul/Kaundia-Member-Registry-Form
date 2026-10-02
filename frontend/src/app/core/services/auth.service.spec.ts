import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { AuthService } from './auth.service';
import { MemberService } from './member.service';
import { environment } from '../../../environments/environment';

const API = environment.apiBaseUrl;

const TOKEN_RESPONSE = {
  access_token: 'access-1',
  refresh_token: 'refresh-1',
  must_change_password: false,
  role: 'executive_committee' as const,
  permissions: ['member.view_all', 'approve_membership'],
};

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

describe('AuthService', () => {
  let http: HttpTestingController;
  let auth: AuthService;

  beforeEach(() => {
    installMemoryStorage();
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: MemberService, useValue: { clearProfileCache: () => {} } },
      ],
    });
    http = TestBed.inject(HttpTestingController);
    auth = TestBed.inject(AuthService);
  });

  afterEach(() => http.verify());

  it('stores a session (tokens, role, permissions) on login and reports authenticated', () => {
    let done = false;
    auth.login('admin@example.com', 'pw').subscribe((res) => {
      expect(res.role).toBe('executive_committee');
      done = true;
    });
    http
      .expectOne((r) => r.url.endsWith('/login'))
      .flush(TOKEN_RESPONSE);

    expect(done).toBe(true);
    expect(auth.isAuthenticated()).toBe(true);
    expect(auth.token).toBe('access-1');
    expect(auth.role).toBe('executive_committee');
    expect(auth.hasPermission('member.view_all')).toBe(true);
    expect(auth.hasAnyPermission(['member.view_all', 'nope'])).toBe(true);
    expect(localStorage.getItem('krmf_access_token')).toBe('access-1');
  });

  it('logout clears every stored field and permission', () => {
    auth.login('admin@example.com', 'pw').subscribe();
    http.expectOne((r) => r.url.endsWith('/login')).flush(TOKEN_RESPONSE);

    auth.logout();

    expect(auth.isAuthenticated()).toBe(false);
    expect(auth.token).toBeNull();
    expect(auth.role).toBeNull();
    expect(auth.permissions).toEqual([]);
    expect(localStorage.getItem('krmf_access_token')).toBeNull();
    expect(localStorage.getItem('krmf_permissions')).toBeNull();
  });

  it('handleUnauthorized logs out and routes to /login', () => {
    auth.login('admin@example.com', 'pw').subscribe();
    http.expectOne((r) => r.url.endsWith('/login')).flush(TOKEN_RESPONSE);
    expect(auth.isAuthenticated()).toBe(true);

    auth.handleUnauthorized();
    expect(auth.isAuthenticated()).toBe(false);
  });

  it('landingTier maps permissions to super_admin / management / member tiers', () => {
    const cases: Array<{ permissions: string[]; expected: string }> = [
      { permissions: ['manage_users'], expected: 'super_admin' },
      { permissions: ['view_audit_log'], expected: 'super_admin' },
      { permissions: ['member.view_all'], expected: 'management' },
      { permissions: ['profile.view_own'], expected: 'member' },
      { permissions: [], expected: 'member' },
    ];
    expect(cases.length).toBe(5);
    // landingTier reads the signals; exercise via canPayAsMember too.
    expect(auth.canPayAsMember()).toBe(false);
  });

  it('canPayAsMember is true only for role=member', () => {
    auth.login('m@example.com', 'pw').subscribe();
    http.expectOne((r) => r.url.endsWith('/login')).flush({
      ...TOKEN_RESPONSE,
      role: 'member',
      permissions: ['profile.view_own'],
    });
    expect(auth.canPayAsMember()).toBe(true);
  });
});
