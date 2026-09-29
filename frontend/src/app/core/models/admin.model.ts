export type SubmissionStatus = 'pending' | 'approved' | 'rejected';

export interface SubmissionSummary {
  id: string;
  fullName: string;
  mobile: string;
  status: SubmissionStatus;
  createdAt: string;
  propertiesCount?: number;
}

export interface ApplicableDoc {
  id: string;
  docType: string;
  fileUrl: string | null;
  fileName?: string | null;
  fileSize?: number | null;
}

export interface SubmissionProperty {
  id: string;
  propertyType: string[];
  propertyTypeOther?: string | null;
  khatianNo?: string | null;
  dagNoCs?: string | null;
  dagNoRs?: string | null;
  holdingNumber?: string | null;
  landQuantity?: string | null;
  myShareQuantity?: string | null;
  ownership?: string | null;
  jointOwnerCount?: number | null;
  applicableDocs: ApplicableDoc[];
}

export interface Nominee {
  id: string;
  name: string;
  relation: string;
  mobile: string;
  address?: string | null;
  sharePercentage?: number | null;
}

export interface EmergencyContact {
  name?: string | null;
  relation?: string | null;
  mobile?: string | null;
  address?: string | null;
}

/** Friendly aliases for API-facing view models used by detail screens. */
export type Property = SubmissionProperty;
export type PropertyDocument = ApplicableDoc;

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
  permanentDivision?: string;
  currentHouse?: string;
  currentRoad?: string;
  currentPostOffice?: string;
  currentUpazila?: string;
  currentDistrict?: string;
  currentDivision?: string;
  urgentContactName?: string;
  urgentContactRelation?: string;
  urgentContactMobile?: string;
  urgentContactAddress?: string;
  properties: SubmissionProperty[];
  nominees: Nominee[];
  admissionFee: string;
  subscription: string;
  receiptNo: string;
  paymentMethod: string;
  memberPhotoUrl?: string;
  memberSignature?: string;
  receiptPhotoUrl?: string;
  rejectionReason?: string;
  /** Rejection email outcome; 'failed' means the applicant was not notified. */
  notificationStatus?: 'sent' | 'failed';
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

export interface ConfigListItem {
  id: string;
  category: string;
  value: string;
  label: string;
  sortOrder: number;
  isActive: boolean;
}

export interface FeeSetting {
  id: string;
  key: string;
  value: number;
  unit?: string;
  startDate: string;
  endDate?: string;
  status: number;
}

export interface AuditLogEntry {
  id: string;
  actorAdminId: string | null;
  action: string;
  entityType: string;
  entityId: string;
  detail: string | null;
  createdAt: string;
}
