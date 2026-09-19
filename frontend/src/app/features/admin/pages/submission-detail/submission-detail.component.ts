import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import type { SubmissionDetail } from '../../../../core/models/admin.model';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';

/** A single label/value row rendered inside a property or nominee card. */
export interface DetailField {
  label: string;
  value: string;
}

/** A card of label/value rows built from one raw property or nominee record. */
export interface DetailCard {
  title: string;
  fields: DetailField[];
}

/** Translation keys for known property/nominee record keys. */
const FIELD_LABEL_KEYS: Record<string, string> = {
  type: 'admin.submissionDetail.fieldLabels.type',
  category: 'admin.submissionDetail.fieldLabels.type',
  address: 'admin.submissionDetail.fieldLabels.address',
  location: 'admin.submissionDetail.fieldLabels.address',
  area: 'admin.submissionDetail.fieldLabels.area',
  size: 'admin.submissionDetail.fieldLabels.area',
  description: 'admin.submissionDetail.fieldLabels.description',
  name: 'admin.submissionDetail.fieldLabels.name',
  relation: 'admin.submissionDetail.fieldLabels.relation',
  relationship: 'admin.submissionDetail.fieldLabels.relation',
  mobile: 'admin.submissionDetail.fieldLabels.mobile',
  phone: 'admin.submissionDetail.fieldLabels.mobile',
  nid: 'admin.submissionDetail.fieldLabels.nid',
  percentage: 'admin.submissionDetail.fieldLabels.percentage',
  share: 'admin.submissionDetail.fieldLabels.percentage',
  dob: 'admin.submissionDetail.fieldLabels.dob',
  address_1: 'admin.submissionDetail.fieldLabels.address',
};

function humanizeKey(key: string, translate: TranslateService): string {
  const translationKey = FIELD_LABEL_KEYS[key];
  return translationKey ? translate.instant(translationKey) : key.replace(/_/g, ' ');
}

function toDetailCard(
  record: unknown,
  index: number,
  titlePrefix: string,
  translate: TranslateService,
): DetailCard {
  const title = `${titlePrefix} ${index + 1}`;
  if (typeof record !== 'object' || record === null) {
    return {
      title,
      fields: [
        {
          label: translate.instant('admin.submissionDetail.fieldLabels.value'),
          value: String(record),
        },
      ],
    };
  }
  const fields = Object.entries(record as Record<string, unknown>)
    .filter(([, value]) => value !== null && value !== undefined && value !== '')
    .map(([key, value]) => ({ label: humanizeKey(key, translate), value: String(value) }));
  return { title, fields };
}

@Component({
  selector: 'app-submission-detail',
  standalone: true,
  imports: [FormsModule, ConfirmModalComponent, TranslatePipe],
  templateUrl: './submission-detail.component.html',
})
export class SubmissionDetailComponent implements OnInit {
  submission: SubmissionDetail | null = null;
  loading = false;
  error = '';
  actionError = '';
  rejectReason = '';
  showApproveModal = false;
  showRejectModal = false;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private adminService: AdminService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

  get propertyCards(): DetailCard[] {
    return (this.submission?.properties ?? []).map((item, index) =>
      toDetailCard(
        item,
        index,
        this.translate.instant('admin.submissionDetail.propertyCardTitle'),
        this.translate,
      ),
    );
  }

  get nomineeCards(): DetailCard[] {
    return (this.submission?.nominees ?? []).map((item, index) =>
      toDetailCard(
        item,
        index,
        this.translate.instant('admin.submissionDetail.nomineeCardTitle'),
        this.translate,
      ),
    );
  }

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) return;
    this.loading = true;
    this.adminService.getSubmission(id).subscribe({
      next: (data) => {
        this.submission = data;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.submissionDetail.errors.loadFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  approve(): void {
    if (!this.submission) return;
    this.actionError = '';
    this.adminService.approveSubmission(this.submission.id).subscribe({
      next: () => this.router.navigate(['/submissions']),
      error: () => {
        this.actionError = this.translate.instant('admin.submissionDetail.errors.approveFailed');
        this.showApproveModal = false;
        this.cdr.markForCheck();
      },
    });
  }

  reject(): void {
    if (!this.submission || !this.rejectReason.trim()) {
      this.actionError = this.translate.instant('admin.submissionDetail.errors.reasonRequired');
      return;
    }
    this.actionError = '';
    this.adminService.rejectSubmission(this.submission.id, this.rejectReason).subscribe({
      next: () => this.router.navigate(['/submissions']),
      error: () => {
        this.actionError = this.translate.instant('admin.submissionDetail.errors.rejectFailed');
        this.showRejectModal = false;
        this.cdr.markForCheck();
      },
    });
  }
}
