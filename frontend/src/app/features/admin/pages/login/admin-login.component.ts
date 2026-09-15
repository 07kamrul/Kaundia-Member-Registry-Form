import { Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../../../core/services/auth.service';

@Component({
  selector: 'app-admin-login',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './admin-login.component.html',
})
export class AdminLoginComponent {
  form: FormGroup;
  error = '';
  submitting = false;

  constructor(
    private fb: FormBuilder,
    private auth: AuthService,
    private router: Router,
  ) {
    this.form = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', Validators.required],
    });
  }

  onSubmit(): void {
    if (this.form.invalid) return;
    this.error = '';
    this.submitting = true;
    const { email, password } = this.form.value;
    this.auth.adminLogin(email, password).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/admin/submissions']);
      },
      error: () => {
        this.submitting = false;
        this.error = 'লগইন ব্যর্থ হয়েছে। ইমেইল অথবা পাসওয়ার্ড সঠিক নয়।';
      },
    });
  }
}
