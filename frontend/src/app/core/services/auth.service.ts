import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';

export type UserRole = 'admin' | 'member';

interface TokenResponse {
  access_token: string;
  refresh_token: string;
  must_change_password?: boolean;
  role: UserRole;
}

const ACCESS_TOKEN_KEY = 'krmf_access_token';
const REFRESH_TOKEN_KEY = 'krmf_refresh_token';
const ROLE_KEY = 'krmf_role';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private accessToken = signal<string | null>(localStorage.getItem(ACCESS_TOKEN_KEY));
  private refreshTokenValue = signal<string | null>(localStorage.getItem(REFRESH_TOKEN_KEY));
  private roleValue = signal<UserRole | null>(
    (localStorage.getItem(ROLE_KEY) as UserRole | null) ?? null,
  );

  readonly isAuthenticated = signal<boolean>(!!this.accessToken());

  constructor(
    private http: HttpClient,
    private router: Router,
  ) {}

  get token(): string | null {
    return this.accessToken();
  }

  get role(): UserRole | null {
    return this.roleValue();
  }

  login(identifier: string, password: string): Observable<TokenResponse> {
    return this.http
      .post<TokenResponse>(`${environment.apiBaseUrl}/login`, { identifier, password })
      .pipe(tap((res) => this.storeSession(res, res.role)));
  }

  private storeSession(res: TokenResponse, role: UserRole): void {
    this.accessToken.set(res.access_token);
    this.refreshTokenValue.set(res.refresh_token);
    this.roleValue.set(role);
    this.isAuthenticated.set(true);
    localStorage.setItem(ACCESS_TOKEN_KEY, res.access_token);
    localStorage.setItem(REFRESH_TOKEN_KEY, res.refresh_token);
    localStorage.setItem(ROLE_KEY, role);
  }

  logout(): void {
    this.accessToken.set(null);
    this.refreshTokenValue.set(null);
    this.roleValue.set(null);
    this.isAuthenticated.set(false);
    localStorage.removeItem(ACCESS_TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
    localStorage.removeItem(ROLE_KEY);
  }

  handleUnauthorized(): void {
    this.logout();
    this.router.navigate(['/login']);
  }
}
