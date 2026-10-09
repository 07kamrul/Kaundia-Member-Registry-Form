import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, Observable, shareReplay } from 'rxjs';
import { environment } from '../../../environments/environment';
import type { Installment } from '../models/admin.model';
import {
  toNeighbourDirectory,
  type NeighbourDagType,
  type NeighbourDirectory,
  type NeighbourDirectoryApiModel,
} from '../models/neighbour.model';
import { toFileUrl } from './admin.service';

export interface MemberCoOwner {
  id: number;
  ownerName: string;
  ownerPhone: string;
}

export interface MemberPropertyDoc {
  id: number;
  docType: string;
  fileUrl?: string;
  /** Server-side path, used as keep_path when re-submitting docs on requests. */
  filePath?: string;
}

export interface MemberProperty {
  id: number;
  propertyType: string[];
  propertyTypeOther?: string;
  khatianNo?: string;
  dagNoCs?: string;
  dagNoRs?: string;
  holdingNumber?: string;
  landQuantity?: string;
  myShareQuantity?: string;
  ownership?: string;
  jointOwnerCount?: number | null;
  coOwners: MemberCoOwner[];
  applicableDocs: MemberPropertyDoc[];
}

export interface MemberNominee {
  id: number;
  name: string;
  relation: string;
  mobile: string;
  address?: string;
}

interface PropertyApiModel {
  id: number;
  property_type?: string[];
  property_type_other?: string | null;
  khatian_no?: string | null;
  dag_no_cs?: string | null;
  dag_no_rs?: string | null;
  holding_number?: string | null;
  land_quantity?: string | null;
  my_share_quantity?: string | null;
  ownership?: string | null;
  joint_owner_count?: number | null;
  co_owners?: { id: number; owner_name: string; owner_phone: string }[];
  applicable_docs?: { id: number; doc_type: string; file_path: string | null }[];
}

interface NomineeApiModel {
  id: number;
  name: string;
  relation: string;
  mobile: string;
  address?: string | null;
}

export interface MemberProfile {
  memberId: string;
  status: string;
  fullName: string;
  fatherOrHusband: string;
  mother: string;
  dob: string;
  nationality?: string;
  nid?: string;
  gender?: string;
  mobile: string;
  email?: string;
  occupation?: string;
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
  admissionFee?: string;
  subscription?: string;
  receiptNo?: string;
  paymentMethod?: string;
  memberSignature?: string;
  submissionDate?: string;
  memberPhotoUrl?: string;
  receiptPhotoUrl?: string;
  /** Neighbour-directory contact visibility (a preference - never re-queues review). */
  showInNeighbourDirectory: boolean;
  properties: MemberProperty[];
  nominees: MemberNominee[];
}

interface MemberProfileApiModel {
  member_id: string | null;
  status: string;
  full_name: string;
  father_or_husband: string;
  mother: string;
  dob: string;
  nationality?: string;
  nid?: string;
  gender?: string;
  mobile: string;
  email?: string;
  occupation?: string;
  permanent_house?: string;
  permanent_road?: string;
  permanent_post_office?: string;
  permanent_upazila?: string;
  permanent_district?: string;
  permanent_division?: string;
  current_house?: string;
  current_road?: string;
  current_post_office?: string;
  current_upazila?: string;
  current_district?: string;
  current_division?: string;
  urgent_contact_name?: string;
  urgent_contact_relation?: string;
  urgent_contact_mobile?: string;
  urgent_contact_address?: string;
  admission_fee?: string;
  subscription?: string;
  receipt_no?: string;
  payment_method?: string;
  member_signature?: string | null;
  submission_date?: string;
  member_photo_path?: string | null;
  receipt_photo_path?: string | null;
  show_in_neighbour_directory?: boolean | null;
  properties: PropertyApiModel[];
  nominees: NomineeApiModel[];
}

function toProperty(api: PropertyApiModel): MemberProperty {
  return {
    id: api.id,
    propertyType: api.property_type ?? [],
    propertyTypeOther: api.property_type_other ?? undefined,
    khatianNo: api.khatian_no ?? undefined,
    dagNoCs: api.dag_no_cs ?? undefined,
    dagNoRs: api.dag_no_rs ?? undefined,
    holdingNumber: api.holding_number ?? undefined,
    landQuantity: api.land_quantity ?? undefined,
    myShareQuantity: api.my_share_quantity ?? undefined,
    ownership: api.ownership ?? undefined,
    jointOwnerCount: api.joint_owner_count ?? null,
    coOwners: (api.co_owners ?? []).map((c) => ({
      id: c.id,
      ownerName: c.owner_name,
      ownerPhone: c.owner_phone,
    })),
    applicableDocs: (api.applicable_docs ?? []).map((d) => ({
      id: d.id,
      docType: d.doc_type,
      fileUrl: toFileUrl(d.file_path),
      filePath: d.file_path ?? undefined,
    })),
  };
}

