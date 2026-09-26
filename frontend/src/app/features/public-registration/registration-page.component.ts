import { HttpErrorResponse } from '@angular/common/http';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  DestroyRef,
  inject,
  OnInit,
  signal,
} from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { MAX_PHOTO_BYTES } from '../../core/models/registration.model';
import { RegistrationService } from '../../core/services/registration.service';
import { RegistrationDraftService } from './services/registration-draft.service';
import { MemberInfoComponent } from './components/member-info/member-info.component';
import { AddressInfoComponent } from './components/address-info/address-info.component';
import { UrgentContactComponent } from './components/urgent-contact/urgent-contact.component';
import { PropertyListComponent } from './components/property-list/property-list.component';
import { NomineeListComponent } from './components/nominee-list/nominee-list.component';
import { PaymentInfoComponent } from './components/payment-info/payment-info.component';
import { ConfirmationComponent } from './components/confirmation/confirmation.component';
import { ReviewSummaryComponent } from './components/review-summary/review-summary.component';
import { buildRegistrationForm, propertiesArray, nomineesArray } from './registration-form.builder';

const MOBILE_PATTERN = /^01[3-9]\d{8}$/;

export interface RegistrationStep {
  id: number;
  title: string;
  shortLabel: string;
}

export const REGISTRATION_STEPS: RegistrationStep[] = [
  {
    id: 1,
    title: 'registration.stepTitles.memberInfo',
    shortLabel: 'registration.stepShortLabels.memberInfo',
  },
  {
    id: 2,
    title: 'registration.stepTitles.property',
    shortLabel: 'registration.stepShortLabels.property',
  },
  {
    id: 3,
    title: 'registration.stepTitles.contactAndNominee',
    shortLabel: 'registration.stepShortLabels.nominee',
  },
  {
    id: 4,
    title: 'registration.stepTitles.payment',
    shortLabel: 'registration.stepShortLabels.payment',
  },
  {
    id: 5,
    title: 'registration.stepTitles.declarationAndSignature',
    shortLabel: 'registration.stepShortLabels.signature',
  },
  {
    id: 6,
    title: 'registration.stepTitles.review',
    shortLabel: 'registration.stepShortLabels.review',
  },
];

@Component({
  selector: 'app-registration-page',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    ReactiveFormsModule,
    MemberInfoComponent,
    AddressInfoComponent,
    UrgentContactComponent,
    PropertyListComponent,
    NomineeListComponent,
    PaymentInfoComponent,
    ConfirmationComponent,
    ReviewSummaryComponent,
    TranslatePipe,
  ],
  templateUrl: './registration-page.component.html',
})
export class RegistrationPageComponent implements OnInit {
  form: FormGroup;
  errors: string[] = [];
  serverError: string | null = null;
  submitting = false;
  submitAttempted = false;
  success: { id: string } | null = null;
  memberPhotoPreview = signal('');

  steps = REGISTRATION_STEPS;
  currentStep = 1;

  showDraftRestoredToast = false;

  private readonly translate = inject(TranslateService);
  private readonly draftService = inject(RegistrationDraftService);
  private readonly cdr = inject(ChangeDetectorRef);
  private readonly destroyRef = inject(DestroyRef);

  readonly draftLastSaved = this.draftService.lastSaved;

  constructor(
    private fb: FormBuilder,
    private registrationService: RegistrationService,
    private router: Router,
  ) {
    this.form = buildRegistrationForm(this.fb);
  }

  ngOnInit(): void {
    const draft = this.draftService.peekDraft();
    if (draft) {
      this.draftService.restore(this.form, this.fb, draft);
      this.currentStep = draft.currentStep;
      this.showDraftRestoredToast = true;
    }
    this.draftService.watch(this.form, () => this.currentStep);
    this.destroyRef.onDestroy(() => this.draftService.unwatch());
  }

  dismissDraftToast(): void {
    this.showDraftRestoredToast = false;
  }

