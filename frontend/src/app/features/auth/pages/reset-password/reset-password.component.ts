import { ChangeDetectionStrategy, ChangeDetectorRef, Component, inject } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { PasswordFieldComponent } from '../../../../shared/password-field/password-field.component';
import { AuthService } from '../../../../core/services/auth.service';

@Component({
  selector: 'app-reset-password',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, ReactiveFormsModule, TranslatePipe, PasswordFieldComponent],
  templateUrl: './reset-password.component.html',
})
export class ResetPasswordComponent {
  token = '';
  tokenMissing = false;
  form: FormGroup;
  error = '';
  submitting = false;
  submitAttempted = false;
  resetDone = false;

  private readonly cdr = inject(ChangeDetectorRef);

  constructor(
    private fb: FormBuilder,
    private auth: AuthService,
    private route: ActivatedRoute,
    private translate: TranslateService,
  ) {
    this.token = this.route.snapshot.queryParamMap.get('token') ?? '';
    this.tokenMissing = this.token.trim().length === 0;
    this.form = this.fb.group(
      {
        newPassword: ['', Validators.required],
        confirmPassword: ['', Validators.required],
      },
      { validators: (group) =>
        group.value.newPassword !== group.value.confirmPassword
          ? { mismatch: true }
          : null,
      },
    );
  }

  showError(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.invalid && (control.touched || this.submitAttempted);
  }

  errorMessage(controlName: string): string {
    if (controlName === 'confirmPassword' && this.form.hasError('mismatch')) {
      return this.translate.instant('auth.resetPassword.mismatchError');
    }
    return this.translate.instant('auth.resetPassword.passwordRequiredError');
  }

  passwordHintVisible(): boolean {
    const control = this.form.get('newPassword');
    return !!control && control.invalid && (control.touched || this.submitAttempted);
  }

  onSubmit(): void {
    this.submitAttempted = true;
    if (this.form.invalid) return;
    this.error = '';
    this.submitting = true;
    this.auth.resetPassword(this.token, this.form.value.newPassword).subscribe({
      next: () => {
        this.submitting = false;
        this.resetDone = true;
        this.cdr.markForCheck();
      },
      error: (err) => {
        this.submitting = false;
        if (err?.status === 422) {
          this.error = this.translate.instant('auth.resetPassword.weakPasswordError');
        } else if (err?.status === 400) {
          this.error = this.translate.instant('auth.resetPassword.invalidTokenError');
        } else {
          this.error = this.translate.instant('auth.resetPassword.errors.resetFailed');
        }
        this.cdr.markForCheck();
      },
    });
  }
}
