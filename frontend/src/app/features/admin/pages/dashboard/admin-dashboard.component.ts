import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { DatePipe } from '@angular/common';
import { RouterLink } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import type { SubmissionSummary } from '../../../../core/models/admin.model';
import { IconComponent } from '../../../../shared/icon/icon.component';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [RouterLink, IconComponent, DatePipe, TranslatePipe],
  templateUrl: './admin-dashboard.component.html',
})
export class AdminDashboardComponent implements OnInit {
  pending: SubmissionSummary[] = [];
  loading = false;
  error = '';

  constructor(
    private adminService: AdminService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.error = '';
    this.adminService.listSubmissions('pending').subscribe({
      next: (data) => {
        this.pending = data;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.dashboard.errors.loadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  referenceFor(submission: SubmissionSummary): string {
    const year = new Date(submission.createdAt).getFullYear() || new Date().getFullYear();
    return `REF-${year}-${submission.id.padStart(4, '0')}`;
  }
}
