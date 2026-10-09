import 'package:equatable/equatable.dart';

import '../../../core/enums/enums.dart';

/// Member profile entities mirroring member.service.ts MemberProfile &
/// friends, field-for-field (camelCase, ids as String).
class MemberProfile extends Equatable {
  const MemberProfile({
    required this.memberId,
    required this.status,
    required this.fullName,
    required this.fatherOrHusband,
    required this.mother,
    required this.dob,
    this.nationality,
    this.nid,
    this.gender,
    required this.mobile,
    this.email,
    this.occupation,
    this.permanentHouse,
    this.permanentRoad,
    this.permanentPostOffice,
    this.permanentUpazila,
    this.permanentDistrict,
    this.permanentDivision,
    this.currentHouse,
    this.currentRoad,
    this.currentPostOffice,
    this.currentUpazila,
    this.currentDistrict,
    this.currentDivision,
    this.urgentContactName,
    this.urgentContactRelation,
    this.urgentContactMobile,
    this.urgentContactAddress,
    this.admissionFee,
    this.subscription,
    this.receiptNo,
    this.paymentMethod,
    this.memberSignature,
    this.submissionDate,
    required this.memberPhotoUrl,
    required this.receiptPhotoUrl,
    required this.properties,
    required this.nominees,
    this.showInNeighbourDirectory = true,
  });

  final String memberId;
  final String status;
  final String fullName;
  final String fatherOrHusband;
  final String mother;
  final String dob;
  final String? nationality;
  final String? nid;
  final String? gender;
  final String mobile;
  final String? email;
  final String? occupation;
  final String? permanentHouse;
  final String? permanentRoad;
  final String? permanentPostOffice;
  final String? permanentUpazila;
  final String? permanentDistrict;
  final String? permanentDivision;
  final String? currentHouse;
  final String? currentRoad;
  final String? currentPostOffice;
  final String? currentUpazila;
  final String? currentDistrict;
  final String? currentDivision;
  final String? urgentContactName;
  final String? urgentContactRelation;
  final String? urgentContactMobile;
  final String? urgentContactAddress;
  final String? admissionFee;
  final String? subscription;
  final String? receiptNo;
  final String? paymentMethod;
  final String? memberSignature;
  final String? submissionDate;
  final String memberPhotoUrl;
  final String receiptPhotoUrl;
  final List<MemberProperty> properties;
  final List<MemberNominee> nominees;

  /// Non-core privacy preference: mobile shown in the neighbour directory.
  final bool showInNeighbourDirectory;

  MemberStatus get memberStatus => MemberStatusX.fromName(status);

  bool hasCurrentAddress() =>
      (currentHouse ?? '').isNotEmpty ||
      (currentRoad ?? '').isNotEmpty ||
      (currentPostOffice ?? '').isNotEmpty ||
      (currentUpazila ?? '').isNotEmpty ||
      (currentDistrict ?? '').isNotEmpty ||
      (currentDivision ?? '').isNotEmpty;

  @override
  List<Object?> get props => [
        memberId, status, fullName, fatherOrHusband, mother, dob, nationality,
        nid, gender, mobile, email, occupation, permanentHouse, permanentRoad,
        permanentPostOffice, permanentUpazila, permanentDistrict,
        permanentDivision, currentHouse, currentRoad, currentPostOffice,
        currentUpazila, currentDistrict, currentDivision, urgentContactName,
        urgentContactRelation, urgentContactMobile, urgentContactAddress,
        admissionFee, subscription, receiptNo, paymentMethod, memberSignature,
        submissionDate, memberPhotoUrl, receiptPhotoUrl, properties, nominees,
        showInNeighbourDirectory,
      ];
}

extension MemberStatusX on MemberStatus {
  static MemberStatus fromName(String? name) => switch (name) {
        'pending' => MemberStatus.pending,
        'approved' => MemberStatus.approved,
        'rejected' => MemberStatus.rejected,
        _ => MemberStatus.unknown,
      };
}

class MemberCoOwner extends Equatable {
  const MemberCoOwner({required this.id, required this.ownerName, required this.ownerPhone});

  final String id;
  final String ownerName;
  final String ownerPhone;

  @override
  List<Object?> get props => [id, ownerName, ownerPhone];
}

class MemberPropertyDoc extends Equatable {
  const MemberPropertyDoc({
    required this.id,
    required this.docType,
    this.fileUrl,
    this.filePath,
  });

  final String id;
  final String docType;

  /// Absolute URL for display/download.
  final String? fileUrl;

  /// Server-side path, used as keep_path when re-submitting docs on requests.
  final String? filePath;

  @override
  List<Object?> get props => [id, docType, fileUrl, filePath];
}

