import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import type { SubmissionDetail } from '../../../../core/models/admin.model';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';

@Component({
  selector: 'app-submission-detail',
  standalone: true,
  imports: [FormsModule, ConfirmModalComponent, TranslatePipe],
  templateUrl: './submission-detail.component.html',
})
export class SubmissionDetailComponent implements OnInit {
  submission: SubmissionDetail | null = null;
  loading = false;
  error = '';
  actionError = '';
  rejectReason = '';
  showApproveModal = false;
  showRejectModal = false;
  previewImageUrl: string | null = null;
  previewImageAlt = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private adminService: AdminService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

  /** Only allow review actions once the submission has finished loading without error. */
  get isReviewReady(): boolean {
    return !this.loading && !this.error && this.submission !== null;
  }

  /** Avatar fallback initials when no member photo is available. */
  get applicantInitials(): string {
    const name = this.submission?.fullName?.trim();
    if (!name) return '?';
    return name
      .split(/\s+/)
      .slice(0, 2)
      .map((part) => part.charAt(0))
      .join('')
      .toUpperCase();
  }

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) return;
    this.loading = true;
    this.adminService.getSubmission(id).subscribe({
      next: (data) => {
        this.submission = data;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.submissionDetail.errors.loadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  openPreview(url: string, altKey: string): void {
    this.previewImageUrl = url;
    this.previewImageAlt = this.translate.instant(altKey);
  }

  closePreview(): void {
    this.previewImageUrl = null;
    this.previewImageAlt = '';
  }

  approve(): void {
    if (!this.submission) return;
    this.actionError = '';
    this.adminService.approveSubmission(this.submission.id).subscribe({
      next: () => this.router.navigate(['/submissions']),
      error: () => {
        this.actionError = this.translate.instant('admin.submissionDetail.errors.approveFailed');
        this.showApproveModal = false;
        this.cdr.markForCheck();
      },
    });
  }

  reject(): void {
    if (!this.submission || !this.rejectReason.trim()) {
      this.actionError = this.translate.instant('admin.submissionDetail.errors.reasonRequired');
      return;
    }
    this.actionError = '';
    this.adminService.rejectSubmission(this.submission.id, this.rejectReason).subscribe({
      next: () => this.router.navigate(['/submissions']),
      error: () => {
        this.actionError = this.translate.instant('admin.submissionDetail.errors.rejectFailed');
        this.showRejectModal = false;
        this.cdr.markForCheck();
      },
    });
  }
}
