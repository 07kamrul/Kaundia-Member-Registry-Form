import { AfterViewInit, Component, ElementRef, ViewChild } from '@angular/core';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
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
import { buildRegistrationForm, propertiesArray, nomineesArray } from './registration-form.builder';

const MOBILE_PATTERN = /^01[3-9]\d{8}$/;

@Component({
  selector: 'app-registration-page',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    MemberInfoComponent,
    AddressInfoComponent,
    UrgentContactComponent,
    PropertyListComponent,
    NomineeListComponent,
    PaymentInfoComponent,
    ConfirmationComponent,
  ],
  templateUrl: './registration-page.component.html',
})
export class RegistrationPageComponent implements AfterViewInit {
  @ViewChild('sigCanvas') sigCanvas?: ElementRef<HTMLCanvasElement>;

  form: FormGroup;
  errors: string[] = [];
  submitting = false;
  submitAttempted = false;
  success: { id: string; fullName: string } | null = null;
  memberPhotoPreview = '';
  private signaturePad?: SignaturePad;

  constructor(
    private fb: FormBuilder,
    private registrationService: RegistrationService,
  ) {
    this.form = buildRegistrationForm(this.fb);
  }

  ngAfterViewInit(): void {
    if (this.sigCanvas) {
      this.signaturePad = new SignaturePad(this.sigCanvas.nativeElement, {
        backgroundColor: 'rgb(255,255,255)',
      });
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
      this.errors = ['ছবির ফাইল নির্বাচন করুন (JPG/PNG)'];
      return;
    }
    if (file.size > MAX_PHOTO_BYTES) {
      this.errors = ['ছবির সাইজ ৩ এমবি-এর কম হতে হবে'];
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      const dataUrl = reader.result as string;
      this.form.get('memberPhoto')?.setValue(dataUrl);
      this.memberPhotoPreview = dataUrl;
    };
    reader.readAsDataURL(file);
  }

  clearPhoto(): void {
    this.form.get('memberPhoto')?.setValue('');
    this.memberPhotoPreview = '';
  }

  private validate(): string[] {
    const errs: string[] = [];
    const v = this.form.value;

    if (!v.fullName?.trim()) errs.push('পূর্ণ নাম আবশ্যক');
    if (!v.fatherOrHusband?.trim()) errs.push('পিতা/স্বামী আবশ্যক');
    if (!v.mother?.trim()) errs.push('মাতা আবশ্যক');
    if (!v.dob) errs.push('জন্ম তারিখ আবশ্যক');
    if (!v.mobile?.trim()) errs.push('মোবাইল আবশ্যক');
    else if (!MOBILE_PATTERN.test(v.mobile.trim())) errs.push('মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)');
    if (v.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.email)) errs.push('ই-মেইল সঠিক নয়');
    if (v.nid && !/^\d{10,17}$/.test(v.nid)) errs.push('NID নম্বর ১০-১৭ সংখ্যার হতে হবে');

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
            if (!co.ownerName?.trim() && !co.ownerPhone?.trim()) return;
            if (!co.ownerName?.trim()) errs.push(`${label}, মালিক #${ci + 1}: নাম আবশ্যক`);
            if (!co.ownerPhone?.trim()) errs.push(`${label}, মালিক #${ci + 1}: মোবাইল নং আবশ্যক`);
            else if (!MOBILE_PATTERN.test(co.ownerPhone.trim()))
              errs.push(`${label}, মালিক #${ci + 1}: মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)`);
          });
        }
      }
      (property.applicableDocs as any[]).forEach((doc) => {
        if (!doc.fileDataUrl) errs.push(`${label}: "${doc.type}" এর জন্য ফাইল সংযুক্ত করা আবশ্যক`);
      });
    });

    if (!v.admissionFee) errs.push('ভর্তি ফি আবশ্যক');
    if (!v.subscription) errs.push('চাঁদা আবশ্যক');
    if (!v.paymentMethod) errs.push('পেমেন্ট মাধ্যম আবশ্যক');
    if (!v.declarationAccepted) errs.push('অঙ্গীকারনামায় সম্মতি প্রদান আবশ্যক');

    return errs;
  }

  onSubmit(): void {
    this.errors = [];
    this.submitAttempted = true;

    const clientErrors = this.validate();
    if (clientErrors.length > 0) {
      this.errors = clientErrors;
      window.scrollTo({ top: 0, behavior: 'smooth' });
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
          this.errors = [res.error ?? 'সাবমিটে সমস্যা হয়েছে'];
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }
      },
      error: () => {
        this.submitting = false;
        this.errors = ['নেটওয়ার্কে সমস্যা। অনুগ্রহ করে আবার চেষ্টা করুন।'];
        window.scrollTo({ top: 0, behavior: 'smooth' });
      },
    });
  }

  resetForm(): void {
    this.success = null;
    this.form = buildRegistrationForm(this.fb);
    this.memberPhotoPreview = '';
    this.signaturePad?.clear();
    this.submitAttempted = false;
  }

  toggleDeclaration(): void {
    const control = this.form.get('declarationAccepted');
    control?.setValue(!control.value);
  }
}
