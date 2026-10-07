import { ChangeDetectionStrategy, ChangeDetectorRef, Component, inject } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AuthService } from '../../../../core/services/auth.service';

@Component({
  selector: 'app-forgot-password',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, ReactiveFormsModule, TranslatePipe],
  templateUrl: './forgot-password.component.html',
})
export class ForgotPasswordComponent {
  form: FormGroup;
  error = '';
  submitting = false;
  submitAttempted = false;
  sent = false;

  private readonly cdr = inject(ChangeDetectorRef);

  constructor(
    private fb: FormBuilder,
    private auth: AuthService,
    private translate: TranslateService,
  ) {
    this.form = this.fb.group({
      identifier: ['', Validators.required],
    });
  }

  showError(): boolean {
    const control = this.form.get('identifier');
    return !!control && control.invalid && (control.touched || this.submitAttempted);
  }

  onSubmit(): void {
    this.submitAttempted = true;
    if (this.form.invalid) return;
    this.error = '';
    this.submitting = true;
    this.auth.requestPasswordReset(this.form.value.identifier.trim().toLowerCase()).subscribe({
      next: () => {
        this.submitting = false;
        this.sent = true;
        this.cdr.markForCheck();
      },
      error: () => {
        this.submitting = false;
        this.error = this.translate.instant('auth.forgotPassword.errors.requestFailed');
        this.cdr.markForCheck();
      },
    });
  }
}
