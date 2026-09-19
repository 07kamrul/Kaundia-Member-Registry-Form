import { Component, OnInit } from '@angular/core';
import { forkJoin } from 'rxjs';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { MemberService, type MemberProfile } from '../../../../core/services/member.service';
import type { Installment } from '../../../../core/models/admin.model';
import { monthNameKey } from '../../../../shared/constants/months';

interface RecentContribution {
  id: Installment['id'];
  labelKey: string;
  status: Installment['status'];
}

@Component({
  selector: 'app-member-dashboard',
  standalone: true,
  imports: [TranslatePipe],
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

  constructor(
    private memberService: MemberService,
    private translate: TranslateService,
  ) {}

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
          .map((item) => ({ id: item.id, labelKey: monthNameKey(item.month), status: item.status }));
        this.loading = false;
      },
      error: () => {
        this.error = this.translate.instant('member.dashboard.loadError');
        this.loading = false;
      },
    });
  }
}
