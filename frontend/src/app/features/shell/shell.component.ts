import { Component, OnInit, signal } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { TranslatePipe } from '@ngx-translate/core';
import {
  AuthService,
  MEMBER_PAYMENT_ROLES,
  type UserRole,
} from '../../core/services/auth.service';
import { ThemeService } from '../../core/services/theme.service';
import { LanguageService } from '../../core/services/language.service';
import { MemberService } from '../../core/services/member.service';
import { IdCardModalComponent } from '../member/components/id-card-modal/id-card-modal.component';
import { IconComponent, type IconName } from '../../shared/icon/icon.component';

interface NavItem {
  labelKey: string;
  route: string;
  icon: IconName;
  // Absent = visible to any authenticated user (member-tier baseline).
  // Present = visible only if the user holds at least one of these keys.
  requiredPermission?: string[];
  // Absent = no role restriction. Present = visible only to these roles
  // (shared config - see MEMBER_PAYMENT_ROLES in auth.service.ts).
  requiredRoles?: readonly UserRole[];
  // True for entries every authenticated account can see. They carry no
  // requiredPermission, so list them here to keep the shared nav styling
  // (gold link color) applied to them too.
  openAccess?: boolean;
}

const NAV_ITEMS: NavItem[] = [
  { labelKey: 'nav.dashboard', route: '/dashboard', icon: 'dashboard' },
  {
    labelKey: 'nav.resolutionBook',
    route: '/resolution-book',
    icon: 'doc',
    // Members read via profile.view_own; committee/admin tiers hold
    // member.view_all - the nav shows the item when either key is held.
    requiredPermission: ['profile.view_own', 'member.view_all'],
  },
  { labelKey: 'nav.profile', route: '/profile', icon: 'user', requiredPermission: ['profile.view_own'] },
  {
    labelKey: 'nav.installments',
    route: '/installments',
    icon: 'wallet',
    requiredPermission: ['profile.view_own'],
  },
  {
    labelKey: 'nav.picnicPayment',
    route: '/picnic-payment',
    icon: 'sun',
    requiredPermission: ['profile.view_own'],
    requiredRoles: MEMBER_PAYMENT_ROLES,
  },
  {
    labelKey: 'nav.costShares',
    route: '/cost-shares',
    icon: 'coin',
    requiredPermission: ['profile.view_own'],
  },
  // Fund transparency: every authenticated account (members and committee
  // alike) can read the society's approved ledger.
  {
    labelKey: 'nav.fundTransparency',
    route: '/fund-transparency',
    icon: 'chart',
    openAccess: true,
  },
  // Society roadmap: visible to every authenticated account.
  {
    labelKey: 'nav.roadmap',
    route: '/roadmap',
    icon: 'map',
    openAccess: true,
  },
  { labelKey: 'nav.changePassword', route: '/change-password', icon: 'lock', requiredPermission: ['profile.view_own'] },
  // Published notices/events - the same public pages logged-out visitors read.
  {
    labelKey: 'nav.notices',
    route: '/notices',
    icon: 'doc',
    requiredPermission: ['notice.view'],
  },
  {
    labelKey: 'nav.events',
    route: '/events',
    icon: 'pin',
    requiredPermission: ['event.view'],
  },
  {
    labelKey: 'nav.submissions',
    route: '/submissions',
    icon: 'inbox',
    requiredPermission: ['membership.review'],
  },
  {
    labelKey: 'nav.propertyRequests',
    route: '/property-requests',
    icon: 'doc',
    requiredPermission: ['property.review'],
  },
  {
    labelKey: 'nav.membersList',
    route: '/members',
    icon: 'users',
    requiredPermission: ['member.view_all'],
  },
  {
    labelKey: 'nav.picnicPayments',
    route: '/picnic-payments',
    icon: 'wallet',
    requiredPermission: ['member.view_all'],
  },
  {
    labelKey: 'nav.installmentsManagement',
    route: '/installments-management',
    icon: 'coin',
    requiredPermission: ['member.view_all'],
  },
  {
    labelKey: 'nav.rolesPermissions',
    route: '/roles',
    icon: 'shield',
    requiredPermission: ['manage_roles', 'manage_users'],
  },
  {
    labelKey: 'nav.feeSettings',
    route: '/fee-settings',
    icon: 'coin',
    requiredPermission: ['manage_fee_settings'],
  },
  {
    labelKey: 'nav.societyCosts',
    route: '/society-costs',
    icon: 'coin',
    requiredPermission: ['manage_costs'],
  },
  {
    labelKey: 'nav.financeManagement',
    route: '/finance-management',
    icon: 'chart',
    requiredPermission: ['manage_finance'],
  },
  {
    labelKey: 'nav.paymentVerifications',
    route: '/payment-verifications',
    icon: 'check-circle',
    requiredPermission: ['manage_finance'],
  },
  {
    labelKey: 'nav.roadmapManagement',
    route: '/roadmap-management',
    icon: 'map',
    requiredPermission: ['manage_roadmap'],
  },
  {
    labelKey: 'nav.auditLog',
    route: '/audit-log',
    icon: 'shield',
    requiredPermission: ['view_audit_log'],
  },
  {
    labelKey: 'nav.configLists',
    route: '/config-lists',
    icon: 'inbox',
    requiredPermission: ['manage_system_config'],
  },
  {
    labelKey: 'nav.noticesManagement',
    route: '/notices-management',
    icon: 'doc',
    requiredPermission: ['manage_notices'],
  },
  {
    labelKey: 'nav.eventsManagement',
    route: '/events-management',
    icon: 'pin',
    requiredPermission: ['manage_notices'],
  },
];

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [RouterLink, RouterLinkActive, RouterOutlet, IconComponent, TranslatePipe, IdCardModalComponent],
  templateUrl: './shell.component.html',
  styleUrl: './shell.component.scss',
  host: { '(document:keydown.escape)': 'closeUserMenu()' },
})
export class ShellComponent implements OnInit {
  isUserMenuOpen = false;
  readonly sidebarOpen = signal(false);
  readonly displayName = signal('');
  readonly memberId = signal('');
  readonly avatarPhotoUrl = signal<string | undefined>(undefined);
  readonly isIdCardOpen = signal(false);

