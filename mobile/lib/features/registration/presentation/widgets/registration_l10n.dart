import '../../../../l10n/app_localizations.dart';
import '../../domain/registration_validators.dart';
import '../../domain/submission_error_mapper.dart';

/// Presentation-only mapping of structured validation/server errors to
/// localized strings (mirrors the translate.instant calls in the Angular
/// page). Keeps l10n lookups out of the bloc.

/// Finds the first [RegError] of [kind] (and optional narrowing filters) for
/// inline field error display.
RegError? findError(
  List<RegError> errors,
  RegErrorKind kind, {
  int? propertyIndex,
  int? nomineeIndex,
  AddressField? addressField,
  bool? isCurrentAddress,
  String? docType,
}) {
  for (final e in errors) {
    if (e.kind != kind) continue;
    if (propertyIndex != null && e.propertyIndex != propertyIndex) continue;
    if (nomineeIndex != null && e.nomineeIndex != nomineeIndex) continue;
    if (addressField != null && e.addressField != addressField) continue;
    if (isCurrentAddress != null && e.isCurrentAddress != isCurrentAddress) continue;
    if (docType != null && e.docType != docType) continue;
    return e;
  }
  return null;
}

String regErrorMessage(AppLocalizations l10n, RegError e) {
  switch (e.kind) {
    case RegErrorKind.fullNameRequired:
      return l10n.registrationValidationFullNameRequired;
    case RegErrorKind.fatherOrHusbandRequired:
      return l10n.registrationValidationFatherOrHusbandRequired;
    case RegErrorKind.motherRequired:
      return l10n.registrationValidationMotherRequired;
    case RegErrorKind.dobRequired:
      return l10n.registrationValidationDobRequired;
    case RegErrorKind.mobileRequired:
      return l10n.registrationValidationMobileRequired;
    case RegErrorKind.mobileInvalid:
      return l10n.registrationValidationMobileInvalid;
    case RegErrorKind.genderRequired:
      return l10n.registrationValidationGenderRequired;
    case RegErrorKind.emailInvalid:
      return l10n.registrationValidationEmailInvalid;
    case RegErrorKind.nidInvalid:
      return l10n.registrationValidationNidInvalid;
    case RegErrorKind.photoRequired:
      return l10n.registrationMemberInfoMemberPhotoRequired;
    case RegErrorKind.addressFieldRequired:
      final fieldLabel = switch (e.addressField) {
        AddressField.division => l10n.registrationAddressInfoDivisionRequired,
        AddressField.district => l10n.registrationAddressInfoDistrictRequired,
        AddressField.upazila => l10n.registrationAddressInfoUpazilaRequired,
        AddressField.postOffice => l10n.registrationAddressInfoPostOfficeRequired,
        AddressField.road => l10n.registrationAddressInfoRoadRequired,
        AddressField.house => l10n.registrationAddressInfoHouseRequired,
        null => '',
      };
      final blockLabel = (e.isCurrentAddress ?? true)
          ? l10n.registrationValidationCurrentAddressLabel
          : l10n.registrationValidationPermanentAddressLabel;
      return '$blockLabel: $fieldLabel';
    case RegErrorKind.propertyCountRequired:
      return l10n.registrationValidationPropertyCountRequired;
    case RegErrorKind.propertyTypeRequired:
      return '${_propertyLabel(l10n, e.propertyIndex)}: ${l10n.registrationValidationPropertyTypeRequired}';
    case RegErrorKind.khatianRequired:
      return '${_propertyLabel(l10n, e.propertyIndex)}: ${l10n.registrationPropertyKhatianNoRequired}';
    case RegErrorKind.dagCsRequired:
      return '${_propertyLabel(l10n, e.propertyIndex)}: ${l10n.registrationPropertyDagNoCsRequired}';
    case RegErrorKind.dagRsRequired:
      return '${_propertyLabel(l10n, e.propertyIndex)}: ${l10n.registrationPropertyDagNoRsRequired}';
    case RegErrorKind.ownershipRequired:
      return '${_propertyLabel(l10n, e.propertyIndex)}: ${l10n.registrationValidationOwnershipRequired}';
    case RegErrorKind.jointOwnerCountRequired:
      return '${_propertyLabel(l10n, e.propertyIndex)}: ${l10n.registrationValidationJointOwnerCountRequired}';
    case RegErrorKind.landQuantityRequired:
      return '${_propertyLabel(l10n, e.propertyIndex)}: ${l10n.registrationValidationLandQuantityRequired}';
    case RegErrorKind.landQuantityInvalid:
      return '${_propertyLabel(l10n, e.propertyIndex)}: ${l10n.registrationValidationLandQuantityInvalid}';
    case RegErrorKind.shareQuantityRequired:
      return '${_propertyLabel(l10n, e.propertyIndex)}: ${l10n.registrationValidationMyShareQuantityRequired}';
    case RegErrorKind.shareQuantityInvalid:
      return '${_propertyLabel(l10n, e.propertyIndex)}: ${l10n.registrationValidationMyShareQuantityInvalid}';
    case RegErrorKind.shareQuantityExceedsTotal:
      return '${_propertyLabel(l10n, e.propertyIndex)}: ${l10n.registrationValidationMyShareQuantityExceedsTotal}';
    case RegErrorKind.applicableDocsRequired:
      return '${_propertyLabel(l10n, e.propertyIndex)}: ${l10n.registrationValidationApplicableDocsRequired}';
    case RegErrorKind.docFileRequired:
      return '${_propertyLabel(l10n, e.propertyIndex)}: ${l10n.registrationValidationDocFileRequired(e.docType ?? '')}';
    case RegErrorKind.urgentNameRequired:
      return '${l10n.registrationValidationUrgentContactLabel}: ${l10n.registrationValidationNameRequired}';
    case RegErrorKind.urgentMobileRequired:
      return '${l10n.registrationValidationUrgentContactLabel}: ${l10n.registrationValidationMobileRequired}';
    case RegErrorKind.urgentMobileInvalid:
      return '${l10n.registrationValidationUrgentContactLabel}: ${l10n.registrationValidationMobileInvalid}';
    case RegErrorKind.nomineeNameRequired:
      return '${l10n.registrationValidationNomineeLabel(e.nomineeIndex! + 1)}: ${l10n.registrationValidationNameRequired}';
    case RegErrorKind.nomineeMobileRequired:
      return '${l10n.registrationValidationNomineeLabel(e.nomineeIndex! + 1)}: ${l10n.registrationValidationMobileRequired}';
    case RegErrorKind.nomineeMobileInvalid:
      return '${l10n.registrationValidationNomineeLabel(e.nomineeIndex! + 1)}: ${l10n.registrationValidationMobileInvalid}';
    case RegErrorKind.admissionFeeRequired:
      return l10n.registrationPaymentAdmissionFeeRequired;
    case RegErrorKind.subscriptionRequired:
      return l10n.registrationPaymentSubscriptionRequired;
    case RegErrorKind.paymentMethodRequired:
      return l10n.registrationPaymentPaymentMethodRequired;
    case RegErrorKind.declarationRequired:
      return l10n.registrationDeclarationConsentRequired;
  }
}

