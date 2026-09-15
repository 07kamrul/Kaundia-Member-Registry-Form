import { Routes } from '@angular/router';
import { adminGuard } from './core/guards/admin.guard';
import { memberGuard } from './core/guards/member.guard';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () => import('./features/home/home.component').then((m) => m.HomeComponent),
  },
  {
    path: 'register',
    loadComponent: () =>
      import('./features/public-registration/registration-page.component').then(
        (m) => m.RegistrationPageComponent,
      ),
  },
  {
    path: 'admin/login',
    loadComponent: () =>
      import('./features/admin/pages/login/admin-login.component').then(
        (m) => m.AdminLoginComponent,
      ),
  },
  {
    path: 'admin/submissions',
    canActivate: [adminGuard],
    loadComponent: () =>
      import('./features/admin/pages/submissions-list/submissions-list.component').then(
        (m) => m.SubmissionsListComponent,
      ),
  },
  {
    path: 'admin/submissions/:id',
    canActivate: [adminGuard],
    loadComponent: () =>
      import('./features/admin/pages/submission-detail/submission-detail.component').then(
        (m) => m.SubmissionDetailComponent,
      ),
  },
  {
    path: 'admin/members',
    canActivate: [adminGuard],
    loadComponent: () =>
      import('./features/admin/pages/members-list/members-list.component').then(
        (m) => m.MembersListComponent,
      ),
  },
  {
    path: 'member/login',
    loadComponent: () =>
      import('./features/member/pages/login/member-login.component').then(
        (m) => m.MemberLoginComponent,
      ),
  },
  {
    path: 'member/dashboard',
    canActivate: [memberGuard],
    loadComponent: () =>
      import('./features/member/pages/dashboard/member-dashboard.component').then(
        (m) => m.MemberDashboardComponent,
      ),
  },
  {
    path: 'member/change-password',
    canActivate: [memberGuard],
    loadComponent: () =>
      import('./features/member/pages/change-password/change-password.component').then(
        (m) => m.ChangePasswordComponent,
      ),
  },
  {
    path: 'member/profile',
    canActivate: [memberGuard],
    loadComponent: () =>
      import('./features/member/pages/profile/profile.component').then((m) => m.ProfileComponent),
  },
  {
    path: 'member/installments',
    canActivate: [memberGuard],
    loadComponent: () =>
      import('./features/member/pages/installments/installments.component').then(
        (m) => m.InstallmentsComponent,
      ),
  },
  { path: '**', redirectTo: '' },
];