function toNominee(api: NomineeApiModel): MemberNominee {
  return {
    id: api.id,
    name: api.name,
    relation: api.relation,
    mobile: api.mobile,
    address: api.address ?? undefined,
  };
}

function toMemberProfile(api: MemberProfileApiModel): MemberProfile {
  return {
    memberId: api.member_id ?? '',
    status: api.status,
    fullName: api.full_name,
    fatherOrHusband: api.father_or_husband,
    mother: api.mother,
    dob: api.dob,
    nationality: api.nationality,
    nid: api.nid,
    gender: api.gender,
    mobile: api.mobile,
    email: api.email,
    occupation: api.occupation,
    permanentHouse: api.permanent_house,
    permanentRoad: api.permanent_road,
    permanentPostOffice: api.permanent_post_office,
    permanentUpazila: api.permanent_upazila,
    permanentDistrict: api.permanent_district,
    permanentDivision: api.permanent_division,
    currentHouse: api.current_house,
    currentRoad: api.current_road,
    currentPostOffice: api.current_post_office,
    currentUpazila: api.current_upazila,
    currentDistrict: api.current_district,
    currentDivision: api.current_division,
    urgentContactName: api.urgent_contact_name,
    urgentContactRelation: api.urgent_contact_relation,
    urgentContactMobile: api.urgent_contact_mobile,
    urgentContactAddress: api.urgent_contact_address,
    admissionFee: api.admission_fee,
    subscription: api.subscription,
    receiptNo: api.receipt_no,
    paymentMethod: api.payment_method,
    memberSignature: api.member_signature ?? undefined,
    submissionDate: api.submission_date,
    memberPhotoUrl: toFileUrl(api.member_photo_path ?? null),
    receiptPhotoUrl: toFileUrl(api.receipt_photo_path ?? null),
    // Absent on older servers: the backend default is "shown".
    showInNeighbourDirectory: api.show_in_neighbour_directory ?? true,
    properties: (api.properties ?? []).map(toProperty),
    nominees: (api.nominees ?? []).map(toNominee),
  };
}

/** Property fields carried inside a property change request's payload. */
export interface PropertyRequestPayload {
  propertyType: string[];
  propertyTypeOther: string | null;
  khatianNo: string | null;
  dagNoCs: string | null;
  dagNoRs: string | null;
  holdingNumber: string | null;
  landQuantity: string | null;
  myShareQuantity: string | null;
  ownership: string | null;
  coOwners: { ownerName: string; ownerPhone: string }[];
  docs: { docType: string; keepPath: string | null }[];
}

export type PropertyRequestAction = 'add' | 'edit' | 'delete';
export type PropertyRequestStatus = 'pending' | 'approved' | 'cancelled';

export interface MemberPropertyRequest {
  id: number;
  action: PropertyRequestAction;
  propertyId: number | null;
  payload: PropertyRequestPayload;
  status: PropertyRequestStatus;
  cancelReason: string | null;
  reviewedAt: string | null;
  createdAt: string;
  /** Admin listings only; undefined on member-owned requests. */
  memberName?: string;
  memberCode?: string | null;
}

interface PropertyRequestApiModel {
  id: number;
  action: PropertyRequestAction;
  property_id: number | null;
  payload: Record<string, unknown>;
  status: PropertyRequestStatus;
  cancel_reason: string | null;
  reviewed_at: string | null;
  created_at: string;
  member_name?: string;
  member_code?: string | null;
}

function str(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 ? value : null;
}

export function toPropertyRequest(api: PropertyRequestApiModel): MemberPropertyRequest {
  const p = api.payload ?? {};
  const coOwners = Array.isArray(p['co_owners']) ? p['co_owners'] : [];
  const docs = Array.isArray(p['docs']) ? p['docs'] : [];
  return {
    id: api.id,
    action: api.action,
    propertyId: api.property_id,
    payload: {
      propertyType: Array.isArray(p['property_type']) ? (p['property_type'] as string[]) : [],
      propertyTypeOther: str(p['property_type_other']),
      khatianNo: str(p['khatian_no']),
      dagNoCs: str(p['dag_no_cs']),
      dagNoRs: str(p['dag_no_rs']),
      holdingNumber: str(p['holding_number']),
      landQuantity: str(p['land_quantity']),
      myShareQuantity: str(p['my_share_quantity']),
      ownership: str(p['ownership']),
      coOwners: (coOwners as Record<string, unknown>[]).map((c) => ({
        ownerName: str(c['owner_name']) ?? '',
        ownerPhone: str(c['owner_phone']) ?? '',
      })),
      docs: (docs as Record<string, unknown>[]).map((d) => ({
        docType: str(d['doc_type']) ?? '',
        keepPath: str(d['keep_path']),
      })),
    },
    status: api.status,
    cancelReason: api.cancel_reason,
    reviewedAt: api.reviewed_at,
    createdAt: api.created_at,
    memberName: api.member_name,
    memberCode: api.member_code ?? undefined,
  };
}