String _propertyLabel(AppLocalizations l10n, int? index) =>
    l10n.registrationValidationPropertyLabel((index ?? 0) + 1);

String submitItemMessage(AppLocalizations l10n, SubmitErrorItem item) {
  switch (item.kind) {
    case SubmitErrorKind.network:
      return l10n.registrationSubmitNetworkError;
    case SubmitErrorKind.fileTooLarge:
      return l10n.registrationSubmitFileTooLarge;
    case SubmitErrorKind.server:
      return l10n.registrationSubmitServerError;
    case SubmitErrorKind.feeNotConfigured:
      return l10n.registrationSubmitFeeNotConfigured;
    case SubmitErrorKind.invalidShareQuantity:
      return l10n.registrationSubmitInvalidShareQuantity;
    case SubmitErrorKind.invalidData:
      return l10n.registrationSubmitInvalidData;
    case SubmitErrorKind.generic:
      final generic = l10n.registrationSubmitGenericError;
      final code = l10n.registrationSubmitErrorCode(item.status ?? 0);
      return '$generic ($code)';
    case SubmitErrorKind.field:
      final label = _submitFieldLabel(l10n, item.fieldRoot ?? '');
      final position = item.position != null ? ' ${item.position! + 1}' : '';
      final reason = item.reason == SubmitErrorReason.required
          ? l10n.registrationSubmitReasonsRequired
          : l10n.registrationSubmitReasonsInvalid;
      return '$label$position: $reason';
  }
}

String _submitFieldLabel(AppLocalizations l10n, String root) => switch (root) {
      'full_name' => l10n.registrationSubmitFieldsFullName,
      'father_or_husband' => l10n.registrationSubmitFieldsFatherOrHusband,
      'mother' => l10n.registrationSubmitFieldsMother,
      'dob' => l10n.registrationSubmitFieldsDob,
      'nationality' => l10n.registrationSubmitFieldsNationality,
      'occupation' => l10n.registrationSubmitFieldsOccupation,
      'nid' => l10n.registrationSubmitFieldsNid,
      'mobile' => l10n.registrationSubmitFieldsMobile,
      'gender' => l10n.registrationSubmitFieldsGender,
      'email' => l10n.registrationSubmitFieldsEmail,
      'permanent_address' => l10n.registrationSubmitFieldsPermanentAddress,
      'current_address' => l10n.registrationSubmitFieldsCurrentAddress,
      'properties' => l10n.registrationSubmitFieldsProperties,
      'nominees' => l10n.registrationSubmitFieldsNominees,
      'admission_fee' => l10n.registrationSubmitFieldsAdmissionFee,
      'subscription' => l10n.registrationSubmitFieldsSubscription,
      'receipt_no' => l10n.registrationSubmitFieldsReceiptNo,
      'payment_method' => l10n.registrationSubmitFieldsPaymentMethod,
      'member_signature' => l10n.registrationSubmitFieldsMemberSignature,
      'submission_date' => l10n.registrationSubmitFieldsSubmissionDate,
      'urgent_contact_name' => l10n.registrationSubmitFieldsUrgentContactName,
      'urgent_contact_relation' => l10n.registrationSubmitFieldsUrgentContactRelation,
      'urgent_contact_mobile' => l10n.registrationSubmitFieldsUrgentContactMobile,
      'urgent_contact_address' => l10n.registrationSubmitFieldsUrgentContactAddress,
      _ => root,
    };
