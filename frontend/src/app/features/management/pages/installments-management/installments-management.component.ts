import { ChangeDetectorRef, Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import type { Installment, Member } from '../../../../core/models/admin.model';
import { IconComponent } from '../../../../shared/icon/icon.component';

const MONTH_KEYS = [
  '',
  'admin.installments.months.january',
  'admin.installments.months.february',
  'admin.installments.months.march',
  'admin.installments.months.april',
  'admin.installments.months.may',
  'admin.installments.months.june',
  'admin.installments.months.july',
  'admin.installments.months.august',
  'admin.installments.months.september',
  'admin.installments.months.october',
  'admin.installments.months.november',
  'admin.installments.months.december',
];

@Component({
  selector: 'app-installments-management',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [IconComponent, TranslatePipe],
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
    private translate: TranslateService,
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
        this.error = this.translate.instant('admin.installments.errors.loadMembersFailed');
        this.loadingMembers = false;
        this.cdr.markForCheck();
      },
    });
  }

  get selectedMember(): Member | undefined {
    return this.members.find((m) => m.id === this.selectedMemberId);
  }

  monthName(month: number): string {
    const key = MONTH_KEYS[month];
    return key ? this.translate.instant(key) : String(month);
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
        this.error = this.translate.instant('admin.installments.errors.loadInstallmentsFailed');
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
        this.error = this.translate.instant('admin.installments.errors.markPaidFailed');
        this.markingId = null;
        this.cdr.markForCheck();
      },
    });
  }
}
