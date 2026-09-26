import { DatePipe } from '@angular/common';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnDestroy,
  OnInit,
} from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { DomSanitizer, type SafeResourceUrl } from '@angular/platform-browser';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { AdminService, type AttachmentKind } from '../../../../core/services/admin.service';
import {
  AttachmentMissingError,
  AttachmentService,
} from '../../../../core/services/attachment.service';
import type {
  ApplicableDoc,
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
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, ConfirmModalComponent, TranslatePipe, IconComponent, DatePipe],
  templateUrl: './submission-detail.component.html',
})
export class SubmissionDetailComponent implements OnInit, OnDestroy {
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
  /** In-app error shown instead of a preview that is missing on the server. */
  previewError = '';
  /** True while a non-image preview is fetched (a missing file must not reach the iframe). */
  previewLoading = false;
  /** In-app error shown after a failed download; never navigate to a dead file URL. */
  attachmentError = '';
  /** File URLs that failed to load (e.g. the file is missing on the server). */
  brokenFileUrls: ReadonlySet<string> = new Set<string>();
  /** Attachment currently being re-uploaded, if any. */
  uploadingKind: AttachmentKind | null = null;
  uploadError = '';
  copiedKey: string | null = null;
  expandedPropertyIds = new Set<string>();

  private copyResetTimer: ReturnType<typeof setTimeout> | null = null;
  /** Object URL backing a blob preview; revoked when the preview closes. */
  private previewObjectUrl: string | null = null;
  /** Bumped whenever the preview target changes, to ignore stale loads. */
  private previewRequestId = 0;
  /** What the modal's download button should fetch, and under which name. */
  private previewTarget: { url: string; filename: string } | null = null;

  /* ---------- derived-value caches ----------
   *
   * The template for this page is large and re-reads these helpers on every
   * change-detection pass. They used to rebuild objects, rescan nominees and
   * re-run the URL sanitizer on each read. Everything below is computed once
   * per submission (or per preview URL) and invalidated when the source
   * changes, so a render pass costs map lookups instead of array scans.
   */

