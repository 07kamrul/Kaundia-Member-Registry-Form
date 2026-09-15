import { FormArray, FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';

const MOBILE_PATTERN = /^01[3-9]\d{8}$/;
const NID_PATTERN = /^\d{10,17}$/;

export function buildCoOwnerGroup(fb: FormBuilder): FormGroup {
  return fb.group({
    ownerName: [''],
    ownerPhone: [''],
  });
}

export function buildApplicableDocGroup(fb: FormBuilder, type: string): FormGroup {
  return fb.group({
    type: [type],
    fileName: [''],
    fileDataUrl: [''],
  });
}

export function buildPropertyGroup(fb: FormBuilder): FormGroup {
  return fb.group({
    propertyType: fb.control<string[]>([]),
    propertyTypeOther: [''],
    khatianNo: [''],
    dagNo: fb.group({ cs: [''], rs: [''] }),
    landQuantity: [''],
    ownership: ['', Validators.required],
    applicableDocs: fb.array([]),
    coOwners: fb.array([]),
  });
}

export function buildAddressGroup(fb: FormBuilder): FormGroup {
  return fb.group({
    house: ['', Validators.required],
    road: ['', Validators.required],
    postOffice: ['', Validators.required],
    upazila: ['', Validators.required],
    district: ['', Validators.required],
  });
}

export function buildNomineeGroup(fb: FormBuilder): FormGroup {
  return fb.group({
    name: [''],
    relation: [''],
    mobile: [''],
    address: [''],
  });
}

export function buildRegistrationForm(fb: FormBuilder): FormGroup {
  return fb.group({
    fullName: ['', Validators.required],
    fatherOrHusband: ['', Validators.required],
    mother: ['', Validators.required],
    dob: ['', Validators.required],
    nationality: ['বাংলাদেশী'],
    occupation: [''],
    nid: ['', Validators.pattern(NID_PATTERN)],
    mobile: ['', [Validators.required, Validators.pattern(MOBILE_PATTERN)]],
    whatsapp: [''],
    email: ['', Validators.email],

    permanentAddress: buildAddressGroup(fb),
    currentAddress: buildAddressGroup(fb),

    urgentContactName: [''],
    urgentContactRelation: [''],
    urgentContactMobile: [''],
    urgentContactAddress: [''],

    propertyCount: new FormControl(1),
    properties: fb.array([buildPropertyGroup(fb)]),

    nominees: fb.array([buildNomineeGroup(fb)]),

    admissionFee: ['', Validators.required],
    subscription: ['', Validators.required],
    receiptNo: [''],
    paymentMethod: ['', Validators.required],

    memberSignature: [''],
    submissionDate: [new Date().toISOString().split('T')[0]],
    memberPhoto: [''],

    declarationAccepted: [false, Validators.requiredTrue],
  });
}

export function propertiesArray(form: FormGroup): FormArray {
  return form.get('properties') as FormArray;
}

export function nomineesArray(form: FormGroup): FormArray {
  return form.get('nominees') as FormArray;
}

export function coOwnersArray(propertyGroup: FormGroup): FormArray {
  return propertyGroup.get('coOwners') as FormArray;
}

export function applicableDocsArray(propertyGroup: FormGroup): FormArray {
  return propertyGroup.get('applicableDocs') as FormArray;
}

export const MOBILE_REGEX = MOBILE_PATTERN;
