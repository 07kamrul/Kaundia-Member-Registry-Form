import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, Observable, shareReplay } from 'rxjs';
import { environment } from '../../../environments/environment';
import type { Installment } from '../models/admin.model';
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
    coOwners: (api.co_owners ?? []).map((c) => ({
      id: c.id,
      ownerName: c.owner_name,
      ownerPhone: c.owner_phone,
    })),
    applicableDocs: (api.applicable_docs ?? []).map((d) => ({
      id: d.id,
      docType: d.doc_type,
      fileUrl: toFileUrl(d.file_path),
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
    properties: (api.properties ?? []).map(toProperty),
    nominees: (api.nominees ?? []).map(toNominee),
  };
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
    const body: Record<string, string> = {};
    for (const [key, value] of Object.entries(payload)) {
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

  getInstallments(): Observable<Installment[]> {
    return this.http.get<Installment[]>(`${this.base}/installments`);
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