  private derivedFor: SubmissionDetail | null | undefined = undefined;
  private derivedInitials = '';
  private derivedEmergency: EmergencyContact | null = null;
  private derivedEmergencyAlsoNominee = false;
  private derivedEmergencyIsApplicant = false;
  private derivedShareTotal = 0;
  private derivedShareDeclared = false;
  private derivedShareWarning = false;
  private readonly duplicateMobilesByProperty = new Map<string, Set<string>>();
  private readonly emptyValueByLang = new Map<string, string>();
  private sanitizedFrameUrl: SafeResourceUrl | null = null;
  private sanitizedFrameUrlFor: string | null | undefined = undefined;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private adminService: AdminService,
    private attachments: AttachmentService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
    private sanitizer: DomSanitizer,
  ) {}

  /** Sanitized URL for embedding non-image previews (e.g. PDF) in an iframe. */
  get previewFrameUrl(): SafeResourceUrl {
    if (this.sanitizedFrameUrlFor !== this.previewImageUrl) {
      this.sanitizedFrameUrlFor = this.previewImageUrl;
      this.sanitizedFrameUrl = this.sanitizer.bypassSecurityTrustResourceUrl(
        this.previewImageUrl ?? '',
      );
    }
    return this.sanitizedFrameUrl as SafeResourceUrl;
  }

  /** Only allow review actions once the submission has finished loading without error. */
  get isReviewReady(): boolean {
    return !this.loading && !this.error && this.submission !== null;
  }

  /** Avatar fallback initials when no member photo is available. */
  get applicantInitials(): string {
    this.ensureDerived();
    return this.derivedInitials;
  }

  /** Typed view of the emergency-contact fields on the submission. */
  get emergencyContact(): EmergencyContact | null {
    this.ensureDerived();
    return this.derivedEmergency;
  }

  /** True when the emergency contact is also listed as a nominee. */
  get emergencyAlsoNominee(): boolean {
    this.ensureDerived();
    return this.derivedEmergencyAlsoNominee;
  }

  /** True when the emergency contact matches the applicant themself. */
  get emergencyIsApplicant(): boolean {
    this.ensureDerived();
    return this.derivedEmergencyIsApplicant;
  }

  /** Sum of nominee share percentages (only nominees that declare one). */
  get nomineeShareTotal(): number {
    this.ensureDerived();
    return this.derivedShareTotal;
  }

  get nomineeShareDeclared(): boolean {
    this.ensureDerived();
    return this.derivedShareDeclared;
  }

  get nomineeShareWarning(): boolean {
    this.ensureDerived();
    return this.derivedShareWarning;
  }

  /** Recomputes the cached submission-derived values if the submission changed. */
  private ensureDerived(): void {
    if (this.derivedFor === this.submission) return;
    this.derivedFor = this.submission;
    this.duplicateMobilesByProperty.clear();

    const submission = this.submission;
    if (!submission) {
      this.derivedInitials = '';
      this.derivedEmergency = null;
      this.derivedEmergencyAlsoNominee = false;
      this.derivedEmergencyIsApplicant = false;
      this.derivedShareTotal = 0;
      this.derivedShareDeclared = false;
      this.derivedShareWarning = false;
      return;
    }

    this.derivedInitials = this.initials(submission.fullName);

    const { urgentContactName, urgentContactRelation, urgentContactMobile, urgentContactAddress } =
      submission;
    const emergency =
      urgentContactName || urgentContactMobile || urgentContactAddress
        ? ({
            name: urgentContactName,
            relation: urgentContactRelation,
            mobile: urgentContactMobile,
            address: urgentContactAddress,
          } as EmergencyContact)
        : null;
    this.derivedEmergency = emergency;
    this.derivedEmergencyAlsoNominee = emergency
      ? submission.nominees.some((nominee) => this.samePerson(emergency, nominee))
      : false;
    this.derivedEmergencyIsApplicant = emergency
      ? this.samePerson(emergency, { name: submission.fullName, mobile: submission.mobile })
      : false;

    let shareTotal = 0;
    let shareDeclared = false;
    for (const nominee of submission.nominees) {
      if (typeof nominee.sharePercentage === 'number') {
        shareDeclared = true;
        shareTotal += nominee.sharePercentage;
      }
    }
    this.derivedShareTotal = shareTotal;
    this.derivedShareDeclared = shareDeclared;
    this.derivedShareWarning = shareDeclared && Math.round(shareTotal) !== 100;
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

  ngOnDestroy(): void {
    if (this.copyResetTimer) clearTimeout(this.copyResetTimer);
    this.revokePreviewObjectUrl();
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
    const lang = this.translate.currentLang() ?? '';
    const cached = this.emptyValueByLang.get(lang);
    if (cached !== undefined) return cached;
    const value = this.translate.instant('admin.submissionDetail.notProvided');
    this.emptyValueByLang.set(lang, value);
    return value;
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
    this.startPreview({
      url: doc.fileUrl,
      alt: doc.docType,
      isImage: this.docFileKind(doc) === 'image',
      filename: this.attachmentFilename(doc.docType, doc.fileUrl),
    });
  }

  isFileBroken(url?: string | null): boolean {
    return !!url && this.brokenFileUrls.has(url);
  }

  markFileBroken(url?: string | null): void {
    if (!url || this.brokenFileUrls.has(url)) return;
    this.brokenFileUrls = new Set([...this.brokenFileUrls, url]);
    // The (error) handlers that call us run outside Angular's zone under OnPush.
    this.cdr.markForCheck();
  }

  /** Upload a replacement for a missing or wrong member photo / receipt. */
  replaceAttachment(kind: AttachmentKind, event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (!this.submission || !file || this.uploadingKind) return;

    this.uploadingKind = kind;
    this.uploadError = '';
    this.adminService.replaceAttachment(this.submission.id, kind, file).subscribe({
      next: (data) => {
        this.submission = data;
        this.uploadingKind = null;
        this.cdr.markForCheck();
      },
      error: (err) => {
        const detail = typeof err?.error?.detail === 'string' ? err.error.detail : '';
        this.uploadError =
          detail || this.translate.instant('admin.submissionDetail.errors.uploadFailed');
        this.uploadingKind = null;
        this.cdr.markForCheck();
      },
    });
  }

  openPreview(url: string, altKey: string): void {
    const alt = this.translate.instant(altKey);
    this.startPreview({
      url,
      alt,
      isImage: /\.(png|jpe?g|gif|webp|svg|avif)(\?|$)/i.test(url) || /^data:image\//i.test(url),
      filename: this.attachmentFilename(alt, url),
    });
  }

  closePreview(): void {
    this.resetPreview();
  }

  /** The modal's <img> failed: replace it with the app's missing-file message. */
  onPreviewImageError(): void {
    if (!this.previewImageUrl) return;
    this.markFileBroken(this.previewImageUrl);
    this.previewError = this.translate.instant('admin.submissionDetail.fileMissing');
    this.previewImageUrl = null;
    this.cdr.markForCheck();
  }

  /** Modal download button: fetch as a blob instead of navigating to the URL. */
  downloadPreview(): void {
    if (this.previewTarget) this.download(this.previewTarget.url, this.previewTarget.filename);
  }

  downloadDoc(doc: ApplicableDoc): void {
    if (!doc.fileUrl) return;
    this.download(doc.fileUrl, this.attachmentFilename(doc.docType, doc.fileUrl));
  }

  /**
   * Open the preview modal for a file URL.
   *
   * Images are handed straight to `<img>` (its `error` handler reports a 404);
   * every other type is fetched into a blob first so a file that no longer
   * exists shows the app's error UI instead of the backend's raw JSON inside
   * an iframe.
   */
  private startPreview(target: {
    url: string;
    alt: string;
    isImage: boolean;
    filename: string;
  }): void {
    this.resetPreview();
    const requestId = this.previewRequestId;
    this.previewTarget = { url: target.url, filename: target.filename };
    this.previewImageAlt = target.alt;
    this.previewIsImage = target.isImage;

    if (target.isImage) {
      this.previewImageUrl = target.url;
      return;
    }

    this.previewLoading = true;
    this.attachments.load(target.url).then(
      (blob) => {
        if (requestId !== this.previewRequestId) return; // preview moved on
        this.previewObjectUrl = URL.createObjectURL(blob);
        this.previewImageUrl = this.previewObjectUrl;
        this.previewLoading = false;
        this.cdr.markForCheck();
      },
      () => {
        if (requestId !== this.previewRequestId) return;
        this.previewLoading = false;
        this.previewError = this.translate.instant('admin.submissionDetail.fileMissing');
        this.markFileBroken(target.url);
        this.cdr.markForCheck();
      },
    );
  }

  private resetPreview(): void {
    this.revokePreviewObjectUrl();
    this.previewRequestId++;
    this.previewImageUrl = null;
    this.previewImageAlt = '';
    this.previewIsImage = true;
    this.previewError = '';
    this.previewLoading = false;
    this.previewTarget = null;
  }

  private revokePreviewObjectUrl(): void {
    if (!this.previewObjectUrl) return;
    URL.revokeObjectURL(this.previewObjectUrl);
    this.previewObjectUrl = null;
  }

  private download(url: string, filename: string): void {
    this.attachmentError = '';
    this.attachments.download(url, filename).catch((err: unknown) => {
      this.attachmentError = this.translate.instant(
        err instanceof AttachmentMissingError
          ? 'admin.submissionDetail.fileMissing'
          : 'admin.submissionDetail.errors.downloadFailed',
      );
      if (err instanceof AttachmentMissingError) this.markFileBroken(url);
      this.cdr.markForCheck();
    });
  }

  /** Download name: the Bengali label stays readable, path-hostile characters go. */
  private attachmentFilename(label: string, url: string): string {
    const base = label.replace(/[\\/:*?"<>|]/g, '-').trim() || 'attachment';
    const ext =
      /^data:image\/([a-z0-9.+-]+);/i.exec(url)?.[1] ?? /\.([a-z0-9]{1,8})(?:$|\?)/i.exec(url)?.[1];
    return ext ? `${base}.${ext.toLowerCase()}` : base;
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
