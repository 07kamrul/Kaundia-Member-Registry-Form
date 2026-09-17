import { Component } from '@angular/core';
import { Router, RouterLink, RouterOutlet } from '@angular/router';
import { ThemeService } from '../../core/services/theme.service';
import { IconComponent } from '../../shared/icon/icon.component';

/**
 * Shared chrome for the public-facing pages (home, registration, login) —
 * sticky header with brand mark + gold rule + nav actions, and a footer,
 * matching the reference prototype's `<header>`/`<footer>` wrapper that
 * every one of its views renders inside.
 */
@Component({
  selector: 'app-public-shell',
  standalone: true,
  imports: [RouterLink, RouterOutlet, IconComponent],
  templateUrl: './public-shell.component.html',
  styleUrl: './public-shell.component.scss',
})
export class PublicShellComponent {
  constructor(
    public theme: ThemeService,
    private router: Router,
  ) {}

  goHome(): void {
    this.router.navigate(['/']);
  }
}
