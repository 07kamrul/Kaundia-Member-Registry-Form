import { Component, OnInit } from '@angular/core';
import { MemberService } from '../../../../core/services/member.service';
import type { Installment } from '../../../../core/models/admin.model';

@Component({
  selector: 'app-member-installments',
  standalone: true,
  templateUrl: './installments.component.html',
})
export class InstallmentsComponent implements OnInit {
  installments: Installment[] = [];
  loading = false;
  error = '';

  constructor(private memberService: MemberService) {}

  ngOnInit(): void {
    this.loading = true;
    this.memberService.getInstallments().subscribe({
      next: (data) => {
        this.installments = data;
        this.loading = false;
      },
      error: () => {
        this.error = 'কিস্তির তালিকা লোড করা যায়নি।';
        this.loading = false;
      },
    });
  }
}
