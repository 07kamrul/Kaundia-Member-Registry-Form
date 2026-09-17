import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import type { Installment, Member } from '../../../../core/models/admin.model';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';

interface MemberWithInstallments extends Member {
  installments: Installment[];
  expanded: boolean;
  newYear: number;
  newMonth: number;
  newAmount: number;
}

@Component({
  selector: 'app-members-list',
  standalone: true,
  imports: [FormsModule, IconComponent, ConfirmModalComponent],
  templateUrl: './members-list.component.html',
})
export class MembersListComponent implements OnInit {
  members: MemberWithInstallments[] = [];
  loading = false;
  error = '';
  deleteTarget: MemberWithInstallments | null = null;
  deleting = false;

  constructor(
    private adminService: AdminService,
    public auth: AuthService,
  ) {}

  ngOnInit(): void {
    this.loading = true;
    this.adminService.listMembers().subscribe({
      next: (data) => {
        this.members = data.map((m) => ({
          ...m,
          installments: [],
          expanded: false,
          newYear: new Date().getFullYear(),
          newMonth: new Date().getMonth() + 1,
          newAmount: 0,
        }));
        this.loading = false;
      },
      error: () => {
        this.error = 'সদস্য তালিকা লোড করা যায়নি।';
        this.loading = false;
      },
    });
  }

  addInstallment(member: MemberWithInstallments): void {
    this.adminService
      .addInstallment(member.id, {
        year: member.newYear,
        month: member.newMonth,
        amount: member.newAmount,
      })
      .subscribe({
        next: (installment) => member.installments.push(installment),
      });
  }

  toggleStatus(member: MemberWithInstallments, installment: Installment): void {
    const nextStatus = installment.status === 'paid' ? 'due' : 'paid';
    this.adminService.updateInstallment(installment.id, nextStatus).subscribe({
      next: (updated) => {
        const idx = member.installments.findIndex((i) => i.id === installment.id);
        if (idx >= 0) member.installments[idx] = updated;
      },
    });
  }

  askDelete(member: MemberWithInstallments): void {
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
      },
      error: () => {
        this.error = 'সদস্য মুছে ফেলা যায়নি।';
        this.deleteTarget = null;
        this.deleting = false;
      },
    });
  }
}
