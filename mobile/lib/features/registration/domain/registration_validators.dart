import '../../../core/enums/enums.dart';
import 'phone_validator.dart';
import 'registration_form.dart';

const _nidPattern = r'^\d{10,17}$';
final _nidRegExp = RegExp(_nidPattern);
final _decimalRegExp = RegExp(r'^\d+(\.\d+)?$');
final _emailRegExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Address field variants (labels reused by both address blocks).
enum AddressField { division, district, upazila, postOffice, road, house }

/// One validation failure, carrying enough context for the UI to localize it
/// (mirrors the translated string list the Angular page builds, but structured
/// so widgets stay logic-free).
class RegError implements Comparable<RegError> {
  const RegError(this.kind, {this.propertyIndex, this.nomineeIndex, this.docType, this.addressField, this.isCurrentAddress});

  final RegErrorKind kind;
  final int? propertyIndex;
  final int? nomineeIndex;
  final String? docType;
  final AddressField? addressField;

  /// true = current address block, false = permanent address block.
  final bool? isCurrentAddress;

  @override
  int compareTo(RegError other) => kind.index - other.kind.index;

  @override
  bool operator ==(Object other) =>
      other is RegError &&
      other.kind == kind &&
      other.propertyIndex == propertyIndex &&
      other.nomineeIndex == nomineeIndex &&
      other.docType == docType &&
      other.addressField == addressField &&
      other.isCurrentAddress == isCurrentAddress;

  @override
  int get hashCode => Object.hash(kind, propertyIndex, nomineeIndex, docType, addressField, isCurrentAddress);
}

enum RegErrorKind {
  fullNameRequired,
  fatherOrHusbandRequired,
  motherRequired,
  dobRequired,
  mobileRequired,
  mobileInvalid,
  genderRequired,
  emailInvalid,
  nidInvalid,
  photoRequired,
  addressFieldRequired,
  permanentAddressRequired,
  propertyCountRequired,
  propertyTypeRequired,
  ownershipRequired,
  jointOwnerCountRequired,
  landQuantityRequired,
  landQuantityInvalid,
  shareQuantityRequired,
  shareQuantityInvalid,
  shareQuantityExceedsTotal,
  applicableDocsRequired,
  docFileRequired,
  urgentNameRequired,
  urgentMobileRequired,
  urgentMobileInvalid,
  nomineeNameRequired,
  nomineeMobileRequired,
  nomineeMobileInvalid,
  admissionFeeRequired,
  subscriptionRequired,
  paymentMethodRequired,
  declarationRequired,
}

const wizardStepCount = 6;

List<RegError> validateStep(int step, RegistrationForm form) => switch (step) {
        1 => validateMemberStep(form),
        2 => validatePropertyStep(form),
        3 => validateContactStep(form),
        4 => validatePaymentStep(form),
        5 => validateDeclarationStep(form),
        _ => const [],
      };

List<RegError> validateAllSteps(RegistrationForm form) => [
      for (var s = 1; s <= 5; s++) ...validateStep(s, form),
    ];

/// First step (1-based) failing its own validation; review (6) never fails.
int? firstInvalidStep(RegistrationForm form) {
  for (var step = 1; step < wizardStepCount; step++) {
    if (validateStep(step, form).isNotEmpty) return step;
  }
  return null;
}

List<RegError> validateMemberStep(RegistrationForm form) {
  final errs = <RegError>[];
  if (form.fullName.trim().isEmpty) errs.add(const RegError(RegErrorKind.fullNameRequired));
  if (form.fatherOrHusband.trim().isEmpty) errs.add(const RegError(RegErrorKind.fatherOrHusbandRequired));
  if (form.mother.trim().isEmpty) errs.add(const RegError(RegErrorKind.motherRequired));
  if (form.dob.isEmpty) errs.add(const RegError(RegErrorKind.dobRequired));
  if (form.mobile.trim().isEmpty) {
    errs.add(const RegError(RegErrorKind.mobileRequired));
  } else if (!isValidInternationalPhone(form.mobile)) {
    errs.add(const RegError(RegErrorKind.mobileInvalid));
  }
  if (form.gender == Gender.unknown) errs.add(const RegError(RegErrorKind.genderRequired));
  if (form.email.isNotEmpty && !_emailRegExp.hasMatch(form.email)) {
    errs.add(const RegError(RegErrorKind.emailInvalid));
  }
  if (form.nid.isNotEmpty && !_nidRegExp.hasMatch(form.nid)) {
    errs.add(const RegError(RegErrorKind.nidInvalid));
  }
  // Requires an actual file on disk: after a draft restore only metadata is
  // present and the user must re-attach (see the reattach banner).
  if (form.memberPhoto == null || !form.memberPhoto!.hasFile) {
    errs.add(const RegError(RegErrorKind.photoRequired));
  }

  // Both address blocks are validated unconditionally, mirroring the Angular
  // page (its permanent block stays enabled even when "same as current").
  errs.addAll(_validateAddressBlock(form.currentAddress, isCurrent: true));
  errs.addAll(_validateAddressBlock(form.permanentAddress, isCurrent: false));
  return errs;
}

