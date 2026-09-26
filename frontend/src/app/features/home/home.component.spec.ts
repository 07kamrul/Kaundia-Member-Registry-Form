import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { provideTranslateService } from '@ngx-translate/core';
import { provideRouter } from '@angular/router';
import { HomeComponent } from './home.component';
import { PublicStatsService, type PublicStats } from '../../core/services/public-stats.service';

describe('HomeComponent (OnPush)', () => {
  const stats: PublicStats = {
    pendingCount: 4,
    approvedCount: 11,
    monthlySubscriptionTotal: 250,
  };

  function setup(result: PublicStats | 'error') {
    TestBed.configureTestingModule({
      imports: [HomeComponent],
      providers: [
        provideRouter([]),
        provideTranslateService(),
        {
          provide: PublicStatsService,
          useValue: {
            getStats: () =>
              result === 'error'
                ? // eslint-disable-next-line rxjs/no-throw-error
                  { subscribe: ({ error }: { error: () => void }) => error() }
                : of(result),
          },
        },
      ],
    });
    return TestBed.createComponent(HomeComponent);
  }

  it('renders loaded stats despite OnPush', () => {
    const fixture = setup(stats);
    fixture.detectChanges();
    const text: string = fixture.nativeElement.textContent;
    expect(text).toContain('4');
    expect(text).toContain('11');
    expect(text).toContain('250');
  });

  it('falls back to zeros when the stats request fails', () => {
    const fixture = setup('error');
    fixture.detectChanges();
    expect(fixture.componentInstance.pendingCount).toBe(0);
    expect(fixture.componentInstance.approvedCount).toBe(0);
    expect(fixture.componentInstance.monthlySubscriptionTotal).toBe(0);
  });
});
