import { inject } from '@angular/core';
import { Router, type CanActivateFn } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = (route, state) => {
  const auth = inject(AuthService);
  const router = inject(Router);

  if (!auth.token) {
    return router.createUrlTree(['/login'], { queryParams: { returnUrl: state.url } });
  }

  // A member with an admin-issued temporary password must set a new one
  // before reaching any other page. Admin-tier accounts are exempt: the
  // backend has no admin change-password endpoint, so hard-blocking them
  // would lock the account until an email-token reset.
  if (
    auth.mustChangePassword &&
    auth.role === 'member' &&
    state.url !== '/change-password' &&
    route.routeConfig?.path !== 'change-password'
  ) {
    return router.createUrlTree(['/change-password']);
  }

  return true;
};
