export type SubmissionStatus = 'pending' | 'approved' | 'rejected';

export interface SubmissionSummary {
  id: string;
  fullName: string;
  mobile: string;
  status: SubmissionStatus;
  createdAt: string;
  propertiesCount?: number;
}

export interface SubmissionDetail extends SubmissionSummary {
  fatherOrHusband: string;
  mother: string;
  dob: string;
  nationality: string;
  occupation: string;
  nid: string;
  gender: string;
  email: string;
  permanentHouse?: string;
  permanentRoad?: string;
  permanentPostOffice?: string;
  permanentUpazila?: string;
  permanentDistrict?: string;
  currentHouse?: string;
  currentRoad?: string;
  currentPostOffice?: string;
  currentUpazila?: string;
  currentDistrict?: string;
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
  receiptPhotoUrl?: string;
  rejectionReason?: string;
}

export interface Member {
  id: string;
  memberId: string | null;
  status: SubmissionStatus;
  fullName: string;
  mobile: string;
  email?: string;
  dueInstallments: number;
}

export interface Installment {
  id: string;
  year: number;
  month: number;
  amount: number;
  status: 'paid' | 'due';
  paidAt?: string;
}
