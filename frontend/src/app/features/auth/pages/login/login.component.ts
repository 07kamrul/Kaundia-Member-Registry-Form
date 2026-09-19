import { Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AuthService } from '../../../../core/services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [RouterLink, ReactiveFormsModule, TranslatePipe],
  templateUrl: './login.component.html',
})
export class LoginComponent {
  form: FormGroup;
  error = '';
  submitting = false;
  submitAttempted = false;

  constructor(
    private fb: FormBuilder,
    private auth: AuthService,
    private router: Router,
    private translate: TranslateService,
  ) {
    this.form = this.fb.group({
      identifier: ['', Validators.required],
      password: ['', Validators.required],
    });
  }

  showError(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.invalid && (control.touched || this.submitAttempted);
  }

  errorMessage(controlName: string): string {
    const messages: Record<string, string> = {
      identifier: this.translate.instant('auth.login.identifierRequiredError'),
      password: this.translate.instant('auth.login.passwordRequiredError'),
    };
    return messages[controlName] ?? '';
  }

  onSubmit(): void {
    this.submitAttempted = true;
    if (this.form.invalid) return;
    this.error = '';
    this.submitting = true;
    const { identifier, password } = this.form.value;
    this.auth.login(identifier, password).subscribe({
      next: (res) => {
        this.submitting = false;
        if (res.must_change_password) {
          this.router.navigate(['/change-password']);
        } else {
          this.router.navigate(['/dashboard']);
        }
      },
      error: () => {
        this.submitting = false;
        this.error = this.translate.instant('auth.login.loginFailedError');
      },
    });
  }
}
