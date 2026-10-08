import '../../../core/enums/enums.dart';

/// Admin-area entities (management portal). Mirrors
/// frontend/src/app/core/models/admin.model.ts — ids are String client-side.

class SubmissionSummary {
  const SubmissionSummary({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String mobile;
  final SubmissionStatus status;
  final String createdAt;
}

class ApplicableDoc {
  const ApplicableDoc({required this.id, required this.docType, required this.fileUrl});

  final String id;
  final String docType;

  /// Absolute URL (via AppConfig.fileUrl) or null when the file was lost.
  final String? fileUrl;
}

class SubmissionProperty {
  const SubmissionProperty({
    required this.id,
    required this.propertyType,
    required this.applicableDocs,
    this.propertyTypeOther,
    this.khatianNo,
    this.dagNoCs,
    this.dagNoRs,
    this.holdingNumber,
    this.landQuantity,
    this.myShareQuantity,
    this.ownership,
    this.jointOwnerCount,
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
  final int? jointOwnerCount;
  final List<ApplicableDoc> applicableDocs;
}

class Nominee {
  const Nominee({
    required this.id,
    required this.name,
    required this.relation,
    required this.mobile,
    this.address,
    this.sharePercentage,
  });

  final String id;
  final String name;
  final String relation;
  final String mobile;
  final String? address;
  final num? sharePercentage;
}

class SubmissionDetail extends SubmissionSummary {
  const SubmissionDetail({
    required super.id,
    required super.fullName,
    required super.mobile,
    required super.status,
    required super.createdAt,
    required this.fatherOrHusband,
    required this.mother,
    required this.dob,
    required this.nationality,
    required this.occupation,
    required this.nid,
    required this.gender,
    required this.email,
    required this.properties,
    required this.nominees,
    required this.admissionFee,
    required this.subscription,
    required this.receiptNo,
    required this.paymentMethod,
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
    this.memberId,
    this.memberPhotoUrl,
    this.memberSignature,
    this.receiptPhotoUrl,
    this.rejectionReason,
    this.notificationStatus,
  });

  final String fatherOrHusband;
  final String mother;
  final String dob;
  final String nationality;
  final String occupation;
  final String nid;
  final String gender;
  final String email;
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
  final String? memberId;
  final List<SubmissionProperty> properties;
  final List<Nominee> nominees;
  final String admissionFee;
  final String subscription;
  final String receiptNo;
  final String paymentMethod;
  final String? memberPhotoUrl;
  final String? memberSignature;
  final String? receiptPhotoUrl;
  final String? rejectionReason;

  /// 'sent' | 'failed' — whether the applicant was notified of the rejection.
  final String? notificationStatus;
}

class Member {
  const Member({
    required this.id,
    required this.status,
    required this.fullName,
    required this.mobile,
    required this.dueInstallments,
    this.memberId,
    this.email,
  });

  final String id;
  final String? memberId;
  final SubmissionStatus status;
  final String fullName;
  final String mobile;
  final String? email;
  final int dueInstallments;
}

class Installment {
  const Installment({
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

  /// 'paid' | 'due'
  final String status;
  final String? paidAt;

  bool get isPaid => status == 'paid';
}

class MemberFeeSummary {
  const MemberFeeSummary({
    required this.dueCount,
    required this.paidCount,
    required this.dueTotal,
    required this.paidTotal,
  });

  final int dueCount;
  final int paidCount;
  final num dueTotal;
  final num paidTotal;
}

class MemberPicnicPayment {
  const MemberPicnicPayment({
    required this.id,
    required this.total,
    required this.additionalCount,
    required this.paymentDate,
    this.receiptNo,
    this.paymentMethod,
  });

  final int id;
  final num total;
  final int additionalCount;
  final String paymentDate;
  final String? receiptNo;
  final String? paymentMethod;
}

class MemberAuditEntry {
  const MemberAuditEntry({
    required this.id,
    required this.action,
    required this.createdAt,
    this.detail,
    this.actorName,
  });

  final int id;
  final String action;
  final String? detail;
  final String? actorName;
  final String createdAt;
}

/// Full admin view of a member (GET /admin/members/:id).
class MemberProfile extends SubmissionDetail {
  const MemberProfile({
    required super.id,
    required super.fullName,
    required super.mobile,
    required super.status,
    required super.createdAt,
    required super.fatherOrHusband,
    required super.mother,
    required super.dob,
    required super.nationality,
    required super.occupation,
    required super.nid,
    required super.gender,
    required super.email,
    required super.properties,
    required super.nominees,
    required super.admissionFee,
    required super.subscription,
    required super.receiptNo,
    required super.paymentMethod,
    required this.updatedAt,
    required this.feeSummary,
    required this.installments,
    required this.picnicPayments,
    required this.auditTrail,
    super.memberId,
    super.permanentHouse,
    super.permanentRoad,
    super.permanentPostOffice,
    super.permanentUpazila,
    super.permanentDistrict,
    super.permanentDivision,
    super.currentHouse,
    super.currentRoad,
    super.currentPostOffice,
    super.currentUpazila,
    super.currentDistrict,
    super.currentDivision,
    super.urgentContactName,
    super.urgentContactRelation,
    super.urgentContactMobile,
    super.urgentContactAddress,
    super.memberPhotoUrl,
    super.memberSignature,
    super.receiptPhotoUrl,
    super.rejectionReason,
    super.notificationStatus,
    this.reviewedAt,
    this.reviewedByName,
  });

  final String updatedAt;
  final String? reviewedAt;
  final String? reviewedByName;
  final MemberFeeSummary feeSummary;
  final List<Installment> installments;
  final List<MemberPicnicPayment> picnicPayments;
  final List<MemberAuditEntry> auditTrail;
}

class FeeSetting {
  const FeeSetting({
    required this.id,
    required this.key,
    required this.value,
    required this.startDate,
    required this.status,
    this.unit,
    this.endDate,
  });

  final String id;
  final String key;
  final num value;
  final String? unit;
  final String startDate;
  final String? endDate;

  /// 1 = the currently active version.
  final int status;

  bool get isActive => status == 1;
}

class ConfigListItem {
  const ConfigListItem({
    required this.id,
    required this.category,
    required this.value,
    required this.label,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String category;
  final String value;
  final String label;
  final int sortOrder;
  final bool isActive;

  ConfigListItem copyWith({String? label, int? sortOrder, bool? isActive}) => ConfigListItem(
        id: id,
        category: category,
        value: value,
        label: label ?? this.label,
        sortOrder: sortOrder ?? this.sortOrder,
        isActive: isActive ?? this.isActive,
      );
}

class AdminPicnicPayment {
  const AdminPicnicPayment({
    required this.id,
    required this.memberId,
    required this.headPrice,
    required this.additionalPrice,
    required this.additionalCount,
    required this.total,
    required this.paymentDate,
    this.memberName,
    this.receiptNo,
    this.paymentMethod,
  });

  final int id;
  final int memberId;
  final String? memberName;
  final num headPrice;
  final num additionalPrice;
  final int additionalCount;
  final num total;
  final String paymentDate;
  final String? receiptNo;
  final String? paymentMethod;
}

class PicnicPaymentsPage {
  const PicnicPaymentsPage({
    required this.items,
    required this.totalCollected,
    required this.count,
  });

  final List<AdminPicnicPayment> items;
  final num totalCollected;
  final int count;
}

// ----- Notices / events (management CRUD) -----

class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.isPublished,
    required this.isMembersOnly,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.publishAt,
  });

  final String id;
  final String title;
  final String body;
  final String? categoryId;
  final bool isPublished;
  final bool isMembersOnly;
  final String? publishAt;
  final String createdAt;
  final String updatedAt;
}

class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.isPublished,
    required this.isMembersOnly,
    required this.startAt,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.location,
    this.categoryId,
    this.endAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? location;
  final String? categoryId;
  final String startAt;
  final String? endAt;
  final bool isPublished;
  final bool isMembersOnly;
  final String createdAt;
  final String updatedAt;
}

// ----- Property requests (admin review) -----

enum PropertyRequestStatus { pending, approved, cancelled, unknown }

enum PropertyRequestAction { add, edit, delete, unknown }

class PropertyRequestCoOwner {
  const PropertyRequestCoOwner({required this.ownerName, required this.ownerPhone});

  final String ownerName;
  final String ownerPhone;
}

class PropertyRequestDoc {
  const PropertyRequestDoc({required this.docType, required this.keepPath});

  final String docType;

  /// Stored relative upload path of an existing document kept by the request.
  final String? keepPath;
}

class PropertyRequestPayload {
  const PropertyRequestPayload({
    required this.propertyType,
    required this.coOwners,
    required this.docs,
    this.propertyTypeOther,
    this.khatianNo,
    this.dagNoCs,
    this.dagNoRs,
    this.holdingNumber,
    this.landQuantity,
    this.myShareQuantity,
    this.ownership,
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
  final List<PropertyRequestDoc> docs;
}

class MemberPropertyRequest {
  const MemberPropertyRequest({
    required this.id,
    required this.payload,
    required this.status,
    required this.createdAt,
    required this.action,
    this.propertyId,
    this.cancelReason,
    this.reviewedAt,
    this.memberName,
    this.memberCode,
  });

  final int id;
  final PropertyRequestAction action;
  final int? propertyId;
  final PropertyRequestPayload payload;
  final PropertyRequestStatus status;
  final String? cancelReason;
  final String? reviewedAt;
  final String createdAt;

  /// Admin listings only.
  final String? memberName;
  final String? memberCode;
}
