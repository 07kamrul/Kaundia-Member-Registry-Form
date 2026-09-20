import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, type Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface PublicStats {
  pendingCount: number;
  approvedCount: number;
  monthlySubscriptionTotal: number;
}

interface PublicStatsApiModel {
  pending_count: number;
  approved_count: number;
  monthly_subscription_total: number;
}

function toPublicStats(api: PublicStatsApiModel): PublicStats {
  return {
    pendingCount: api.pending_count,
    approvedCount: api.approved_count,
    monthlySubscriptionTotal: api.monthly_subscription_total,
  };
}

@Injectable({ providedIn: 'root' })
export class PublicStatsService {
  constructor(private http: HttpClient) {}

  getStats(): Observable<PublicStats> {
    return this.http
      .get<PublicStatsApiModel>(`${environment.apiBaseUrl}/public/stats`)
      .pipe(map(toPublicStats));
  }
}
