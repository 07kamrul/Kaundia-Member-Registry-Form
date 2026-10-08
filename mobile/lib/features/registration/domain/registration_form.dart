import '../../../core/enums/enums.dart';

/// Immutable form model for the public registration wizard, mirroring the
/// Angular `buildRegistrationForm` (registration-form.builder.ts) and
/// `registration.model.ts`. File attachments hold local file metadata only —
/// the draft never carries file bytes or fee-derived amounts.

/// Mirrors Angular PROPERTY_TYPES — static defaults used when the
/// /public/config-lists/property_type fetch is empty or fails.
const defaultPropertyTypes = <String>['জমি', 'বাড়ি', 'ফ্ল্যাট', 'প্লট', 'অন্যান্য'];

/// Mirrors Angular DOCUMENT_OPTIONS — static defaults for document_type.
const defaultDocumentOptions = <String>['খতিয়ান/পর্চা', 'নামজারি/মিউটেশন', 'খাজনা/কর রশিদ', 'উত্তরাধিকার সনদ'];

enum Gender { male, female, unknown }

extension GenderX on Gender {
  /// Radio values in the Angular form are the raw Bangla strings.
  String get apiValue => switch (this) {
        Gender.male => 'পুরুষ',
        Gender.female => 'মহিলা',
        Gender.unknown => '',
      };

  static Gender fromApi(String? value) => switch (value) {
        'পুরুষ' => Gender.male,
        'মহিলা' => Gender.female,
        _ => Gender.unknown,
      };
}

/// Mirrors Angular PAYMENT_METHODS (sent verbatim in the payload).
enum PaymentMethod { cash, bank, mfs, other, unknown }

extension PaymentMethodX on PaymentMethod {
  String get apiValue => switch (this) {
        PaymentMethod.cash => 'ক্যাশ',
        PaymentMethod.bank => 'ব্যাংক',
        PaymentMethod.mfs => 'MFS (বিকাশ/নগদ/রকেট)',
        PaymentMethod.other => 'অন্যান্য',
        PaymentMethod.unknown => '',
      };

  static PaymentMethod fromApi(String? value) => switch (value) {
        'ক্যাশ' => PaymentMethod.cash,
        'ব্যাংক' => PaymentMethod.bank,
        'MFS (বিকাশ/নগদ/রকেট)' => PaymentMethod.mfs,
        'অন্যান্য' => PaymentMethod.other,
        _ => PaymentMethod.unknown,
      };
}

/// Local attachment metadata. The file lives on disk at [path]; after a draft
/// restore [path] is null (bytes are never persisted) and the UI prompts for
/// re-attachment.
class FileRef {
  const FileRef({this.fileName, this.path});

  final String? fileName;
  final String? path;

  bool get hasFile => path != null && path!.isNotEmpty;
  bool get hasMetadata => (fileName != null && fileName!.isNotEmpty) || hasFile;

  FileRef copyWith({String? fileName, String? path, bool clearPath = false}) => FileRef(
        fileName: fileName ?? this.fileName,
        path: clearPath ? null : (path ?? this.path),
      );

  @override
  bool operator ==(Object other) => other is FileRef && other.fileName == fileName && other.path == path;

  @override
  int get hashCode => Object.hash(fileName, path);
}

class AddressDetail {
  const AddressDetail({
    this.house = '',
    this.road = '',
    this.postOffice = '',
    this.upazila = '',
    this.district = '',
    this.division = '',
  });

  final String house;
  final String road;
  final String postOffice;
  final String upazila;
  final String district;
  final String division;

  bool get isEmpty => house.isEmpty && road.isEmpty && postOffice.isEmpty && upazila.isEmpty && district.isEmpty && division.isEmpty;

  AddressDetail copyWith({String? house, String? road, String? postOffice, String? upazila, String? district, String? division}) =>
      AddressDetail(
        house: house ?? this.house,
        road: road ?? this.road,
        postOffice: postOffice ?? this.postOffice,
        upazila: upazila ?? this.upazila,
        district: district ?? this.district,
        division: division ?? this.division,
      );

  @override
  bool operator ==(Object other) => other is AddressDetail && other.house == house && other.road == road && other.postOffice == postOffice && other.upazila == upazila && other.district == district && other.division == division;

  @override
  int get hashCode => Object.hash(house, road, postOffice, upazila, district, division);
}

class Nominee {
  const Nominee({this.name = '', this.relation = '', this.mobile = '', this.address = ''});

