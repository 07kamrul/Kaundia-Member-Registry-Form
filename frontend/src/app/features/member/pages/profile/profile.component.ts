import {
  Component,
  OnInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  inject,
  signal,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { of } from 'rxjs';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import {
  MemberService,
  type MemberProfile,
  type MemberProperty,
  type MemberProfileUpdatePayload,
} from '../../../../core/services/member.service';
import { IconComponent } from '../../../../shared/icon/icon.component';

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
  imports: [TranslatePipe, FormsModule, IconComponent],
  templateUrl: './profile.component.html',
  styleUrl: './profile.component.scss',
})
export class ProfileComponent implements OnInit {
  profile: MemberProfile | null = null;
  loading = false;
  error = '';

  editing = false;
  draft: MemberProfileUpdatePayload = {};
  saving = false;
  saveError = '';
  willRequeue = false;
  readonly photoFailed = signal(false);

  // Pending photo replacement: picked in edit mode, uploaded on save.
  selectedPhoto: File | null = null;
  photoPreviewUrl: string | null = null;
  photoInputError = '';
  photoUploadError = '';

  private readonly cdr = inject(ChangeDetectorRef);

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
