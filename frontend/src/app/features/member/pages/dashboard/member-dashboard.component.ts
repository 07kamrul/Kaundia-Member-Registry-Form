import { Component, OnInit } from '@angular/core';
import { forkJoin } from 'rxjs';
import { MemberService, type MemberProfile } from '../../../../core/services/member.service';
import type { Installment } from '../../../../core/models/admin.model';
import { monthName } from '../../../../shared/constants/months';

interface RecentContribution {
  id: number;
  label: string;
  status: Installment['status'];
}

@Component({
  selector: 'app-member-dashboard',
  standalone: true,
  imports: [],
  templateUrl: './member-dashboard.component.html',
})
export class MemberDashboardComponent implements OnInit {
  profile: MemberProfile | null = null;
  recentInstallments: RecentContribution[] = [];
  paidCount = 0;
  totalCount = 0;
  dueCount = 0;
  loading = false;
  error = '';

  constructor(private memberService: MemberService) {}

  ngOnInit(): void {
    this.loading = true;
    forkJoin({
      profile: this.memberService.getProfile(),
      installments: this.memberService.getInstallments(),
    }).subscribe({
      next: ({ profile, installments }) => {
        this.profile = profile;
        this.dueCount = installments.filter((item) => item.status === 'due').length;
        this.totalCount = installments.length;
        this.paidCount = this.totalCount - this.dueCount;
        this.recentInstallments = [...installments]
          .sort((a, b) => b.year - a.year || b.month - a.month)
          .slice(0, 6)
          .reverse()
          .map((item) => ({ id: item.id, label: monthName(item.month), status: item.status }));
        this.loading = false;
      },
      error: () => {
        this.error = 'তথ্য লোড করা যায়নি।';
        this.loading = false;
      },
    });
  }
}
