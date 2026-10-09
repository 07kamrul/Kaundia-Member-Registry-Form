import { HttpErrorResponse } from '@angular/common/http';
import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { provideTranslateService } from '@ngx-translate/core';
import { of, throwError } from 'rxjs';
import { MemberService } from '../../../../core/services/member.service';
import { ChangePasswordComponent } from './change-password.component';

class MemoryStorage {
  private readonly entries = new Map<string, string>();
  get length(): number { return this.entries.size; }
  clear(): void { this.entries.clear(); }
  getItem(key: string): string | null { return this.entries.get(key) ?? null; }
  key(index: number): string | null { return [...this.entries.keys()][index] ?? null; }
  removeItem(key: string): void { this.entries.delete(key); }
  setItem(key: string, value: string): void { this.entries.set(key, String(value)); }
}

describe('ChangePasswordComponent', () => {
  const changePassword = vi.fn();

  // The component builds the real AuthService, which reads localStorage at
  // construction; give this spec its own store instead of relying on another
  // spec having installed one first.
  beforeEach(() => {
    Object.defineProperty(globalThis, 'localStorage', {
      value: new MemoryStorage(), configurable: true, writable: true,
    });
  });

  function setup() {
    changePassword.mockReset();
    TestBed.configureTestingModule({
      imports: [ChangePasswordComponent],
      providers: [
        provideTranslateService(),
        { provide: MemberService, useValue: { changePassword } },
        { provide: Router, useValue: { navigate: vi.fn() } },
      ],
    });
    const fixture = TestBed.createComponent(ChangePasswordComponent);
    fixture.detectChanges();
    return fixture.componentInstance;
  }

  function fill(c: ChangePasswordComponent, current: string, next: string, confirm: string) {
    c.form.setValue({ currentPassword: current, newPassword: next, confirmPassword: confirm });
  }

  it('sends a valid change and shows the success state with cleared fields', () => {
    const c = setup();
    changePassword.mockReturnValue(of(undefined));
    fill(c, 'oldpass123', 'brandnew99', 'brandnew99');
    c.onSubmit();
    expect(changePassword).toHaveBeenCalledWith('oldpass123', 'brandnew99');
    expect(c.success).toBe(true);
    expect(c.form.value.newPassword).toBe('');
  });

  it('blocks a mismatched confirmation client-side', () => {
    const c = setup();
    fill(c, 'oldpass123', 'brandnew99', 'different99');
    c.onSubmit();
    expect(changePassword).not.toHaveBeenCalled();
    expect(c.form.hasError('passwordMismatch')).toBe(true);
    expect(c.fieldError('confirmPassword')).not.toBe('');
  });

  it('blocks a weak new password client-side', () => {
    const c = setup();
    fill(c, 'oldpass123', 'short1', 'short1');
    c.onSubmit();
    expect(changePassword).not.toHaveBeenCalled();
    expect(c.form.get('newPassword')?.hasError('passwordPolicy')).toBe(true);
  });

  it('blocks a new password equal to the current one', () => {
    const c = setup();
    fill(c, 'samepass123', 'samepass123', 'samepass123');
    c.onSubmit();
    expect(changePassword).not.toHaveBeenCalled();
    expect(c.form.hasError('sameAsCurrent')).toBe(true);
  });

  it('maps a 422 field error from the server onto the current password input', () => {
    const c = setup();
    changePassword.mockReturnValue(
      throwError(
        () =>
          new HttpErrorResponse({
            status: 422,
            error: {
              detail: {
                message: 'Current password is incorrect',
                errors: { current_password: 'Current password is incorrect' },
              },
            },
          }),
      ),
    );
    fill(c, 'wrongpass1', 'brandnew99', 'brandnew99');
    c.onSubmit();
    expect(c.fieldError('currentPassword')).toBe('Current password is incorrect');
    expect(c.error).toBe('');
  });

  it('falls back to the generic message for unexpected errors', () => {
    const c = setup();
    changePassword.mockReturnValue(throwError(() => new HttpErrorResponse({ status: 500 })));
    fill(c, 'oldpass123', 'brandnew99', 'brandnew99');
    c.onSubmit();
    expect(c.error).not.toBe('');
    expect(c.serverErrors).toEqual({});
  });
});