  discardDraft(): void {
    this.draftService.clear();
    this.form = buildRegistrationForm(this.fb);
    this.currentStep = 1;
    this.showDraftRestoredToast = false;
    this.draftService.watch(this.form, () => this.currentStep);
  }

  get properties(): FormArray {
    return propertiesArray(this.form);
  }

  get nominees(): FormArray {
    return nomineesArray(this.form);
  }

  clearSignature(): void {
    this.form.get('memberSignature')?.setValue('');
  }

  onPhotoChange(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      this.serverError = this.translate.instant('registration.memberInfo.photoTypeError');
      return;
    }
    if (file.size > MAX_PHOTO_BYTES) {
      this.serverError = this.translate.instant('registration.memberInfo.photoSizeError');
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      const dataUrl = reader.result as string;
      this.form.get('memberPhoto')?.setValue(dataUrl);
      this.memberPhotoPreview.set(dataUrl);
      this.cdr.markForCheck();
    };
    reader.readAsDataURL(file);
  }

  clearPhoto(): void {
    this.form.get('memberPhoto')?.setValue('');
    this.memberPhotoPreview.set('');
  }

  private validateMemberStep(): string[] {
    const errs: string[] = [];
    const v = this.form.value;

    if (!v.fullName?.trim())
      errs.push(this.translate.instant('registration.validation.fullNameRequired'));
    if (!v.fatherOrHusband?.trim())
      errs.push(this.translate.instant('registration.validation.fatherOrHusbandRequired'));
    if (!v.mother?.trim())
      errs.push(this.translate.instant('registration.validation.motherRequired'));
    if (!v.dob) errs.push(this.translate.instant('registration.validation.dobRequired'));
    if (!v.mobile?.trim())
      errs.push(this.translate.instant('registration.validation.mobileRequired'));
    else if (!MOBILE_PATTERN.test(v.mobile.trim()))
      errs.push(this.translate.instant('registration.validation.mobileInvalid'));
    if (!v.gender?.trim())
      errs.push(this.translate.instant('registration.validation.genderRequired'));
    if (v.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.email))
      errs.push(this.translate.instant('registration.validation.emailInvalid'));
    if (v.nid && !/^\d{10,17}$/.test(v.nid))
      errs.push(this.translate.instant('registration.validation.nidInvalid'));

    errs.push(
      ...this.validateAddressGroup(
        this.translate.instant('registration.validation.currentAddressLabel'),
        v.currentAddress,
      ),
    );
    if (this.form.get('permanentAddress')?.enabled) {
      errs.push(
        ...this.validateAddressGroup(
          this.translate.instant('registration.validation.permanentAddressLabel'),
          v.permanentAddress,
        ),
      );
    }

    return errs;
  }

  private validateAddressGroup(
    label: string,
    address: {
      division?: string;
      district?: string;
      upazila?: string;
      postOffice?: string;
      road?: string;
      house?: string;
    },
  ): string[] {
    const errs: string[] = [];
    if (!address.division?.trim())
      errs.push(`${label}: ${this.translate.instant('registration.addressInfo.divisionRequired')}`);
    if (!address.district?.trim())
      errs.push(`${label}: ${this.translate.instant('registration.addressInfo.districtRequired')}`);
    if (!address.upazila?.trim())
      errs.push(`${label}: ${this.translate.instant('registration.addressInfo.upazilaRequired')}`);
    if (!address.postOffice?.trim())
      errs.push(
        `${label}: ${this.translate.instant('registration.addressInfo.postOfficeRequired')}`,
      );
    if (!address.road?.trim())
      errs.push(`${label}: ${this.translate.instant('registration.addressInfo.roadRequired')}`);
    if (!address.house?.trim())
      errs.push(`${label}: ${this.translate.instant('registration.addressInfo.houseRequired')}`);
    return errs;
  }

  private validatePropertyStep(): string[] {
    const errs: string[] = [];
    const v = this.form.value;

    if (!v.propertyCount) {
      errs.push(this.translate.instant('registration.validation.propertyCountRequired'));
      return errs;
    }

    (v.properties as any[]).forEach((property, i) => {
      const label = this.translate.instant('registration.validation.propertyLabel', {
        number: i + 1,
      });
      if (!property.propertyType || property.propertyType.length === 0) {
        errs.push(
          `${label}: ${this.translate.instant('registration.validation.propertyTypeRequired')}`,
        );
      }
      if (!property.ownership)
        errs.push(
          `${label}: ${this.translate.instant('registration.validation.ownershipRequired')}`,
        );
      if (property.ownership === 'যৌথ') {
        const count = property.jointOwnerCount;
        if (!count || count < 1) {
          errs.push(
            `${label}: ${this.translate.instant('registration.validation.jointOwnerCountRequired')}`,
          );
        }
      }
      const landRaw = String(property.landQuantity ?? '').trim();
      const shareRaw = String(property.myShareQuantity ?? '').trim();
      const landQuantity = parseFloat(landRaw);
      const myShareQuantity = parseFloat(shareRaw);
      if (!landRaw) {
        errs.push(
          `${label}: ${this.translate.instant('registration.validation.landQuantityRequired')}`,
        );
      } else if (!Number.isFinite(landQuantity) || landQuantity <= 0) {
        errs.push(
          `${label}: ${this.translate.instant('registration.validation.landQuantityInvalid')}`,
        );
      }
      if (!shareRaw) {
        errs.push(
          `${label}: ${this.translate.instant('registration.validation.myShareQuantityRequired')}`,
        );
      } else if (!Number.isFinite(myShareQuantity) || myShareQuantity <= 0) {
        errs.push(
          `${label}: ${this.translate.instant('registration.validation.myShareQuantityInvalid')}`,
        );
      }
      if (
        Number.isFinite(landQuantity) &&
        Number.isFinite(myShareQuantity) &&
        myShareQuantity > landQuantity
      ) {
        errs.push(
          `${label}: ${this.translate.instant('registration.validation.myShareQuantityExceedsTotal')}`,
        );
      }
      if (!property.applicableDocs || property.applicableDocs.length === 0) {
        errs.push(
          `${label}: ${this.translate.instant('registration.validation.applicableDocsRequired')}`,
        );
      }
      (property.applicableDocs as any[]).forEach((doc) => {
        if (!doc.fileDataUrl)
          errs.push(
            `${label}: ${this.translate.instant('registration.validation.docFileRequired', { docType: doc.type })}`,
          );
      });
    });

    return errs;
  }

  private validateContactStep(): string[] {
    const errs: string[] = [];
    const v = this.form.value;
    const nominees = this.form.getRawValue().nominees;

    const urgentContactLabel = this.translate.instant('registration.validation.urgentContactLabel');
    if (!v.urgentContactName?.trim())
      errs.push(
        `${urgentContactLabel}: ${this.translate.instant('registration.validation.nameRequired')}`,
      );
    if (!v.urgentContactMobile?.trim())
      errs.push(
        `${urgentContactLabel}: ${this.translate.instant('registration.validation.mobileRequired')}`,
      );
    else if (!MOBILE_PATTERN.test(v.urgentContactMobile.trim()))
      errs.push(
        `${urgentContactLabel}: ${this.translate.instant('registration.validation.mobileInvalid')}`,
      );

    (nominees as any[]).forEach((nominee, i) => {
      const label = this.translate.instant('registration.validation.nomineeLabel', {
        number: i + 1,
      });
      if (!nominee.name?.trim())
        errs.push(`${label}: ${this.translate.instant('registration.validation.nameRequired')}`);
      if (!nominee.mobile?.trim())
        errs.push(`${label}: ${this.translate.instant('registration.validation.mobileRequired')}`);
      else if (!MOBILE_PATTERN.test(nominee.mobile.trim()))
        errs.push(`${label}: ${this.translate.instant('registration.validation.mobileInvalid')}`);
    });

    return errs;
  }

  private validatePaymentStep(): string[] {
    const errs: string[] = [];
    const v = this.form.value;

    if (!v.admissionFee)
      errs.push(this.translate.instant('registration.payment.admissionFeeRequired'));
    if (!v.subscription)
      errs.push(this.translate.instant('registration.payment.subscriptionRequired'));
    if (!v.paymentMethod)
      errs.push(this.translate.instant('registration.payment.paymentMethodRequired'));

    return errs;
  }

  private validateDeclarationStep(): string[] {
    const errs: string[] = [];
    if (!this.form.value.declarationAccepted)
      errs.push(this.translate.instant('registration.declaration.consentRequired'));
    return errs;
  }

  private validateStep(step: number): string[] {
    switch (step) {
      case 1:
        return this.validateMemberStep();
      case 2:
        return this.validatePropertyStep();
      case 3:
        return this.validateContactStep();
      case 4:
        return this.validatePaymentStep();
      case 5:
        return this.validateDeclarationStep();
      default:
        return [];
    }
  }

  private validate(): string[] {
    return [
      ...this.validateMemberStep(),
      ...this.validatePropertyStep(),
      ...this.validateContactStep(),
      ...this.validatePaymentStep(),
      ...this.validateDeclarationStep(),
    ];
  }

  /** Returns the first step (1-based) that fails its own validation, or null if all steps pass. */
  private firstInvalidStep(): number | null {
    for (const step of this.steps) {
      if (step.id === this.steps.length) continue;
      if (this.validateStep(step.id).length > 0) return step.id;
    }
    return null;
  }

  goToStep(step: number): void {
    if (step > this.currentStep) {
      for (let s = this.currentStep; s < step; s++) {
        const stepErrors = this.validateStep(s);
        if (stepErrors.length > 0) {
          this.errors = stepErrors;
          this.submitAttempted = true;
          this.form.markAllAsTouched();
          window.scrollTo({ top: 0, behavior: 'smooth' });
          return;
        }
      }
    }
    this.errors = [];
    this.currentStep = step;
    this.draftService.saveNow(this.form, this.currentStep);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  nextStep(): void {
    this.goToStep(this.currentStep + 1);
  }

  prevStep(): void {
    this.errors = [];
    if (this.currentStep > 1) {
      this.goToStep(this.currentStep - 1);
    }
  }

  onSubmit(): void {
    this.errors = [];
    this.serverError = null;
    this.submitAttempted = true;

    const clientErrors = this.validate();
    if (clientErrors.length > 0) {
      this.errors = clientErrors;
      const invalidStep = this.firstInvalidStep();
      if (invalidStep) {
        this.goToStep(invalidStep);
      } else {
        window.scrollTo({ top: 0, behavior: 'smooth' });
      }
      return;
    }

    this.submitting = true;
    this.cdr.markForCheck();
    this.registrationService.submit(this.form.getRawValue()).subscribe({
      next: (res) => {
        this.submitting = false;
        if (res.success) {
          this.success = { id: res.id ?? '' };
        } else {
          this.serverError =
            res.error ?? this.translate.instant('registration.submit.genericError');
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }
        this.cdr.markForCheck();
      },
      error: (err: HttpErrorResponse) => {
        this.submitting = false;
        this.serverError = this.translate.instant(
          err.status > 0 ? 'registration.submit.genericError' : 'registration.submit.networkError',
        );
        window.scrollTo({ top: 0, behavior: 'smooth' });
        this.cdr.markForCheck();
      },
    });
  }

  onConfirmationAcknowledged(): void {
    this.draftService.clear();
    this.success = null;
    this.router.navigateByUrl('/');
  }

  toggleDeclaration(): void {
    const control = this.form.get('declarationAccepted');
    control?.setValue(!control.value);
  }
}
