import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { permissionGuard } from './core/guards/permission.guard';
import { roleGuard } from './core/guards/role.guard';
import { ADMIN_ROLES } from './core/services/auth.service';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./features/public-shell/public-shell.component').then((m) => m.PublicShellComponent),
    children: [
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
        loadComponent: () =>
          import('./features/auth/pages/login/login.component').then((m) => m.LoginComponent),
      },
    ],
  },
  {
    path: '',
    canActivate: [authGuard],
    loadComponent: () => import('./features/shell/shell.component').then((m) => m.ShellComponent),
    children: [
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./features/dashboard/dashboard.component').then((m) => m.DashboardComponent),
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
        canActivate: [roleGuard(ADMIN_ROLES)],
        loadComponent: () =>
          import('./features/admin/pages/submissions-list/submissions-list.component').then(
            (m) => m.SubmissionsListComponent,
          ),
      },
      {
        path: 'submissions/:id',
        canActivate: [roleGuard(ADMIN_ROLES)],
        loadComponent: () =>
          import('./features/admin/pages/submission-detail/submission-detail.component').then(
            (m) => m.SubmissionDetailComponent,
          ),
      },
      {
        path: 'members',
        canActivate: [roleGuard(ADMIN_ROLES)],
        loadComponent: () =>
          import('./features/admin/pages/members-list/members-list.component').then(
            (m) => m.MembersListComponent,
          ),
      },
      {
        path: 'installments-management',
        canActivate: [roleGuard(ADMIN_ROLES)],
        loadComponent: () =>
          import(
            './features/admin/pages/installments-management/installments-management.component'
          ).then((m) => m.InstallmentsManagementComponent),
      },
      {
        path: 'roles',
        canActivate: [permissionGuard(['manage_roles'])],
        loadComponent: () =>
          import('./features/admin/pages/role-management/role-management.component').then(
            (m) => m.RoleManagementComponent,
          ),
      },
    ],
  },
  { path: '**', redirectTo: '' },
];
