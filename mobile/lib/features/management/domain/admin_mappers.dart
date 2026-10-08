import '../../../core/config/app_config.dart';
import '../../../core/enums/enums.dart';
import 'admin_entities.dart';

/// Hand-written snake_case JSON -> entity mappers (AdminService.ts parity).
/// Extensions on the raw API map keep the DTO layer transparent: the tests
/// assert every field straight from a JSON literal.

String? _s(Map<String, dynamic> m, String k) => m[k] as String?;
String _sOr(Map<String, dynamic> m, String k) => (m[k] as String?) ?? '';
int _i(Map<String, dynamic> m, String k) => (m[k] as num?)?.toInt() ?? 0;
int? _iN(Map<String, dynamic> m, String k) => (m[k] as num?)?.toInt();
num _n(Map<String, dynamic> m, String k) => (m[k] as num?) ?? 0;
bool _b01(Map<String, dynamic> m, String k) => (m[k] as num?) == 1;

/// Absolute URL for a stored relative upload path (mirrors toFileUrl()).
String? fileUrlOf(String? rawPath) =>
    rawPath == null || rawPath.isEmpty ? null : AppConfig.fileUrl(rawPath);

extension SubmissionSummaryApiX on Map<String, dynamic> {
  SubmissionSummary toSummaryEntity() => SubmissionSummary(
        id: '${this['id']}',
        fullName: _sOr(this, 'full_name'),
        mobile: _sOr(this, 'mobile'),
        status: SubmissionStatusX.fromName(this['status'] as String?),
        createdAt: _sOr(this, 'created_at'),
      );
}

extension ApplicableDocApiX on Map<String, dynamic> {
  ApplicableDoc toDocEntity() => ApplicableDoc(
        id: '${this['id']}',
        docType: _sOr(this, 'doc_type'),
        fileUrl: fileUrlOf(_s(this, 'file_path')),
      );
}

extension SubmissionPropertyApiX on Map<String, dynamic> {
  SubmissionProperty toPropertyEntity() {
    final rawTypes = this['property_type'];
    final docs = this['applicable_docs'];
    return SubmissionProperty(
      id: '${this['id']}',
      propertyType: rawTypes is List
          ? rawTypes.whereType<String>().toList(growable: false)
          : const <String>[],
      propertyTypeOther: _s(this, 'property_type_other'),
      khatianNo: _s(this, 'khatian_no'),
      dagNoCs: _s(this, 'dag_no_cs'),
      dagNoRs: _s(this, 'dag_no_rs'),
      holdingNumber: _s(this, 'holding_number'),
      landQuantity: _s(this, 'land_quantity'),
      myShareQuantity: _s(this, 'my_share_quantity'),
      ownership: _s(this, 'ownership'),
      jointOwnerCount: _iN(this, 'joint_owner_count'),
      applicableDocs: docs is List
          ? docs
              .whereType<Map>()
              .map((d) => Map<String, dynamic>.from(d).toDocEntity())
              .toList(growable: false)
          : const <ApplicableDoc>[],
    );
  }
}

extension NomineeApiX on Map<String, dynamic> {
  Nominee toNomineeEntity() => Nominee(
        id: '${this['id']}',
        name: _sOr(this, 'name'),
        relation: _sOr(this, 'relation'),
        mobile: _sOr(this, 'mobile'),
        address: _s(this, 'address'),
        sharePercentage: this['share_percentage'] as num?,
      );
}

