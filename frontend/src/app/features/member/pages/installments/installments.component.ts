import { Component, OnInit } from '@angular/core';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { MemberService } from '../../../../core/services/member.service';
import type { Installment } from '../../../../core/models/admin.model';
import { monthNameKey } from '../../../../shared/constants/months';

@Component({
  selector: 'app-member-installments',
  standalone: true,
  imports: [TranslatePipe],
  templateUrl: './installments.component.html',
})
export class InstallmentsComponent implements OnInit {
  installments: Installment[] = [];
  year: number | null = null;
  loading = false;
  error = '';

  constructor(
    private memberService: MemberService,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.loading = true;
    this.memberService.getInstallments().subscribe({
      next: (data) => {
        this.installments = [...data].sort((a, b) => a.year - b.year || a.month - b.month);
        this.year = this.installments[0]?.year ?? null;
        this.loading = false;
      },
      error: () => {
        this.error = this.translate.instant('member.installments.loadError');
        this.loading = false;
      },
    });
  }

  monthLabel(month: number): string {
    return monthNameKey(month);
  }
}
