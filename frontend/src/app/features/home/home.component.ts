import {
  Component,
  OnInit,
  inject,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslatePipe } from '@ngx-translate/core';
import { IconComponent } from '../../shared/icon/icon.component';
import { PublicStatsService } from '../../core/services/public-stats.service';

@Component({
  selector: 'app-home',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, IconComponent, TranslatePipe],
  templateUrl: './home.component.html',
})
export class HomeComponent implements OnInit {
  private readonly publicStatsService = inject(PublicStatsService);

  pendingCount = 0;
  approvedCount = 0;
  monthlySubscriptionTotal = 0;
  private readonly cdr = inject(ChangeDetectorRef);

  ngOnInit(): void {
    this.publicStatsService.getStats().subscribe({
      next: (stats) => {
        this.pendingCount = stats.pendingCount || 0;
        this.approvedCount = stats.approvedCount || 0;
        this.monthlySubscriptionTotal = stats.monthlySubscriptionTotal || 0;
        this.cdr.markForCheck();
      },
      error: () => {
        this.pendingCount = 0;
        this.approvedCount = 0;
        this.monthlySubscriptionTotal = 0;
        this.cdr.markForCheck();
      },
    });
  }
}
