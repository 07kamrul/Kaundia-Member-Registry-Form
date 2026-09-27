import {
  Component,
  OnInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  inject,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import {
  MemberService,
  type MemberProfile,
  type MemberProfileUpdatePayload,
} from '../../../../core/services/member.service';

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

interface ProfileProperty {
  id: number;
  property_type?: string[];
  khatian_no?: string | null;
  land_quantity?: string | null;
}

@Component({
  selector: 'app-member-profile',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, FormsModule],
  templateUrl: './profile.component.html',
})
export class ProfileComponent implements OnInit {
  profile: MemberProfile | null = null;
  propertySummaries: string[] = [];
  loading = false;
  error = '';

  editing = false;
  draft: MemberProfileUpdatePayload = {};
  saving = false;
  saveError = '';
  willRequeue = false;

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
        this.propertySummaries = (data.properties as ProfileProperty[]).map((property) =>
          [
            `${this.translate.instant('member.profile.propertyItemLabel')} ${property.id}`,
            property.property_type?.join('/') ?? '',
            property.khatian_no
              ? `${this.translate.instant('member.profile.khatianLabel')} ${property.khatian_no}`
              : '',
            property.land_quantity
              ? `${property.land_quantity} ${this.translate.instant('member.profile.decimalUnit')}`
              : '',
          ]
            .filter(Boolean)
            .join(' · ')
            .replace(' · ', ' — '),
        );
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
    this.checkRequeue();
  }

  cancelEdit(): void {
    this.editing = false;
    this.draft = {};
    this.saveError = '';
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
