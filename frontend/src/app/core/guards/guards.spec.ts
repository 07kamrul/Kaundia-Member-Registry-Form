import { TestBed } from '@angular/core/testing';
import { provideRouter, Router } from '@angular/router';
import { authGuard } from './auth.guard';
import { permissionGuard } from './permission.guard';
import { roleGuard } from './role.guard';
import { AuthService, FEE_MANAGER_PERMISSION } from '../services/auth.service';

type UserRole = 'super_admin' | 'executive_committee' | 'administrator' | 'member';

function fakeAuth(options: {
  token?: string | null;
  permissions?: string[];
  role?: UserRole | null;
}): AuthService {
  const permissions = options.permissions ?? [];
  return {
    get token() {
      return options.token ?? null;
    },
    get role() {
      return options.role ?? null;
    },
    hasPermission: (key: string) => permissions.includes(key),
    hasAnyPermission: (keys: string[]) => keys.some((key) => permissions.includes(key)),
  } as unknown as AuthService;
}

const route = {} as never;
const state = { url: '/members' } as never;

function setup(auth: AuthService) {
  TestBed.configureTestingModule({
    providers: [provideRouter([]), { provide: AuthService, useValue: auth }],
  });
  return TestBed.inject(Router);
}

describe('authGuard', () => {
  it('redirects an unauthenticated visitor to /login with returnUrl set', () => {
    const router = setup(fakeAuth({}));
    const tree = TestBed.runInInjectionContext(() => authGuard(route, state));
    expect(router.serializeUrl(tree as never)).toBe('/login?returnUrl=%2Fmembers');
  });

  it('passes through an authenticated user', () => {
    const router = setup(fakeAuth({ token: 'tok', permissions: [] }));
    const result = TestBed.runInInjectionContext(() => authGuard(route, state));
    expect(result).toBe(true);
    expect(router.url).toBe('/');
  });
});

describe('permissionGuard', () => {
  it('redirects to /login when no token exists, even with permissions stored', () => {
    const router = setup(fakeAuth({ permissions: ['member.view_all'] }));
    const tree = TestBed.runInInjectionContext(() => permissionGuard(['member.view_all'])(route, state));
    expect(router.serializeUrl(tree as never)).toBe('/login?returnUrl=%2Fmembers');
  });

  it('redirects to /403 (not /dashboard or /login) when the permission is missing', () => {
    const router = setup(fakeAuth({ token: 'tok', permissions: ['notice.view'] }));
    const tree = TestBed.runInInjectionContext(() =>
      permissionGuard(['member.view_all'])(route, state),
    );
    expect(router.serializeUrl(tree as never)).toBe('/403');
  });

  it('passes through when any of the required permissions is held', () => {
    setup(fakeAuth({ token: 'tok', permissions: ['member.view_all'] }));
    const result = TestBed.runInInjectionContext(() =>
      permissionGuard(['member.view_all', 'member.manage'])(route, state),
    );
    expect(result).toBe(true);
  });
});

describe('roleGuard (area guards)', () => {
  it('member area: passes a member role through', () => {
    setup(fakeAuth({ token: 'tok', role: 'member', permissions: [] }));
    const result = TestBed.runInInjectionContext(() => roleGuard(['member'])(route, state));
    expect(result).toBe(true);
  });

  it('member area: sends management tier to the dashboard, not the member area', () => {
    const router = setup(
      fakeAuth({ token: 'tok', role: 'executive_committee', permissions: ['member.view_all'] }),
    );
    const tree = TestBed.runInInjectionContext(() => roleGuard(['member'])(route, state));
    expect(router.serializeUrl(tree as never)).toBe('/dashboard');
  });

  it('management area: passes executive committee through', () => {
    setup(fakeAuth({ token: 'tok', role: 'executive_committee', permissions: [] }));
    const result = TestBed.runInInjectionContext(() =>
      roleGuard(['executive_committee', 'administrator', 'super_admin'])(route, state),
    );
    expect(result).toBe(true);
  });

  it('management area: sends a member to the dashboard', () => {
    const router = setup(fakeAuth({ token: 'tok', role: 'member', permissions: [] }));
    const tree = TestBed.runInInjectionContext(() =>
      roleGuard(['executive_committee', 'administrator', 'super_admin'])(route, state),
    );
    expect(router.serializeUrl(tree as never)).toBe('/dashboard');
  });

  it('super-admin area: passes super_admin through', () => {
    setup(fakeAuth({ token: 'tok', role: 'super_admin', permissions: [] }));
    const result = TestBed.runInInjectionContext(() => roleGuard(['super_admin'])(route, state));
    expect(result).toBe(true);
  });

  it('super-admin area: sends other management roles to the dashboard', () => {
    const router = setup(fakeAuth({ token: 'tok', role: 'administrator', permissions: [] }));
    const tree = TestBed.runInInjectionContext(() => roleGuard(['super_admin'])(route, state));
    expect(router.serializeUrl(tree as never)).toBe('/dashboard');
  });

  it('a fee manager without the allowed role lands on /fee-settings, not /dashboard or /403', () => {
    const router = setup(
      fakeAuth({
        token: 'tok',
        role: 'administrator',
        permissions: [FEE_MANAGER_PERMISSION],
      }),
    );
    const tree = TestBed.runInInjectionContext(() => roleGuard(['super_admin'])(route, state));
    expect(router.serializeUrl(tree as never)).toBe('/fee-settings');
  });
});
