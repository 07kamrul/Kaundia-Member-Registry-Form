import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { DomSanitizer, type SafeResourceUrl } from '@angular/platform-browser';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService } from '../../../../core/services/admin.service';
import type {
  ApplicableDoc,
  CoOwner,
  EmergencyContact,
  Nominee,
  SubmissionDetail,
  SubmissionProperty,
} from '../../../../core/models/admin.model';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';
import { IconComponent } from '../../../../shared/icon/icon.component';

@Component({
  selector: 'app-submission-detail',
  standalone: true,
  imports: [FormsModule, ConfirmModalComponent, TranslatePipe, IconComponent],
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
  previewImageUrl: string | null = null;
  previewImageAlt = '';
  previewIsImage = true;
  copiedKey: string | null = null;
  expandedPropertyIds = new Set<string>();

  private copyResetTimer: ReturnType<typeof setTimeout> | null = null;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private adminService: AdminService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
    private sanitizer: DomSanitizer,
  ) {}

  /** Sanitized URL for embedding non-image previews (e.g. PDF) in an iframe. */
  get previewFrameUrl(): SafeResourceUrl {
    return this.sanitizer.bypassSecurityTrustResourceUrl(this.previewImageUrl ?? '');
  }

  /** Only allow review actions once the submission has finished loading without error. */
  get isReviewReady(): boolean {
    return !this.loading && !this.error && this.submission !== null;
  }

  /** Avatar fallback initials when no member photo is available. */
  get applicantInitials(): string {
    return this.initials(this.submission?.fullName);
  }

  /** Typed view of the emergency-contact fields on the submission. */
  get emergencyContact(): EmergencyContact | null {
    if (!this.submission) return null;
    const { urgentContactName, urgentContactRelation, urgentContactMobile, urgentContactAddress } =
      this.submission;
    if (!urgentContactName && !urgentContactMobile && !urgentContactAddress) return null;
    return {
      name: urgentContactName,
      relation: urgentContactRelation,
      mobile: urgentContactMobile,
      address: urgentContactAddress,
    };
  }

  /** True when the emergency contact is also listed as a nominee. */
  get emergencyAlsoNominee(): boolean {
    const emergency = this.emergencyContact;
    if (!emergency || !this.submission) return false;
    return this.submission.nominees.some((nominee) => this.samePerson(emergency, nominee));
  }

  /** True when the emergency contact matches the applicant themself. */
  get emergencyIsApplicant(): boolean {
    const emergency = this.emergencyContact;
    if (!emergency || !this.submission) return false;
    return this.samePerson(emergency, {
      name: this.submission.fullName,
      mobile: this.submission.mobile,
    });
  }

  /** Sum of nominee share percentages (only nominees that declare one). */
  get nomineeShareTotal(): number {
    if (!this.submission) return 0;
    return this.submission.nominees.reduce(
      (sum, nominee) =>
        sum + (typeof nominee.sharePercentage === 'number' ? nominee.sharePercentage : 0),
      0,
    );
  }

  get nomineeShareDeclared(): boolean {
    if (!this.submission) return false;
    return this.submission.nominees.some((nominee) => typeof nominee.sharePercentage === 'number');
  }

  get nomineeShareWarning(): boolean {
    return this.nomineeShareDeclared && Math.round(this.nomineeShareTotal) !== 100;
  }

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) return;
    this.loading = true;
    this.adminService.getSubmission(id).subscribe({
      next: (data) => {
        this.submission = data;
        // First property expanded by default; the rest start collapsed.
        this.expandedPropertyIds = new Set(
          data.properties.slice(0, 1).map((property) => property.id),
        );
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

  /* ---------- shared field helpers ---------- */

  initials(name?: string | null): string {
    const trimmed = (name ?? '').trim();
    if (!trimmed) return '?';
    return trimmed
      .split(/\s+/)
      .slice(0, 2)
      .map((part) => part.charAt(0))
      .join('')
      .toUpperCase();
  }

  displayValue(value?: string | number | null): string {
    if (value === null || value === undefined) return '';
    const text = String(value).trim();
    return text;
  }

  /** Muted placeholder for empty values (em dash / "Not provided"). */
  emptyValue(): string {
    return this.translate.instant('admin.submissionDetail.notProvided');
  }

  formatLandQuantity(quantity?: string | null): { value: string; unit: string } {
    const text = (quantity ?? '').trim();
    if (!text) return { value: '', unit: '' };
    if (/^\d+(\.\d+)?$/.test(text)) {
      return { value: text, unit: this.translate.instant('admin.submissionDetail.decimalUnit') };
    }
    return { value: text, unit: '' };
  }

  propertyTypeLabel(property: SubmissionProperty): string {
    const types = (property.propertyType ?? []).filter(Boolean);
    const other = property.propertyTypeOther?.trim();
    if (other) types.push(other);
    return types.join(', ');
  }

  ownershipKind(ownership?: string | null): 'single' | 'joint' | 'other' {
    const value = (ownership ?? '').trim().toLowerCase();
    if (!value) return 'other';
    if (value.includes('একক') || value.includes('single')) return 'single';
    if (value.includes('যৌথ') || value.includes('joint')) return 'joint';
    return 'other';
  }

  telHref(mobile?: string | null): string {
    const digits = (mobile ?? '').replace(/[^\d+]/g, '');
    return digits ? `tel:${digits}` : '';
  }

  copyText(scope: string, value?: string | null): void {
    const text = (value ?? '').trim();
    if (!text) return;
    const key = `${scope}:${text}`;
    const write =
      typeof navigator !== 'undefined' && navigator.clipboard?.writeText
        ? navigator.clipboard.writeText(text)
        : this.fallbackCopy(text);

    Promise.resolve(write)
      .then(() => {
        this.copiedKey = key;
        if (this.copyResetTimer) clearTimeout(this.copyResetTimer);
        this.copyResetTimer = setTimeout(() => {
          this.copiedKey = null;
          this.cdr.markForCheck();
        }, 1600);
        this.cdr.markForCheck();
      })
      .catch(() => undefined);
  }

  isCopied(scope: string, value?: string | null): boolean {
    return this.copiedKey === `${scope}:${(value ?? '').trim()}`;
  }

  private fallbackCopy(text: string): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        const area = document.createElement('textarea');
        area.value = text;
        area.setAttribute('readonly', '');
        area.style.position = 'fixed';
        area.style.opacity = '0';
        document.body.appendChild(area);
        area.select();
        const ok = document.execCommand('copy');
        document.body.removeChild(area);
        ok ? resolve() : reject(new Error('copy failed'));
      } catch (err) {
        reject(err);
      }
    });
  }

  /* ---------- person matching / roles ---------- */

  private normalize(value?: string | null): string {
    return (value ?? '').toLowerCase().replace(/[\s\-()+]/g, '');
  }

  private samePerson(
    a: { name?: string | null; mobile?: string | null },
    b: { name?: string | null; mobile?: string | null },
  ): boolean {
    const nameA = (a.name ?? '').trim().toLowerCase();
    const nameB = (b.name ?? '').trim().toLowerCase();
    const mobileA = this.normalize(a.mobile);
    const mobileB = this.normalize(b.mobile);
    if (nameA && nameB && nameA === nameB) return true;
    if (mobileA && mobileB && mobileA === mobileB) return true;
    return false;
  }

  /** Role tags for a co-owner: applicant / emergency / nominee (can be several). */
  coOwnerRoles(owner: CoOwner): Array<'applicant' | 'emergency' | 'nominee'> {
    const roles: Array<'applicant' | 'emergency' | 'nominee'> = [];
    if (!this.submission) return roles;
    if (
      this.samePerson(owner, { name: this.submission.fullName, mobile: this.submission.mobile })
    ) {
      roles.push('applicant');
    }
    const emergency = this.emergencyContact;
    if (emergency && this.samePerson(owner, emergency)) roles.push('emergency');
    if (this.submission.nominees.some((nominee) => this.samePerson(owner, nominee))) {
      roles.push('nominee');
    }
    return roles;
  }

  isApplicantRow(owner: CoOwner): boolean {
    return this.coOwnerRoles(owner).includes('applicant');
  }

  /** True when a nominee's details match the emergency contact. */
  nomineeMatchesEmergency(nominee: Nominee): boolean {
    const emergency = this.emergencyContact;
    return !!emergency && this.samePerson(nominee, emergency);
  }

  nomineeMatchesApplicant(nominee: Nominee): boolean {
    if (!this.submission) return false;
    return this.samePerson(nominee, {
      name: this.submission.fullName,
      mobile: this.submission.mobile,
    });
  }

  /* ---------- co-owner duplicate mobiles ---------- */

  /** Mobile numbers used by more than one co-owner on this property. */
  duplicateMobiles(property: SubmissionProperty): Set<string> {
    const counts = new Map<string, number>();
    for (const owner of property.coOwners ?? []) {
      const key = this.normalize(owner.mobile);
      if (!key) continue;
      counts.set(key, (counts.get(key) ?? 0) + 1);
    }
    const dupes = new Set<string>();
    for (const owner of property.coOwners ?? []) {
      const key = this.normalize(owner.mobile);
      if (key && (counts.get(key) ?? 0) > 1) dupes.add(key);
    }
    return dupes;
  }

  isDuplicateMobile(property: SubmissionProperty, owner: CoOwner): boolean {
    return this.duplicateMobiles(property).has(this.normalize(owner.mobile));
  }

  /* ---------- property collapse ---------- */

  isPropertyExpanded(propertyId: string): boolean {
    return this.expandedPropertyIds.has(propertyId);
  }

  toggleProperty(propertyId: string): void {
    if (this.expandedPropertyIds.has(propertyId)) {
      this.expandedPropertyIds.delete(propertyId);
    } else {
      this.expandedPropertyIds.add(propertyId);
    }
  }

  propertySummary(property: SubmissionProperty): string {
    const parts: string[] = [];
    const type = this.propertyTypeLabel(property);
    if (type) parts.push(type);
    if (property.khatianNo) parts.push(`Khatian ${property.khatianNo}`);
    const qty = this.formatLandQuantity(property.landQuantity);
    if (qty.value) parts.push(qty.unit ? `${qty.value} ${qty.unit}` : qty.value);
    if (property.ownership) parts.push(property.ownership);
    return parts.join(' · ');
  }

  /* ---------- documents ---------- */

  docFileExtension(doc: ApplicableDoc): string {
    const url = doc.fileUrl ?? '';
    const match = url.split('?')[0].match(/\.([a-z0-9]+)$/i);
    if (match) return match[1].toUpperCase();
    if (doc.fileName) {
      const nameMatch = doc.fileName.match(/\.([a-z0-9]+)$/i);
      if (nameMatch) return nameMatch[1].toUpperCase();
    }
    return 'FILE';
  }

  docFileKind(doc: ApplicableDoc): 'image' | 'pdf' | 'file' {
    const ext = this.docFileExtension(doc);
    if (['JPG', 'JPEG', 'PNG', 'GIF', 'WEBP', 'SVG', 'AVIF'].includes(ext)) return 'image';
    if (ext === 'PDF') return 'pdf';
    return 'file';
  }

  docFileSizeLabel(doc: ApplicableDoc): string {
    if (typeof doc.fileSize === 'number' && doc.fileSize > 0) {
      if (doc.fileSize < 1024) return `${doc.fileSize} B`;
      if (doc.fileSize < 1024 * 1024) return `${Math.round(doc.fileSize / 1024)} KB`;
      return `${(doc.fileSize / (1024 * 1024)).toFixed(1)} MB`;
    }
    return this.docFileExtension(doc);
  }

  openDocPreview(doc: ApplicableDoc): void {
    if (!doc.fileUrl) return;
    this.previewImageUrl = doc.fileUrl;
    this.previewImageAlt = doc.docType;
    this.previewIsImage = this.docFileKind(doc) === 'image';
  }

  openPreview(url: string, altKey: string): void {
    this.previewImageUrl = url;
    this.previewImageAlt = this.translate.instant(altKey);
    this.previewIsImage = /\.(png|jpe?g|gif|webp|svg|avif)(\?|$)/i.test(url);
  }

  closePreview(): void {
    this.previewImageUrl = null;
    this.previewImageAlt = '';
    this.previewIsImage = true;
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
