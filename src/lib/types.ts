export interface Nominee {
  name: string;
  relation: string;
  mobile: string;
  address: string;
}

export interface CoOwner {
  ownerName: string;
  ownerPhone: string;
}

export interface PropertyItem {
  propertyType: string[];
  propertyTypeOther: string;
  khatianNo: string;
  dagNo: string;
  landQuantity: string;
  ownership: string;
  applicableDocs: string[];
  // Only populated/used when ownership === "যৌথ"
  coOwners: CoOwner[];
}

export const MAX_PROPERTY_COUNT = 9;
// Cap on co-owner rows flattened into Sheet columns per property
// (property{n}_coOwner1_name..property{n}_coOwner{MAX_CO_OWNER_COUNT}_name/phone).
export const MAX_CO_OWNER_COUNT = 5;

export function createEmptyCoOwner(): CoOwner {
  return { ownerName: "", ownerPhone: "" };
}

export function createEmptyProperty(): PropertyItem {
  return {
    propertyType: [],
    propertyTypeOther: "",
    khatianNo: "",
    dagNo: "",
    landQuantity: "",
    ownership: "",
    applicableDocs: [],
    coOwners: [],
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
