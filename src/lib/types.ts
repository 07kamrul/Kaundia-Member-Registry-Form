export interface Nominee {
  name: string;
  relation: string;
  mobile: string;
  address: string;
}

export interface PropertyItem {
  propertyType: string[];
  propertyTypeOther: string;
  khatianNo: string;
  dagNo: string;
  landQuantity: string;
  ownership: string;
  applicableDocs: string[];
}

export const MAX_PROPERTY_COUNT = 9;

export function createEmptyProperty(): PropertyItem {
  return {
    propertyType: [],
    propertyTypeOther: "",
    khatianNo: "",
    dagNo: "",
    landQuantity: "",
    ownership: "",
    applicableDocs: [],
  };
}

export interface FormData {
  // Member Info
  fullName: string;
  fatherOrHusband: string;
  mother: string;
  dob: string;
  nationality: string;
  occupation: string;
  nid: string;
  mobile: string;
  whatsapp: string;
  email: string;

  // Address Info
  permanentAddress?: string;
  currentAddress?: string;

  // Urgent Contact
  urgentContactName?: string;
  urgentContactRelation?: string;
  urgentContactMobile?: string;
  urgentContactAddress?: string;

  // Property Info
  propertyCount: number;
  properties: PropertyItem[];

  // Nominees
  nominees: Nominee[];

  // Payment
  admissionFee: string;
  subscription: string;
  receiptNo: string;
  paymentMethod: string;

  // Signature
  memberSignature: string;
  submissionDate: string;

  // Member Photo (base64 data URL, e.g. "data:image/jpeg;base64,...")
  memberPhoto?: string;

  // Honeypot
  website: string;

  // Client-side only (not persisted to Sheets/PDF)
  declarationAccepted?: boolean;
}

export interface SubmissionResult {
  success: boolean;
  formNo: string;
  driveFileId?: string;
  driveFileLink?: string;
  photoFileId?: string;
  photoFileLink?: string;
  error?: string;
}
