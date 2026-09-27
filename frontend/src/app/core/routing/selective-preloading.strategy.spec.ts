import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { AuthService } from '../services/auth.service';
import { SelectivePreloadingStrategy } from './selective-preloading.strategy';

describe('SelectivePreloadingStrategy', () => {
  function strategy(permissions: string[]): SelectivePreloadingStrategy {
    TestBed.configureTestingModule({
      providers: [
        {
          provide: AuthService,
          useValue: {
            hasAnyPermission: (keys: string[]) => keys.some((k) => permissions.includes(k)),
          },
        },
      ],
    });
    return TestBed.inject(SelectivePreloadingStrategy);
  }

  function preload(
    strategy: SelectivePreloadingStrategy,
    data: Record<string, unknown> | undefined,
  ): { called: boolean; value: unknown } {
    let called = false;
    let value: unknown;
    strategy
      .preload({ path: 'x', data } as never, () => {
        called = true;
        return of('chunk');
      })
      .subscribe((v) => (value = v));
    return { called, value };
  }

  it('preloads routes with no requiredPermissions for every session', () => {
    const result = preload(strategy([]), undefined);
    expect(result.called).toBe(true);
    expect(result.value).toBe('chunk');
  });

  it('preloads gated routes when the session holds one of the required permissions', () => {
    const result = preload(strategy(['manage_roles']), {
      requiredPermissions: ['manage_roles', 'manage_users'],
    });
    expect(result.called).toBe(true);
    expect(result.value).toBe('chunk');
  });

  it('does not download gated chunks for a session missing every required permission', () => {
    const result = preload(strategy([]), { requiredPermissions: ['manage_roles'] });
    expect(result.called).toBe(false);
    expect(result.value).toBeNull();
  });
});
