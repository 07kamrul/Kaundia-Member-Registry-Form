import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { MemberService } from './member.service';

export type UserRole = 'super_admin' | 'executive_committee' | 'administrator' | 'member';

export type LandingTier = 'super_admin' | 'management' | 'member';

// Mirrors backend/app/core/permissions.py ROLE_DEFAULT_PERMISSIONS: these keys
// exist only in the Super Admin's full-catalog tuple, so holding any of them
// is a permission-based (not role-name) way to detect Super Admin tier.
export const SUPER_ADMIN_AREA_PERMISSIONS = ['manage_users', 'manage_roles', 'view_audit_log'];

// The single shared gate for everything fee-settings related (Fee Settings
// page/menu, "Go to Fee Settings" on the picnic payment page). Super Admin's
// full permission catalog includes it, so no role-name checks are needed.
export const FEE_MANAGER_PERMISSION = 'manage_fee_settings';

// The one shared gate for the member payment page (Picnic Fee): only roles
// that pay as members see it - in the sidebar, the route guard, and the
// backend's member payment endpoints (which 403 fee managers, see
// backend/app/api/routes/member.py). Management-tier roles configure fees in
// Fee Settings and review all payments under Picnic Payments instead.
export const MEMBER_PAYMENT_ROLES: readonly UserRole[] = ['member'];

// Union of EXECUTIVE_COMMITTEE + ADMINISTRATOR default tuples - holding any
// of these means "management tier or above" for area-guard/landing purposes.
export const MANAGEMENT_AREA_PERMISSIONS = [
  'member.view_all',
  'member.manage',
  'property.view_all',
  'property.review',
  'membership.review',
  'approve_membership',
  'complaint.view_all',
  'complaint.review',
  'manage_notices',
  'report.view',
  'manage_fee_settings',
  'manage_system_config',
  'member.register',
  'member.verify',
  'document.verify',
  'complaint.view_assigned',
  'complaint.process',
  'report.view_operational',
];

interface TokenResponse {
  access_token: string;
  refresh_token: string;
  must_change_password?: boolean;
  role: UserRole;
  permissions?: string[];
}

const ACCESS_TOKEN_KEY = 'krmf_access_token';
const REFRESH_TOKEN_KEY = 'krmf_refresh_token';
const ROLE_KEY = 'krmf_role';
const PERMISSIONS_KEY = 'krmf_permissions';

function readStoredPermissions(): string[] {
  try {
    const raw = localStorage.getItem(PERMISSIONS_KEY);
    return raw ? (JSON.parse(raw) as string[]) : [];
  } catch {
    return [];
  }
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private accessToken = signal<string | null>(localStorage.getItem(ACCESS_TOKEN_KEY));
  private refreshTokenValue = signal<string | null>(localStorage.getItem(REFRESH_TOKEN_KEY));
  private roleValue = signal<UserRole | null>(
    (localStorage.getItem(ROLE_KEY) as UserRole | null) ?? null,
  );
  private permissionsValue = signal<string[]>(readStoredPermissions());

  readonly isAuthenticated = signal<boolean>(!!this.accessToken());

  constructor(
    private http: HttpClient,
    private router: Router,
    private memberService: MemberService,
  ) {}

  get token(): string | null {
    return this.accessToken();
  }

  get role(): UserRole | null {
    return this.roleValue();
  }

  get permissions(): string[] {
    return this.permissionsValue();
  }

  landingTier(): LandingTier {
    if (this.hasAnyPermission(SUPER_ADMIN_AREA_PERMISSIONS)) return 'super_admin';
    if (this.hasAnyPermission(MANAGEMENT_AREA_PERMISSIONS)) return 'management';
    return 'member';
  }

  hasPermission(permissionKey: string): boolean {
    return this.permissionsValue().includes(permissionKey);
  }

  hasAnyPermission(permissionKeys: string[]): boolean {
    return permissionKeys.some((key) => this.hasPermission(key));
  }

  canPayAsMember(): boolean {
    const role = this.roleValue();
    return role !== null && MEMBER_PAYMENT_ROLES.includes(role);
  }

  login(identifier: string, password: string): Observable<TokenResponse> {
    return this.http
      .post<TokenResponse>(`${environment.apiBaseUrl}/login`, { identifier, password })
      .pipe(tap((res) => this.storeSession(res, res.role)));
  }

  private storeSession(res: TokenResponse, role: UserRole): void {
    const permissions = res.permissions ?? [];
    this.memberService.clearProfileCache();
    this.accessToken.set(res.access_token);
    this.refreshTokenValue.set(res.refresh_token);
    this.roleValue.set(role);
    this.permissionsValue.set(permissions);
    this.isAuthenticated.set(true);
    localStorage.setItem(ACCESS_TOKEN_KEY, res.access_token);
    localStorage.setItem(REFRESH_TOKEN_KEY, res.refresh_token);
    localStorage.setItem(ROLE_KEY, role);
    localStorage.setItem(PERMISSIONS_KEY, JSON.stringify(permissions));
  }

  logout(): void {
    this.memberService.clearProfileCache();
    this.accessToken.set(null);
    this.refreshTokenValue.set(null);
    this.roleValue.set(null);
    this.permissionsValue.set([]);
    this.isAuthenticated.set(false);
    localStorage.removeItem(ACCESS_TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
    localStorage.removeItem(ROLE_KEY);
    localStorage.removeItem(PERMISSIONS_KEY);
  }

  handleUnauthorized(): void {
    this.logout();
    this.router.navigate(['/login']);
  }
}
