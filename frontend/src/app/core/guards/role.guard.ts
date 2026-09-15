import { inject } from '@angular/core';
import { Router, type CanActivateFn } from '@angular/router';
import { AuthService, type UserRole } from '../services/auth.service';

export const roleGuard = (allowedRoles: UserRole[]): CanActivateFn => {
  return () => {
    const auth = inject(AuthService);
    const router = inject(Router);

    if (auth.token && auth.role && allowedRoles.includes(auth.role)) {
      return true;
    }

    return router.createUrlTree(['/dashboard']);
  };
};