  final String name;
  final String relation;
  final String mobile;
  final String address;

  Nominee copyWith({String? name, String? relation, String? mobile, String? address}) => Nominee(
        name: name ?? this.name,
        relation: relation ?? this.relation,
        mobile: mobile ?? this.mobile,
        address: address ?? this.address,
      );

  @override
  bool operator ==(Object other) => other is Nominee && other.name == name && other.relation == relation && other.mobile == mobile && other.address == address;

  @override
  int get hashCode => Object.hash(name, relation, mobile, address);
}

class ApplicableDoc {
  const ApplicableDoc({required this.type, this.fileName = '', this.path});

  /// Config-list document type (Bangla label sent verbatim as doc_type).
  final String type;
  final String fileName;
  final String? path;

  bool get hasFile => path != null && path!.isNotEmpty;

  ApplicableDoc copyWith({String? fileName, String? path, bool clearFile = false}) => ApplicableDoc(
        type: type,
        fileName: fileName ?? this.fileName,
        path: clearFile ? null : (path ?? this.path),
      );

  @override
  bool operator ==(Object other) => other is ApplicableDoc && other.type == type && other.fileName == fileName && other.path == path;

  @override
  int get hashCode => Object.hash(type, fileName, path);
}

class PropertyItem {
  const PropertyItem({
    this.propertyType = const [],
    this.propertyTypeOther = '',
    this.khatianNo = '',
    this.dagNoCs = '',
    this.dagNoRs = '',
    this.holdingNumber = '',
    this.landQuantity = '',
    this.myShareQuantity = '',
    this.ownership = OwnershipType.unknown,
    this.jointOwnerCount,
    this.applicableDocs = const [],
  });

  final List<String> propertyType;
  final String propertyTypeOther;
  final String khatianNo;
  final String dagNoCs;
  final String dagNoRs;
  final String holdingNumber;
  final String landQuantity;
  final String myShareQuantity;
  final OwnershipType ownership;
  final int? jointOwnerCount;
  final List<ApplicableDoc> applicableDocs;

  bool get isJoint => ownership == OwnershipType.joint;

  PropertyItem copyWith({
    List<String>? propertyType,
    String? propertyTypeOther,
    String? khatianNo,
    String? dagNoCs,
    String? dagNoRs,
    String? holdingNumber,
    String? landQuantity,
    String? myShareQuantity,
    OwnershipType? ownership,
    int? jointOwnerCount,
    bool clearJointOwnerCount = false,
    List<ApplicableDoc>? applicableDocs,
  }) =>
      PropertyItem(
        propertyType: propertyType ?? this.propertyType,
        propertyTypeOther: propertyTypeOther ?? this.propertyTypeOther,
        khatianNo: khatianNo ?? this.khatianNo,
        dagNoCs: dagNoCs ?? this.dagNoCs,
        dagNoRs: dagNoRs ?? this.dagNoRs,
        holdingNumber: holdingNumber ?? this.holdingNumber,
        landQuantity: landQuantity ?? this.landQuantity,
        myShareQuantity: myShareQuantity ?? this.myShareQuantity,
        ownership: ownership ?? this.ownership,
        jointOwnerCount: clearJointOwnerCount ? null : (jointOwnerCount ?? this.jointOwnerCount),
        applicableDocs: applicableDocs ?? this.applicableDocs,
      );

  @override
  bool operator ==(Object other) => other is PropertyItem && other.propertyType == propertyType && other.propertyTypeOther == propertyTypeOther && other.khatianNo == khatianNo && other.dagNoCs == dagNoCs && other.dagNoRs == dagNoRs && other.holdingNumber == holdingNumber && other.landQuantity == landQuantity && other.myShareQuantity == myShareQuantity && other.ownership == ownership && other.jointOwnerCount == jointOwnerCount && other.applicableDocs == applicableDocs;

  @override
  int get hashCode => Object.hash(propertyType, propertyTypeOther, khatianNo, dagNoCs, dagNoRs, holdingNumber, landQuantity, myShareQuantity, ownership, jointOwnerCount, applicableDocs);
}

