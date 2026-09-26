import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { MemberService } from './member.service';

export type UserRole = 'super_admin' | 'executive_committee' | 'administrator' | 'member';

export const ADMIN_ROLES: UserRole[] = ['super_admin', 'executive_committee', 'administrator'];

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

  get isAdmin(): boolean {
    const role = this.roleValue();
    return role !== null && ADMIN_ROLES.includes(role);
  }

  hasPermission(permissionKey: string): boolean {
    return this.permissionsValue().includes(permissionKey);
  }

  hasAnyPermission(permissionKeys: string[]): boolean {
    return permissionKeys.some((key) => this.hasPermission(key));
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
