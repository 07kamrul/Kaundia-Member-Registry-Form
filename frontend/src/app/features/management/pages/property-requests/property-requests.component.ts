import { ChangeDetectorRef, Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import {
  AdminService,
  toFileUrl,
} from '../../../../core/services/admin.service';
import {
  type MemberPropertyRequest,
  type PropertyRequestStatus,
} from '../../../../core/services/member.service';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';
import { IconComponent } from '../../../../shared/icon/icon.component';

@Component({
  selector: 'app-property-requests',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, ConfirmModalComponent, IconComponent, DatePipe, TranslatePipe],
  templateUrl: './property-requests.component.html',
  styleUrl: './property-requests.component.scss',
})
export class PropertyRequestsComponent implements OnInit {
  requests: MemberPropertyRequest[] = [];
  statusFilter: PropertyRequestStatus | '' = 'pending';
  loading = false;
  error = '';

  readonly statuses: Array<PropertyRequestStatus | ''> = ['', 'pending', 'approved', 'cancelled'];

  /** Request ids whose payload detail row is expanded. */
  expandedIds = new Set<number>();

  actionError = '';
  showApproveModal = false;
  showCancelModal = false;
  activeRequest: MemberPropertyRequest | null = null;
  cancelReason = '';
  approving = false;
  cancelling = false;

  constructor(
    private adminService: AdminService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.error = '';
    this.adminService.listPropertyRequests(this.statusFilter || undefined).subscribe({
      next: (data) => {
        this.requests = data;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.propertyRequests.errors.loadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  onFilterChange(event: Event): void {
    this.statusFilter = (event.target as HTMLSelectElement).value as PropertyRequestStatus | '';
    this.load();
  }

  referenceFor(request: MemberPropertyRequest): string {
    const year = new Date(request.createdAt).getFullYear() || new Date().getFullYear();
    return `PR-${year}-${String(request.id).padStart(4, '0')}`;
  }

  statusLabel(status: PropertyRequestStatus | ''): string {
    return this.translate.instant(
      `admin.propertyRequests.statusLabels.${status || 'all'}`,
    );
  }

  actionLabel(action: MemberPropertyRequest['action']): string {
    return this.translate.instant(`admin.propertyRequests.actions.${action}`);
  }

  /** Short property description from the payload (khatian / dag numbers). */
  propertySummary(request: MemberPropertyRequest): string {
    const p = request.payload;
    const parts: string[] = [];
    const types = [...p.propertyType, p.propertyTypeOther ?? ''].filter(Boolean);
    if (types.length) parts.push(types.join(' / '));
    if (p.khatianNo) parts.push(`Khatian ${p.khatianNo}`);
    if (p.dagNoCs) parts.push(`CS ${p.dagNoCs}`);
    if (p.dagNoRs) parts.push(`RS ${p.dagNoRs}`);
    return parts.join(' · ');
  }

  isExpanded(id: number): boolean {
    return this.expandedIds.has(id);
  }

  toggleExpanded(id: number): void {
    if (this.expandedIds.has(id)) {
      this.expandedIds.delete(id);
    } else {
      this.expandedIds.add(id);
    }
  }

  payloadRows(request: MemberPropertyRequest): Array<{ label: string; value: string }> {
    const p = request.payload;
    const rows: Array<{ label: string; value: string }> = [];
    const add = (labelKey: string, value?: string | null) => {
      const text = (value ?? '').trim();
      if (text) rows.push({ label: this.translate.instant(labelKey), value: text });
    };
    const types = [...p.propertyType, p.propertyTypeOther ?? ''].filter(Boolean);
    add('registration.property.typeLabel', types.join(' / '));
    add('registration.property.khatianNoLabel', p.khatianNo);
    add('member.profile.dagNoCsLabel', p.dagNoCs);
    add('member.profile.dagNoRsLabel', p.dagNoRs);
    add('registration.property.holdingNumberLabel', p.holdingNumber);
    add('registration.property.landQuantityLabel', p.landQuantity);
    add('registration.property.myShareQuantityLabel', p.myShareQuantity);
    add('registration.property.ownershipLabel', p.ownership);
    if (p.coOwners.length) {
      add(
        'member.profile.coOwnerLabel',
        p.coOwners.map((c) => `${c.ownerName} (${c.ownerPhone})`).join(', '),
      );
    }
    if (p.docs.length) {
      add(
        'member.profile.documentLabel',
        p.docs.map((d) => d.docType).join(', '),
      );
    }
    return rows;
  }

  docUrl(request: MemberPropertyRequest, doc: { docType: string; keepPath: string | null }): string | undefined {
    return toFileUrl(doc.keepPath);
  }

  /* ---------- approve / cancel ---------- */

  openApproveModal(request: MemberPropertyRequest): void {
    this.activeRequest = request;
    this.actionError = '';
    this.showApproveModal = true;
  }

  openCancelModal(request: MemberPropertyRequest): void {
    this.activeRequest = request;
    this.cancelReason = '';
    this.actionError = '';
    this.showCancelModal = true;
  }

  approve(): void {
    if (!this.activeRequest || this.approving) return;
    this.approving = true;
    this.actionError = '';
    this.adminService.approvePropertyRequest(this.activeRequest.id).subscribe({
      next: () => {
        this.approving = false;
        this.showApproveModal = false;
        this.load();
      },
      error: (err) => {
        this.approving = false;
        this.showApproveModal = false;
        const detail = typeof err?.error?.detail === 'string' ? err.error.detail : '';
        this.actionError =
          detail || this.translate.instant('admin.propertyRequests.errors.approveFailed');
        this.cdr.markForCheck();
      },
    });
  }

  cancel(): void {
    const reason = this.cancelReason.trim();
    if (!this.activeRequest || !reason) {
      this.actionError = this.translate.instant('admin.propertyRequests.errors.reasonRequired');
      return;
    }
    if (this.cancelling) return;
    this.cancelling = true;
    this.actionError = '';
    this.adminService.cancelPropertyRequest(this.activeRequest.id, reason).subscribe({
      next: () => {
        this.cancelling = false;
        this.showCancelModal = false;
        this.load();
      },
      error: (err) => {
        this.cancelling = false;
        this.showCancelModal = false;
        const detail = typeof err?.error?.detail === 'string' ? err.error.detail : '';
        this.actionError =
          detail || this.translate.instant('admin.propertyRequests.errors.cancelFailed');
        this.cdr.markForCheck();
      },
    });
  }
}
