import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import type { SubmissionStatus, SubmissionSummary } from '../../../../core/models/admin.model';
import { IconComponent } from '../../../../shared/icon/icon.component';

@Component({
  selector: 'app-submissions-list',
  standalone: true,
  imports: [RouterLink, IconComponent, TranslatePipe],
  templateUrl: './submissions-list.component.html',
})
export class SubmissionsListComponent implements OnInit {
  submissions: SubmissionSummary[] = [];
  statusFilter: SubmissionStatus | '' = 'pending';
  loading = false;
  error = '';

  readonly statuses: Array<SubmissionStatus | ''> = ['', 'pending', 'approved', 'rejected'];

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
    this.adminService.listSubmissions(this.statusFilter || undefined).subscribe({
      next: (data) => {
        this.submissions = data;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.submissionsList.errors.loadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  onFilterChange(event: Event): void {
    this.statusFilter = (event.target as HTMLSelectElement).value as SubmissionStatus | '';
    this.load();
  }
}
