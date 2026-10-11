import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, type Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import type {
  ApplicableDoc,
  AuditLogEntry,
  ConfigListItem,
  FeeSetting,
  Installment,
  Member,
  MemberProfile,
  Nominee,
  SubmissionDetail,
  SubmissionProperty,
  SubmissionStatus,
  SubmissionSummary,
} from '../models/admin.model';
import {
  toEventItem,
  toNotice,
  type EventApiModel,
  type EventItem,
  type Notice,
  type NoticeApiModel,
} from '../models/content.model';
import { toPropertyRequest, type MemberPropertyRequest, type PropertyRequestStatus } from './member.service';

export type AttachmentKind = 'member_photo' | 'receipt_photo';

/** Outcome of a rejection: the submission is rejected either way, but the
 * applicant is only notified when `emailSent` is true. */
export interface RejectResult {
  emailSent: boolean;
}

/** Fields a notice is created/edited with. Dates are ISO instants (UTC). */
export interface NoticeInput {
  title: string;
  body: string;
  categoryId?: string | null;
  isPublished?: boolean;
  isMembersOnly?: boolean;
  publishAt?: string | null;
}

/** Fields an event is created/edited with. Dates are ISO instants (UTC). */
export interface EventInput {
  title: string;
  description?: string | null;
  location?: string | null;
  categoryId?: string | null;
  startAt: string;
  endAt?: string | null;
  isPublished?: boolean;
  isMembersOnly?: boolean;
}

interface MemberApiModel {
  id: number;
  member_id: string | null;
  status: SubmissionStatus;
  full_name: string;
  mobile: string;
  email?: string;
  due_installments: number;
}

interface FeeSettingApiModel {
  id: number;
  key: string;
  value: number;
  unit?: string | null;
  start_date: string;
  end_date?: string | null;
  status: number;
}

interface ConfigListItemApiModel {
  id: number;
  category: string;
  value: string;
  label: string;
  sort_order: number;
  is_active: number;
}

interface AuditLogApiModel {
  id: number;
  actor_admin_id: number | null;
  action: string;
  entity_type: string;
  entity_id: string;
  detail: string | null;
  created_at: string;
}

function toAuditLogEntry(api: AuditLogApiModel): AuditLogEntry {
  return {
    id: String(api.id),
    actorAdminId: api.actor_admin_id !== null ? String(api.actor_admin_id) : null,
    action: api.action,
    entityType: api.entity_type,
    entityId: api.entity_id,
    detail: api.detail,
    createdAt: api.created_at,
  };
}

