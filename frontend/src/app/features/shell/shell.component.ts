import { Component, OnInit, signal } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { TranslatePipe } from '@ngx-translate/core';
import { AuthService } from '../../core/services/auth.service';
import { ThemeService } from '../../core/services/theme.service';
import { LanguageService } from '../../core/services/language.service';
import { MemberService } from '../../core/services/member.service';
import { IconComponent, type IconName } from '../../shared/icon/icon.component';

interface NavItem {
  labelKey: string;
  route: string;
  icon: IconName;
  adminOnly: boolean;
  memberOnly?: boolean;
  requiredPermission?: string;
}

const NAV_ITEMS: NavItem[] = [
  { labelKey: 'nav.dashboard', route: '/dashboard', icon: 'dashboard', adminOnly: false },
  { labelKey: 'nav.profile', route: '/profile', icon: 'user', adminOnly: false, memberOnly: true },
  {
    labelKey: 'nav.installments',
    route: '/installments',
    icon: 'wallet',
    adminOnly: false,
    memberOnly: true,
  },
  { labelKey: 'nav.changePassword', route: '/change-password', icon: 'lock', adminOnly: false },
  { labelKey: 'nav.submissions', route: '/submissions', icon: 'inbox', adminOnly: true },
  { labelKey: 'nav.membersList', route: '/members', icon: 'users', adminOnly: true },
  {
    labelKey: 'nav.installmentsManagement',
    route: '/installments-management',
    icon: 'coin',
    adminOnly: true,
  },
  {
    labelKey: 'nav.rolesPermissions',
    route: '/roles',
    icon: 'shield',
    adminOnly: true,
    requiredPermission: 'manage_roles',
  },
];

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [RouterLink, RouterLinkActive, RouterOutlet, IconComponent, TranslatePipe],
  templateUrl: './shell.component.html',
  styleUrl: './shell.component.scss',
})
export class ShellComponent implements OnInit {
  readonly sidebarOpen = signal(false);
  readonly displayName = signal('');
  readonly memberId = signal('');

  constructor(
    public auth: AuthService,
    public theme: ThemeService,
    public lang: LanguageService,
    private memberService: MemberService,
    private router: Router,
  ) {}

  ngOnInit(): void {
    if (!this.auth.isAdmin) {
      this.memberService.getProfile().subscribe({
        next: (profile) => {
          this.displayName.set(profile.fullName);
          this.memberId.set(profile.memberId);
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

  get welcomeName(): string {
    return this.displayName() || (this.auth.isAdmin ? this.adminLabel : '');
  }

  private get adminLabel(): string {
    return this.lang.lang() === 'bn' ? 'প্রশাসক' : 'Admin';
  }

  get navItems(): NavItem[] {
    return NAV_ITEMS.filter((item) => {
      if (item.memberOnly && this.auth.isAdmin) {
        return false;
      }
      if (item.requiredPermission) {
        return this.auth.hasPermission(item.requiredPermission);
      }
      return !item.adminOnly || this.auth.isAdmin;
    });
  }

  toggleSidebar(): void {
    this.sidebarOpen.update((open) => !open);
  }

  closeSidebar(): void {
    this.sidebarOpen.set(false);
  }

  logout(): void {
    this.auth.logout();
    this.router.navigate(['/login']);
  }
}
