import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, type Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import type {
  ApplicableDoc,
  CoOwner,
  Installment,
  Member,
  Nominee,
  SubmissionDetail,
  SubmissionProperty,
  SubmissionStatus,
  SubmissionSummary,
} from '../models/admin.model';

export type AttachmentKind = 'member_photo' | 'receipt_photo';

interface MemberApiModel {
  id: number;
  member_id: string | null;
  status: SubmissionStatus;
  full_name: string;
  mobile: string;
  email?: string;
  due_installments: number;
}

interface SubmissionSummaryApiModel {
  id: number;
  member_id: string | null;
  status: SubmissionStatus;
  full_name: string;
  mobile: string;
  created_at: string;
}

interface CoOwnerApiModel {
  id: number;
  owner_name: string;
  owner_phone: string;
}

interface ApplicableDocApiModel {
  id: number;
  doc_type: string;
  file_path: string | null;
}

interface SubmissionPropertyApiModel {
  id: number;
  property_type: string[];
  property_type_other: string | null;
  khatian_no: string | null;
  dag_no_cs: string | null;
  dag_no_rs: string | null;
  holding_number: string | null;
  land_quantity: string | null;
  ownership: string | null;
  co_owners: CoOwnerApiModel[];
  applicable_docs: ApplicableDocApiModel[];
}

interface NomineeApiModel {
  id: number;
  name: string;
  relation: string;
  mobile: string;
  address: string | null;
}

interface SubmissionDetailApiModel {
  id: number;
  member_id: string | null;
  status: SubmissionStatus;
  full_name: string;
  mobile: string;
  created_at: string;
  father_or_husband: string;
  mother: string;
  dob: string;
  nationality: string;
  occupation: string;
  nid: string;
  gender: string;
  email: string;
  permanent_house: string | null;
  permanent_road: string | null;
  permanent_post_office: string | null;
  permanent_upazila: string | null;
  permanent_district: string | null;
  permanent_division: string | null;
  current_house: string | null;
  current_road: string | null;
  current_post_office: string | null;
  current_upazila: string | null;
  current_district: string | null;
  current_division: string | null;
  urgent_contact_name: string | null;
  urgent_contact_relation: string | null;
  urgent_contact_mobile: string | null;
  urgent_contact_address: string | null;
  admission_fee: string;
  subscription: string;
  receipt_no: string;
  payment_method: string;
  member_signature: string | null;
  member_photo_path: string | null;
  receipt_photo_path: string | null;
  rejection_reason: string | null;
  properties: SubmissionPropertyApiModel[];
  nominees: NomineeApiModel[];
}

function toMember(api: MemberApiModel): Member {
  return {
    id: String(api.id),
    memberId: api.member_id,
    status: api.status,
    fullName: api.full_name,
    mobile: api.mobile,
    email: api.email,
    dueInstallments: api.due_installments,
  };
}

function toSubmissionSummary(api: SubmissionSummaryApiModel): SubmissionSummary {
  return {
    id: String(api.id),
    fullName: api.full_name,
    mobile: api.mobile,
    status: api.status,
    createdAt: api.created_at,
  };
}

/** Origin the backend serves `/uploads/*` static files from (apiBaseUrl without the `/api` suffix). */
const uploadsOrigin = environment.apiBaseUrl.replace(/\/api\/?$/, '');

function toFileUrl(relativePath: string | null): string | undefined {
  if (!relativePath) return undefined;
  return `${uploadsOrigin}/uploads/${relativePath}`;
}

function toCoOwner(api: CoOwnerApiModel): CoOwner {
  return { id: String(api.id), name: api.owner_name, mobile: api.owner_phone };
}

function toApplicableDoc(api: ApplicableDocApiModel): ApplicableDoc {
  return { id: String(api.id), docType: api.doc_type, fileUrl: toFileUrl(api.file_path) ?? null };
}

function toSubmissionProperty(api: SubmissionPropertyApiModel): SubmissionProperty {
  return {
    id: String(api.id),
    propertyType: api.property_type,
    propertyTypeOther: api.property_type_other,
    khatianNo: api.khatian_no,
    dagNoCs: api.dag_no_cs,
    dagNoRs: api.dag_no_rs,
    holdingNumber: api.holding_number,
    landQuantity: api.land_quantity,
    ownership: api.ownership,
    coOwners: api.co_owners.map(toCoOwner),
    applicableDocs: api.applicable_docs.map(toApplicableDoc),
  };
}

