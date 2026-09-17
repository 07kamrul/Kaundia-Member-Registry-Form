import { Component, OnInit, signal } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import { ThemeService } from '../../core/services/theme.service';
import { MemberService } from '../../core/services/member.service';
import { IconComponent, type IconName } from '../../shared/icon/icon.component';

interface NavItem {
  label: string;
  route: string;
  icon: IconName;
  adminOnly: boolean;
  requiredPermission?: string;
}

const NAV_ITEMS: NavItem[] = [
  { label: 'ড্যাশবোর্ড', route: '/dashboard', icon: 'dashboard', adminOnly: false },
  { label: 'প্রোফাইল', route: '/profile', icon: 'user', adminOnly: false },
  { label: 'কিস্তি', route: '/installments', icon: 'wallet', adminOnly: false },
  { label: 'পাসওয়ার্ড পরিবর্তন', route: '/change-password', icon: 'lock', adminOnly: false },
  { label: 'সাবমিশন', route: '/submissions', icon: 'inbox', adminOnly: true },
  { label: 'সদস্য তালিকা', route: '/members', icon: 'users', adminOnly: true },
  {
    label: 'চাঁদা ব্যবস্থাপনা',
    route: '/installments-management',
    icon: 'wallet',
    adminOnly: true,
  },
  {
    label: 'ভূমিকা ও অনুমতি',
    route: '/roles',
    icon: 'lock',
    adminOnly: true,
    requiredPermission: 'manage_roles',
  },
];

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [RouterLink, RouterLinkActive, RouterOutlet, IconComponent],
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
    return this.welcomeName.trim().charAt(0) || 'ব';
  }

  get welcomeName(): string {
    return this.displayName() || (this.auth.isAdmin ? 'প্রশাসক' : '');
  }

  get navItems(): NavItem[] {
    return NAV_ITEMS.filter((item) => {
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
