import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import type { Installment, Member } from '../../../../core/models/admin.model';
import { IconComponent } from '../../../../shared/icon/icon.component';

const MONTH_NAMES = [
  '',
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];

@Component({
  selector: 'app-installments-management',
  standalone: true,
  imports: [IconComponent],
  templateUrl: './installments-management.component.html',
})
export class InstallmentsManagementComponent implements OnInit {
  members: Member[] = [];
  loadingMembers = false;
  error = '';

  selectedMemberId = '';
  installments: Installment[] = [];
  loadingInstallments = false;
  markingId: string | null = null;

  constructor(
    private adminService: AdminService,
    public auth: AuthService,
    private route: ActivatedRoute,
    private cdr: ChangeDetectorRef,
  ) {}

  ngOnInit(): void {
    this.loadingMembers = true;
    const requestedMemberId = this.route.snapshot.queryParamMap.get('memberId');
    this.adminService.listMembers().subscribe({
      next: (data) => {
        this.members = data.filter((m) => m.status === 'approved');
        this.loadingMembers = false;
        const initialMember =
          this.members.find((m) => m.id === requestedMemberId) ?? this.members[0];
        if (initialMember) this.selectMember(initialMember.id);
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = 'সদস্য তালিকা লোড করা যায়নি।';
        this.loadingMembers = false;
        this.cdr.markForCheck();
      },
    });
  }

  get selectedMember(): Member | undefined {
    return this.members.find((m) => m.id === this.selectedMemberId);
  }

  monthName(month: number): string {
    return MONTH_NAMES[month] ?? String(month);
  }

  selectMember(memberId: string): void {
    this.selectedMemberId = memberId;
    this.loadingInstallments = true;
    this.installments = [];
    this.adminService.getMemberInstallments(memberId).subscribe({
      next: (data) => {
        this.installments = data;
        this.loadingInstallments = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = 'কিস্তির তথ্য লোড করা যায়নি।';
        this.loadingInstallments = false;
        this.cdr.markForCheck();
      },
    });
  }

  markPaid(installment: Installment): void {
    if (!this.auth.hasPermission('member.manage')) return;
    this.markingId = installment.id;
    this.adminService.updateInstallment(installment.id, 'paid').subscribe({
      next: (updated) => {
        const idx = this.installments.findIndex((i) => i.id === installment.id);
        if (idx >= 0) this.installments[idx] = updated;
        this.markingId = null;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = 'কিস্তি পরিশোধিত হিসেবে চিহ্নিত করা যায়নি।';
        this.markingId = null;
        this.cdr.markForCheck();
      },
    });
  }
}
