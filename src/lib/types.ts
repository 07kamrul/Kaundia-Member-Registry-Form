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

// One entry exists per currently-checked "প্রযোজ্য কাগজ" item. Unchecking the
// item removes its entry (and discards the attached file) instead of leaving
// it hidden and stale.
export interface ApplicableDocEntry {
  type: string;
  // Original filename of the attached file, empty until one is chosen.
  fileName: string;
  // Data URL (data:<mime>;base64,...) of the attached file, empty until
  // uploaded. This is how the file travels from the browser to the API
  // route in the JSON submission payload (mirrors memberPhoto).
  fileDataUrl: string;
  // Populated server-side after the file is uploaded to Drive; never set by
  // the client. Used to render "সংযুক্তি" notes in the PDF and to fill the
  // per-doc Sheet columns.
  driveUrl?: string;
}

export interface PropertyItem {
  propertyType: string[];
  propertyTypeOther: string;
  khatianNo: string;
  dagNo: string;
  landQuantity: string;
  ownership: string;
  applicableDocs: ApplicableDocEntry[];
  // Only populated/used when ownership === "যৌথ"
  coOwners: CoOwner[];
}

export const DOCUMENT_OPTIONS = [
  "খতিয়ান/পর্চা",
  "নামজারি/মিউটেশন",
  "খাজনা/কর রশিদ",
  "উত্তরাধিকার সনদ",
];

// Accepted MIME types for a প্রযোজ্য কাগজ attachment (image or PDF only).
export const ALLOWED_DOC_MIME_TYPES = [
  "image/jpeg",
  "image/jpg",
  "image/png",
  "application/pdf",
];

export const MAX_DOC_FILE_BYTES = 5 * 1024 * 1024; // 5MB per file

export function createEmptyApplicableDoc(type: string): ApplicableDocEntry {
  return { type, fileName: "", fileDataUrl: "" };
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
    applicableDocs: [] as ApplicableDocEntry[],
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