export interface PropertyRequestFormData {
  action: PropertyRequestAction;
  propertyId?: number;
  payload: {
    propertyType: string[];
    propertyTypeOther: string | null;
    khatianNo: string;
    dagNoCs: string;
    dagNoRs: string;
    holdingNumber: string;
    landQuantity: string;
    myShareQuantity: string;
    ownership: string;
    jointOwnerCount: number | null;
    docs: { docType: string; keepPath: string | null }[];
  };
  /** One file per docs[] entry whose keepPath is null, in the same order. */
  newDocFiles: File[];
}

export interface MemberProfileUpdatePayload {
  fullName?: string;
  fatherOrHusband?: string;
  mother?: string;
  dob?: string;
  nationality?: string;
  occupation?: string;
  nid?: string;
  gender?: string;
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
  mobile?: string;
  email?: string;
  urgentContactName?: string;
  urgentContactRelation?: string;
  urgentContactMobile?: string;
  urgentContactAddress?: string;
  /** Non-core preference: applied immediately, never triggers re-review. */
  showInNeighbourDirectory?: boolean;
}

@Injectable({ providedIn: 'root' })
export class MemberService {
  private base = `${environment.apiBaseUrl}/member`;
  private profileCache: Observable<MemberProfile> | null = null;

  constructor(private http: HttpClient) {}

  changePassword(currentPassword: string, newPassword: string): Observable<void> {
    return this.http.post<void>(`${this.base}/change-password`, {
      current_password: currentPassword,
      new_password: newPassword,
    });
  }

  getProfile(): Observable<MemberProfile> {
    if (!this.profileCache) {
      this.profileCache = this.http
        .get<MemberProfileApiModel>(`${this.base}/me`)
        .pipe(map(toMemberProfile), shareReplay({ bufferSize: 1, refCount: false }));
    }
    return this.profileCache;
  }

  clearProfileCache(): void {
    this.profileCache = null;
  }

