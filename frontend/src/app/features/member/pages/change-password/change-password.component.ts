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

function passwordsMatch(control: AbstractControl): ValidationErrors | null {
  const newPassword = control.get('newPassword')?.value;
  const confirmPassword = control.get('confirmPassword')?.value;
  return newPassword === confirmPassword ? null : { passwordMismatch: true };
}

@Component({
  selector: 'app-change-password',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, TranslatePipe],
  templateUrl: './change-password.component.html',
})
export class ChangePasswordComponent {
  form: FormGroup;
  error = '';
  success = false;
  submitting = false;

  private readonly cdr = inject(ChangeDetectorRef);

  constructor(
    private fb: FormBuilder,
    private memberService: MemberService,
    private router: Router,
    private translate: TranslateService,
  ) {
    this.form = this.fb.group(
      {
        oldPassword: ['', Validators.required],
        newPassword: ['', [Validators.required, Validators.minLength(6)]],
        confirmPassword: ['', Validators.required],
      },
      { validators: passwordsMatch },
    );
  }

  onSubmit(): void {
    if (this.form.invalid) return;
    this.error = '';
    this.submitting = true;
    const { oldPassword, newPassword } = this.form.value;
    this.memberService.changePassword(oldPassword, newPassword).subscribe({
      next: () => {
        this.submitting = false;
        this.success = true;
        setTimeout(() => this.router.navigate(['/dashboard']), 400);
        this.cdr.markForCheck();
      },
      error: () => {
        this.submitting = false;
        this.error = this.translate.instant('member.changePassword.changeFailedError');
        this.cdr.markForCheck();
      },
    });
  }
}
