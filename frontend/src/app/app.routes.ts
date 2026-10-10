import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { permissionGuard } from './core/guards/permission.guard';
import { roleGuard } from './core/guards/role.guard';
import {
  MANAGEMENT_AREA_PERMISSIONS,
  MEMBER_PAYMENT_ROLES,
  SUPER_ADMIN_AREA_PERMISSIONS,
} from './core/services/auth.service';

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
        path: 'forgot-password',
        loadComponent: () =>
          import('./features/auth/pages/forgot-password/forgot-password.component').then(
            (m) => m.ForgotPasswordComponent,
          ),
      },
      {
        path: 'reset-password',
        loadComponent: () =>
          import('./features/auth/pages/reset-password/reset-password.component').then(
            (m) => m.ResetPasswordComponent,
          ),
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
            path: 'property-requests/new',
            loadComponent: () =>
              import('./features/member/pages/property-request-form/property-request-form.component').then(
                (m) => m.PropertyRequestFormComponent,
              ),
          },
          {
            path: 'property-requests/:propertyId/edit',
            loadComponent: () =>
              import('./features/member/pages/property-request-form/property-request-form.component').then(
                (m) => m.PropertyRequestFormComponent,
              ),
          },
          {
            path: 'picnic-payment',
            // Member payers only (MEMBER_PAYMENT_ROLES): fee managers are
            // redirected to Fee Settings, never shown the payment form.
            canActivate: [roleGuard(MEMBER_PAYMENT_ROLES)],
            loadComponent: () =>
              import('./features/member/pages/picnic-payment/picnic-payment.component').then(
                (m) => m.PicnicPaymentComponent,
              ),
          },
          {
            path: 'fees',
            // Member payers only: fee managers configure rates in Fee
            // Settings and never pay as members (backend 403s them too).
            canActivate: [roleGuard(MEMBER_PAYMENT_ROLES)],
            loadComponent: () =>
              import('./features/member/pages/fees/fees.component').then(
                (m) => m.FeesComponent,
              ),
          },
          {
            path: 'cost-shares',
            loadComponent: () =>
              import('./features/member/pages/cost-shares/cost-shares.component').then(
                (m) => m.CostSharesComponent,
              ),
          },
          {
            path: 'neighbours',
            canActivate: [permissionGuard(['neighbour.view'])],
            loadComponent: () =>
              import('./features/member/pages/neighbours/neighbours.component').then(
                (m) => m.NeighboursComponent,
              ),
          },
          {
            path: 'plot-map',
            canActivate: [permissionGuard(['boundary.view'])],
            loadComponent: () =>
              import('./features/member/pages/plot-map/plot-map.component').then(
                (m) => m.PlotMapComponent,
              ),
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
      // Fund transparency sits outside the member-area guard like /dashboard:
      // every authenticated tier (member, committee, admin) may read it - the
      // backend exposes approved transactions to any logged-in account.
      {
        path: 'fund-transparency',
        loadComponent: () =>
          import('./features/member/pages/fund-transparency/fund-transparency.component').then(
            (m) => m.FundTransparencyComponent,
          ),
      },
      // Society roadmap: read-only progress view for every authenticated tier.
      {
        path: 'roadmap',
        loadComponent: () =>
          import('./features/member/pages/roadmap/roadmap.component').then(
            (m) => m.RoadmapComponent,
          ),
      },
      // Resolution book - readable by every authenticated account; the
      // add/edit routes are separately committee-gated (the server
      // enforces the same split via manage_resolution_book).
      {
        path: 'resolution-book',
        loadComponent: () =>
          import('./features/member/pages/resolution-book/resolution-book.component').then(
            (m) => m.ResolutionBookComponent,
          ),
      },
      {
        path: 'resolution-book/meeting/:id',
        loadComponent: () =>
          import('./features/member/pages/resolution-book/meeting-detail.component').then(
            (m) => m.MeetingDetailComponent,
          ),
      },
      {
        path: 'resolution-book/add',
        canActivate: [permissionGuard(['manage_resolution_book'])],
        loadComponent: () =>
          import('./features/member/pages/resolution-book/meeting-form.component').then(
            (m) => m.MeetingFormComponent,
          ),
      },
      {
        path: 'resolution-book/edit/:id',
        canActivate: [permissionGuard(['manage_resolution_book'])],
        loadComponent: () =>
          import('./features/member/pages/resolution-book/meeting-form.component').then(
            (m) => m.MeetingFormComponent,
          ),
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
            path: 'property-requests',
            canActivate: [permissionGuard(['property.review'])],
            loadComponent: () =>
              import('./features/management/pages/property-requests/property-requests.component').then(
                (m) => m.PropertyRequestsComponent,
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
              import('./features/management/pages/installments-management/installments-management.component').then(
                (m) => m.InstallmentsManagementComponent,
              ),
          },
          {
            path: 'fees-management',
            canActivate: [permissionGuard(['member.view_all'])],
            loadComponent: () =>
              import('./features/management/pages/fees-management/fees-management.component').then(
                (m) => m.FeesManagementComponent,
              ),
          },
          {
            path: 'picnic-payments',
            canActivate: [permissionGuard(['member.view_all'])],
            loadComponent: () =>
              import('./features/management/pages/picnic-payments/picnic-payments.component').then(
                (m) => m.PicnicPaymentsComponent,
              ),
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
            path: 'society-costs',
            canActivate: [permissionGuard(['manage_costs'])],
            loadComponent: () =>
              import('./features/management/pages/society-costs/society-costs.component').then(
                (m) => m.SocietyCostsComponent,
              ),
          },
          {
            path: 'finance-management',
            canActivate: [permissionGuard(['manage_finance'])],
            loadComponent: () =>
              import('./features/management/pages/finance-management/finance-management.component').then(
                (m) => m.FinanceManagementComponent,
              ),
          },
          {
            path: 'payment-verifications',
            canActivate: [permissionGuard(['manage_finance'])],
            loadComponent: () =>
              import('./features/management/pages/payment-verifications/payment-verifications.component').then(
                (m) => m.PaymentVerificationsComponent,
              ),
          },
          {
            path: 'roadmap-management',
            canActivate: [permissionGuard(['manage_roadmap'])],
            loadComponent: () =>
              import('./features/management/pages/roadmap-management/roadmap-management.component').then(
                (m) => m.RoadmapManagementComponent,
              ),
          },
          {
            path: 'plot-boundaries',
            canActivate: [permissionGuard(['boundary.review'])],
            loadComponent: () =>
              import(
                './features/management/pages/plot-boundaries/plot-boundaries.component'
              ).then((m) => m.PlotBoundariesComponent),
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
