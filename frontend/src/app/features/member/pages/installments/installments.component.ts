import { Component, OnInit } from '@angular/core';
import { MemberService } from '../../../../core/services/member.service';
import type { Installment } from '../../../../core/models/admin.model';
import { monthName } from '../../../../shared/constants/months';

@Component({
  selector: 'app-member-installments',
  standalone: true,
  templateUrl: './installments.component.html',
})
export class InstallmentsComponent implements OnInit {
  installments: Installment[] = [];
  year: number | null = null;
  loading = false;
  error = '';

  constructor(private memberService: MemberService) {}

  ngOnInit(): void {
    this.loading = true;
    this.memberService.getInstallments().subscribe({
      next: (data) => {
        this.installments = [...data].sort((a, b) => a.year - b.year || a.month - b.month);
        this.year = this.installments[0]?.year ?? null;
        this.loading = false;
      },
      error: () => {
        this.error = 'কিস্তির তালিকা লোড করা যায়নি।';
        this.loading = false;
      },
    });
  }

  monthLabel(month: number): string {
    return monthName(month);
  }
}
