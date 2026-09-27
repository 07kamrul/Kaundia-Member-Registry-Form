import { inject, Injectable } from '@angular/core';
import type { Route } from '@angular/router';
import { PreloadingStrategy } from '@angular/router';
import { Observable, of } from 'rxjs';
import { AuthService } from '../services/auth.service';

/**
 * Preloads lazy route chunks in the background after the first paint so
 * navigation doesn't stall on a network round-trip, but skips chunks the
 * current session can never navigate to.
 *
 * Routes opt out with `data: { requiredPermissions: string[] }`; those are
 * only fetched when the signed-in user actually holds one of the listed
 * permission keys, so e.g. a member's browser doesn't download the
 * submissions/RBAC code it can never reach.
 */
@Injectable({ providedIn: 'root' })
export class SelectivePreloadingStrategy implements PreloadingStrategy {
  private readonly auth = inject(AuthService);

  preload(route: Route, fn: () => Observable<any>): Observable<any> {
    const requiredPermissions = route.data?.['requiredPermissions'] as string[] | undefined;
    if (requiredPermissions && !this.auth.hasAnyPermission(requiredPermissions)) return of(null);
    return fn();
  }
}
