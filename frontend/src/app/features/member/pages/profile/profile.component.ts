import {
  Component,
  OnInit,
  OnDestroy,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  inject,
  signal,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { DatePipe } from '@angular/common';
import { DomSanitizer, type SafeResourceUrl } from '@angular/platform-browser';
import { RouterLink } from '@angular/router';
import { of } from 'rxjs';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import {
  MemberService,
  type MemberProfile,
  type MemberProperty,
  type MemberPropertyDoc,
  type MemberPropertyRequest,
  type MemberProfileUpdatePayload,
} from '../../../../core/services/member.service';
import { AttachmentService } from '../../../../core/services/attachment.service';
import { ConfirmModalComponent } from '../../../../shared/confirm-modal/confirm-modal.component';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { PhoneInputComponent } from '../../../../shared/phone-input/phone-input.component';
import { isValidInternationalPhone } from '../../../../shared/phone-input/phone-number';

const CORE_FIELDS: (keyof MemberProfileUpdatePayload)[] = [
  'fullName',
  'fatherOrHusband',
  'mother',
  'dob',
  'nationality',
  'occupation',
  'nid',
  'gender',
  'permanentHouse',
  'permanentRoad',
  'permanentPostOffice',
  'permanentUpazila',
  'permanentDistrict',
  'permanentDivision',
  'currentHouse',
  'currentRoad',
  'currentPostOffice',
  'currentUpazila',
  'currentDistrict',
  'currentDivision',
];

@Component({
  selector: 'app-member-profile',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    TranslatePipe,
    FormsModule,
    DatePipe,
    RouterLink,
    IconComponent,
    PhoneInputComponent,
    ConfirmModalComponent,
  ],
  templateUrl: './profile.component.html',
  styleUrl: './profile.component.scss',
})
export class ProfileComponent implements OnInit, OnDestroy {
  profile: MemberProfile | null = null;
  loading = false;
  error = '';

  editing = false;
  draft: MemberProfileUpdatePayload = {};
  saving = false;
  saveError = '';
  willRequeue = false;
  readonly photoFailed = signal(false);

  // Neighbour-directory visibility: a non-core preference saved on toggle.
  directorySaving = false;
  directoryError = '';

  // Pending photo replacement: picked in edit mode, uploaded on save.
  selectedPhoto: File | null = null;
  photoPreviewUrl: string | null = null;
  photoInputError = '';
  photoUploadError = '';

  // Property document popup preview (mirrors the admin submission-detail modal).
  previewUrl: string | null = null;
  previewTitle = '';
  previewIsImage = true;
  previewLoading = false;
  previewError = '';
  downloadError = '';

  /* ---------- property change requests ---------- */
  requests: MemberPropertyRequest[] = [];
  requestsLoading = false;
  requestsError = '';
  requestSuccess = '';
  requestActionError = '';
  deleteTarget: MemberProperty | null = null;
  showDeleteModal = false;
  deleteSubmitting = false;
  withdrawTarget: MemberPropertyRequest | null = null;
  showWithdrawModal = false;
  withdrawSubmitting = false;

  private readonly cdr = inject(ChangeDetectorRef);
  private readonly attachments = inject(AttachmentService);
  private readonly sanitizer = inject(DomSanitizer);

  /** Object URL backing a blob preview; revoked when the preview closes. */
  private previewObjectUrl: string | null = null;
  /** Bumped whenever the preview target changes, to ignore stale loads. */
  private previewRequestId = 0;
  /** What the modal's download button should fetch, and under which name. */
  private previewTarget: { url: string; filename: string } | null = null;
  private sanitizedFrameUrl: SafeResourceUrl | null = null;
  private sanitizedFrameUrlFor: string | null | undefined = undefined;

