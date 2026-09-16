import {
  AfterViewChecked,
  AfterViewInit,
  Component,
  ElementRef,
  signal,
  ViewChild,
} from '@angular/core';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import SignaturePad from 'signature_pad';
import { MAX_PHOTO_BYTES } from '../../core/models/registration.model';
import { RegistrationService } from '../../core/services/registration.service';
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
  { id: 1, title: 'সদস্যের তথ্য', shortLabel: 'সদস্য' },
  { id: 2, title: 'সম্পত্তি ও মালিকানা', shortLabel: 'সম্পত্তি' },
  { id: 3, title: 'জরুরি যোগাযোগ ও নমিনি', shortLabel: 'নমিনি' },
  { id: 4, title: 'পেমেন্ট', shortLabel: 'পেমেন্ট' },
  { id: 5, title: 'অঙ্গীকার ও স্বাক্ষর', shortLabel: 'স্বাক্ষর' },
  { id: 6, title: 'পর্যালোচনা ও সাবমিট', shortLabel: 'পর্যালোচনা' },
];

@Component({
  selector: 'app-registration-page',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    RouterLink,
    MemberInfoComponent,
    AddressInfoComponent,
    UrgentContactComponent,
    PropertyListComponent,
    NomineeListComponent,
    PaymentInfoComponent,
    ConfirmationComponent,
    ReviewSummaryComponent,
  ],
  templateUrl: './registration-page.component.html',
})
export class RegistrationPageComponent implements AfterViewInit, AfterViewChecked {
  @ViewChild('sigCanvas') sigCanvas?: ElementRef<HTMLCanvasElement>;

  form: FormGroup;
  errors: string[] = [];
  serverError: string | null = null;
  submitting = false;
  submitAttempted = false;
  success: { id: string; fullName: string } | null = null;
  memberPhotoPreview = signal('');
  private signaturePad?: SignaturePad;

  steps = REGISTRATION_STEPS;
  currentStep = 1;

  constructor(
    private fb: FormBuilder,
    private registrationService: RegistrationService,
  ) {
    this.form = buildRegistrationForm(this.fb);
  }

  ngAfterViewInit(): void {
    this.setupSignaturePad();
  }

  ngAfterViewChecked(): void {
    if (!this.sigCanvas) {
      this.signaturePad = undefined;
    } else if (!this.signaturePad) {
      this.setupSignaturePad();
    }
  }

  private setupSignaturePad(): void {
    if (this.sigCanvas) {
      this.signaturePad = new SignaturePad(this.sigCanvas.nativeElement, {
        backgroundColor: 'rgb(255,255,255)',
      });
      const existing = this.form.get('memberSignature')?.value;
      if (existing) {
        this.signaturePad.fromDataURL(existing);
      }
    }
  }

  get properties(): FormArray {
    return propertiesArray(this.form);
  }

  get nominees(): FormArray {
    return nomineesArray(this.form);
  }

  clearSignature(): void {
    this.signaturePad?.clear();
    this.form.get('memberSignature')?.setValue('');
  }

  onPhotoChange(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      this.serverError = 'ছবির ফাইল নির্বাচন করুন (JPG/PNG)';
      return;
    }
    if (file.size > MAX_PHOTO_BYTES) {
      this.serverError = 'ছবির সাইজ ৩ এমবি-এর কম হতে হবে';
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      const dataUrl = reader.result as string;
      this.form.get('memberPhoto')?.setValue(dataUrl);
      this.memberPhotoPreview.set(dataUrl);
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

    if (!v.fullName?.trim()) errs.push('পূর্ণ নাম আবশ্যক');
    if (!v.fatherOrHusband?.trim()) errs.push('পিতা/স্বামী আবশ্যক');
    if (!v.mother?.trim()) errs.push('মাতা আবশ্যক');
    if (!v.dob) errs.push('জন্ম তারিখ আবশ্যক');
    if (!v.mobile?.trim()) errs.push('মোবাইল আবশ্যক');
    else if (!MOBILE_PATTERN.test(v.mobile.trim()))
      errs.push('মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)');
    if (!v.gender?.trim()) errs.push('লিঙ্গ নির্বাচন করুন');
    if (v.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.email)) errs.push('ই-মেইল সঠিক নয়');
    if (v.nid && !/^\d{10,17}$/.test(v.nid)) errs.push('NID নম্বর ১০-১৭ সংখ্যার হতে হবে');

    errs.push(...this.validateAddressGroup('বর্তমান ঠিকানা', v.currentAddress));
    if (this.form.get('permanentAddress')?.enabled) {
      errs.push(...this.validateAddressGroup('স্থায়ী ঠিকানা', v.permanentAddress));
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
    if (!address.division?.trim()) errs.push(`${label}: বিভাগ আবশ্যক`);
    if (!address.district?.trim()) errs.push(`${label}: জেলা আবশ্যক`);
    if (!address.upazila?.trim()) errs.push(`${label}: উপজেলা/থানা আবশ্যক`);
    if (!address.postOffice?.trim()) errs.push(`${label}: ডাকঘর আবশ্যক`);
    if (!address.road?.trim()) errs.push(`${label}: রাস্তা/গ্রাম আবশ্যক`);
    if (!address.house?.trim()) errs.push(`${label}: বাসা/হোল্ডিং নং আবশ্যক`);
    return errs;
  }

