export interface Nominee {
  name: string;
  relation: string;
  mobile: string;
  address: string;
}

export interface AddressDetail {
  house: string;
  road: string;
  postOffice: string;
  upazila: string;
  district: string;
  division: string;
}

export function createEmptyAddress(): AddressDetail {
  return { house: '', road: '', postOffice: '', upazila: '', district: '', division: '' };
}

export interface CoOwner {
  ownerName: string;
  ownerPhone: string;
}

export interface ApplicableDocEntry {
  type: string;
  fileName: string;
  fileDataUrl: string;
  driveUrl?: string;
}

export interface DagNo {
  cs: string;
  rs: string;
}

export interface PropertyItem {
  propertyType: string[];
  propertyTypeOther: string;
  khatianNo: string;
  dagNo: DagNo;
  holdingNumber: string;
  landQuantity: string;
  ownership: string;
  applicableDocs: ApplicableDocEntry[];
  coOwners: CoOwner[];
}

export const DOCUMENT_OPTIONS: string[] = [
  'খতিয়ান/পর্চা',
  'নামজারি/মিউটেশন',
  'খাজনা/কর রশিদ',
  'উত্তরাধিকার সনদ',
];

export const PROPERTY_TYPES: string[] = ['জমি', 'বাড়ি', 'ফ্ল্যাট', 'প্লট', 'অন্যান্য'];
export const OWNERSHIP_TYPES: string[] = ['একক', 'যৌথ'];
export const PAYMENT_METHODS: string[] = [
  'ক্যাশ',
  'ব্যাংক',
  'MFS (বিকাশ/নগদ/রকেট)',
  'অন্যান্য',
];

export const ALLOWED_DOC_MIME_TYPES: string[] = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'application/pdf',
];

export const MAX_DOC_FILE_BYTES = 5 * 1024 * 1024;
export const MAX_PHOTO_BYTES = 3 * 1024 * 1024;
export const MAX_PROPERTY_COUNT = 9;
export const MAX_CO_OWNER_COUNT = 5;

export function createEmptyApplicableDoc(type: string): ApplicableDocEntry {
  return { type, fileName: '', fileDataUrl: '' };
}

export function createEmptyCoOwner(): CoOwner {
  return { ownerName: '', ownerPhone: '' };
}

export function createEmptyProperty(): PropertyItem {
  return {
    propertyType: [],
    propertyTypeOther: '',
    khatianNo: '',
    dagNo: { cs: '', rs: '' },
    holdingNumber: '',
    landQuantity: '',
    ownership: '',
    applicableDocs: [],
    coOwners: [],
  };
}

export function createEmptyNominee(): Nominee {
  return { name: '', relation: '', mobile: '', address: '' };
}

export interface FormDataModel {
  fullName: string;
  fatherOrHusband: string;
  mother: string;
  dob: string;
  nationality: string;
  occupation: string;
  nid: string;
  mobile: string;
  gender: string;
  email: string;
  permanentAddress?: AddressDetail;
  currentAddress?: AddressDetail;
  urgentContactName?: string;
  urgentContactRelation?: string;
  urgentContactMobile?: string;
  urgentContactAddress?: string;
  propertyCount: number;
  properties: PropertyItem[];
  nominees: Nominee[];
  admissionFee: string;
  subscription: string;
  receiptNo: string;
  paymentMethod: string;
  receiptFileName?: string;
  receiptFileDataUrl?: string;
  memberSignature: string;
  submissionDate: string;
  memberPhoto?: string;
  declarationAccepted?: boolean;
}

export interface SubmissionResult {
  success: boolean;
  id?: string;
  error?: string;
}
