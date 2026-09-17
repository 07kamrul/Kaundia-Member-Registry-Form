import { Component, Input } from '@angular/core';
import { DomSanitizer, type SafeHtml } from '@angular/platform-browser';

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
  | 'x'
  | 'sparkle'
  | 'shield'
  | 'doc'
  | 'coin'
  | 'arrowleft';

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
  sparkle:
    '<path d="M12 2l1.8 5.4L19 9l-5.2 1.6L12 16l-1.8-5.4L5 9l5.2-1.6z"/><path d="M19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8z"/>',
  shield: '<path d="M12 3l7 3v5c0 4.5-3 8-7 10-4-2-7-5.5-7-10V6z"/>',
  doc: '<path d="M7 3h7l4 4v14H7z"/><path d="M14 3v4h4"/><path d="M9.5 12h5M9.5 15.5h5"/>',
  coin: '<circle cx="12" cy="12" r="8.5"/><path d="M9.5 15.5V9.8c0-1 .8-1.8 1.8-1.8h.4c1 0 1.8.8 1.8 1.8v.2M9.5 12.3h4.5"/>',
  arrowleft: '<path d="M19 12H5"/><path d="M11 6l-6 6 6 6"/>',
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

  constructor(private sanitizer: DomSanitizer) {}

  // The SVG path data is a fixed, hardcoded lookup table (ICON_PATHS above),
  // never user input, so trusting it here is safe. Angular's default HTML
  // sanitizer strips <path>/<rect>/<circle> children from an [innerHTML]
  // binding (they aren't in its safe-HTML allowlist), which silently
  // rendered every icon as an empty box — bypassing sanitization for this
  // known-static markup is what actually makes icons paint.
  get path(): SafeHtml {
    return this.sanitizer.bypassSecurityTrustHtml(ICON_PATHS[this.name]);
  }
}