  updateProfile(payload: MemberProfileUpdatePayload): Observable<MemberProfile> {
    const body: Record<string, string | boolean> = {};
    for (const [key, value] of Object.entries(payload) as [string, string | boolean | undefined][]) {
      if (value === undefined) continue;
      const snakeKey = key.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`);
      body[snakeKey] = value;
    }
    this.clearProfileCache();
    return this.http
      .patch<MemberProfileApiModel>(`${this.base}/profile`, body)
      .pipe(map(toMemberProfile));
  }

  /** Uploads a new profile photo (JPG/PNG, enforced again server-side). */
  uploadPhoto(file: File): Observable<MemberProfile> {
    const form = new FormData();
    form.append('photo', file);
    this.clearProfileCache();
    return this.http
      .post<MemberProfileApiModel>(`${this.base}/me/photo`, form)
      .pipe(map(toMemberProfile));
  }

  /**
   * Owners on the member's own dag(s) and the nearest neighbouring dags.
   * `dag_type` is sent only when given; otherwise the server picks the type
   * the member's plots carry and echoes it back.
   */
  getNeighbours(dagType?: NeighbourDagType): Observable<NeighbourDirectory> {
    const options = dagType ? { params: { dag_type: dagType } } : {};
    return this.http
      .get<NeighbourDirectoryApiModel>(`${this.base}/neighbours`, options)
      .pipe(map((api) => toNeighbourDirectory(api, dagType)));
  }

  getPropertyRequests(): Observable<MemberPropertyRequest[]> {
    return this.http
      .get<PropertyRequestApiModel[]>(`${this.base}/property-requests`)
      .pipe(map((rows) => rows.map(toPropertyRequest)));
  }

  /** POSTs a property change request (multipart: payload JSON + new doc files). */
  createPropertyRequest(form: PropertyRequestFormData): Observable<MemberPropertyRequest> {
    const body = new FormData();
    body.append('action', form.action);
    if (form.propertyId !== undefined) {
      body.append('property_id', String(form.propertyId));
    }
    const payloadBody =
      form.action === 'delete'
        ? {}
        : {
            property_type: form.payload.propertyType,
            property_type_other: form.payload.propertyTypeOther,
            khatian_no: form.payload.khatianNo,
            dag_no_cs: form.payload.dagNoCs,
            dag_no_rs: form.payload.dagNoRs,
            holding_number: form.payload.holdingNumber,
            land_quantity: form.payload.landQuantity,
            my_share_quantity: form.payload.myShareQuantity,
            ownership: form.payload.ownership,
            joint_owner_count: form.payload.jointOwnerCount,
            docs: form.payload.docs,
          };
    body.append('payload', JSON.stringify(payloadBody));
    for (const file of form.newDocFiles) {
      body.append('doc_files', file);
    }
    return this.http
      .post<PropertyRequestApiModel>(`${this.base}/property-requests`, body)
      .pipe(map(toPropertyRequest));
  }

  withdrawPropertyRequest(id: number): Observable<MemberPropertyRequest> {
    return this.http
      .post<PropertyRequestApiModel>(`${this.base}/property-requests/${id}/withdraw`, {})
      .pipe(map(toPropertyRequest));
  }

  getInstallments(): Observable<Installment[]> {
    return this.http
      .get<InstallmentApiModel[]>(`${this.base}/installments`)
      .pipe(map((rows) => rows.map(toInstallment)));
  }

  getPicnicPayments(): Observable<PicnicPayment[]> {
    return this.http.get<PicnicPaymentApiModel[]>(`${this.base}/picnic-payments`).pipe(
      map((rows) => rows.map(toPicnicPayment)),
    );
  }

  getPicnicRates(paymentDate: string): Observable<PicnicRates> {
    return this.http
      .get<PicnicRatesApiModel>(`${this.base}/picnic-rates`, {
        params: { payment_date: paymentDate },
      })
      .pipe(
        map((rates) => ({
          headFee: rates.head_fee,
          additionalHeadFee: rates.additional_head_fee,
          unit: rates.unit,
          effectiveFrom: rates.effective_from,
        })),
      );
  }

  createPicnicPayment(payload: PicnicPaymentPayload): Observable<PicnicPayment> {
    return this.http.post<PicnicPaymentApiModel>(`${this.base}/picnic-payments`, {
      additional_heads: payload.additionalHeads,
      additional_people: payload.additionalPeople,
      payment_date: payload.paymentDate,
      receipt_no: payload.receiptNo || null,
      payment_method: payload.paymentMethod || null,
    }).pipe(map(toPicnicPayment));
  }
}

interface InstallmentApiModel {
  id: number;
  year: number;
  month: number;
  amount: number;
  status: 'paid' | 'due';
  paid_at: string | null;
}

function toInstallment(row: InstallmentApiModel): Installment {
  return {
    id: String(row.id),
    year: row.year,
    month: row.month,
    amount: row.amount,
    status: row.status,
    paidAt: row.paid_at ?? undefined,
  };
}

function toPicnicPayment(row: PicnicPaymentApiModel): PicnicPayment {
  return {
    id: row.id,
    headPrice: row.head_price,
    additionalPrice: row.additional_price,
    additionalCount: row.additional_count,
    total: row.total,
    additionalHeads: row.additional_heads ?? [],
    paymentDate: row.payment_date,
    receiptNo: row.receipt_no,
    paymentMethod: row.payment_method,
    createdAt: row.created_at,
  };
}

export interface PicnicPaymentAdditionalHead {
  name: string;
  relation: string;
}

export interface PicnicRates {
  headFee: number;
  additionalHeadFee: number;
  unit: string;
  effectiveFrom: string;
}

interface PicnicRatesApiModel {
  head_fee: number;
  additional_head_fee: number;
  unit: string;
  effective_from: string;
}

export interface PicnicPayment {
  id: number;
  headPrice: number;
  additionalPrice: number;
  additionalCount: number;
  total: number;
  additionalHeads: PicnicPaymentAdditionalHead[];
  paymentDate: string;
  receiptNo: string | null;
  paymentMethod: string | null;
  createdAt: string;
}

interface PicnicPaymentApiModel {
  id: number;
  head_price: number;
  additional_price: number;
  additional_count: number;
  total: number;
  additional_heads: { name: string; relation: string }[] | null;
  payment_date: string;
  receipt_no: string | null;
  payment_method: string | null;
  created_at: string;
}

export interface PicnicPaymentPayload {
  additionalHeads: number;
  additionalPeople: PicnicPaymentAdditionalHead[];
  paymentDate: string;
  receiptNo?: string;
  paymentMethod?: string;
}
