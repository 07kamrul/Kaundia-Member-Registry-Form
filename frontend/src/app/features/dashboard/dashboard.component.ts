import { Component, ChangeDetectionStrategy } from '@angular/core';
import { AuthService } from '../../core/services/auth.service';
import { AdminDashboardComponent } from '../management/pages/dashboard/admin-dashboard.component';
import { MemberDashboardComponent } from '../member/pages/dashboard/member-dashboard.component';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [AdminDashboardComponent, MemberDashboardComponent],
  template: `
    @if (auth.landingTier() === 'member') {
      <app-member-dashboard />
    } @else {
      <app-admin-dashboard />
    }
  `,
})
export class DashboardComponent {
  constructor(public auth: AuthService) {}
}