interface SubmissionSummaryApiModel {
  id: number;
  member_id: string | null;
  status: SubmissionStatus;
  full_name: string;
  mobile: string;
  created_at: string;
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
  my_share_quantity: string | null;
  ownership: string | null;
  joint_owner_count: number | null;
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
  notification_status?: 'sent' | 'failed' | null;
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

function toFeeSetting(api: FeeSettingApiModel): FeeSetting {
  return {
    id: String(api.id),
    key: api.key,
    value: api.value,
    unit: api.unit ?? undefined,
    startDate: api.start_date,
    endDate: api.end_date ?? undefined,
    status: api.status,
  };
}

export type FeeTypeCalculationType = 'fixed' | 'tiered' | 'head_additional' | 'variable';

export interface AdminFeeTypeCurrentVersion {
  values: Record<string, number>;
  unit?: string | null;
  startDate: string;
}

export interface AdminFeeType {
  key: string;
  labelBn: string;
  labelEn: string;
  calculationType: FeeTypeCalculationType;
  unit: string;
  isRecurring: boolean;
  isPayOnce: boolean;
  feeCategory: 'installment' | 'other';
  isActive: boolean;
  sortOrder: number;
  createdAt: string;
  currentVersion: AdminFeeTypeCurrentVersion | null;
  paymentCount: number;
}

export interface AdminFeeTypeVersion {
  startDate: string;
  endDate: string | null;
  status: number;
  values: Record<string, number>;
}

export interface FeeTypeCalculation {
  calculationType: string;
  total: number | null;
  breakdown: Record<string, number | null>;
}

interface AdminFeeTypeApiModel {
  key: string;
  label_bn: string;
  label_en: string;
  calculation_type: FeeTypeCalculationType;
  unit: string;
  is_recurring: boolean;
  is_pay_once: boolean;
  fee_category: 'installment' | 'other';
  is_active: boolean;
  sort_order: number;
  created_at: string;
  current_version: {
    values: Record<string, number>;
    unit: string | null;
    start_date: string;
  } | null;
  payment_count: number;
}

function toFeeType(api: AdminFeeTypeApiModel): AdminFeeType {
  return {
    key: api.key,
    labelBn: api.label_bn,
    labelEn: api.label_en,
    calculationType: api.calculation_type,
    unit: api.unit,
    isRecurring: api.is_recurring,
    isPayOnce: api.is_pay_once,
    feeCategory: api.fee_category,
    isActive: api.is_active,
    sortOrder: api.sort_order,
    createdAt: api.created_at,
    currentVersion: api.current_version
      ? {
          values: api.current_version.values,
          unit: api.current_version.unit,
          startDate: api.current_version.start_date,
        }
      : null,
    paymentCount: api.payment_count,
  };
}

interface AdminFeeTypeVersionApiModel {
  start_date: string;
  end_date: string | null;
  status: number;
  values: Record<string, number>;
}

interface FeeTypeCalculationApiModel {
  calculation_type: string;
  total: number | string | null;
  breakdown: Record<string, number | null>;
}

function toConfigListItem(api: ConfigListItemApiModel): ConfigListItem {
  return {
    id: String(api.id),
    category: api.category,
    value: api.value,
    label: api.label,
    sortOrder: api.sort_order,
    isActive: api.is_active === 1,
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

/**
 * Absolute URL for a stored relative upload path.
 *
 * Every path segment is percent-encoded individually: stored paths can contain
 * Bengali labels and spaces (`documents/member_1/খাজনা-কর রশিদ/x.pdf`), and
 * leaving encoding to the browser silently breaks on `#`, `?` and `%`.
 */
export function toFileUrl(relativePath: string | null): string | undefined {
  if (!relativePath) return undefined;
  const encoded = relativePath
    .split('/')
    .map((segment) => encodeURIComponent(segment))
    .join('/');
  return `${uploadsOrigin}/uploads/${encoded}`;
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
    myShareQuantity: api.my_share_quantity,
    ownership: api.ownership,
    jointOwnerCount: api.joint_owner_count,
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
    notificationStatus: api.notification_status ?? undefined,
  };
}

interface MemberProfileApiModel extends SubmissionDetailApiModel {
  updated_at: string;
  reviewed_at: string | null;
  reviewed_by_name: string | null;
  fee_summary: { due_count: number; paid_count: number; due_total: number; paid_total: number };
  installments: {
    id: number;
    year: number;
    month: number;
    amount: number;
    status: 'paid' | 'due';
    paid_at: string | null;
  }[];
  picnic_payments: {
    id: number;
    total: number;
    additional_count: number;
    payment_date: string;
    receipt_no: string | null;
    payment_method: string | null;
  }[];
  audit_trail: {
    id: number;
    action: string;
    detail: string | null;
    actor_name: string | null;
    created_at: string;
  }[];
}

function toMemberProfile(api: MemberProfileApiModel): MemberProfile {
  return {
    ...toSubmissionDetail(api),
    memberId: api.member_id,
    updatedAt: api.updated_at,
    reviewedAt: api.reviewed_at ?? undefined,
    reviewedByName: api.reviewed_by_name ?? undefined,
    feeSummary: {
      dueCount: api.fee_summary.due_count,
      paidCount: api.fee_summary.paid_count,
      dueTotal: api.fee_summary.due_total,
      paidTotal: api.fee_summary.paid_total,
    },
    installments: api.installments.map((row) => ({
      id: String(row.id),
      year: row.year,
      month: row.month,
      amount: row.amount,
      status: row.status,
      paidAt: row.paid_at ?? undefined,
    })),
    picnicPayments: api.picnic_payments.map((row) => ({
      id: row.id,
      total: row.total,
      additionalCount: row.additional_count,
      paymentDate: row.payment_date,
      receiptNo: row.receipt_no,
      paymentMethod: row.payment_method,
    })),
    auditTrail: api.audit_trail.map((row) => ({
      id: row.id,
      action: row.action,
      detail: row.detail,
      actorName: row.actor_name,
      createdAt: row.created_at,
    })),
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

  replaceAttachment(id: string, kind: AttachmentKind, file: File): Observable<SubmissionDetail> {
    const body = new FormData();
    body.append('file', file);
    return this.http
      .put<SubmissionDetailApiModel>(`${this.base}/submissions/${id}/attachments/${kind}`, body)
      .pipe(map(toSubmissionDetail));
  }

  /** Replace a property's applicable document, e.g. when the stored file is lost. */
  replaceDocument(id: string, docId: string, file: File): Observable<SubmissionDetail> {
    const body = new FormData();
    body.append('file', file);
    return this.http
      .put<SubmissionDetailApiModel>(
        `${this.base}/submissions/${id}/documents/${docId}`,
        body,
      )
      .pipe(map(toSubmissionDetail));
  }

  approveSubmission(id: string): Observable<{ member_id: string }> {
    return this.http.post<{ member_id: string }>(`${this.base}/submissions/${id}/approve`, {});
  }

  rejectSubmission(id: string, reason: string): Observable<RejectResult> {
    return this.http
      .post<{ status: string; email_sent: boolean }>(`${this.base}/submissions/${id}/reject`, {
        reason,
      })
      .pipe(map((res) => ({ emailSent: res.email_sent })));
  }

  resendRejectionNotification(id: string): Observable<RejectResult> {
    return this.http
      .post<{ status: string; email_sent: boolean }>(
        `${this.base}/submissions/${id}/resend-notification`,
        {},
      )
      .pipe(map((res) => ({ emailSent: res.email_sent })));
  }

  listPropertyRequests(status?: PropertyRequestStatus): Observable<MemberPropertyRequest[]> {
    const url = status
      ? `${this.base}/property-requests?status=${status}`
      : `${this.base}/property-requests`;
    return this.http
      .get<Parameters<typeof toPropertyRequest>[0][]>(url)
      .pipe(map((rows) => rows.map(toPropertyRequest)));
  }

  approvePropertyRequest(id: number): Observable<MemberPropertyRequest> {
    return this.http
      .post<Parameters<typeof toPropertyRequest>[0]>(
        `${this.base}/property-requests/${id}/approve`,
        {},
      )
      .pipe(map(toPropertyRequest));
  }

  cancelPropertyRequest(id: number, reason: string): Observable<MemberPropertyRequest> {
    return this.http
      .post<Parameters<typeof toPropertyRequest>[0]>(
        `${this.base}/property-requests/${id}/cancel`,
        { reason },
      )
      .pipe(map(toPropertyRequest));
  }

  listMembers(): Observable<Member[]> {
    return this.http
      .get<MemberApiModel[]>(`${this.base}/members`)
      .pipe(map((rows) => rows.map(toMember)));
  }

  getMemberProfile(id: string): Observable<MemberProfile> {
    return this.http
      .get<MemberProfileApiModel>(`${this.base}/members/${id}`)
      .pipe(map(toMemberProfile));
  }

  getMemberInstallments(memberId: string): Observable<Installment[]> {
    return this.http.get<Installment[]>(`${this.base}/members/${memberId}/installments`);
  }

  deleteMember(memberId: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/members/${memberId}`);
  }

  resetMemberPassword(memberId: string): Observable<{ member_id: string; email_sent: boolean }> {
    return this.http.post<{ member_id: string; email_sent: boolean }>(
      `${this.base}/members/${memberId}/reset-password`,
      {},
    );
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

  getPicnicPayments(filters: {
    memberId?: number;
    dateFrom?: string;
    dateTo?: string;
  }): Observable<PicnicPaymentsPage> {
    const params: Record<string, string> = {};
    if (filters.memberId != null) params['member_id'] = String(filters.memberId);
    if (filters.dateFrom) params['date_from'] = filters.dateFrom;
    if (filters.dateTo) params['date_to'] = filters.dateTo;
    return this.http.get<PicnicPaymentsPageApiModel>(`${this.base}/picnic-payments`, { params }).pipe(
      map((page) => ({
        totalCollected: page.total_collected,
        count: page.count,
        items: page.items.map((row) => ({
          id: row.id,
          memberId: row.member_id,
          memberName: row.member_name,
          headPrice: row.head_price,
          additionalPrice: row.additional_price,
          additionalCount: row.additional_count,
          total: row.total,
          paymentDate: row.payment_date,
          receiptNo: row.receipt_no,
          paymentMethod: row.payment_method,
        })),
      })),
    );
  }


  /** All members' non-installment payments in one ledger - the generalized
   * (paginated) picnic payments list, picnic rows included, installments
   * never. Backed by GET /admin/other-fees/payments. */
  getFeePayments(filters: {
    memberId?: number;
    feeType?: string;
    dateFrom?: string;
    dateTo?: string;
    page?: number;
    pageSize?: number;
  }): Observable<FeePaymentsPage> {
    const params: Record<string, string> = {};
    if (filters.memberId != null) params['member_id'] = String(filters.memberId);
    if (filters.feeType) params['fee_type'] = filters.feeType;
    if (filters.dateFrom) params['date_from'] = filters.dateFrom;
    if (filters.dateTo) params['date_to'] = filters.dateTo;
    if (filters.page != null) params['page'] = String(filters.page);
    if (filters.pageSize != null) params['page_size'] = String(filters.pageSize);
    return this.http
      .get<FeePaymentsPageApiModel>(`${this.base}/other-fees/payments`, { params })
      .pipe(
        map((page) => ({
          totalCollected: page.summary.total_paid,
          count: page.total,
          page: page.page,
          pageSize: page.page_size,
          byType: page.summary.by_type,
          items: page.items.map((row) => ({
            id: row.id,
            memberId: row.member_id,
            memberName: row.member_name,
            feeType: row.fee_type,
            amount: Number(row.amount),
            paymentDate: row.payment_date,
            receiptNo: row.receipt_no,
            paymentMethod: row.payment_method,
            note: row.note,
            additionalHeads: row.additional_heads,
            source: row.source,
          })),
        })),
      );
  }

  getActiveFeeSettings(): Observable<FeeSetting[]> {
    return this.http
      .get<FeeSettingApiModel[]>(`${this.base}/fee-settings`)
      .pipe(map((rows) => rows.map(toFeeSetting)));
  }

  getFeeSettingHistory(key: string): Observable<FeeSetting[]> {
    return this.http
      .get<FeeSettingApiModel[]>(`${this.base}/fee-settings/${key}/history`)
      .pipe(map((rows) => rows.map(toFeeSetting)));
  }

  createFeeSettingVersion(payload: {
    key: string;
    value: number;
    unit?: string;
    startDate?: string;
  }): Observable<FeeSetting> {
    return this.http
      .post<FeeSettingApiModel>(`${this.base}/fee-settings`, {
        key: payload.key,
        value: payload.value,
        unit: payload.unit,
        start_date: payload.startDate,
      })
      .pipe(map(toFeeSetting));
  }

  getFeeTypes(): Observable<AdminFeeType[]> {
    return this.http
      .get<AdminFeeTypeApiModel[]>(`${this.base}/fee-types`)
      .pipe(map((rows) => rows.map(toFeeType)));
  }

  createFeeType(payload: {
    key: string;
    labelBn: string;
    labelEn: string;
    calculationType: string;
    unit?: string;
    isRecurring?: boolean;
    isPayOnce?: boolean;
    feeCategory?: string;
  }): Observable<AdminFeeType> {
    return this.http
      .post<AdminFeeTypeApiModel>(`${this.base}/fee-types`, {
        key: payload.key,
        label_bn: payload.labelBn,
        label_en: payload.labelEn,
        calculation_type: payload.calculationType,
        unit: payload.unit ?? 'taka',
        is_recurring: payload.isRecurring ?? false,
        is_pay_once: payload.isPayOnce ?? false,
        fee_category: payload.feeCategory ?? 'other',
      })
      .pipe(map(toFeeType));
  }

  updateFeeType(key: string, payload: Partial<AdminFeeType>): Observable<AdminFeeType> {
    const body: Record<string, unknown> = {};
    if (payload.labelBn !== undefined) body['label_bn'] = payload.labelBn;
    if (payload.labelEn !== undefined) body['label_en'] = payload.labelEn;
    if (payload.unit !== undefined) body['unit'] = payload.unit;
    if (payload.isRecurring !== undefined) body['is_recurring'] = payload.isRecurring;
    if (payload.isPayOnce !== undefined) body['is_pay_once'] = payload.isPayOnce;
    if (payload.feeCategory !== undefined) body['fee_category'] = payload.feeCategory;
    if (payload.isActive !== undefined) body['is_active'] = payload.isActive;
    return this.http
      .put<AdminFeeTypeApiModel>(`${this.base}/fee-types/${encodeURIComponent(key)}`, body)
      .pipe(map(toFeeType));
  }

  getFeeTypeVersions(key: string): Observable<AdminFeeTypeVersion[]> {
    return this.http
      .get<AdminFeeTypeVersionApiModel[]>(
        `${this.base}/fee-types/${encodeURIComponent(key)}/versions`,
      )
      .pipe(
        map((rows) =>
          rows.map((row) => ({
            startDate: row.start_date,
            endDate: row.end_date ?? null,
            status: row.status,
            values: row.values,
          })),
        ),
      );
  }

  createFeeTypeVersion(
    key: string,
    payload: {
      value?: number;
      baseAmount?: number;
      additionalRate?: number;
      baseThreshold?: number;
      headFee?: number;
      additionalHeadFee?: number;
      minAmount?: number;
      maxAmount?: number;
      unit?: string;
      startDate?: string;
    },
  ): Observable<AdminFeeTypeVersion[]> {
    return this.http
      .post<AdminFeeTypeVersionApiModel[]>(
        `${this.base}/fee-types/${encodeURIComponent(key)}/versions`,
        {
          value: payload.value,
          base_amount: payload.baseAmount,
          additional_rate: payload.additionalRate,
          base_threshold: payload.baseThreshold,
          head_fee: payload.headFee,
          additional_head_fee: payload.additionalHeadFee,
          min_amount: payload.minAmount,
          max_amount: payload.maxAmount,
          unit: payload.unit,
          start_date: payload.startDate,
        },
      )
      .pipe(
        map((rows) =>
          rows.map((row) => ({
            startDate: row.start_date,
            endDate: row.end_date ?? null,
            status: row.status,
            values: row.values,
          })),
        ),
      );
  }

  calculateFeeType(
    key: string,
    payload: { landSize?: number; additionalHeads?: number; amount?: number },
  ): Observable<FeeTypeCalculation> {
    return this.http
      .post<FeeTypeCalculationApiModel>(
        `${this.base}/fee-types/${encodeURIComponent(key)}/calculate`,
        {
          land_size: payload.landSize,
          additional_heads: payload.additionalHeads,
          amount: payload.amount,
        },
      )
      .pipe(
        map((res) => ({
          calculationType: res.calculation_type,
          total: res.total === null ? null : Number(res.total),
          breakdown: res.breakdown,
        })),
      );
  }

  listAuditLog(): Observable<AuditLogEntry[]> {
    return this.http
      .get<AuditLogApiModel[]>(`${this.base}/audit-log`)
      .pipe(map((rows) => rows.map(toAuditLogEntry)));
  }

  listConfigListItems(category?: string): Observable<ConfigListItem[]> {
    const url = category
      ? `${this.base}/config-lists?category=${encodeURIComponent(category)}`
      : `${this.base}/config-lists`;
    return this.http
      .get<ConfigListItemApiModel[]>(url)
      .pipe(map((rows) => rows.map(toConfigListItem)));
  }

  createConfigListItem(payload: {
    category: string;
    value: string;
    label: string;
    sortOrder?: number;
  }): Observable<ConfigListItem> {
    return this.http
      .post<ConfigListItemApiModel>(`${this.base}/config-lists`, {
        category: payload.category,
        value: payload.value,
        label: payload.label,
        sort_order: payload.sortOrder ?? 0,
      })
      .pipe(map(toConfigListItem));
  }

  updateConfigListItem(
    id: string,
    payload: { label?: string; sortOrder?: number; isActive?: boolean },
  ): Observable<ConfigListItem> {
    return this.http
      .patch<ConfigListItemApiModel>(`${this.base}/config-lists/${id}`, {
        label: payload.label,
        sort_order: payload.sortOrder,
        is_active: payload.isActive,
      })
      .pipe(map(toConfigListItem));
  }

  listNotices(options?: { published?: boolean; categoryId?: string }): Observable<Notice[]> {
    const params: string[] = [];
    if (options?.published !== undefined) params.push(`published=${options.published}`);
    if (options?.categoryId) params.push(`category_id=${encodeURIComponent(options.categoryId)}`);
    const url = params.length ? `${this.base}/notices?${params.join('&')}` : `${this.base}/notices`;
    return this.http.get<NoticeApiModel[]>(url).pipe(map((rows) => rows.map(toNotice)));
  }

  createNotice(payload: NoticeInput): Observable<Notice> {
    return this.http
      .post<NoticeApiModel>(`${this.base}/notices`, this.noticeBody(payload))
      .pipe(map(toNotice));
  }

  updateNotice(id: string, payload: NoticeInput): Observable<Notice> {
    return this.http
      .patch<NoticeApiModel>(`${this.base}/notices/${id}`, this.noticeBody(payload))
      .pipe(map(toNotice));
  }

  deleteNotice(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/notices/${id}`);
  }

  listEvents(options?: { published?: boolean; categoryId?: string }): Observable<EventItem[]> {
    const params: string[] = [];
    if (options?.published !== undefined) params.push(`published=${options.published}`);
    if (options?.categoryId) params.push(`category_id=${encodeURIComponent(options.categoryId)}`);
    const url = params.length ? `${this.base}/events?${params.join('&')}` : `${this.base}/events`;
    return this.http.get<EventApiModel[]>(url).pipe(map((rows) => rows.map(toEventItem)));
  }

  createEvent(payload: EventInput): Observable<EventItem> {
    return this.http
      .post<EventApiModel>(`${this.base}/events`, this.eventBody(payload))
      .pipe(map(toEventItem));
  }

  updateEvent(id: string, payload: EventInput): Observable<EventItem> {
    return this.http
      .patch<EventApiModel>(`${this.base}/events/${id}`, this.eventBody(payload))
      .pipe(map(toEventItem));
  }

  deleteEvent(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/events/${id}`);
  }

  // The form always sends the complete record (never a sparse patch), so an
  // emptied category/date round-trips as null instead of being dropped.
  private noticeBody(payload: NoticeInput): Record<string, unknown> {
    return {
      title: payload.title,
      body: payload.body,
      category_id: payload.categoryId != null ? Number(payload.categoryId) : null,
      is_published: payload.isPublished ?? false,
      is_members_only: payload.isMembersOnly ?? false,
      publish_at: payload.publishAt ?? null,
    };
  }

  private eventBody(payload: EventInput): Record<string, unknown> {
    return {
      title: payload.title,
      description: payload.description ?? null,
      location: payload.location ?? null,
      category_id: payload.categoryId != null ? Number(payload.categoryId) : null,
      start_at: payload.startAt,
      end_at: payload.endAt ?? null,
      is_published: payload.isPublished ?? false,
      is_members_only: payload.isMembersOnly ?? false,
    };
  }
}

interface PicnicPaymentsPageApiModel {
  items: {
    id: number;
    member_id: number;
    member_name: string | null;
    head_price: number;
    additional_price: number;
    additional_count: number;
    total: number;
    payment_date: string;
    receipt_no: string | null;
    payment_method: string | null;
  }[];
  total_collected: number;
  count: number;
}

export interface AdminPicnicPayment {
  id: number;
  memberId: number;
  memberName: string | null;
  headPrice: number;
  additionalPrice: number;
  additionalCount: number;
  total: number;
  paymentDate: string;
  receiptNo: string | null;
  paymentMethod: string | null;
}

export interface PicnicPaymentsPage {
  items: AdminPicnicPayment[];
  totalCollected: number;
  count: number;
}

interface FeePaymentsPageApiModel {
  items: {
    id: number;
    member_id: number;
    member_name: string | null;
    fee_type: string;
    amount: string | number;
    payment_date: string;
    receipt_no: string | null;
    payment_method: string | null;
    note: string | null;
    additional_heads: number | null;
    source: string;
  }[];
  total: number;
  page: number;
  page_size: number;
  summary: { total_paid: number; by_type: Record<string, number> };
}

export interface AdminFeePayment {
  id: number;
  memberId: number;
  memberName: string | null;
  feeType: string;
  amount: number;
  paymentDate: string;
  receiptNo: string | null;
  paymentMethod: string | null;
  note: string | null;
  additionalHeads: number | null;
  source: string;
}

export interface FeePaymentsPage {
  items: AdminFeePayment[];
  totalCollected: number;
  count: number;
  page: number;
  pageSize: number;
  byType: Record<string, number>;
}
