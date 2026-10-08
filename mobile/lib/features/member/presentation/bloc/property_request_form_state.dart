part of 'property_request_form_bloc.dart';

/// Doc file row in the form (Angular NewDocRow / ExistingDocRow).
class FormDocRow extends Equatable {
  const FormDocRow({
    required this.docType,
    this.filePath,
    this.localPath,
    this.keep = true,
    this.error,
  });

  /// Existing doc (edit mode): kept by default via [keep].
  final String docType;
  final String? filePath;
  final String? localPath;
  final bool keep;
  final String? error;

  bool get isIncomplete =>
      docType.isEmpty || (localPath == null && filePath == null);

  FormDocRow copyWith({
    String? docType,
    String? filePath,
    String? localPath,
    bool? keep,
    String? error,
    bool clearError = false,
  }) {
    return FormDocRow(
      docType: docType ?? this.docType,
      filePath: filePath ?? this.filePath,
      localPath: localPath ?? this.localPath,
      keep: keep ?? this.keep,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [docType, filePath, localPath, keep, error];
}

class FormCoOwnerRow extends Equatable {
  const FormCoOwnerRow({this.ownerName = '', this.ownerPhone = ''});

  final String ownerName;
  final String ownerPhone;

  FormCoOwnerRow copyWith({String? ownerName, String? ownerPhone}) =>
      FormCoOwnerRow(
        ownerName: ownerName ?? this.ownerName,
        ownerPhone: ownerPhone ?? this.ownerPhone,
      );

  @override
  List<Object?> get props => [ownerName, ownerPhone];
}

enum PropertyRequestFormStatus {
  loading,
  ready,
  submitting,
  submitted,
  failure
}

class PropertyRequestFormState extends Equatable {
  const PropertyRequestFormState({
    this.status = PropertyRequestFormStatus.loading,
    this.isEdit = false,
    this.propertyId,
    this.error = false,
    this.propertyType = const [],
    this.propertyTypeOther = '',
    this.khatianNo = '',
    this.dagNoCs = '',
    this.dagNoRs = '',
    this.holdingNumber = '',
    this.landQuantity = '',
    this.myShareQuantity = '',
    this.ownership = '',
    this.coOwners = const [],
    this.existingDocs = const [],
    this.newDocs = const [],
    this.submitAttempted = false,
    this.submitError,
  });

  final PropertyRequestFormStatus status;
  final bool isEdit;
  final String? propertyId;
  final bool error;

  final List<String> propertyType;
  final String propertyTypeOther;
  final String khatianNo;
  final String dagNoCs;
  final String dagNoRs;
  final String holdingNumber;
  final String landQuantity;
  final String myShareQuantity;
  final String ownership;
  final List<FormCoOwnerRow> coOwners;
  final List<FormDocRow> existingDocs;
  final List<FormDocRow> newDocs;
  final bool submitAttempted;
  final String? submitError;

  bool get propertyTypeMissing => submitAttempted && propertyType.isEmpty;
  bool get khatianNoMissing => submitAttempted && khatianNo.trim().isEmpty;
  bool get dagNoCsMissing => submitAttempted && dagNoCs.trim().isEmpty;
  bool get dagNoRsMissing => submitAttempted && dagNoRs.trim().isEmpty;
  bool get landQuantityMissing =>
      submitAttempted && landQuantity.trim().isEmpty;
  bool get landQuantityInvalid =>
      submitAttempted &&
      landQuantity.trim().isNotEmpty &&
      !_positive(landQuantity);
  bool get myShareQuantityMissing =>
      submitAttempted && myShareQuantity.trim().isEmpty;
  bool get myShareQuantityInvalid =>
      submitAttempted &&
      myShareQuantity.trim().isNotEmpty &&
      !_positive(myShareQuantity);
  bool get ownershipMissing => submitAttempted && ownership.trim().isEmpty;
  bool get coOwnersInvalid =>
      submitAttempted &&
      coOwners.any(
          (c) => c.ownerName.trim().isEmpty || c.ownerPhone.trim().isEmpty);
  bool get docsInvalid =>
      submitAttempted && newDocs.any((d) => d.isIncomplete || d.error != null);

  bool get formValid =>
      propertyType.isNotEmpty &&
      khatianNo.trim().isNotEmpty &&
      dagNoCs.trim().isNotEmpty &&
      dagNoRs.trim().isNotEmpty &&
      landQuantity.trim().isNotEmpty &&
      _positive(landQuantity) &&
      myShareQuantity.trim().isNotEmpty &&
      _positive(myShareQuantity) &&
      ownership.trim().isNotEmpty &&
      !coOwnersInvalid &&
      !docsInvalid;

  static bool _positive(String v) =>
      RegExp(r'^\d+(\.\d+)?$').hasMatch(v.trim()) &&
      num.tryParse(v.trim())! > 0;

  PropertyRequestFormState copyWith({
    PropertyRequestFormStatus? status,
    bool? isEdit,
    String? propertyId,
    bool clearError = false,
    bool? error,
    List<String>? propertyType,
    String? propertyTypeOther,
    String? khatianNo,
    String? dagNoCs,
    String? dagNoRs,
    String? holdingNumber,
    String? landQuantity,
    String? myShareQuantity,
    String? ownership,
    List<FormCoOwnerRow>? coOwners,
    List<FormDocRow>? existingDocs,
    List<FormDocRow>? newDocs,
    bool? submitAttempted,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return PropertyRequestFormState(
      status: status ?? this.status,
      isEdit: isEdit ?? this.isEdit,
      propertyId: propertyId ?? this.propertyId,
      error: clearError ? false : (error ?? this.error),
      propertyType: propertyType ?? this.propertyType,
      propertyTypeOther: propertyTypeOther ?? this.propertyTypeOther,
      khatianNo: khatianNo ?? this.khatianNo,
      dagNoCs: dagNoCs ?? this.dagNoCs,
      dagNoRs: dagNoRs ?? this.dagNoRs,
      holdingNumber: holdingNumber ?? this.holdingNumber,
      landQuantity: landQuantity ?? this.landQuantity,
      myShareQuantity: myShareQuantity ?? this.myShareQuantity,
      ownership: ownership ?? this.ownership,
      coOwners: coOwners ?? this.coOwners,
      existingDocs: existingDocs ?? this.existingDocs,
      newDocs: newDocs ?? this.newDocs,
      submitAttempted: submitAttempted ?? this.submitAttempted,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        isEdit,
        propertyId,
        error,
        propertyType,
        propertyTypeOther,
        khatianNo,
        dagNoCs,
        dagNoRs,
        holdingNumber,
        landQuantity,
        myShareQuantity,
        ownership,
        coOwners,
        existingDocs,
        newDocs,
        submitAttempted,
        submitError,
      ];
}
