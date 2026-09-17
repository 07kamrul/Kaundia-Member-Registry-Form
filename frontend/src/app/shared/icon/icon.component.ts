import { Component, Input } from '@angular/core';

export type IconName =
  | 'dashboard'
  | 'user'
  | 'wallet'
  | 'lock'
  | 'inbox'
  | 'users'
  | 'logout'
  | 'menu'
  | 'close'
  | 'chevron-right'
  | 'chevron-left'
  | 'sun'
  | 'moon'
  | 'trash'
  | 'check'
  | 'x';

const ICON_PATHS: Record<IconName, string> = {
  dashboard:
    '<rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/>',
  user: '<circle cx="12" cy="8" r="3.5"/><path d="M5 20c0-3.87 3.13-7 7-7s7 3.13 7 7"/>',
  wallet:
    '<rect x="3" y="6" width="18" height="13" rx="2"/><path d="M3 10h18"/><circle cx="16.5" cy="14.5" r="1.25"/>',
  lock: '<rect x="4.5" y="10.5" width="15" height="10" rx="2"/><path d="M8 10.5V7a4 4 0 0 1 8 0v3.5"/>',
  inbox:
    '<path d="M3 12h4.5l1.5 3h6l1.5-3H21"/><path d="M5 5h14l2 7v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-6z"/>',
  users:
    '<circle cx="9" cy="8" r="3"/><path d="M2.5 20c0-3.31 2.91-6 6.5-6s6.5 2.69 6.5 6"/><circle cx="17.5" cy="8.5" r="2.25"/><path d="M15.5 14.2c2.9.4 5 2.7 5 5.8"/>',
  logout:
    '<path d="M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3"/><path d="M10 8l-4 4 4 4"/><path d="M6 12h12"/>',
  menu: '<path d="M4 6h16"/><path d="M4 12h16"/><path d="M4 18h16"/>',
  close: '<path d="M6 6l12 12"/><path d="M18 6L6 18"/>',
  'chevron-right': '<path d="M9 6l6 6-6 6"/>',
  'chevron-left': '<path d="M15 6l-6 6 6 6"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M2 12h2M20 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4"/>',
  moon: '<path d="M21 12.8A9 9 0 1 1 11.2 3 7 7 0 0 0 21 12.8Z"/>',
  trash: '<path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="M6 6l1 15h10l1-15"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  x: '<path d="M18 6 6 18"/><path d="M6 6l12 12"/>',
};

@Component({
  selector: 'app-icon',
  standalone: true,
  template: `
    <svg
      [attr.width]="size"
      [attr.height]="size"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
      [innerHTML]="path"
    ></svg>
  `,
})
export class IconComponent {
  @Input() name: IconName = 'dashboard';
  @Input() size = 20;

  get path(): string {
    return ICON_PATHS[this.name];
  }
}
