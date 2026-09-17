import { Component, signal } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import { ThemeService } from '../../core/services/theme.service';
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

const SIDEBAR_COLLAPSED_KEY = 'sidebarCollapsed';

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [RouterLink, RouterLinkActive, RouterOutlet, IconComponent],
  templateUrl: './shell.component.html',
  styleUrl: './shell.component.scss',
})
export class ShellComponent {
  readonly sidebarOpen = signal(false);
  readonly sidebarCollapsed = signal(this.readStoredCollapsed());

  constructor(
    public auth: AuthService,
    public theme: ThemeService,
    private router: Router,
  ) {}

  get navItems(): NavItem[] {
    return NAV_ITEMS.filter((item) => {
      if (item.requiredPermission) {
        return this.auth.hasPermission(item.requiredPermission);
      }
      return !item.adminOnly || this.auth.isAdmin;
    });
  }

  get pageTitle(): string {
    const activeRoute = this.router.url.split('?')[0];
    const match = NAV_ITEMS.find((item) => activeRoute.startsWith(item.route));
    return match?.label ?? 'ড্যাশবোর্ড';
  }

  toggleSidebar(): void {
    this.sidebarOpen.update((open) => !open);
  }

  closeSidebar(): void {
    this.sidebarOpen.set(false);
  }

  toggleCollapse(): void {
    this.sidebarCollapsed.update((collapsed) => {
      const next = !collapsed;
      this.storeCollapsed(next);
      return next;
    });
  }

  logout(): void {
    this.auth.logout();
    this.router.navigate(['/login']);
  }

  private readStoredCollapsed(): boolean {
    try {
      return localStorage.getItem(SIDEBAR_COLLAPSED_KEY) === 'true';
    } catch {
      return false;
    }
  }

  private storeCollapsed(value: boolean): void {
    try {
      localStorage.setItem(SIDEBAR_COLLAPSED_KEY, String(value));
    } catch {
      // localStorage unavailable (private mode, SSR) — collapse state just won't persist.
    }
  }
}
