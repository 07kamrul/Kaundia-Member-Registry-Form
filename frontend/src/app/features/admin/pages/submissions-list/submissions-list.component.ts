import { Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { AdminService } from '../../../../core/services/admin.service';
import type { SubmissionStatus, SubmissionSummary } from '../../../../core/models/admin.model';
import { IconComponent } from '../../../../shared/icon/icon.component';

@Component({
  selector: 'app-submissions-list',
  standalone: true,
  imports: [RouterLink, IconComponent],
  templateUrl: './submissions-list.component.html',
})
export class SubmissionsListComponent implements OnInit {
  submissions: SubmissionSummary[] = [];
  statusFilter: SubmissionStatus | '' = 'pending';
  loading = false;
  error = '';

  readonly statuses: Array<SubmissionStatus | ''> = ['', 'pending', 'approved', 'rejected'];

  constructor(private adminService: AdminService) {}

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
      },
      error: () => {
        this.error = 'তালিকা লোড করা যায়নি।';
        this.loading = false;
      },
    });
  }

  onFilterChange(event: Event): void {
    this.statusFilter = (event.target as HTMLSelectElement).value as SubmissionStatus | '';
    this.load();
  }
}