class MemberProperty extends Equatable {
  const MemberProperty({
    required this.id,
    required this.propertyType,
    this.propertyTypeOther,
    this.khatianNo,
    this.dagNoCs,
    this.dagNoRs,
    this.holdingNumber,
    this.landQuantity,
    this.myShareQuantity,
    this.ownership,
    required this.coOwners,
    required this.applicableDocs,
  });

  final String id;
  final List<String> propertyType;
  final String? propertyTypeOther;
  final String? khatianNo;
  final String? dagNoCs;
  final String? dagNoRs;
  final String? holdingNumber;
  final String? landQuantity;
  final String? myShareQuantity;
  final String? ownership;
  final List<MemberCoOwner> coOwners;
  final List<MemberPropertyDoc> applicableDocs;

  @override
  List<Object?> get props => [
        id, propertyType, propertyTypeOther, khatianNo, dagNoCs, dagNoRs,
        holdingNumber, landQuantity, myShareQuantity, ownership, coOwners,
        applicableDocs,
      ];
}

class MemberNominee extends Equatable {
  const MemberNominee({
    required this.id,
    required this.name,
    required this.relation,
    required this.mobile,
    this.address,
  });

  final String id;
  final String name;
  final String relation;
  final String mobile;
  final String? address;

  @override
  List<Object?> get props => [id, name, relation, mobile, address];
}

/// Sparse profile update payload; keys are converted to snake_case by the
/// repository (mirrors MemberProfileUpdatePayload).
class MemberProfileUpdate {
  const MemberProfileUpdate({
    this.fullName,
    this.fatherOrHusband,
    this.mother,
    this.dob,
    this.nationality,
    this.occupation,
    this.nid,
    this.gender,
    this.permanentHouse,
    this.permanentRoad,
    this.permanentPostOffice,
    this.permanentUpazila,
    this.permanentDistrict,
    this.permanentDivision,
    this.currentHouse,
    this.currentRoad,
    this.currentPostOffice,
    this.currentUpazila,
    this.currentDistrict,
    this.currentDivision,
    this.mobile,
    this.email,
    this.urgentContactName,
    this.urgentContactRelation,
    this.urgentContactMobile,
    this.urgentContactAddress,
    this.showInNeighbourDirectory,
  });

  final String? fullName;
  final String? fatherOrHusband;
  final String? mother;
  final String? dob;
  final String? nationality;
  final String? occupation;
  final String? nid;
  final String? gender;
  final String? permanentHouse;
  final String? permanentRoad;
  final String? permanentPostOffice;
  final String? permanentUpazila;
  final String? permanentDistrict;
  final String? permanentDivision;
  final String? currentHouse;
  final String? currentRoad;
  final String? currentPostOffice;
  final String? currentUpazila;
  final String? currentDistrict;
  final String? currentDivision;
  final String? mobile;
  final String? email;
  final String? urgentContactName;
  final String? urgentContactRelation;
  final String? urgentContactMobile;
  final String? urgentContactAddress;

  /// Non-core (never re-queues review); omitted from the body when null.
  final bool? showInNeighbourDirectory;

  /// Editing any of these on an approved profile re-queues it for review
  /// (mirrors Angular CORE_FIELDS).
  static const List<String> coreFields = [
    'fullName', 'fatherOrHusband', 'mother', 'dob', 'nationality',
    'occupation', 'nid', 'gender', 'permanentHouse', 'permanentRoad',
    'permanentPostOffice', 'permanentUpazila', 'permanentDistrict',
    'permanentDivision', 'currentHouse', 'currentRoad', 'currentPostOffice',
    'currentUpazila', 'currentDistrict', 'currentDivision',
  ];

  Map<String, Object?> toSnakeCaseBody() => <String, Object?>{
        'full_name': fullName,
        'father_or_husband': fatherOrHusband,
        'mother': mother,
        'dob': dob,
        'nationality': nationality,
        'occupation': occupation,
        'nid': nid,
        'gender': gender,
        'permanent_house': permanentHouse,
        'permanent_road': permanentRoad,
        'permanent_post_office': permanentPostOffice,
        'permanent_upazila': permanentUpazila,
        'permanent_district': permanentDistrict,
        'permanent_division': permanentDivision,
        'current_house': currentHouse,
        'current_road': currentRoad,
        'current_post_office': currentPostOffice,
        'current_upazila': currentUpazila,
        'current_district': currentDistrict,
        'current_division': currentDivision,
        'mobile': mobile,
        'email': email,
        'urgent_contact_name': urgentContactName,
        'urgent_contact_relation': urgentContactRelation,
        'urgent_contact_mobile': urgentContactMobile,
        'urgent_contact_address': urgentContactAddress,
        'show_in_neighbour_directory': showInNeighbourDirectory,
      }..removeWhere((_, v) => v == null);

