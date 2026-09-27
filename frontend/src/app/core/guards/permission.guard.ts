import { inject } from '@angular/core';
import { Router, type CanActivateFn } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const permissionGuard = (requiredPermissionKeys: string[]): CanActivateFn => {
  return (_route, state) => {
    const auth = inject(AuthService);
    const router = inject(Router);

    if (!auth.token) {
      return router.createUrlTree(['/login'], { queryParams: { returnUrl: state.url } });
    }
    if (auth.hasAnyPermission(requiredPermissionKeys)) {
      return true;
    }

    return router.createUrlTree(['/403']);
  };
};