  openIdCard(): void {
    this.closeSidebar();
    this.isIdCardOpen.set(true);
  }

  closeIdCard(): void {
    this.isIdCardOpen.set(false);
  }

  constructor(
    public auth: AuthService,
    public theme: ThemeService,
    public lang: LanguageService,
    private memberService: MemberService,
    private router: Router,
  ) {}

  ngOnInit(): void {
    // Not a permission check: /api/member/me only exists for actual Member-role
    // accounts (member JWTs), regardless of which permissions a role holds -
    // an Executive Committee/Administrator/Super Admin account has no member
    // profile row to fetch, so this stays an account-type check.
    if (this.auth.role === 'member') {
      this.memberService.getProfile().subscribe({
        next: (profile) => {
          this.displayName.set(profile.fullName);
          this.memberId.set(profile.memberId);
          this.avatarPhotoUrl.set(profile.memberPhotoUrl);
        },
        error: () => {
          // Header still renders without the name/ID; page content shows its own error state.
        },
      });
    }
  }

  get avatarInitial(): string {
    return this.welcomeName.trim().charAt(0) || (this.lang.lang() === 'bn' ? 'ব' : 'A');
  }

  // A missing/404 photo (e.g. file not yet on the server) must not render a
  // broken-image icon - fall back to the initial-letter avatar.
  onAvatarError(): void {
    this.avatarPhotoUrl.set(undefined);
  }

  get welcomeName(): string {
    return this.displayName() || (this.auth.landingTier() !== 'member' ? this.adminLabel : '');
  }

  private get adminLabel(): string {
    return this.lang.lang() === 'bn' ? 'প্রশাসক' : 'Admin';
  }

  get navItems(): NavItem[] {
    const role = this.auth.role;
    return NAV_ITEMS.filter((item) => {
      if (item.requiredPermission && !this.auth.hasAnyPermission(item.requiredPermission)) {
        return false;
      }
      if (item.requiredRoles && (role === null || !item.requiredRoles.includes(role))) {
        return false;
      }
      return true;
    });
  }

  toggleSidebar(): void {
    this.sidebarOpen.update((open) => !open);
  }

  closeSidebar(): void {
    this.sidebarOpen.set(false);
  }

  toggleUserMenu(): void {
    this.isUserMenuOpen = !this.isUserMenuOpen;
  }

  closeUserMenu(): void {
    this.isUserMenuOpen = false;
  }

  logout(): void {
    this.closeUserMenu();
    this.auth.logout();
    this.router.navigate(['/login']);
  }
}
