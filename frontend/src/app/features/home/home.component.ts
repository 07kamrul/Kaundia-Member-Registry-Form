import { Component, OnInit, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslatePipe } from '@ngx-translate/core';
import { IconComponent } from '../../shared/icon/icon.component';
import { PublicStatsService } from '../../core/services/public-stats.service';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [RouterLink, IconComponent, TranslatePipe],
  templateUrl: './home.component.html',
})
export class HomeComponent implements OnInit {
  private readonly publicStatsService = inject(PublicStatsService);

  pendingCount = 0;
  approvedCount = 0;
  monthlySubscriptionTotal = 0;

  ngOnInit(): void {
    this.publicStatsService.getStats().subscribe({
      next: (stats) => {
        this.pendingCount = stats.pendingCount || 0;
        this.approvedCount = stats.approvedCount || 0;
        this.monthlySubscriptionTotal = stats.monthlySubscriptionTotal || 0;
      },
      error: () => {
        this.pendingCount = 0;
        this.approvedCount = 0;
        this.monthlySubscriptionTotal = 0;
      },
    });
  }
}
