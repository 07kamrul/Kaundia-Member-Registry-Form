import { ChangeDetectorRef, Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { Router } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import type { Member } from '../../../../core/models/admin.model';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';

@Component({
  selector: 'app-members-list',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [IconComponent, ConfirmModalComponent, TranslatePipe],
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
    private translate: TranslateService,
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
        this.error = this.translate.instant('admin.membersList.errors.loadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  contributionLabel(member: Member): string {
    if (member.status !== 'approved') return '—';
    return member.dueInstallments > 0
      ? `${member.dueInstallments} ${this.translate.instant('admin.membersList.monthsOverdue')}`
      : this.translate.instant('admin.membersList.fullyPaid');
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
        this.error = this.translate.instant('admin.membersList.errors.deleteFailed');
        this.deleteTarget = null;
        this.deleting = false;
        this.cdr.markForCheck();
      },
    });
  }
}
