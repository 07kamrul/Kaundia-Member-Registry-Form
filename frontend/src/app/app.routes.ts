import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { permissionGuard } from './core/guards/permission.guard';
import { MANAGEMENT_AREA_PERMISSIONS, SUPER_ADMIN_AREA_PERMISSIONS } from './core/services/auth.service';

// Member-area baseline permission - see auth.service.ts's landingTier()/area
// guards for why this, not role name, is the right check (Super Admin's full
// permission catalog includes it too, by design).
const MEMBER_AREA_PERMISSIONS = ['profile.view_own'];

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
      {
        path: 'notices',
        loadComponent: () =>
          import('./features/public-pages/notices/notices-page.component').then(
            (m) => m.NoticesPageComponent,
          ),
      },
      {
        path: 'notices/:id',
        loadComponent: () =>
          import('./features/public-pages/notices/notice-detail-page.component').then(
            (m) => m.NoticeDetailPageComponent,
          ),
      },
      {
        path: 'events',
        loadComponent: () =>
          import('./features/public-pages/events/events-page.component').then(
            (m) => m.EventsPageComponent,
          ),
      },
      {
        path: 'events/:id',
        loadComponent: () =>
          import('./features/public-pages/events/event-detail-page.component').then(
            (m) => m.EventDetailPageComponent,
          ),
      },
      {
        path: '403',
        loadComponent: () =>
          import('./core/pages/forbidden/forbidden.component').then((m) => m.ForbiddenComponent),
      },
    ],
  },
  {
    path: '',
    canActivate: [authGuard],
    loadComponent: () => import('./features/shell/shell.component').then((m) => m.ShellComponent),
    children: [
      // Member area - any authenticated account holding the member-tier
      // permission (member role, or Super Admin's full catalog).
      {
        path: '',
        canActivate: [permissionGuard(MEMBER_AREA_PERMISSIONS)],
        children: [
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
            path: 'picnic-payment',
            loadComponent: () =>
              import(
                './features/member/pages/picnic-payment/picnic-payment.component'
              ).then((m) => m.PicnicPaymentComponent),
          },
          {
            path: 'change-password',
            loadComponent: () =>
              import('./features/member/pages/change-password/change-password.component').then(
                (m) => m.ChangePasswordComponent,
              ),
          },
        ],
      },
      // Dashboard is reachable by every authenticated tier - its own internal
      // switch (auth.landingTier()) picks the right content, so it sits
      // outside both area guards below.
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./features/dashboard/dashboard.component').then((m) => m.DashboardComponent),
      },
      // Management area - Executive Committee/Administrator (any manage_*/
      // approve_*/view_* key from their default tuples), Super Admin included.
      {
        path: '',
        canActivate: [permissionGuard(MANAGEMENT_AREA_PERMISSIONS)],
        data: { requiredPermissions: MANAGEMENT_AREA_PERMISSIONS },
        children: [
          {
            path: 'submissions',
            canActivate: [permissionGuard(['membership.review'])],
            loadComponent: () =>
              import('./features/management/pages/submissions-list/submissions-list.component').then(
                (m) => m.SubmissionsListComponent,
              ),
          },
          {
            path: 'submissions/:id',
            canActivate: [permissionGuard(['membership.review'])],
            loadComponent: () =>
              import('./features/management/pages/submission-detail/submission-detail.component').then(
                (m) => m.SubmissionDetailComponent,
              ),
          },
          {
            path: 'members',
            canActivate: [permissionGuard(['member.view_all'])],
            loadComponent: () =>
              import('./features/management/pages/members-list/members-list.component').then(
                (m) => m.MembersListComponent,
              ),
          },
          {
            path: 'installments-management',
            canActivate: [permissionGuard(['member.view_all'])],
            loadComponent: () =>
              import(
                './features/management/pages/installments-management/installments-management.component'
              ).then((m) => m.InstallmentsManagementComponent),
          },
          {
            path: 'picnic-payments',
            canActivate: [permissionGuard(['member.view_all'])],
            loadComponent: () =>
              import(
                './features/management/pages/picnic-payments/picnic-payments.component'
              ).then((m) => m.PicnicPaymentsComponent),
          },
          {
            path: 'fee-settings',
            canActivate: [permissionGuard(['manage_fee_settings'])],
            loadComponent: () =>
              import('./features/management/pages/fee-settings/fee-settings.component').then(
                (m) => m.FeeSettingsComponent,
              ),
          },
          {
            path: 'config-lists',
            canActivate: [permissionGuard(['manage_system_config'])],
            loadComponent: () =>
              import('./features/management/pages/config-lists/config-lists.component').then(
                (m) => m.ConfigListsComponent,
              ),
          },
          // `-management` suffix mirrors installments-management: the public
          // /notices and /events routes already own the unsuffixed paths.
          {
            path: 'notices-management',
            canActivate: [permissionGuard(['manage_notices'])],
            loadComponent: () =>
              import('./features/management/pages/notices/notices.component').then(
                (m) => m.NoticesComponent,
              ),
          },
          {
            path: 'events-management',
            canActivate: [permissionGuard(['manage_notices'])],
            loadComponent: () =>
              import('./features/management/pages/events/events.component').then(
                (m) => m.EventsComponent,
              ),
          },
        ],
      },
      // Super Admin area - manage_users/manage_roles/view_audit_log exist
      // only in the Super Admin's full permission catalog today.
      {
        path: '',
        canActivate: [permissionGuard(SUPER_ADMIN_AREA_PERMISSIONS)],
        data: { requiredPermissions: SUPER_ADMIN_AREA_PERMISSIONS },
        children: [
          {
            path: 'roles',
            canActivate: [permissionGuard(['manage_roles', 'manage_users'])],
            loadComponent: () =>
              import('./features/management/pages/role-management/role-management.component').then(
                (m) => m.RoleManagementComponent,
              ),
          },
          {
            path: 'audit-log',
            canActivate: [permissionGuard(['view_audit_log'])],
            loadComponent: () =>
              import('./features/management/pages/audit-log/audit-log.component').then(
                (m) => m.AuditLogComponent,
              ),
          },
        ],
      },
    ],
  },
  { path: '**', redirectTo: '' },
];
