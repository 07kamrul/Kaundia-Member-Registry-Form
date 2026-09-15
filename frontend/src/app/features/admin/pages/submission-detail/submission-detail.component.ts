import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { JsonPipe } from '@angular/common';
import { AdminService } from '../../../../core/services/admin.service';
import type { SubmissionDetail } from '../../../../core/models/admin.model';

@Component({
  selector: 'app-submission-detail',
  standalone: true,
  imports: [FormsModule, JsonPipe],
  templateUrl: './submission-detail.component.html',
})
export class SubmissionDetailComponent implements OnInit {
  submission: SubmissionDetail | null = null;
  loading = false;
  error = '';
  actionError = '';
  rejectReason = '';
  showRejectForm = false;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private adminService: AdminService,
  ) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) return;
    this.loading = true;
    this.adminService.getSubmission(id).subscribe({
      next: (data) => {
        this.submission = data;
        this.loading = false;
      },
      error: () => {
        this.error = 'আবেদনের তথ্য পাওয়া যায়নি।';
        this.loading = false;
      },
    });
  }

  approve(): void {
    if (!this.submission) return;
    this.actionError = '';
    this.adminService.approveSubmission(this.submission.id).subscribe({
      next: () => this.router.navigate(['/submissions']),
      error: () => (this.actionError = 'অনুমোদন ব্যর্থ হয়েছে।'),
    });
  }

  reject(): void {
    if (!this.submission || !this.rejectReason.trim()) {
      this.actionError = 'বাতিলের কারণ লিখুন।';
      return;
    }
    this.actionError = '';
    this.adminService.rejectSubmission(this.submission.id, this.rejectReason).subscribe({
      next: () => this.router.navigate(['/submissions']),
      error: () => (this.actionError = 'বাতিল করা ব্যর্থ হয়েছে।'),
    });
  }
}
