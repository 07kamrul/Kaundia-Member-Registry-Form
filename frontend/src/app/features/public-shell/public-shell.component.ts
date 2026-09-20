import { Component } from '@angular/core';
import { Router, RouterLink, RouterOutlet } from '@angular/router';
import { TranslatePipe } from '@ngx-translate/core';
import { ThemeService } from '../../core/services/theme.service';
import { LanguageService } from '../../core/services/language.service';
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
  imports: [RouterLink, RouterOutlet, IconComponent, TranslatePipe],
  templateUrl: './public-shell.component.html',
  styleUrl: './public-shell.component.scss',
})
export class PublicShellComponent {
  isMobileMenuOpen = false;

  constructor(
    public theme: ThemeService,
    public lang: LanguageService,
    private router: Router,
  ) {}

  goHome(): void {
    this.closeMobileMenu();
    this.router.navigate(['/']);
  }

  toggleMobileMenu(): void {
    this.isMobileMenuOpen = !this.isMobileMenuOpen;
  }

  closeMobileMenu(): void {
    this.isMobileMenuOpen = false;
  }
}