  /// True when any core field differs between [current] profile values and
  /// this draft (Angular checkRequeue()).
  bool touchesCoreFields(MemberProfile current) {
    String? cur(String field) => switch (field) {
          'fullName' => current.fullName,
          'fatherOrHusband' => current.fatherOrHusband,
          'mother' => current.mother,
          'dob' => current.dob,
          'nationality' => current.nationality,
          'occupation' => current.occupation,
          'nid' => current.nid,
          'gender' => current.gender,
          'permanentHouse' => current.permanentHouse,
          'permanentRoad' => current.permanentRoad,
          'permanentPostOffice' => current.permanentPostOffice,
          'permanentUpazila' => current.permanentUpazila,
          'permanentDistrict' => current.permanentDistrict,
          'permanentDivision' => current.permanentDivision,
          'currentHouse' => current.currentHouse,
          'currentRoad' => current.currentRoad,
          'currentPostOffice' => current.currentPostOffice,
          'currentUpazila' => current.currentUpazila,
          'currentDistrict' => current.currentDistrict,
          'currentDivision' => current.currentDivision,
          _ => null,
        };
    final values = {
      'fullName': fullName,
      'fatherOrHusband': fatherOrHusband,
      'mother': mother,
      'dob': dob,
      'nationality': nationality,
      'occupation': occupation,
      'nid': nid,
      'gender': gender,
      'permanentHouse': permanentHouse,
      'permanentRoad': permanentRoad,
      'permanentPostOffice': permanentPostOffice,
      'permanentUpazila': permanentUpazila,
      'permanentDistrict': permanentDistrict,
      'permanentDivision': permanentDivision,
      'currentHouse': currentHouse,
      'currentRoad': currentRoad,
      'currentPostOffice': currentPostOffice,
      'currentUpazila': currentUpazila,
      'currentDistrict': currentDistrict,
      'currentDivision': currentDivision,
    };
    // Only fields present in the draft are compared (mirrors Angular, where
    // the payload only carries edited entries).
    for (final entry in values.entries) {
      if (entry.value == null) continue;
      if (entry.value != cur(entry.key)) return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// Installment history (GET /member/installments)
// ---------------------------------------------------------------------------

class MemberInstallment extends Equatable {
  const MemberInstallment({
    required this.id,
    required this.year,
    required this.month,
    required this.amount,
    required this.status,
    this.paidAt,
  });

  final String id;
  final int year;
  final int month;
  final num amount;
  final String status; // 'paid' | 'due'
  final String? paidAt;

  bool get isPaid => status == 'paid';

  @override
  List<Object?> get props => [id, year, month, amount, status, paidAt];
}

// ---------------------------------------------------------------------------
// Picnic payments
// ---------------------------------------------------------------------------

class PicnicAdditionalHead extends Equatable {
  const PicnicAdditionalHead({required this.name, required this.relation});

  final String name;
  final String relation;

  @override
  List<Object?> get props => [name, relation];
}

class PicnicPayment extends Equatable {
  const PicnicPayment({
    required this.id,
    required this.headPrice,
    required this.additionalPrice,
    required this.additionalCount,
    required this.total,
    required this.additionalHeads,
    required this.paymentDate,
    this.receiptNo,
    this.paymentMethod,
    required this.createdAt,
  });

  final String id;
  final num headPrice;
  final num additionalPrice;
  final int additionalCount;
  final num total;
  final List<PicnicAdditionalHead> additionalHeads;
  final String paymentDate;
  final String? receiptNo;
  final String? paymentMethod;
  final String createdAt;

  @override
  List<Object?> get props => [
        id, headPrice, additionalPrice, additionalCount, total,
        additionalHeads, paymentDate, receiptNo, paymentMethod, createdAt,
      ];
}

class PicnicRates extends Equatable {
  const PicnicRates({
    required this.headFee,
    required this.additionalHeadFee,
    required this.unit,
    required this.effectiveFrom,
  });

  final num headFee;
  final num additionalHeadFee;
  final String unit;
  final String effectiveFrom;

  @override
  List<Object?> get props => [headFee, additionalHeadFee, unit, effectiveFrom];
}

class PicnicPaymentInput extends Equatable {
  const PicnicPaymentInput({
    required this.additionalHeads,
    required this.additionalPeople,
    required this.paymentDate,
    this.receiptNo,
    this.paymentMethod,
  });

  final int additionalHeads;
  final List<PicnicAdditionalHead> additionalPeople;
  final String paymentDate;
  final String? receiptNo;
  final String? paymentMethod;

  @override
  List<Object?> get props =>
      [additionalHeads, additionalPeople, paymentDate, receiptNo, paymentMethod];
}

// ---------------------------------------------------------------------------
// Property change requests
// ---------------------------------------------------------------------------

enum PropertyRequestAction { add, edit, delete, unknown }

extension PropertyRequestActionX on PropertyRequestAction {
  static PropertyRequestAction fromName(String? name) => switch (name) {
        'add' => PropertyRequestAction.add,
        'edit' => PropertyRequestAction.edit,
        'delete' => PropertyRequestAction.delete,
        _ => PropertyRequestAction.unknown,
      };

  String get apiName => switch (this) {
        PropertyRequestAction.add => 'add',
        PropertyRequestAction.edit => 'edit',
        PropertyRequestAction.delete => 'delete',
        PropertyRequestAction.unknown => 'unknown',
      };
}

enum PropertyRequestStatus { pending, approved, cancelled, unknown }

extension PropertyRequestStatusX on PropertyRequestStatus {
  static PropertyRequestStatus fromName(String? name) => switch (name) {
        'pending' => PropertyRequestStatus.pending,
        'approved' => PropertyRequestStatus.approved,
        'cancelled' => PropertyRequestStatus.cancelled,
        _ => PropertyRequestStatus.unknown,
      };
}

class PropertyRequestDocsEntry extends Equatable {
  const PropertyRequestDocsEntry({required this.docType, this.keepPath});

  final String docType;
  final String? keepPath;

  @override
  List<Object?> get props => [docType, keepPath];
}

class PropertyRequestCoOwner extends Equatable {
  const PropertyRequestCoOwner({required this.ownerName, required this.ownerPhone});

  final String ownerName;
  final String ownerPhone;

  @override
  List<Object?> get props => [ownerName, ownerPhone];
}

class PropertyRequestPayload extends Equatable {
  const PropertyRequestPayload({
    required this.propertyType,
    this.propertyTypeOther,
    this.khatianNo,
    this.dagNoCs,
    this.dagNoRs,
    this.holdingNumber,
    this.landQuantity,
    this.myShareQuantity,
    this.ownership,
    required this.coOwners,
    required this.docs,
  });

  final List<String> propertyType;
  final String? propertyTypeOther;
  final String? khatianNo;
  final String? dagNoCs;
  final String? dagNoRs;
  final String? holdingNumber;
  final String? landQuantity;
  final String? myShareQuantity;
  final String? ownership;
  final List<PropertyRequestCoOwner> coOwners;
  final List<PropertyRequestDocsEntry> docs;

  Map<String, dynamic> toApiJson({bool empty = false}) => empty
      ? <String, dynamic>{}
      : {
          'property_type': propertyType,
          'property_type_other': propertyTypeOther,
          'khatian_no': khatianNo,
          'dag_no_cs': dagNoCs,
          'dag_no_rs': dagNoRs,
          'holding_number': holdingNumber,
          'land_quantity': landQuantity,
          'my_share_quantity': myShareQuantity,
          'ownership': ownership,
          'co_owners': [
            for (final c in coOwners)
              {'owner_name': c.ownerName, 'owner_phone': c.ownerPhone},
          ],
          'docs': [
            for (final d in docs)
              {'doc_type': d.docType, 'keep_path': d.keepPath},
          ],
        };

  @override
  List<Object?> get props => [
        propertyType, propertyTypeOther, khatianNo, dagNoCs, dagNoRs,
        holdingNumber, landQuantity, myShareQuantity, ownership, coOwners, docs,
      ];
}

class MemberPropertyRequest extends Equatable {
  const MemberPropertyRequest({
    required this.id,
    required this.action,
    required this.propertyId,
    required this.payload,
    required this.status,
    required this.cancelReason,
    required this.reviewedAt,
    required this.createdAt,
    this.memberName,
    this.memberCode,
  });

  final String id;
  final PropertyRequestAction action;
  final String? propertyId;
  final PropertyRequestPayload payload;
  final PropertyRequestStatus status;
  final String? cancelReason;
  final String? reviewedAt;
  final String createdAt;

  /// Admin listings only; null on member-owned requests.
  final String? memberName;
  final String? memberCode;

  /// PR-YYYY-NNNN reference (Angular referenceFor()).
  String get reference {
    final year = DateTime.tryParse(createdAt)?.year ?? DateTime.now().year;
    return 'PR-$year-${id.padLeft(4, '0')}';
  }

  @override
  List<Object?> get props => [
        id, action, propertyId, payload, status, cancelReason, reviewedAt,
        createdAt, memberName, memberCode,
      ];
}
