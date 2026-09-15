import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { roleGuard } from './core/guards/role.guard';

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
    path: 'login',
    redirectTo: '',
  },
  {
    path: '',
    canActivate: [authGuard],
    loadComponent: () => import('./features/shell/shell.component').then((m) => m.ShellComponent),
    children: [
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./features/member/pages/dashboard/member-dashboard.component').then(
            (m) => m.MemberDashboardComponent,
          ),
      },
      {
        path: 'profile',
        loadComponent: () =>
          import('./features/member/pages/profile/profile.component').then(
            (m) => m.ProfileComponent,
          ),
      },
      {
        path: 'installments',
        loadComponent: () =>
          import('./features/member/pages/installments/installments.component').then(
            (m) => m.InstallmentsComponent,
          ),
      },
      {
        path: 'change-password',
        loadComponent: () =>
          import('./features/member/pages/change-password/change-password.component').then(
            (m) => m.ChangePasswordComponent,
          ),
      },
      {
        path: 'submissions',
        canActivate: [roleGuard(['admin'])],
        loadComponent: () =>
          import('./features/admin/pages/submissions-list/submissions-list.component').then(
            (m) => m.SubmissionsListComponent,
          ),
      },
      {
        path: 'submissions/:id',
        canActivate: [roleGuard(['admin'])],
        loadComponent: () =>
          import('./features/admin/pages/submission-detail/submission-detail.component').then(
            (m) => m.SubmissionDetailComponent,
          ),
      },
      {
        path: 'members',
        canActivate: [roleGuard(['admin'])],
        loadComponent: () =>
          import('./features/admin/pages/members-list/members-list.component').then(
            (m) => m.MembersListComponent,
          ),
      },
    ],
  },
  { path: '**', redirectTo: '' },
];
