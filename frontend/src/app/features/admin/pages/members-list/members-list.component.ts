import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import type { Member } from '../../../../core/models/admin.model';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';

@Component({
  selector: 'app-members-list',
  standalone: true,
  imports: [IconComponent, ConfirmModalComponent],
  templateUrl: './members-list.component.html',
})
export class MembersListComponent implements OnInit {
  members: Member[] = [];
  loading = false;
  error = '';
  deleteTarget: Member | null = null;
  deleting = false;

  constructor(
    private adminService: AdminService,
    private router: Router,
    public auth: AuthService,
    private cdr: ChangeDetectorRef,
  ) {}

  ngOnInit(): void {
    this.loading = true;
    this.adminService.listMembers().subscribe({
      next: (data) => {
        this.members = data;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = 'সদস্য তালিকা লোড করা যায়নি।';
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  contributionLabel(member: Member): string {
    if (member.status !== 'approved') return '—';
    return member.dueInstallments > 0
      ? `${member.dueInstallments} মাস বকেয়া`
      : 'সম্পূর্ণ পরিশোধিত';
  }

  viewContributions(member: Member): void {
    if (member.status !== 'approved') return;
    this.router.navigate(['/installments-management'], { queryParams: { memberId: member.id } });
  }

  askDelete(member: Member): void {
    if (!this.auth.hasPermission('member.manage')) return;
    this.deleteTarget = member;
  }

  confirmDelete(): void {
    if (!this.deleteTarget) return;
    this.deleting = true;
    this.adminService.deleteMember(this.deleteTarget.id).subscribe({
      next: () => {
        this.members = this.members.filter((m) => m.id !== this.deleteTarget!.id);
        this.deleteTarget = null;
        this.deleting = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = 'সদস্য মুছে ফেলা যায়নি।';
        this.deleteTarget = null;
        this.deleting = false;
        this.cdr.markForCheck();
      },
    });
  }
}
