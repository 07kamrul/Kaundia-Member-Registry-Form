import { inject } from '@angular/core';
import { Router, type CanActivateFn } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const permissionGuard = (requiredPermissionKeys: string[]): CanActivateFn => {
  return () => {
    const auth = inject(AuthService);
    const router = inject(Router);

    if (auth.token && auth.hasAnyPermission(requiredPermissionKeys)) {
      return true;
    }

    return router.createUrlTree(['/dashboard']);
  };
};