function toNominee(api: NomineeApiModel): Nominee {
  return {
    id: String(api.id),
    name: api.name,
    relation: api.relation,
    mobile: api.mobile,
    address: api.address,
  };
}

function toSubmissionDetail(api: SubmissionDetailApiModel): SubmissionDetail {
  return {
    id: String(api.id),
    fullName: api.full_name,
    mobile: api.mobile,
    status: api.status,
    createdAt: api.created_at,
    fatherOrHusband: api.father_or_husband,
    mother: api.mother,
    dob: api.dob,
    nationality: api.nationality,
    occupation: api.occupation,
    nid: api.nid,
    gender: api.gender,
    email: api.email,
    permanentHouse: api.permanent_house ?? undefined,
    permanentRoad: api.permanent_road ?? undefined,
    permanentPostOffice: api.permanent_post_office ?? undefined,
    permanentUpazila: api.permanent_upazila ?? undefined,
    permanentDistrict: api.permanent_district ?? undefined,
    permanentDivision: api.permanent_division ?? undefined,
    currentHouse: api.current_house ?? undefined,
    currentRoad: api.current_road ?? undefined,
    currentPostOffice: api.current_post_office ?? undefined,
    currentUpazila: api.current_upazila ?? undefined,
    currentDistrict: api.current_district ?? undefined,
    currentDivision: api.current_division ?? undefined,
    urgentContactName: api.urgent_contact_name ?? undefined,
    urgentContactRelation: api.urgent_contact_relation ?? undefined,
    urgentContactMobile: api.urgent_contact_mobile ?? undefined,
    urgentContactAddress: api.urgent_contact_address ?? undefined,
    properties: api.properties.map(toSubmissionProperty),
    nominees: api.nominees.map(toNominee),
    admissionFee: api.admission_fee,
    subscription: api.subscription,
    receiptNo: api.receipt_no,
    paymentMethod: api.payment_method,
    memberPhotoUrl: toFileUrl(api.member_photo_path),
    memberSignature: api.member_signature ?? undefined,
    receiptPhotoUrl: toFileUrl(api.receipt_photo_path),
    rejectionReason: api.rejection_reason ?? undefined,
  };
}

@Injectable({ providedIn: 'root' })
export class AdminService {
  private base = `${environment.apiBaseUrl}/admin`;

  constructor(private http: HttpClient) {}

  listSubmissions(status?: SubmissionStatus): Observable<SubmissionSummary[]> {
    const url = status ? `${this.base}/submissions?status=${status}` : `${this.base}/submissions`;
    return this.http
      .get<SubmissionSummaryApiModel[]>(url)
      .pipe(map((rows) => rows.map(toSubmissionSummary)));
  }

  getSubmission(id: string): Observable<SubmissionDetail> {
    return this.http
      .get<SubmissionDetailApiModel>(`${this.base}/submissions/${id}`)
      .pipe(map(toSubmissionDetail));
  }

  replaceAttachment(
    id: string,
    kind: AttachmentKind,
    file: File,
  ): Observable<SubmissionDetail> {
    const body = new FormData();
    body.append('file', file);
    return this.http
      .put<SubmissionDetailApiModel>(`${this.base}/submissions/${id}/attachments/${kind}`, body)
      .pipe(map(toSubmissionDetail));
  }

  approveSubmission(id: string): Observable<{ member_id: string }> {
    return this.http.post<{ member_id: string }>(`${this.base}/submissions/${id}/approve`, {});
  }

  rejectSubmission(id: string, reason: string): Observable<void> {
    return this.http.post<void>(`${this.base}/submissions/${id}/reject`, { reason });
  }

  listMembers(): Observable<Member[]> {
    return this.http
      .get<MemberApiModel[]>(`${this.base}/members`)
      .pipe(map((rows) => rows.map(toMember)));
  }

  getMemberInstallments(memberId: string): Observable<Installment[]> {
    return this.http.get<Installment[]>(`${this.base}/members/${memberId}/installments`);
  }

  deleteMember(memberId: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/members/${memberId}`);
  }

  addInstallment(
    memberId: string,
    installment: { year: number; month: number; amount: number },
  ): Observable<Installment> {
    return this.http.post<Installment>(
      `${this.base}/members/${memberId}/installments`,
      installment,
    );
  }

  updateInstallment(id: string, status: 'paid' | 'due'): Observable<Installment> {
    return this.http.patch<Installment>(`${this.base}/installments/${id}`, { status });
  }
}