  private validatePropertyStep(): string[] {
    const errs: string[] = [];
    const v = this.form.value;

    if (!v.propertyCount) {
      errs.push('সম্পত্তির সংখ্যা নির্বাচন করুন');
      return errs;
    }

    (v.properties as any[]).forEach((property, i) => {
      const label = `সম্পত্তি #${i + 1}`;
      if (!property.propertyType || property.propertyType.length === 0) {
        errs.push(`${label}: সম্পত্তির ধরন আবশ্যক`);
      }
      if (!property.ownership) errs.push(`${label}: মালিকানা আবশ্যক`);
      if (property.ownership === 'যৌথ') {
        const hasFilledCoOwner = (property.coOwners as any[]).some(
          (co) => co.ownerName?.trim() && co.ownerPhone?.trim(),
        );
        if (!hasFilledCoOwner) {
          errs.push(`${label}: অন্তত একজন মালিকের নাম ও মোবাইল নং আবশ্যক`);
        } else {
          (property.coOwners as any[]).forEach((co, ci) => {
            if (!co.ownerName?.trim()) errs.push(`${label}, মালিক #${ci + 1}: নাম আবশ্যক`);
            if (!co.ownerPhone?.trim()) errs.push(`${label}, মালিক #${ci + 1}: মোবাইল নং আবশ্যক`);
            else if (!MOBILE_PATTERN.test(co.ownerPhone.trim()))
              errs.push(`${label}, মালিক #${ci + 1}: মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)`);
          });
        }
      }
      if (!property.applicableDocs || property.applicableDocs.length === 0) {
        errs.push(`${label}: প্রযোজ্য কাগজ নির্বাচন আবশ্যক`);
      }
      (property.applicableDocs as any[]).forEach((doc) => {
        if (!doc.fileDataUrl) errs.push(`${label}: "${doc.type}" এর জন্য ফাইল সংযুক্ত করা আবশ্যক`);
      });
    });

    return errs;
  }

  private validateContactStep(): string[] {
    const errs: string[] = [];
    const v = this.form.value;

    if (!v.urgentContactName?.trim()) errs.push('জরুরি যোগাযোগ: নাম আবশ্যক');
    if (!v.urgentContactMobile?.trim()) errs.push('জরুরি যোগাযোগ: মোবাইল আবশ্যক');
    else if (!MOBILE_PATTERN.test(v.urgentContactMobile.trim()))
      errs.push('জরুরি যোগাযোগ: মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)');

    (v.nominees as any[]).forEach((nominee, i) => {
      const label = `মনোনীত ব্যক্তি #${i + 1}`;
      if (!nominee.name?.trim()) errs.push(`${label}: নাম আবশ্যক`);
      if (!nominee.mobile?.trim()) errs.push(`${label}: মোবাইল আবশ্যক`);
      else if (!MOBILE_PATTERN.test(nominee.mobile.trim()))
        errs.push(`${label}: মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)`);
    });

    return errs;
  }

  private validatePaymentStep(): string[] {
    const errs: string[] = [];
    const v = this.form.value;

    if (!v.admissionFee) errs.push('ভর্তি ফি আবশ্যক');
    if (!v.subscription) errs.push('চাঁদা আবশ্যক');
    if (!v.paymentMethod) errs.push('পেমেন্ট মাধ্যম আবশ্যক');

    return errs;
  }

  private validateDeclarationStep(): string[] {
    const errs: string[] = [];
    if (!this.form.value.declarationAccepted) errs.push('অঙ্গীকারনামায় সম্মতি প্রদান আবশ্যক');
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

    if (this.signaturePad && !this.signaturePad.isEmpty()) {
      this.form.get('memberSignature')?.setValue(this.signaturePad.toDataURL());
    }

    this.submitting = true;
    this.registrationService.submit(this.form.getRawValue()).subscribe({
      next: (res) => {
        this.submitting = false;
        if (res.success) {
          this.success = { id: res.id ?? '', fullName: this.form.value.fullName };
        } else {
          this.serverError = res.error ?? 'সাবমিটে সমস্যা হয়েছে';
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }
      },
      error: () => {
        this.submitting = false;
        this.serverError = 'নেটওয়ার্কে সমস্যা। অনুগ্রহ করে আবার চেষ্টা করুন।';
        window.scrollTo({ top: 0, behavior: 'smooth' });
      },
    });
  }

  resetForm(): void {
    this.success = null;
    this.form = buildRegistrationForm(this.fb);
    this.memberPhotoPreview.set('');
    this.signaturePad?.clear();
    this.submitAttempted = false;
    this.serverError = null;
    this.currentStep = 1;
  }

  toggleDeclaration(): void {
    const control = this.form.get('declarationAccepted');
    control?.setValue(!control.value);
  }
}
