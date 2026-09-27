import { ChangeDetectorRef, Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { environment } from '../../../../../environments/environment';

export interface AuditLogEntry {
  id: string;
  actorAdminId: string | null;
  action: string;
  entityType: string;
  entityId: string;
  detail: string | null;
  createdAt: string;
}

interface AuditLogApiModel {
  id: number;
  actor_admin_id: number | null;
  action: string;
  entity_type: string;
  entity_id: string;
  detail: string | null;
  created_at: string;
}

@Component({
  selector: 'app-audit-log',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  templateUrl: './audit-log.component.html',
})
export class AuditLogComponent implements OnInit {
  entries: AuditLogEntry[] = [];
  loading = false;
  error = '';

  constructor(
    private http: HttpClient,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.loading = true;
    this.http.get<AuditLogApiModel[]>(`${environment.apiBaseUrl}/admin/audit-log`).subscribe({
      next: (rows) => {
        this.entries = rows.map((r) => ({
          id: String(r.id),
          actorAdminId: r.actor_admin_id !== null ? String(r.actor_admin_id) : null,
          action: r.action,
          entityType: r.entity_type,
          entityId: r.entity_id,
          detail: r.detail,
          createdAt: r.created_at,
        }));
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.auditLog.errors.loadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }
}
