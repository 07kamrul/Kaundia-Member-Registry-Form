import { HttpErrorResponse } from '@angular/common/http';
import { Component, ChangeDetectionStrategy, ChangeDetectorRef, inject } from '@angular/core';
import {
  AbstractControl,
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  ValidationErrors,
  Validators,
} from '@angular/forms';
import { Router } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { MemberService } from '../../../../core/services/member.service';
import { AuthService } from '../../../../core/services/auth.service';
import { PasswordFieldComponent } from '../../../../shared/password-field/password-field.component';

export const MIN_PASSWORD_LENGTH = 8;
const REDIRECT_DELAY_MS = 1500;

export function passwordPolicy(control: AbstractControl): ValidationErrors | null {
  const value: string = control.value ?? '';
  if (!value) return null; // `required` reports the empty case
  return value.length >= MIN_PASSWORD_LENGTH && /\d/.test(value) ? null : { passwordPolicy: true };
}

export function passwordGroupValidator(group: AbstractControl): ValidationErrors | null {
  const current = group.get('currentPassword')?.value;
  const next = group.get('newPassword')?.value;
  const confirm = group.get('confirmPassword')?.value;
  const errors: ValidationErrors = {};
  if (next !== confirm) errors['passwordMismatch'] = true;
  if (next && next === current) errors['sameAsCurrent'] = true;
  return Object.keys(errors).length ? errors : null;
}

/** Maps the backend's `detail.errors` ({field: message}) to form control names. */
const SERVER_FIELD_TO_CONTROL: Record<string, string> = {
  current_password: 'currentPassword',
  new_password: 'newPassword',
};

export function extractServerErrors(err: unknown): { fields: Record<string, string>; message: string } | null {
  if (!(err instanceof HttpErrorResponse) || err.status !== 422) return null;
  const detail = err.error?.detail;
  const raw: Record<string, string> | undefined = detail?.errors;
  if (!raw) return null;
  const fields: Record<string, string> = {};
  for (const [field, message] of Object.entries(raw)) {
    const control = SERVER_FIELD_TO_CONTROL[field];
    if (control) fields[control] = message;
  }
  return Object.keys(fields).length ? { fields, message: detail.message ?? '' } : null;
}

@Component({
  selector: 'app-change-password',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, TranslatePipe, PasswordFieldComponent],
  templateUrl: './change-password.component.html',
})
export class ChangePasswordComponent {
  form: FormGroup;
  error = '';
  serverErrors: Record<string, string> = {};
  success = false;
  submitting = false;
  submitAttempted = false;

  private readonly cdr = inject(ChangeDetectorRef);

  constructor(
    private fb: FormBuilder,
    private memberService: MemberService,
    private router: Router,
    private translate: TranslateService,
    private auth: AuthService,
  ) {
    this.form = this.fb.group(
      {
        currentPassword: ['', Validators.required],
        newPassword: ['', [Validators.required, passwordPolicy]],
        confirmPassword: ['', Validators.required],
      },
      { validators: passwordGroupValidator },
    );
    this.form.valueChanges.subscribe(() => {
      if (Object.keys(this.serverErrors).length) this.serverErrors = {};
    });
  }

  /** First applicable message for a control, or '' when none should be shown yet. */
  fieldError(name: 'currentPassword' | 'newPassword' | 'confirmPassword'): string {
    const control = this.form.get(name);
    if (!control) return '';
    const serverMessage = this.serverErrors[name];
    if (serverMessage) return serverMessage;
    if (!(control.touched || this.submitAttempted)) return '';
    const t = (key: string) => this.translate.instant(`member.changePassword.${key}`);
    if (name === 'currentPassword' && control.hasError('required')) return t('currentPasswordRequiredError');
    if (name === 'newPassword') {
      if (control.hasError('required') || control.hasError('passwordPolicy')) return t('passwordPolicyError');
      if (this.form.hasError('sameAsCurrent')) return t('sameAsCurrentError');
    }
    if (name === 'confirmPassword' && (control.hasError('required') || this.form.hasError('passwordMismatch'))) {
      return t('passwordMismatchError');
    }
    return '';
  }

  onSubmit(): void {
    this.submitAttempted = true;
    if (this.form.invalid) {
      this.cdr.markForCheck();
      return;
    }
    this.error = '';
    this.serverErrors = {};
    this.submitting = true;
    const { currentPassword, newPassword } = this.form.value;
    this.memberService.changePassword(currentPassword, newPassword).subscribe({
      next: () => {
        this.submitting = false;
        this.success = true;
        this.auth.markPasswordChanged();
        this.form.reset({ currentPassword: '', newPassword: '', confirmPassword: '' });
        setTimeout(() => this.router.navigate(['/dashboard']), REDIRECT_DELAY_MS);
        this.cdr.markForCheck();
      },
      error: (err: unknown) => {
        this.submitting = false;
        const server = extractServerErrors(err);
        if (server) {
          this.serverErrors = server.fields;
        } else {
          this.error = this.translate.instant('member.changePassword.changeFailedError');
        }
        this.cdr.markForCheck();
      },
    });
  }
}