/// Whole-form value (Angular form.getRawValue() equivalent).
class RegistrationForm {
  const RegistrationForm({
    this.fullName = '',
    this.fatherOrHusband = '',
    this.mother = '',
    this.dob = '',
    this.nationality = 'বাংলাদেশী',
    this.occupation = '',
    this.nid = '',
    this.mobile = '',
    this.gender = Gender.unknown,
    this.email = '',
    this.permanentAddress = const AddressDetail(),
    this.currentAddress = const AddressDetail(),
    this.sameAsCurrentAddress = false,
    this.urgentContactName = '',
    this.urgentContactRelation = '',
    this.urgentContactMobile = '',
    this.urgentContactAddress = '',
    this.propertyCount,
    this.properties = const [],
    this.nominees = const [Nominee()],
    this.receiptNo = '',
    this.paymentMethod = PaymentMethod.unknown,
    this.receiptFile,
    this.memberPhoto,
    this.memberSignature = '',
    this.submissionDate = '',
    this.declarationAccepted = false,
  });

  final String fullName;
  final String fatherOrHusband;
  final String mother;
  final String dob;
  final String nationality;
  final String occupation;
  final String nid;
  final String mobile;
  final Gender gender;
  final String email;

  final AddressDetail permanentAddress;
  final AddressDetail currentAddress;

  /// UI-only toggle (never submitted, mirrors the Angular extra control).
  final bool sameAsCurrentAddress;

  final String urgentContactName;
  final String urgentContactRelation;
  final String urgentContactMobile;
  final String urgentContactAddress;

  final int? propertyCount;
  final List<PropertyItem> properties;

  final List<Nominee> nominees;

  final String receiptNo;
  final PaymentMethod paymentMethod;
  final FileRef? receiptFile;

  final FileRef? memberPhoto;

  /// PNG data URL captured from the signature pad (Angular memberSignature).
  final String memberSignature;
  final String submissionDate;
  final bool declarationAccepted;

  RegistrationForm copyWith({
    String? fullName,
    String? fatherOrHusband,
    String? mother,
    String? dob,
    String? nationality,
    String? occupation,
    String? nid,
    String? mobile,
    Gender? gender,
    String? email,
    AddressDetail? permanentAddress,
    AddressDetail? currentAddress,
    bool? sameAsCurrentAddress,
    String? urgentContactName,
    String? urgentContactRelation,
    String? urgentContactMobile,
    String? urgentContactAddress,
    int? propertyCount,
    bool clearPropertyCount = false,
    List<PropertyItem>? properties,
    List<Nominee>? nominees,
    String? receiptNo,
    PaymentMethod? paymentMethod,
    FileRef? receiptFile,
    bool clearReceiptFile = false,
    FileRef? memberPhoto,
    bool clearMemberPhoto = false,
    String? memberSignature,
    String? submissionDate,
    bool? declarationAccepted,
  }) =>
      RegistrationForm(
        fullName: fullName ?? this.fullName,
        fatherOrHusband: fatherOrHusband ?? this.fatherOrHusband,
        mother: mother ?? this.mother,
        dob: dob ?? this.dob,
        nationality: nationality ?? this.nationality,
        occupation: occupation ?? this.occupation,
        nid: nid ?? this.nid,
        mobile: mobile ?? this.mobile,
        gender: gender ?? this.gender,
        email: email ?? this.email,
        permanentAddress: permanentAddress ?? this.permanentAddress,
        currentAddress: currentAddress ?? this.currentAddress,
        sameAsCurrentAddress: sameAsCurrentAddress ?? this.sameAsCurrentAddress,
        urgentContactName: urgentContactName ?? this.urgentContactName,
        urgentContactRelation: urgentContactRelation ?? this.urgentContactRelation,
        urgentContactMobile: urgentContactMobile ?? this.urgentContactMobile,
        urgentContactAddress: urgentContactAddress ?? this.urgentContactAddress,
        propertyCount: clearPropertyCount ? null : (propertyCount ?? this.propertyCount),
        properties: properties ?? this.properties,
        nominees: nominees ?? this.nominees,
        receiptNo: receiptNo ?? this.receiptNo,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        receiptFile: clearReceiptFile ? null : (receiptFile ?? this.receiptFile),
        memberPhoto: clearMemberPhoto ? null : (memberPhoto ?? this.memberPhoto),
        memberSignature: memberSignature ?? this.memberSignature,
        submissionDate: submissionDate ?? this.submissionDate,
        declarationAccepted: declarationAccepted ?? this.declarationAccepted,
      );

  /// Sum of all properties' share quantities — drives the চাঁদা quote request.
  double get totalShareQuantity => properties.fold(
        0,
        (sum, p) => sum + ((double.tryParse(p.myShareQuantity.trim()) ?? 0) > 0 ? (double.tryParse(p.myShareQuantity.trim()) ?? 0) : 0),
      );
}