extension SubmissionDetailApiX on Map<String, dynamic> {
  SubmissionDetail toDetailEntity() => SubmissionDetail(
        id: '${this['id']}',
        fullName: _sOr(this, 'full_name'),
        mobile: _sOr(this, 'mobile'),
        status: SubmissionStatusX.fromName(this['status'] as String?),
        createdAt: _sOr(this, 'created_at'),
        fatherOrHusband: _sOr(this, 'father_or_husband'),
        mother: _sOr(this, 'mother'),
        dob: _sOr(this, 'dob'),
        nationality: _sOr(this, 'nationality'),
        occupation: _sOr(this, 'occupation'),
        nid: _sOr(this, 'nid'),
        gender: _sOr(this, 'gender'),
        email: _sOr(this, 'email'),
        permanentHouse: _s(this, 'permanent_house'),
        permanentRoad: _s(this, 'permanent_road'),
        permanentPostOffice: _s(this, 'permanent_post_office'),
        permanentUpazila: _s(this, 'permanent_upazila'),
        permanentDistrict: _s(this, 'permanent_district'),
        permanentDivision: _s(this, 'permanent_division'),
        currentHouse: _s(this, 'current_house'),
        currentRoad: _s(this, 'current_road'),
        currentPostOffice: _s(this, 'current_post_office'),
        currentUpazila: _s(this, 'current_upazila'),
        currentDistrict: _s(this, 'current_district'),
        currentDivision: _s(this, 'current_division'),
        urgentContactName: _s(this, 'urgent_contact_name'),
        urgentContactRelation: _s(this, 'urgent_contact_relation'),
        urgentContactMobile: _s(this, 'urgent_contact_mobile'),
        urgentContactAddress: _s(this, 'urgent_contact_address'),
        properties: _list(this, 'properties')
            .map((p) => p.toPropertyEntity())
            .toList(growable: false),
        nominees:
            _list(this, 'nominees').map((n) => n.toNomineeEntity()).toList(growable: false),
        admissionFee: _sOr(this, 'admission_fee'),
        subscription: _sOr(this, 'subscription'),
        receiptNo: _sOr(this, 'receipt_no'),
        paymentMethod: _sOr(this, 'payment_method'),
        memberPhotoUrl: fileUrlOf(_s(this, 'member_photo_path')),
        memberSignature: _s(this, 'member_signature'),
        receiptPhotoUrl: fileUrlOf(_s(this, 'receipt_photo_path')),
        rejectionReason: _s(this, 'rejection_reason'),
        notificationStatus: _s(this, 'notification_status'),
      );

  static List<Map<String, dynamic>> _list(Map<String, dynamic> m, String k) =>
      m[k] is List ? (m[k] as List).whereType<Map>().map(Map<String, dynamic>.from).toList() : const [];
}

extension MemberApiX on Map<String, dynamic> {
  Member toMemberEntity() => Member(
        id: '${this['id']}',
        memberId: _s(this, 'member_id'),
        status: SubmissionStatusX.fromName(this['status'] as String?),
        fullName: _sOr(this, 'full_name'),
        mobile: _sOr(this, 'mobile'),
        email: _s(this, 'email'),
        dueInstallments: _i(this, 'due_installments'),
      );
}

extension InstallmentApiX on Map<String, dynamic> {
  Installment toInstallmentEntity() => Installment(
        id: '${this['id']}',
        year: _i(this, 'year'),
        month: _i(this, 'month'),
        amount: _n(this, 'amount'),
        status: _sOr(this, 'status'),
        paidAt: _s(this, 'paid_at'),
      );
}

extension FeeSettingApiX on Map<String, dynamic> {
  FeeSetting toFeeSettingEntity() => FeeSetting(
        id: '${this['id']}',
        key: _sOr(this, 'key'),
        value: _n(this, 'value'),
        unit: _s(this, 'unit'),
        startDate: _sOr(this, 'start_date'),
        endDate: _s(this, 'end_date'),
        status: _i(this, 'status'),
      );
}

extension ConfigListItemApiX on Map<String, dynamic> {
  ConfigListItem toConfigItemEntity() => ConfigListItem(
        id: '${this['id']}',
        category: _sOr(this, 'category'),
        value: _sOr(this, 'value'),
        label: _sOr(this, 'label'),
        sortOrder: _i(this, 'sort_order'),
        isActive: _b01(this, 'is_active'),
      );
}

extension PicnicPaymentsPageApiX on Map<String, dynamic> {
  PicnicPaymentsPage toPicnicPageEntity() {
    final items = this['items'];
    return PicnicPaymentsPage(
      totalCollected: _n(this, 'total_collected'),
      count: _i(this, 'count'),
      items: items is List
          ? items
              .whereType<Map>()
              .map((r) {
                final row = Map<String, dynamic>.from(r);
                return AdminPicnicPayment(
                  id: _i(row, 'id'),
                  memberId: _i(row, 'member_id'),
                  memberName: _s(row, 'member_name'),
                  headPrice: _n(row, 'head_price'),
                  additionalPrice: _n(row, 'additional_price'),
                  additionalCount: _i(row, 'additional_count'),
                  total: _n(row, 'total'),
                  paymentDate: _sOr(row, 'payment_date'),
                  receiptNo: _s(row, 'receipt_no'),
                  paymentMethod: _s(row, 'payment_method'),
                );
              })
              .toList(growable: false)
          : const <AdminPicnicPayment>[],
    );
  }
}

