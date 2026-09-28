import { inject } from '@angular/core';
import { Router, type CanActivateFn } from '@angular/router';
import { AuthService, FEE_MANAGER_PERMISSION } from '../services/auth.service';

/**
 * Restricts a route to specific roles (shared config - see MEMBER_PAYMENT_ROLES
 * in auth.service.ts). Fee managers are redirected to Fee Settings, their own
 * area, instead of the 403 page; everyone else lands on the dashboard.
 */
export const roleGuard = (allowedRoles: readonly string[]): CanActivateFn => {
  return () => {
    const auth = inject(AuthService);
    const router = inject(Router);

    const role = auth.role;
    if (role !== null && allowedRoles.includes(role)) {
      return true;
    }
    if (auth.hasPermission(FEE_MANAGER_PERMISSION)) {
      return router.createUrlTree(['/fee-settings']);
    }
    return router.createUrlTree(['/dashboard']);
  };
};