List<RegError> _validateAddressBlock(AddressDetail a, {required bool isCurrent}) {
  final errs = <RegError>[];
  void check(AddressField field, String value) {
    if (value.trim().isEmpty) {
      errs.add(RegError(RegErrorKind.addressFieldRequired, addressField: field, isCurrentAddress: isCurrent));
    }
  }

  check(AddressField.division, a.division);
  check(AddressField.district, a.district);
  check(AddressField.upazila, a.upazila);
  check(AddressField.postOffice, a.postOffice);
  check(AddressField.road, a.road);
  check(AddressField.house, a.house);
  return errs;
}

List<RegError> validatePropertyStep(RegistrationForm form) {
  final errs = <RegError>[];
  final count = form.propertyCount;
  if (count == null || count == 0) {
    errs.add(const RegError(RegErrorKind.propertyCountRequired));
    return errs;
  }

  for (var i = 0; i < form.properties.length; i++) {
    final p = form.properties[i];
    if (p.propertyType.isEmpty) {
      errs.add(RegError(RegErrorKind.propertyTypeRequired, propertyIndex: i));
    }
    if (p.ownership == OwnershipType.unknown) {
      errs.add(RegError(RegErrorKind.ownershipRequired, propertyIndex: i));
    }
    if (p.isJoint && (p.jointOwnerCount == null || p.jointOwnerCount! < 1)) {
      errs.add(RegError(RegErrorKind.jointOwnerCountRequired, propertyIndex: i));
    }
    final land = p.landQuantity.trim();
    final share = p.myShareQuantity.trim();
    final landValue = double.tryParse(land);
    final shareValue = double.tryParse(share);
    if (land.isEmpty) {
      errs.add(RegError(RegErrorKind.landQuantityRequired, propertyIndex: i));
    } else if (landValue == null || landValue <= 0) {
      errs.add(RegError(RegErrorKind.landQuantityInvalid, propertyIndex: i));
    }
    if (share.isEmpty) {
      errs.add(RegError(RegErrorKind.shareQuantityRequired, propertyIndex: i));
    } else if (shareValue == null || shareValue <= 0) {
      errs.add(RegError(RegErrorKind.shareQuantityInvalid, propertyIndex: i));
    }
    if (landValue != null && shareValue != null && shareValue > landValue) {
      errs.add(RegError(RegErrorKind.shareQuantityExceedsTotal, propertyIndex: i));
    }
    if (p.applicableDocs.isEmpty) {
      errs.add(RegError(RegErrorKind.applicableDocsRequired, propertyIndex: i));
    }
    for (final doc in p.applicableDocs) {
      if (!doc.hasFile) {
        errs.add(RegError(RegErrorKind.docFileRequired, propertyIndex: i, docType: doc.type));
      }
    }
  }
  return errs;
}

List<RegError> validateContactStep(RegistrationForm form) {
  final errs = <RegError>[];
  if (form.urgentContactName.trim().isEmpty) errs.add(const RegError(RegErrorKind.urgentNameRequired));
  if (form.urgentContactMobile.trim().isEmpty) {
    errs.add(const RegError(RegErrorKind.urgentMobileRequired));
  } else if (!isValidInternationalPhone(form.urgentContactMobile)) {
    errs.add(const RegError(RegErrorKind.urgentMobileInvalid));
  }

  for (var i = 0; i < form.nominees.length; i++) {
    final n = form.nominees[i];
    if (n.name.trim().isEmpty) errs.add(RegError(RegErrorKind.nomineeNameRequired, nomineeIndex: i));
    if (n.mobile.trim().isEmpty) {
      errs.add(RegError(RegErrorKind.nomineeMobileRequired, nomineeIndex: i));
    } else if (!isValidInternationalPhone(n.mobile)) {
      errs.add(RegError(RegErrorKind.nomineeMobileInvalid, nomineeIndex: i));
    }
  }
  return errs;
}

/// Step 4 validation. [admissionFee]/[subscription] are resolved live from the
/// fee settings/quote — never stored on the form, so they are passed in.
List<RegError> validatePaymentStep(RegistrationForm form, {required bool hasAdmissionFee, required bool hasSubscription}) {
  final errs = <RegError>[];
  if (!hasAdmissionFee) errs.add(const RegError(RegErrorKind.admissionFeeRequired));
  if (!hasSubscription) errs.add(const RegError(RegErrorKind.subscriptionRequired));
  if (form.paymentMethod == PaymentMethod.unknown) {
    errs.add(const RegError(RegErrorKind.paymentMethodRequired));
  }
  return errs;
}

List<RegError> validateDeclarationStep(RegistrationForm form) {
  final errs = <RegError>[];
  if (!form.declarationAccepted) errs.add(const RegError(RegErrorKind.declarationRequired));
  return errs;
}

/// Decimal pattern gate mirroring the Angular DECIMAL_PATTERN validator.
bool isValidDecimal(String raw) => _decimalRegExp.hasMatch(raw.trim());