extension MemberProfileApiX on Map<String, dynamic> {
  MemberProfile toProfileEntity() {
    final detail = Map<String, dynamic>.from(this).toDetailEntity();
    final feeSummary = this['fee_summary'];
    final fee = feeSummary is Map ? Map<String, dynamic>.from(feeSummary) : const <String, dynamic>{};
    final installments = _list('installments')
        .map((r) => r.toInstallmentEntity())
        .toList(growable: false);
    final picnic = _list('picnic_payments')
        .map((r) => MemberPicnicPayment(
              id: r['id'] as int,
              total: (r['total'] as num?) ?? 0,
              additionalCount: ((r['additional_count'] as num?) ?? 0).toInt(),
              paymentDate: (r['payment_date'] as String?) ?? '',
              receiptNo: r['receipt_no'] as String?,
              paymentMethod: r['payment_method'] as String?,
            ))
        .toList(growable: false);
    final audit = _list('audit_trail')
        .map((r) => MemberAuditEntry(
              id: r['id'] as int,
              action: (r['action'] as String?) ?? '',
              detail: r['detail'] as String?,
              actorName: r['actor_name'] as String?,
              createdAt: (r['created_at'] as String?) ?? '',
            ))
        .toList(growable: false);
    return MemberProfile(
      id: detail.id,
      fullName: detail.fullName,
      mobile: detail.mobile,
      status: detail.status,
      createdAt: detail.createdAt,
      fatherOrHusband: detail.fatherOrHusband,
      mother: detail.mother,
      dob: detail.dob,
      nationality: detail.nationality,
      occupation: detail.occupation,
      nid: detail.nid,
      gender: detail.gender,
      email: detail.email,
      permanentHouse: detail.permanentHouse,
      permanentRoad: detail.permanentRoad,
      permanentPostOffice: detail.permanentPostOffice,
      permanentUpazila: detail.permanentUpazila,
      permanentDistrict: detail.permanentDistrict,
      permanentDivision: detail.permanentDivision,
      currentHouse: detail.currentHouse,
      currentRoad: detail.currentRoad,
      currentPostOffice: detail.currentPostOffice,
      currentUpazila: detail.currentUpazila,
      currentDistrict: detail.currentDistrict,
      currentDivision: detail.currentDivision,
      urgentContactName: detail.urgentContactName,
      urgentContactRelation: detail.urgentContactRelation,
      urgentContactMobile: detail.urgentContactMobile,
      urgentContactAddress: detail.urgentContactAddress,
      memberId: _s(this, 'member_id'),
      properties: detail.properties,
      nominees: detail.nominees,
      admissionFee: detail.admissionFee,
      subscription: detail.subscription,
      receiptNo: detail.receiptNo,
      paymentMethod: detail.paymentMethod,
      memberPhotoUrl: detail.memberPhotoUrl,
      memberSignature: detail.memberSignature,
      receiptPhotoUrl: detail.receiptPhotoUrl,
      rejectionReason: detail.rejectionReason,
      notificationStatus: detail.notificationStatus,
      updatedAt: _sOr(this, 'updated_at'),
      reviewedAt: _s(this, 'reviewed_at'),
      reviewedByName: _s(this, 'reviewed_by_name'),
      feeSummary: MemberFeeSummary(
        dueCount: ((fee['due_count'] as num?) ?? 0).toInt(),
        paidCount: ((fee['paid_count'] as num?) ?? 0).toInt(),
        dueTotal: (fee['due_total'] as num?) ?? 0,
        paidTotal: (fee['paid_total'] as num?) ?? 0,
      ),
      installments: installments,
      picnicPayments: picnic,
      auditTrail: audit,
    );
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic> m, String k) =>
      m[k] is List ? (m[k] as List).whereType<Map>().map(Map<String, dynamic>.from).toList() : const [];
}

// ----- Notices / events -----

