import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../domain/member_entities.dart';

/// Repository for GET/PATCH /member/me etc. Mappers mirror member.service.ts
/// ApiModel -> app model field-for-field; ids become String client-side.
class MemberRepository {
  MemberRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<MemberProfile> getProfile() async {
    final data = await _api.getUri('/member/me') as Map<dynamic, dynamic>;
    return memberProfileFromApi(data);
  }

  Future<MemberProfile> updateProfile(MemberProfileUpdate update) async {
    final data = await _api.patch('/member/profile', update.toSnakeCaseBody())
        as Map<dynamic, dynamic>;
    return memberProfileFromApi(data);
  }

  /// Uploads a new profile photo (multipart field `photo`).
  Future<MemberProfile> uploadPhoto(AttachedFileBytes photo) async {
    final form = FormData();
    form.files.add(MapEntry(
      'photo',
      MultipartFile.fromBytes(photo.bytes, filename: photo.fileName, contentType: photo.contentType),
    ));
    final data = await _api.postMultipart('/member/me/photo', form) as Map<dynamic, dynamic>;
    return memberProfileFromApi(data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post('/member/change-password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<List<MemberPropertyRequest>> getPropertyRequests() async {
    final data = await _api.getUri('/member/property-requests') as List<dynamic>;
    return [for (final row in data) propertyRequestFromApi(row as Map<dynamic, dynamic>)];
  }

  Future<MemberPropertyRequest> createPropertyRequest(
    PropertyRequestInput input,
  ) async {
    final form = FormData();
    form.fields.add(MapEntry('action', input.action.apiName));
    if (input.propertyId != null) {
      form.fields.add(MapEntry('property_id', input.propertyId!));
    }
    form.fields.add(MapEntry('payload', input.payloadJson()));
    for (final file in input.newDocFiles) {
      form.files.add(MapEntry(
        'doc_files',
        MultipartFile.fromBytes(file.bytes, filename: file.fileName, contentType: file.contentType),
      ));
    }
    final data = await _api.postMultipart('/member/property-requests', form)
        as Map<dynamic, dynamic>;
    return propertyRequestFromApi(data);
  }

  Future<MemberPropertyRequest> withdrawPropertyRequest(String id) async {
    final data =
        await _api.post('/member/property-requests/$id/withdraw', <String, dynamic>{})
            as Map<dynamic, dynamic>;
    return propertyRequestFromApi(data);
  }

  Future<List<MemberInstallment>> getInstallments() async {
    final data = await _api.getUri('/member/installments') as List<dynamic>;
    return [for (final row in data) installmentFromApi(row as Map<dynamic, dynamic>)];
  }

  Future<List<PicnicPayment>> getPicnicPayments() async {
    final data = await _api.getUri('/member/picnic-payments') as List<dynamic>;
    return [for (final row in data) picnicPaymentFromApi(row as Map<dynamic, dynamic>)];
  }

  Future<PicnicRates> getPicnicRates(String paymentDate) async {
    final data = await _api.getUri('/member/picnic-rates',
        query: {'payment_date': paymentDate}) as Map<dynamic, dynamic>;
    return PicnicRates(
      headFee: (data['head_fee'] as num?) ?? 0,
      additionalHeadFee: (data['additional_head_fee'] as num?) ?? 0,
      unit: (data['unit'] as String?) ?? '',
      effectiveFrom: (data['effective_from'] as String?) ?? '',
    );
  }

  Future<PicnicPayment> createPicnicPayment(PicnicPaymentInput input) async {
    final data = await _api.post('/member/picnic-payments', {
      'additional_heads': input.additionalHeads,
      'additional_people': [
        for (final p in input.additionalPeople)
          {'name': p.name, 'relation': p.relation},
      ],
      'payment_date': input.paymentDate,
      'receipt_no': (input.receiptNo ?? '').isEmpty ? null : input.receiptNo,
      'payment_method': (input.paymentMethod ?? '').isEmpty ? null : input.paymentMethod,
    }) as Map<dynamic, dynamic>;
    return picnicPaymentFromApi(data);
  }
}

/// Raw attachment bytes ready for a multipart field.
class AttachedFileBytes {
  const AttachedFileBytes({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final List<int> bytes;
  final String fileName;
  final DioMediaType contentType;
}

class PropertyRequestInput {
  const PropertyRequestInput({
    required this.action,
    this.propertyId,
    required this.payload,
    this.newDocFiles = const [],
  });

  final PropertyRequestAction action;
  final String? propertyId;
  final PropertyRequestPayload payload;
  final List<AttachedFileBytes> newDocFiles;

  String payloadJson() =>
      jsonEncode(payload.toApiJson(empty: action == PropertyRequestAction.delete));
}

// ---------------------------------------------------------------------------
// Mappers (hand-written, snake_case asserted in tests)
// ---------------------------------------------------------------------------

String? _s(dynamic v) => v?.toString();
String _str(dynamic v) => v?.toString() ?? '';

String? _toFileUrl(dynamic path) {
  final raw = _s(path);
  if (raw == null || raw.isEmpty) return null;
  return AppConfig.fileUrl(raw);
}

MemberProfile memberProfileFromApi(Map<dynamic, dynamic> api) {
  final props = (api['properties'] as List<dynamic>? ?? const []);
  final nominees = (api['nominees'] as List<dynamic>? ?? const []);
  return MemberProfile(
    memberId: api['member_id']?.toString() ?? '',
    status: _str(api['status']),
    fullName: _str(api['full_name']),
    fatherOrHusband: _str(api['father_or_husband']),
    mother: _str(api['mother']),
    dob: _str(api['dob']),
    nationality: _s(api['nationality']),
    nid: _s(api['nid']),
    gender: _s(api['gender']),
    mobile: _str(api['mobile']),
    email: _s(api['email']),
    occupation: _s(api['occupation']),
    permanentHouse: _s(api['permanent_house']),
    permanentRoad: _s(api['permanent_road']),
    permanentPostOffice: _s(api['permanent_post_office']),
    permanentUpazila: _s(api['permanent_upazila']),
    permanentDistrict: _s(api['permanent_district']),
    permanentDivision: _s(api['permanent_division']),
    currentHouse: _s(api['current_house']),
    currentRoad: _s(api['current_road']),
    currentPostOffice: _s(api['current_post_office']),
    currentUpazila: _s(api['current_upazila']),
    currentDistrict: _s(api['current_district']),
    currentDivision: _s(api['current_division']),
    urgentContactName: _s(api['urgent_contact_name']),
    urgentContactRelation: _s(api['urgent_contact_relation']),
    urgentContactMobile: _s(api['urgent_contact_mobile']),
    urgentContactAddress: _s(api['urgent_contact_address']),
    admissionFee: _s(api['admission_fee']),
    subscription: _s(api['subscription']),
    receiptNo: _s(api['receipt_no']),
    paymentMethod: _s(api['payment_method']),
    memberSignature: _s(api['member_signature']),
    submissionDate: _s(api['submission_date']),
    memberPhotoUrl: _toFileUrl(api['member_photo_path']) ?? '',
    receiptPhotoUrl: _toFileUrl(api['receipt_photo_path']) ?? '',
    properties: [for (final p in props) memberPropertyFromApi(p as Map<dynamic, dynamic>)],
    nominees: [for (final n in nominees) memberNomineeFromApi(n as Map<dynamic, dynamic>)],
    showInNeighbourDirectory: _boolOr(api['show_in_neighbour_directory'], fallback: true),
  );
}

bool _boolOr(dynamic v, {required bool fallback}) => switch (v) {
      final bool b => b,
      final num n => n != 0,
      _ => fallback,
    };

MemberProperty memberPropertyFromApi(Map<dynamic, dynamic> api) {
  final coOwners = (api['co_owners'] as List<dynamic>? ?? const []);
  final docs = (api['applicable_docs'] as List<dynamic>? ?? const []);
  return MemberProperty(
    id: _str(api['id']),
    propertyType: [
      for (final t in (api['property_type'] as List<dynamic>? ?? const [])) t.toString(),
    ],
    propertyTypeOther: _s(api['property_type_other']),
    khatianNo: _s(api['khatian_no']),
    dagNoCs: _s(api['dag_no_cs']),
    dagNoRs: _s(api['dag_no_rs']),
    holdingNumber: _s(api['holding_number']),
    landQuantity: _s(api['land_quantity']),
    myShareQuantity: _s(api['my_share_quantity']),
    ownership: _s(api['ownership']),
    coOwners: [
      for (final c in coOwners)
        MemberCoOwner(
          id: _str((c as Map<dynamic, dynamic>)['id']),
          ownerName: _str(c['owner_name']),
          ownerPhone: _str(c['owner_phone']),
        ),
    ],
    applicableDocs: [
      for (final d in docs)
        MemberPropertyDoc(
          id: _str((d as Map<dynamic, dynamic>)['id']),
          docType: _str(d['doc_type']),
          fileUrl: _toFileUrl(d['file_path']),
          filePath: _s(d['file_path']),
        ),
    ],
  );
}

MemberNominee memberNomineeFromApi(Map<dynamic, dynamic> api) => MemberNominee(
      id: _str(api['id']),
      name: _str(api['name']),
      relation: _str(api['relation']),
      mobile: _str(api['mobile']),
      address: _s(api['address']),
    );

String? _strOrNull(dynamic v) =>
    v is String && v.isNotEmpty ? v : (v != null && v is! String ? v.toString() : null);

MemberPropertyRequest propertyRequestFromApi(Map<dynamic, dynamic> api) {
  final p = (api['payload'] as Map<dynamic, dynamic>? ?? const {});
  final coOwners = (p['co_owners'] as List<dynamic>? ?? const []);
  final docs = (p['docs'] as List<dynamic>? ?? const []);
  String? str(dynamic v) => _strOrNull(v);
  return MemberPropertyRequest(
    id: _str(api['id']),
    action: PropertyRequestActionX.fromName(_s(api['action'])),
    propertyId: api['property_id']?.toString(),
    payload: PropertyRequestPayload(
      propertyType: [
        for (final t in (p['property_type'] as List<dynamic>? ?? const [])) t.toString(),
      ],
      propertyTypeOther: str(p['property_type_other']),
      khatianNo: str(p['khatian_no']),
      dagNoCs: str(p['dag_no_cs']),
      dagNoRs: str(p['dag_no_rs']),
      holdingNumber: str(p['holding_number']),
      landQuantity: str(p['land_quantity']),
      myShareQuantity: str(p['my_share_quantity']),
      ownership: str(p['ownership']),
      coOwners: [
        for (final c in coOwners)
          PropertyRequestCoOwner(
            ownerName: str((c as Map<dynamic, dynamic>)['owner_name']) ?? '',
            ownerPhone: str(c['owner_phone']) ?? '',
          ),
      ],
      docs: [
        for (final d in docs)
          PropertyRequestDocsEntry(
            docType: str((d as Map<dynamic, dynamic>)['doc_type']) ?? '',
            keepPath: str(d['keep_path']),
          ),
      ],
    ),
    status: PropertyRequestStatusX.fromName(_s(api['status'])),
    cancelReason: str(api['cancel_reason']),
    reviewedAt: str(api['reviewed_at']),
    createdAt: _str(api['created_at']),
    memberName: str(api['member_name']),
    memberCode: str(api['member_code']),
  );
}

MemberInstallment installmentFromApi(Map<dynamic, dynamic> api) => MemberInstallment(
      id: _str(api['id']),
      year: (api['year'] as num?)?.toInt() ?? 0,
      month: (api['month'] as num?)?.toInt() ?? 0,
      amount: (api['amount'] as num?) ?? 0,
      status: _str(api['status']),
      paidAt: _s(api['paid_at']),
    );

PicnicPayment picnicPaymentFromApi(Map<dynamic, dynamic> api) => PicnicPayment(
      id: _str(api['id']),
      headPrice: (api['head_price'] as num?) ?? 0,
      additionalPrice: (api['additional_price'] as num?) ?? 0,
      additionalCount: (api['additional_count'] as num?)?.toInt() ?? 0,
      total: (api['total'] as num?) ?? 0,
      additionalHeads: [
        for (final h in (api['additional_heads'] as List<dynamic>? ?? const []))
          PicnicAdditionalHead(
            name: _str((h as Map<dynamic, dynamic>)['name']),
            relation: _str(h['relation']),
          ),
      ],
      paymentDate: _str(api['payment_date']),
      receiptNo: _s(api['receipt_no']),
      paymentMethod: _s(api['payment_method']),
      createdAt: _str(api['created_at']),
    );
