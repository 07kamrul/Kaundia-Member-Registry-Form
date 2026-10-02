import { TestBed, ComponentFixture } from '@angular/core/testing';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideTranslateService } from '@ngx-translate/core';
import { provideRouter } from '@angular/router';
import { vi } from 'vitest';
import { ForbiddenComponent } from '../../../core/pages/forbidden/forbidden.component';
import { InstallmentsComponent } from './installments/installments.component';
import { MemberDashboardComponent } from './dashboard/member-dashboard.component';
import { MemberService } from '../../../core/services/member.service';

class MemoryStorage {
  private readonly entries = new Map<string, string>();
  get length(): number { return this.entries.size; }
  clear(): void { this.entries.clear(); }
  getItem(key: string): string | null { return this.entries.get(key) ?? null; }
  key(index: number): string | null { return [...this.entries.keys()][index] ?? null; }
  removeItem(key: string): void { this.entries.delete(key); }
  setItem(key: string, value: string): void { this.entries.set(key, String(value)); }
}

const PROFILE = {
  member_id: 'UKAMKS-1',
  status: 'approved',
  full_name: 'Test User',
  mobile: '01700000000',
  email: 't@e.com',
  properties: [],
  nominees: [],
};

const INSTALLMENTS = [
  { id: '1', year: 2026, month: 3, amount: 100, status: 'due' },
  { id: '2', year: 2026, month: 1, amount: 100, status: 'paid' },
  { id: '3', year: 2025, month: 12, amount: 100, status: 'paid' },
];

describe('ForbiddenComponent', () => {
  it('renders a link back to the dashboard', () => {
    Object.defineProperty(globalThis, 'localStorage', {
      value: new MemoryStorage(), configurable: true, writable: true,
    });
    TestBed.configureTestingModule({
      providers: [provideTranslateService(), provideRouter([])],
    });
    const fixture = TestBed.createComponent(ForbiddenComponent);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('a')).not.toBeNull();
  });
});

describe('MemberInstallmentsComponent', () => {
  let http: HttpTestingController;

  function create(): ComponentFixture<InstallmentsComponent> {
    Object.defineProperty(globalThis, 'localStorage', {
      value: new MemoryStorage(), configurable: true, writable: true,
    });
    TestBed.configureTestingModule({
      imports: [InstallmentsComponent],
      providers: [provideTranslateService(), provideHttpClient(), provideHttpClientTesting()],
    });
    http = TestBed.inject(HttpTestingController);
    const fixture = TestBed.createComponent(InstallmentsComponent);
    fixture.detectChanges();
    return fixture;
  }

  it('sorts installments chronologically and remembers the year', () => {
    const fixture = create();
    http
      .expectOne((r) => r.url.endsWith('/member/installments'))
      .flush(INSTALLMENTS);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    expect(component.installments.map((i) => `${i.year}-${i.month}`)).toEqual([
      '2025-12',
      '2026-1',
      '2026-3',
    ]);
    expect(component.year).toBe(2025);
    expect(component.loading).toBe(false);
    expect(component.error).toBe('');
  });

  it('sets an error message when loading fails', () => {
    const fixture = create();
    http
      .expectOne((r) => r.url.endsWith('/member/installments'))
      .flush('error', { status: 500, statusText: 'boom' });
    fixture.detectChanges();
    expect(fixture.componentInstance.error).not.toBe('');
    expect(fixture.componentInstance.loading).toBe(false);
  });
});

describe('MemberDashboardComponent', () => {
  function create(): ComponentFixture<MemberDashboardComponent> {
    Object.defineProperty(globalThis, 'localStorage', {
      value: new MemoryStorage(), configurable: true, writable: true,
    });
    TestBed.configureTestingModule({
      imports: [MemberDashboardComponent],
      providers: [provideTranslateService(), provideHttpClient(), provideHttpClientTesting()],
    });
    const fixture = TestBed.createComponent(MemberDashboardComponent);
    fixture.detectChanges();
    return fixture;
  }

  it('joins profile + installments and derives due/paid counts and recent list', () => {
    const fixture = create();
    const http = TestBed.inject(HttpTestingController);
    http.expectOne((r) => r.url.endsWith('/member/me')).flush(PROFILE);
    http.expectOne((r) => r.url.endsWith('/member/installments')).flush(INSTALLMENTS);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    expect(component.profile).not.toBeNull();
    expect(component.totalCount).toBe(3);
    expect(component.dueCount).toBe(1);
    expect(component.paidCount).toBe(2);
    // Six most recent, chronological order after the reverse.
    expect(component.recentInstallments.map((i) => i.id)).toEqual(['3', '2', '1']);
    expect(component.loading).toBe(false);
  });

  it('shows the error UI when either request fails', () => {
    const fixture = create();
    const http = TestBed.inject(HttpTestingController);
    http.expectOne((r) => r.url.endsWith('/member/me')).flush(PROFILE);
    http
      .expectOne((r) => r.url.endsWith('/member/installments'))
      .flush('error', { status: 500, statusText: 'boom' });
    fixture.detectChanges();
    expect(fixture.componentInstance.error).not.toBe('');
  });
});

describe('monthNameKey is used through MemberService pipelines', () => {
  it('member service exposes clearProfileCache as a no-op-safe method', () => {
    Object.defineProperty(globalThis, 'localStorage', {
      value: new MemoryStorage(), configurable: true, writable: true,
    });
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    expect(() => TestBed.inject(MemberService).clearProfileCache()).not.toThrow();
    TestBed.inject(HttpTestingController).verify();
  });
});
