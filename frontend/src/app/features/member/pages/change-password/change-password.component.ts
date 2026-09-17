import { Component } from '@angular/core';
import { AbstractControl, FormBuilder, FormGroup, ReactiveFormsModule, ValidationErrors, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { MemberService } from '../../../../core/services/member.service';

function passwordsMatch(control: AbstractControl): ValidationErrors | null {
  const newPassword = control.get('newPassword')?.value;
  const confirmPassword = control.get('confirmPassword')?.value;
  return newPassword === confirmPassword ? null : { passwordMismatch: true };
}

@Component({
  selector: 'app-change-password',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './change-password.component.html',
})
export class ChangePasswordComponent {
  form: FormGroup;
  error = '';
  success = false;
  submitting = false;

  constructor(
    private fb: FormBuilder,
    private memberService: MemberService,
    private router: Router,
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
        setTimeout(() => this.router.navigate(['/dashboard']), 1200);
      },
      error: () => {
        this.submitting = false;
        this.error = 'পাসওয়ার্ড পরিবর্তন ব্যর্থ হয়েছে।';
      },
    });
  }
}
