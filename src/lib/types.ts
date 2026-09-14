export interface Nominee {
  name: string;
  relation: string;
  mobile: string;
  address: string;
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
  propertyType: string;
  propertyTypeOther: string;
  khatianNo: string;
  dagNo: string;
  landQuantity: string;
  ownership: string;
  applicableDocs: string[];

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

  // Honeypot
  website: string;
}

export interface SubmissionResult {
  success: boolean;
  formNo: string;
  driveFileId?: string;
  driveFileLink?: string;
  error?: string;
}
