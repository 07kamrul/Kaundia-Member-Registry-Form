import { Component, signal } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import { IconComponent, type IconName } from '../../shared/icon/icon.component';

interface NavItem {
  label: string;
  route: string;
  icon: IconName;
  adminOnly: boolean;
}

const NAV_ITEMS: NavItem[] = [
  { label: 'ড্যাশবোর্ড', route: '/dashboard', icon: 'dashboard', adminOnly: false },
  { label: 'প্রোফাইল', route: '/profile', icon: 'user', adminOnly: false },
  { label: 'কিস্তি', route: '/installments', icon: 'wallet', adminOnly: false },
  { label: 'পাসওয়ার্ড পরিবর্তন', route: '/change-password', icon: 'lock', adminOnly: false },
  { label: 'সাবমিশন', route: '/submissions', icon: 'inbox', adminOnly: true },
  { label: 'সদস্য তালিকা', route: '/members', icon: 'users', adminOnly: true },
];

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [RouterLink, RouterLinkActive, RouterOutlet, IconComponent],
  templateUrl: './shell.component.html',
  styleUrl: './shell.component.scss',
})
export class ShellComponent {
  readonly sidebarOpen = signal(false);

  constructor(
    public auth: AuthService,
    private router: Router,
  ) {}

  get navItems(): NavItem[] {
    return NAV_ITEMS.filter((item) => !item.adminOnly || this.auth.isAdmin);
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