extension NoticeApiX on Map<String, dynamic> {
  Notice toNoticeEntity() => Notice(
        id: '${this['id']}',
        title: _sOr(this, 'title'),
        body: _sOr(this, 'body'),
        categoryId: this['category_id'] == null ? null : '${this['category_id']}',
        isPublished: this['is_published'] == true,
        isMembersOnly: this['is_members_only'] == true,
        publishAt: _s(this, 'publish_at'),
        createdAt: _sOr(this, 'created_at'),
        updatedAt: _sOr(this, 'updated_at'),
      );
}

extension EventApiX on Map<String, dynamic> {
  EventItem toEventEntity() => EventItem(
        id: '${this['id']}',
        title: _sOr(this, 'title'),
        description: _s(this, 'description'),
        location: _s(this, 'location'),
        categoryId: this['category_id'] == null ? null : '${this['category_id']}',
        startAt: _sOr(this, 'start_at'),
        endAt: _s(this, 'end_at'),
        isPublished: this['is_published'] == true,
        isMembersOnly: this['is_members_only'] == true,
        createdAt: _sOr(this, 'created_at'),
        updatedAt: _sOr(this, 'updated_at'),
      );
}

// ----- Property requests -----

PropertyRequestStatus _propertyStatus(String? raw) => switch (raw) {
      'pending' => PropertyRequestStatus.pending,
      'approved' => PropertyRequestStatus.approved,
      'cancelled' => PropertyRequestStatus.cancelled,
      _ => PropertyRequestStatus.unknown,
    };

PropertyRequestAction _propertyAction(String? raw) => switch (raw) {
      'add' => PropertyRequestAction.add,
      'edit' => PropertyRequestAction.edit,
      'delete' => PropertyRequestAction.delete,
      _ => PropertyRequestAction.unknown,
    };

extension PropertyRequestApiX on Map<String, dynamic> {
  MemberPropertyRequest toPropertyRequestEntity() {
    final rawPayload = this['payload'];
    final p = rawPayload is Map ? Map<String, dynamic>.from(rawPayload) : const <String, dynamic>{};
    String? str(String k) {
      final v = p[k];
      return v is String && v.isNotEmpty ? v : null;
    }

    final types = p['property_type'];
    final coOwners = p['co_owners'];
    final docs = p['docs'];
    return MemberPropertyRequest(
      id: _i(this, 'id'),
      action: _propertyAction(this['action'] as String?),
      propertyId: _iN(this, 'property_id'),
      payload: PropertyRequestPayload(
        propertyType: types is List
            ? types.whereType<String>().toList(growable: false)
            : const <String>[],
        propertyTypeOther: str('property_type_other'),
        khatianNo: str('khatian_no'),
        dagNoCs: str('dag_no_cs'),
        dagNoRs: str('dag_no_rs'),
        holdingNumber: str('holding_number'),
        landQuantity: str('land_quantity'),
        myShareQuantity: str('my_share_quantity'),
        ownership: str('ownership'),
        coOwners: coOwners is List
            ? coOwners
                .whereType<Map>()
                .map((c) {
                  final m = Map<String, dynamic>.from(c);
                  String s(String k) => m[k] is String && (m[k] as String).isNotEmpty
                      ? m[k] as String
                      : '';
                  return PropertyRequestCoOwner(ownerName: s('owner_name'), ownerPhone: s('owner_phone'));
                })
                .toList(growable: false)
            : const <PropertyRequestCoOwner>[],
        docs: docs is List
            ? docs
                .whereType<Map>()
                .map((d) {
                  final m = Map<String, dynamic>.from(d);
                  String? s(String k) {
                    final v = m[k];
                    return v is String && v.isNotEmpty ? v : null;
                  }

                  return PropertyRequestDoc(docType: s('doc_type') ?? '', keepPath: s('keep_path'));
                })
                .toList(growable: false)
            : const <PropertyRequestDoc>[],
      ),
      status: _propertyStatus(this['status'] as String?),
      cancelReason: _s(this, 'cancel_reason'),
      reviewedAt: _s(this, 'reviewed_at'),
      createdAt: _sOr(this, 'created_at'),
      memberName: _s(this, 'member_name'),
      memberCode: _s(this, 'member_code'),
    );
  }
}