  constructor(
    private memberService: MemberService,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.loading = true;
    this.memberService.getProfile().subscribe({
      next: (data) => {
        this.profile = data;
        this.photoFailed.set(false);
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('member.profile.loadError');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
    this.loadRequests();
  }

  /* ---------- property change requests ---------- */

  loadRequests(): void {
    this.requestsLoading = true;
    this.requestsError = '';
    this.memberService.getPropertyRequests().subscribe({
      next: (rows) => {
        this.requests = rows;
        this.requestsLoading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.requestsError = this.translate.instant('member.propertyRequests.errors.loadFailed');
        this.requestsLoading = false;
        this.cdr.markForCheck();
      },
    });
  }

  referenceFor(request: MemberPropertyRequest): string {
    const year = new Date(request.createdAt).getFullYear() || new Date().getFullYear();
    return `PR-${year}-${String(request.id).padStart(4, '0')}`;
  }

  requestStatusLabel(status: MemberPropertyRequest['status']): string {
    return this.translate.instant(`member.propertyRequests.statusLabels.${status}`);
  }

  requestActionLabel(action: MemberPropertyRequest['action']): string {
    return this.translate.instant(`member.propertyRequests.actions.${action}`);
  }

  /** Short property description from a request payload (khatian / dag numbers). */
  requestPropertySummary(request: MemberPropertyRequest): string {
    const p = request.payload;
    const parts: string[] = [];
    const types = [...p.propertyType, p.propertyTypeOther ?? ''].filter(Boolean);
    if (types.length) parts.push(types.join(' / '));
    if (p.khatianNo) parts.push(`Khatian ${p.khatianNo}`);
    if (p.dagNoCs) parts.push(`CS ${p.dagNoCs}`);
    if (p.dagNoRs) parts.push(`RS ${p.dagNoRs}`);
    return parts.join(' · ');
  }

  hasPendingRequest(propertyId: number): boolean {
    return this.requests.some((r) => r.status === 'pending' && r.propertyId === propertyId);
  }

  requestDelete(property: MemberProperty): void {
    this.deleteTarget = property;
    this.requestActionError = '';
    this.showDeleteModal = true;
  }

  confirmDelete(): void {
    if (!this.deleteTarget || this.deleteSubmitting) return;
    this.deleteSubmitting = true;
    this.requestActionError = '';
    this.memberService
      .createPropertyRequest({
        action: 'delete',
        propertyId: this.deleteTarget.id,
        payload: {
          propertyType: [],
          propertyTypeOther: null,
          khatianNo: '',
          dagNoCs: '',
          dagNoRs: '',
          holdingNumber: '',
          landQuantity: '',
          myShareQuantity: '',
          ownership: '',
          jointOwnerCount: null,
          docs: [],
        },
        newDocFiles: [],
      })
      .subscribe({
        next: () => {
          this.deleteSubmitting = false;
          this.showDeleteModal = false;
          this.requestSuccess = this.translate.instant('member.propertyRequests.successSent');
          this.loadRequests();
        },
        error: (err) => {
          this.deleteSubmitting = false;
          this.showDeleteModal = false;
          const detail = typeof err?.error?.detail === 'string' ? err.error.detail : '';
          this.requestActionError =
            detail || this.translate.instant('member.propertyRequests.errors.submitFailed');
          this.cdr.markForCheck();
        },
      });
  }

  requestWithdraw(request: MemberPropertyRequest): void {
    this.withdrawTarget = request;
    this.requestActionError = '';
    this.showWithdrawModal = true;
  }

  confirmWithdraw(): void {
    if (!this.withdrawTarget || this.withdrawSubmitting) return;
    this.withdrawSubmitting = true;
    this.requestActionError = '';
    this.memberService.withdrawPropertyRequest(this.withdrawTarget.id).subscribe({
      next: () => {
        this.withdrawSubmitting = false;
        this.showWithdrawModal = false;
        this.requestSuccess = this.translate.instant('member.propertyRequests.withdrawnSuccess');
        this.loadRequests();
      },
      error: (err) => {
        this.withdrawSubmitting = false;
        this.showWithdrawModal = false;
        const detail = typeof err?.error?.detail === 'string' ? err.error.detail : '';
        this.requestActionError =
          detail || this.translate.instant('member.propertyRequests.errors.withdrawFailed');
        this.cdr.markForCheck();
      },
    });
  }

  dismissRequestSuccess(): void {
    this.requestSuccess = '';
  }

  ngOnDestroy(): void {
    this.revokePreviewObjectUrl();
  }

  propertyTypes(property: MemberProperty): string {
    return [...property.propertyType, property.propertyTypeOther ?? ''].filter(Boolean).join(' / ');
  }

  get avatarInitial(): string {
    return (this.profile?.fullName ?? '').trim().charAt(0) || '—';
  }

  get statusKey(): string {
    switch (this.profile?.status) {
      case 'approved':
        return 'member.profile.statusApproved';
      case 'rejected':
        return 'member.profile.statusRejected';
      default:
        return 'member.profile.statusPending';
    }
  }

  get statusClass(): string {
    switch (this.profile?.status) {
      case 'approved':
        return 'profile-status-badge approved';
      case 'rejected':
        return 'profile-status-badge rejected';
      default:
        return 'profile-status-badge pending';
    }
  }

  // A 404/missing photo must fall back to the initial avatar, never a broken image.
  onPhotoError(): void {
    this.photoFailed.set(true);
  }

  /* ---------- property document preview ---------- */

  /** Sanitized URL for embedding non-image previews (e.g. PDF) in an iframe. */
  get previewFrameUrl(): SafeResourceUrl {
    if (this.sanitizedFrameUrlFor !== this.previewUrl) {
      this.sanitizedFrameUrlFor = this.previewUrl;
      this.sanitizedFrameUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.previewUrl ?? '');
    }
    return this.sanitizedFrameUrl as SafeResourceUrl;
  }

  openDocPreview(doc: MemberPropertyDoc): void {
    if (!doc.fileUrl) return;
    this.startPreview({
      url: doc.fileUrl,
      title: doc.docType,
      isImage:
        /\.(png|jpe?g|gif|webp|svg|avif)(\?|$)/i.test(doc.fileUrl) ||
        /^data:image\//i.test(doc.fileUrl),
      filename: this.attachmentFilename(doc.docType, doc.fileUrl),
    });
  }

  closePreview(): void {
    this.resetPreview();
  }

  /** The modal's <img> failed: replace it with the app's missing-file message. */
  onPreviewImageError(): void {
    if (!this.previewUrl) return;
    this.previewError = this.translate.instant('member.profile.fileMissing');
    this.previewUrl = null;
    this.cdr.markForCheck();
  }

  /** Modal download button: fetch as a blob instead of navigating to the URL. */
  downloadPreview(): void {
    if (!this.previewTarget) return;
    this.downloadError = '';
    this.attachments.download(this.previewTarget.url, this.previewTarget.filename).catch(() => {
      this.downloadError = this.translate.instant('member.profile.downloadFailed');
      this.cdr.markForCheck();
    });
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
    title: string;
    isImage: boolean;
    filename: string;
  }): void {
    this.resetPreview();
    const requestId = this.previewRequestId;
    this.previewTarget = { url: target.url, filename: target.filename };
    this.previewTitle = target.title;
    this.previewIsImage = target.isImage;

    if (target.isImage) {
      this.previewUrl = target.url;
      return;
    }

    this.previewLoading = true;
    this.attachments.load(target.url).then(
      (blob) => {
        if (requestId !== this.previewRequestId) return; // preview moved on
        this.previewObjectUrl = URL.createObjectURL(blob);
        this.previewUrl = this.previewObjectUrl;
        this.previewLoading = false;
        this.cdr.markForCheck();
      },
      () => {
        if (requestId !== this.previewRequestId) return;
        this.previewLoading = false;
        this.previewError = this.translate.instant('member.profile.fileMissing');
        this.cdr.markForCheck();
      },
    );
  }

  private resetPreview(): void {
    this.revokePreviewObjectUrl();
    this.previewRequestId++;
    this.previewUrl = null;
    this.previewTitle = '';
    this.previewIsImage = true;
    this.previewError = '';
    this.previewLoading = false;
    this.downloadError = '';
    this.previewTarget = null;
  }

  private revokePreviewObjectUrl(): void {
    if (!this.previewObjectUrl) return;
    URL.revokeObjectURL(this.previewObjectUrl);
    this.previewObjectUrl = null;
  }

  /** Download name: the Bengali label stays readable, path-hostile characters go. */
  private attachmentFilename(label: string, url: string): string {
    const base = label.replace(/[\\/:*?"<>|]/g, '-').trim() || 'attachment';
    const ext =
      /^data:image\/([a-z0-9.+-]+);/i.exec(url)?.[1] ?? /\.([a-z0-9]{1,8})(?:$|\?)/i.exec(url)?.[1];
    return ext ? `${base}.${ext.toLowerCase()}` : base;
  }

  onPhotoSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0] ?? null;
    this.photoInputError = '';
    if (!file) return;
    if (!/\.(jpe?g|png)$/i.test(file.name)) {
      this.photoInputError = this.translate.instant('member.profile.photoTypeError');
      input.value = '';
      return;
    }
    if (file.size > 3 * 1024 * 1024) {
      this.photoInputError = this.translate.instant('member.profile.photoSizeError');
      input.value = '';
      return;
    }
    this.selectedPhoto = file;
    this.photoPreviewUrl = URL.createObjectURL(file);
    input.value = '';
  }

  removeSelectedPhoto(): void {
    if (this.photoPreviewUrl) URL.revokeObjectURL(this.photoPreviewUrl);
    this.selectedPhoto = null;
    this.photoPreviewUrl = null;
    this.photoInputError = '';
  }

  private resetPhotoDraft(): void {
    this.removeSelectedPhoto();
    this.photoUploadError = '';
  }

  hasCurrentAddress(profile: MemberProfile): boolean {
    return [
      profile.currentHouse,
      profile.currentRoad,
      profile.currentPostOffice,
      profile.currentUpazila,
      profile.currentDistrict,
      profile.currentDivision,
    ].some(Boolean);
  }

  isImageDataUrl(value?: string): boolean {
    return !!value && value.startsWith('data:image/');
  }

  startEdit(): void {
    if (!this.profile) return;
    this.draft = {
      fullName: this.profile.fullName,
      fatherOrHusband: this.profile.fatherOrHusband,
      mother: this.profile.mother,
      dob: this.profile.dob,
      nationality: this.profile.nationality,
      occupation: this.profile.occupation,
      nid: this.profile.nid,
      gender: this.profile.gender,
      permanentHouse: this.profile.permanentHouse,
      permanentRoad: this.profile.permanentRoad,
      permanentPostOffice: this.profile.permanentPostOffice,
      permanentUpazila: this.profile.permanentUpazila,
      permanentDistrict: this.profile.permanentDistrict,
      permanentDivision: this.profile.permanentDivision,
      currentHouse: this.profile.currentHouse,
      currentRoad: this.profile.currentRoad,
      currentPostOffice: this.profile.currentPostOffice,
      currentUpazila: this.profile.currentUpazila,
      currentDistrict: this.profile.currentDistrict,
      currentDivision: this.profile.currentDivision,
      mobile: this.profile.mobile,
      email: this.profile.email,
      urgentContactName: this.profile.urgentContactName,
      urgentContactRelation: this.profile.urgentContactRelation,
      urgentContactMobile: this.profile.urgentContactMobile,
      urgentContactAddress: this.profile.urgentContactAddress,
    };
    this.editing = true;
    this.saveError = '';
    this.resetPhotoDraft();
    this.checkRequeue();
  }

  cancelEdit(): void {
    this.editing = false;
    this.draft = {};
    this.saveError = '';
    this.resetPhotoDraft();
  }

  checkRequeue(): void {
    if (!this.profile || this.profile.status !== 'approved') {
      this.willRequeue = false;
      return;
    }
    this.willRequeue = CORE_FIELDS.some(
      (field) => (this.draft[field] ?? '') !== (this.profile![field] ?? ''),
    );
  }

  saveProfile(): void {
    if (!this.profile) return;
    if (this.draft.mobile && !isValidInternationalPhone(this.draft.mobile)) {
      this.saveError = this.translate.instant('member.profile.mobileInvalid');
      return;
    }
    this.saving = true;
    this.saveError = '';
    this.photoUploadError = '';
    // The photo upload goes first: if it fails, the text edits stay in draft
    // so the member can retry without retyping anything.
    const details$ = this.selectedPhoto
      ? this.memberService.uploadPhoto(this.selectedPhoto)
      : of(null as unknown as MemberProfile);
    details$.subscribe({
      next: (uploaded) => {
        if (uploaded) {
          this.profile = uploaded;
          this.photoFailed.set(false);
          this.resetPhotoDraft();
        }
        this.patchProfileDetails();
      },
      error: () => {
        this.photoUploadError = this.translate.instant('member.profile.photoUploadError');
        this.saving = false;
        this.cdr.markForCheck();
      },
    });
  }

  /**
   * Sends only `show_in_neighbour_directory` (a boolean), so it can never
   * touch core fields or re-queue an approved membership for review.
   */
  toggleNeighbourDirectory(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!this.profile || this.directorySaving) {
      input.checked = this.profile?.showInNeighbourDirectory ?? true;
      return;
    }
    const previous = this.profile.showInNeighbourDirectory;
    const next = input.checked;
    this.directorySaving = true;
    this.directoryError = '';
    this.profile = { ...this.profile, showInNeighbourDirectory: next };
    this.memberService.updateProfile({ showInNeighbourDirectory: next }).subscribe({
      next: (updated) => {
        this.profile = updated;
        this.directorySaving = false;
        this.cdr.markForCheck();
      },
      error: () => {
        if (this.profile) this.profile = { ...this.profile, showInNeighbourDirectory: previous };
        input.checked = previous;
        this.directoryError = this.translate.instant('member.profile.saveError');
        this.directorySaving = false;
        this.cdr.markForCheck();
      },
    });
  }

  private patchProfileDetails(): void {
    if (!this.profile) return;
    this.memberService.updateProfile(this.draft).subscribe({
      next: (updated) => {
        this.profile = updated;
        this.editing = false;
        this.saving = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.saveError = this.translate.instant('member.profile.saveError');
        this.saving = false;
        this.cdr.markForCheck();
      },
    });
  }
}
