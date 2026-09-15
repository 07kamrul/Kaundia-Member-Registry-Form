export type SubmissionStatus = 'pending' | 'approved' | 'rejected';

export interface SubmissionSummary {
  id: string;
  fullName: string;
  mobile: string;
  status: SubmissionStatus;
  createdAt: string;
}

export interface SubmissionDetail extends SubmissionSummary {
  fatherOrHusband: string;
  mother: string;
  dob: string;
  nationality: string;
  occupation: string;
  nid: string;
  whatsapp: string;
  email: string;
  permanentAddress?: string;
  currentAddress?: string;
  urgentContactName?: string;
  urgentContactRelation?: string;
  urgentContactMobile?: string;
  urgentContactAddress?: string;
  properties: unknown[];
  nominees: unknown[];
  admissionFee: string;
  subscription: string;
  receiptNo: string;
  paymentMethod: string;
  memberPhotoUrl?: string;
  memberSignatureUrl?: string;
  rejectionReason?: string;
}

export interface Member {
  id: string;
  memberId: string;
  fullName: string;
  mobile: string;
  email?: string;
}

export interface Installment {
  id: string;
  year: number;
  month: number;
  amount: number;
  status: 'paid' | 'due';
  paidAt?: string;
}
