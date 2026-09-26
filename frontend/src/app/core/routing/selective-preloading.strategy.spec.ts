import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { AuthService } from '../services/auth.service';
import { SelectivePreloadingStrategy } from './selective-preloading.strategy';

describe('SelectivePreloadingStrategy', () => {
  function strategy(isAdmin: boolean): SelectivePreloadingStrategy {
    TestBed.configureTestingModule({
      providers: [{ provide: AuthService, useValue: { isAdmin } }],
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

  it('preloads routes that are not admin-only for every session', () => {
    const result = preload(strategy(false), undefined);
    expect(result.called).toBe(true);
    expect(result.value).toBe('chunk');
  });

  it('preloads admin-only routes for admins', () => {
    const result = preload(strategy(true), { requiresAdmin: true });
    expect(result.called).toBe(true);
    expect(result.value).toBe('chunk');
  });

  it('does not download admin-only chunks for a non-admin session', () => {
    const result = preload(strategy(false), { requiresAdmin: true });
    expect(result.called).toBe(false);
    expect(result.value).toBeNull();
  });
});
