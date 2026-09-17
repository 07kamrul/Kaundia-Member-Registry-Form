import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
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

/** Human-readable Bangla labels for known property/nominee record keys. */
const FIELD_LABELS: Record<string, string> = {
  type: 'ধরন',
  category: 'ধরন',
  address: 'ঠিকানা',
  location: 'ঠিকানা',
  area: 'পরিমাণ',
  size: 'পরিমাণ',
  description: 'বিবরণ',
  name: 'নাম',
  relation: 'সম্পর্ক',
  relationship: 'সম্পর্ক',
  mobile: 'মোবাইল',
  phone: 'মোবাইল',
  nid: 'NID',
  percentage: 'শতাংশ',
  share: 'শতাংশ',
  dob: 'জন্ম তারিখ',
  address_1: 'ঠিকানা',
};

function humanizeKey(key: string): string {
  return FIELD_LABELS[key] ?? key.replace(/_/g, ' ');
}

function toDetailCard(record: unknown, index: number, titlePrefix: string): DetailCard {
  const title = `${titlePrefix} ${index + 1}`;
  if (typeof record !== 'object' || record === null) {
    return { title, fields: [{ label: 'মান', value: String(record) }] };
  }
  const fields = Object.entries(record as Record<string, unknown>)
    .filter(([, value]) => value !== null && value !== undefined && value !== '')
    .map(([key, value]) => ({ label: humanizeKey(key), value: String(value) }));
  return { title, fields };
}

@Component({
  selector: 'app-submission-detail',
  standalone: true,
  imports: [FormsModule, ConfirmModalComponent],
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
  ) {}

  get propertyCards(): DetailCard[] {
    return (this.submission?.properties ?? []).map((item, index) =>
      toDetailCard(item, index, 'সম্পত্তি'),
    );
  }

  get nomineeCards(): DetailCard[] {
    return (this.submission?.nominees ?? []).map((item, index) =>
      toDetailCard(item, index, 'মনোনীত ব্যক্তি'),
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
      },
      error: () => {
        this.error = 'আবেদনের তথ্য পাওয়া যায়নি।';
        this.loading = false;
      },
    });
  }

  approve(): void {
    if (!this.submission) return;
    this.actionError = '';
    this.adminService.approveSubmission(this.submission.id).subscribe({
      next: () => this.router.navigate(['/submissions']),
      error: () => {
        this.actionError = 'অনুমোদন ব্যর্থ হয়েছে।';
        this.showApproveModal = false;
      },
    });
  }

  reject(): void {
    if (!this.submission || !this.rejectReason.trim()) {
      this.actionError = 'বাতিলের কারণ লিখুন।';
      return;
    }
    this.actionError = '';
    this.adminService.rejectSubmission(this.submission.id, this.rejectReason).subscribe({
      next: () => this.router.navigate(['/submissions']),
      error: () => {
        this.actionError = 'বাতিল করা ব্যর্থ হয়েছে।';
        this.showRejectModal = false;
      },
    });
  }
}
