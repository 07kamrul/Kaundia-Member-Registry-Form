import { Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';
import { MemberService, type MemberProfile } from '../../../../core/services/member.service';
import type { Installment } from '../../../../core/models/admin.model';
import { IconComponent, type IconName } from '../../../../shared/icon/icon.component';

interface SummaryCard {
  route: string;
  icon: IconName;
  title: string;
  value: string;
  hint: string;
}

@Component({
  selector: 'app-member-dashboard',
  standalone: true,
  imports: [RouterLink, IconComponent],
  templateUrl: './member-dashboard.component.html',
})
export class MemberDashboardComponent implements OnInit {
  profile: MemberProfile | null = null;
  cards: SummaryCard[] = [];
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
        this.cards = this.buildCards(profile, installments);
        this.loading = false;
      },
      error: () => {
        this.error = 'তথ্য লোড করা যায়নি।';
        this.loading = false;
      },
    });
  }

  private buildCards(profile: MemberProfile, installments: Installment[]): SummaryCard[] {
    const dueCount = installments.filter((item) => item.status === 'due').length;
    const paidCount = installments.length - dueCount;

    return [
      {
        route: '/profile',
        icon: 'user',
        title: 'প্রোফাইল',
        value: profile.fullName,
        hint: `সদস্য নং ${profile.memberId}`,
      },
      {
        route: '/installments',
        icon: 'wallet',
        title: 'কিস্তির তথ্য',
        value: dueCount > 0 ? `${dueCount}টি বাকি` : 'সব পরিশোধিত',
        hint: `${paidCount}টি পরিশোধিত · মোট ${installments.length}টি`,
      },
      {
        route: '/change-password',
        icon: 'lock',
        title: 'পাসওয়ার্ড পরিবর্তন',
        value: 'নিরাপত্তা সেটিংস',
        hint: 'পাসওয়ার্ড আপডেট করুন',
      },
    ];
  }
}
