import { TestBed, ComponentFixture } from '@angular/core/testing';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { HttpClient, provideHttpClient, withInterceptors } from '@angular/common/http';
import { provideTranslateService } from '@ngx-translate/core';
import { authInterceptor } from '../core/interceptors/auth.interceptor';
import { AuthService } from '../core/services/auth.service';
import { ConfirmModalComponent } from './confirm-modal/confirm-modal.component';
import { TimePickerComponent } from './time-picker/time-picker.component';
import { monthNameKey } from './constants/months';

describe('authInterceptor', () => {
  function setup(token: string | null) {
    const handled: string[] = [];
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withInterceptors([authInterceptor])),
        provideHttpClientTesting(),
        {
          provide: AuthService,
          useValue: { token, handleUnauthorized: () => handled.push('unauth') },
        },
      ],
    });
    return {
      handled,
      client: TestBed.inject(HttpClient),
      http: TestBed.inject(HttpTestingController),
    };
  }

  it('attaches the Bearer token when authenticated', () => {
    const { handled, client, http } = setup('tok-1');
    let result: unknown;
    client.get('/data/x').subscribe((r) => (result = r));
    const req = http.expectOne('/data/x');
    expect(req.request.headers.get('Authorization')).toBe('Bearer tok-1');
    req.flush({});
    expect(result).toEqual({});
    expect(handled).toEqual([]);
  });

  it('sends no Authorization header when logged out, and logs out on 401', () => {
    const { handled, client, http } = setup(null);
    const errors: unknown[] = [];
    client.get('/data/x').subscribe({ error: (e: unknown) => errors.push(e) });
    const req = http.expectOne('/data/x');
    expect(req.request.headers.get('Authorization')).toBeNull();
    req.flush('gone', { status: 401, statusText: 'Unauthorized' });
    expect(errors.length).toBe(1);
    expect(handled).toEqual(['unauth']);
  });

  it('does not treat a 500 as a logout', () => {
    const { handled, client, http } = setup('tok-1');
    const errors: unknown[] = [];
    client.get('/data/x').subscribe({ error: (e: unknown) => errors.push(e) });
    http.expectOne('/data/x').flush('boom', { status: 500, statusText: 'Server Error' });
    expect(errors.length).toBe(1);
    expect(handled).toEqual([]);
  });
});

describe('monthNameKey', () => {
  it('maps 1-12 to keys and falls back for out-of-range values', () => {
    expect(monthNameKey(1)).toBe('common.months.january');
    expect(monthNameKey(6)).toBe('common.months.june');
    expect(monthNameKey(12)).toBe('common.months.december');
    expect(monthNameKey(0)).toBe(''); // MONTH_KEYS[0] is a placeholder for 1-indexing
    expect(monthNameKey(13)).toBe('13');
  });
});

describe('ConfirmModalComponent', () => {
  function create(): ComponentFixture<ConfirmModalComponent> {
    TestBed.configureTestingModule({ providers: [provideTranslateService()] });
    const fixture = TestBed.createComponent(ConfirmModalComponent);
    fixture.detectChanges();
    return fixture;
  }

  it('renders nothing while closed and the full card when open', () => {
    const fixture = create();
    expect(fixture.nativeElement.querySelector('.modal-backdrop')).toBeNull();
    fixture.componentRef.setInput('open', true);
    fixture.componentRef.setInput('title', 'T');
    fixture.componentRef.setInput('message', 'M');
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('.modal-backdrop')).not.toBeNull();
    expect(fixture.nativeElement.textContent).toContain('T');
    expect(fixture.nativeElement.textContent).toContain('M');
  });

  it('hides the cancel button when showCancel is false and marks danger', () => {
    const fixture = create();
    fixture.componentRef.setInput('open', true);
    fixture.componentRef.setInput('showCancel', false);
    fixture.componentRef.setInput('danger', true);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('.btn-secondary')).toBeNull();
    expect(fixture.nativeElement.querySelector('.btn-danger')).not.toBeNull();
  });

  it('disables the confirm button while loading or confirmDisabled', () => {
    const fixture = create();
    fixture.componentRef.setInput('open', true);
    fixture.componentRef.setInput('loading', true);
    fixture.detectChanges();
    const buttons: HTMLButtonElement[] = Array.from(fixture.nativeElement.querySelectorAll('button'));
    expect(buttons.every((b) => b.disabled)).toBe(true);
  });

  it('emits confirm/cancel; only a true backdrop click cancels', () => {
    const fixture = create();
    fixture.componentRef.setInput('open', true);
    fixture.detectChanges();
    const events: string[] = [];
    fixture.componentInstance.confirm.subscribe(() => events.push('confirm'));
    fixture.componentInstance.cancel.subscribe(() => events.push('cancel'));

    const confirmBtn = fixture.nativeElement.querySelector('.modal-actions button:last-child');
    confirmBtn.click();
    expect(events).toEqual(['confirm']);

    // A click on the backdrop itself (target === currentTarget) cancels.
    const backdrop = fixture.nativeElement.querySelector('.modal-backdrop');
    backdrop.dispatchEvent(new MouseEvent('click'));
    expect(events).toEqual(['confirm', 'cancel']);
  });
});

describe('TimePickerComponent', () => {
  function create(): ComponentFixture<TimePickerComponent> {
    TestBed.configureTestingModule({});
    return TestBed.createComponent(TimePickerComponent);
  }

  it('formats HH:mm for display and returns "" for empty/invalid values', () => {
    const fixture = create();
    const c = fixture.componentInstance;
    c.value = '15:30';
    expect(c.displayValue).toMatch(/03:30|15:30/);
    c.value = '';
    expect(c.displayValue).toBe('');
    c.value = 'xx:yy';
    expect(c.displayValue).toBe('');
  });

  it('emits the raw native value on change', () => {
    const fixture = create();
    const emitted: string[] = [];
    fixture.componentInstance.valueChange.subscribe((v: string) => emitted.push(v));
    fixture.componentInstance.onNativeChange({ target: { value: '09:05' } } as never);
    expect(emitted).toEqual(['09:05']);
  });
});
