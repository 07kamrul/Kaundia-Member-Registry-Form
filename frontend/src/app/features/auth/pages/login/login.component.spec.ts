import { TestBed, ComponentFixture } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { ActivatedRoute, Router, provideRouter } from '@angular/router';
import { provideTranslateService } from '@ngx-translate/core';
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
import { LoginComponent } from './login.component';
import { AuthService } from '../../../../core/services/auth.service';

describe('LoginComponent', () => {
  let navigate: ReturnType<typeof vi.fn>;
  let http: HttpTestingController;

  function create(queryParams: Record<string, string> = {}): ComponentFixture<LoginComponent> {
    Object.defineProperty(globalThis, 'localStorage', {
      value: new MemoryStorage(), configurable: true, writable: true,
    });
    navigate = vi.fn();
    TestBed.configureTestingModule({
      imports: [LoginComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        provideTranslateService(),
        provideRouter([]),
        { provide: Router, useValue: { navigate, navigateByUrl: navigate } },
        {
          provide: ActivatedRoute,
          useValue: { snapshot: { queryParamMap: { get: (k: string) => queryParams[k] ?? null } } },
        },
      ],
    });
    http = TestBed.inject(HttpTestingController);
    const fixture = TestBed.createComponent(LoginComponent);
    fixture.detectChanges();
    return fixture;
  }

  it('renders the identifier and password fields', () => {
    const fixture = create();
    const el: HTMLElement = fixture.nativeElement;
    expect(el.querySelector('input')).not.toBeNull();
  });

  it('does not call the API and marks submitAttempted when the form is empty', () => {
    const fixture = create();
    fixture.componentInstance.onSubmit();
    expect(fixture.componentInstance.submitAttempted).toBe(true);
    expect(fixture.componentInstance.submitting).toBe(false);
    http.expectNone((r) => r.url.endsWith('/login'));
  });

  it('submits trimmed lowercase credentials and routes to the returnUrl', () => {
    const fixture = create({ returnUrl: '/fee-settings' });
    fixture.componentInstance.form.patchValue({ identifier: '  Admin@Example.COM ', password: 'pw' });
    fixture.componentInstance.onSubmit();
    expect(fixture.componentInstance.submitting).toBe(true);

    const req = http.expectOne((r) => r.url.endsWith('/login'));
    expect(req.request.body).toEqual({ identifier: 'admin@example.com', password: 'pw' });
    req.flush({
      access_token: 'a',
      refresh_token: 'r',
      must_change_password: false,
      role: 'administrator',
      permissions: [],
    });
    expect(navigate).toHaveBeenCalledWith('/fee-settings');
  });

  it('routes to /change-password when must_change_password is set', () => {
    const fixture = create();
    fixture.componentInstance.form.patchValue({ identifier: 'admin@example.com', password: 'pw' });
    fixture.componentInstance.onSubmit();
    http.expectOne((r) => r.url.endsWith('/login')).flush({
      access_token: 'a',
      refresh_token: 'r',
      must_change_password: true,
      role: 'administrator',
      permissions: [],
    });
    expect(navigate).toHaveBeenCalledWith(['/change-password']);
  });

  it('shows an error message on failed login', () => {
    const fixture = create();
    fixture.componentInstance.form.patchValue({ identifier: 'admin@example.com', password: 'bad' });
    fixture.componentInstance.onSubmit();
    http
      .expectOne((r) => r.url.endsWith('/login'))
      .flush('nope', { status: 401, statusText: 'Unauthorized' });
    expect(fixture.componentInstance.submitting).toBe(false);
    expect(fixture.componentInstance.error).not.toBe('');
  });
});
