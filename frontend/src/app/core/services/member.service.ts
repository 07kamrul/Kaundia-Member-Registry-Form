import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, Observable, shareReplay } from 'rxjs';
import { environment } from '../../../environments/environment';
import type { Installment } from '../models/admin.model';

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
  properties: unknown[];
  nominees: unknown[];
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
  properties: unknown[];
  nominees: unknown[];
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
    properties: api.properties,
    nominees: api.nominees,
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

  changePassword(oldPassword: string, newPassword: string): Observable<void> {
    return this.http.post<void>(`${this.base}/change-password`, {
      old_password: oldPassword,
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
