import { Component, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ThemeService } from './core/services/theme.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  template: '<router-outlet />',
})
export class App {
  // Injected (not just typed) so the theme is applied to <html> on every
  // route, including public pages (home/login/register) that sit outside
  // the authenticated shell and would otherwise never construct this
  // service — leaving data-theme unset and falling back to the OS's
  // prefers-color-scheme, which mismatched the prototype's fixed light look.
  private readonly theme = inject(ThemeService);
}
