import { Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../../../core/services/auth.service';

@Component({
  selector: 'app-member-login',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './member-login.component.html',
})
export class MemberLoginComponent {
  form: FormGroup;
  error = '';
  submitting = false;

  constructor(
    private fb: FormBuilder,
    private auth: AuthService,
    private router: Router,
  ) {
    this.form = this.fb.group({
      username: ['', Validators.required],
      password: ['', Validators.required],
    });
  }

  onSubmit(): void {
    if (this.form.invalid) return;
    this.error = '';
    this.submitting = true;
    const { username, password } = this.form.value;
    this.auth.memberLogin(username, password).subscribe({
      next: (res) => {
        this.submitting = false;
        if (res.must_change_password) {
          this.router.navigate(['/member/change-password']);
        } else {
          this.router.navigate(['/member/profile']);
        }
      },
      error: () => {
        this.submitting = false;
        this.error = 'লগইন ব্যর্থ হয়েছে। ইউজারনেম অথবা পাসওয়ার্ড সঠিক নয়।';
      },
    });
  }
}
