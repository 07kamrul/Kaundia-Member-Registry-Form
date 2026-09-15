import { inject } from '@angular/core';
import type { HttpInterceptorFn } from '@angular/common/http';
import { catchError, throwError } from 'rxjs';
import { AuthService } from '../services/auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const token = auth.token;

  const authorizedReq = token
    ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
    : req;

  return next(authorizedReq).pipe(
    catchError((error: unknown) => {
      if (error instanceof Object && 'status' in error && (error as { status: number }).status === 401) {
        auth.handleUnauthorized();
      }
      return throwError(() => error);
    }),
  );
};
