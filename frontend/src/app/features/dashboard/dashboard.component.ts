import { Component, ChangeDetectionStrategy } from '@angular/core';
import { AuthService } from '../../core/services/auth.service';
import { AdminDashboardComponent } from '../admin/pages/dashboard/admin-dashboard.component';
import { MemberDashboardComponent } from '../member/pages/dashboard/member-dashboard.component';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [AdminDashboardComponent, MemberDashboardComponent],
  template: `
    @if (auth.isAdmin) {
      <app-admin-dashboard />
    } @else {
      <app-member-dashboard />
    }
  `,
})
export class DashboardComponent {
  constructor(public auth: AuthService) {}
}
