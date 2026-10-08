part of 'registration_bloc.dart';

sealed class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => const [];
}

final class RegistrationStarted extends RegistrationEvent {
  const RegistrationStarted();
}

final class RegistrationDraftDiscarded extends RegistrationEvent {
  const RegistrationDraftDiscarded();
}

final class RegistrationDraftBannerDismissed extends RegistrationEvent {
  const RegistrationDraftBannerDismissed();
}

// ---- Step 1: member -------------------------------------------------------

final class MemberFieldChanged extends RegistrationEvent {
  const MemberFieldChanged(this.field, this.value);

  final MemberField field;
  final String value;

  @override
  List<Object?> get props => [field, value];
}

enum MemberField { fullName, fatherOrHusband, mother, dob, nationality, occupation, nid, mobile, email }

final class MemberGenderSelected extends RegistrationEvent {
  const MemberGenderSelected(this.gender);
  final Gender gender;

  @override
  List<Object?> get props => [gender];
}

final class MemberPhotoAttached extends RegistrationEvent {
  const MemberPhotoAttached(this.path);
  final String path;

  @override
  List<Object?> get props => [path];
}

final class MemberPhotoCleared extends RegistrationEvent {
  const MemberPhotoCleared();
}

final class AddressFieldChanged extends RegistrationEvent {
  const AddressFieldChanged({required this.isCurrent, required this.field, required this.value});

  final bool isCurrent;
  final AddressField field;
  final String value;

  @override
  List<Object?> get props => [isCurrent, field, value];
}

final class SameAsCurrentToggled extends RegistrationEvent {
  const SameAsCurrentToggled(this.value);
  final bool value;

  @override
  List<Object?> get props => [value];
}

// ---- Step 2: property -----------------------------------------------------

final class PropertyCountChanged extends RegistrationEvent {
  const PropertyCountChanged(this.count);
  final int count;

  @override
  List<Object?> get props => [count];
}

final class PropertyFieldChanged extends RegistrationEvent {
  const PropertyFieldChanged(this.index, this.field, this.value);

  final int index;
  final PropertyField field;
  final String value;

  @override
  List<Object?> get props => [index, field, value];
}

enum PropertyField { propertyTypeOther, khatianNo, dagNoCs, dagNoRs, holdingNumber, landQuantity, myShareQuantity }

final class PropertyTypeToggled extends RegistrationEvent {
  const PropertyTypeToggled(this.index, this.type);
  final int index;
  final String type;

  @override
  List<Object?> get props => [index, type];
}

final class OwnershipSelected extends RegistrationEvent {
  const OwnershipSelected(this.index, this.ownership);
  final int index;
  final OwnershipType ownership;

  @override
  List<Object?> get props => [index, ownership];
}

final class JointOwnerCountChanged extends RegistrationEvent {
  const JointOwnerCountChanged(this.index, this.count);
  final int index;
  final int? count;

  @override
  List<Object?> get props => [index, count];
}

final class DocToggled extends RegistrationEvent {
  const DocToggled(this.propertyIndex, this.docType);
  final int propertyIndex;
  final String docType;

  @override
  List<Object?> get props => [propertyIndex, docType];
}

final class DocFileAttached extends RegistrationEvent {
  const DocFileAttached(this.propertyIndex, this.docType, this.path, this.fileName);
  final int propertyIndex;
  final String docType;
  final String path;
  final String fileName;

  @override
  List<Object?> get props => [propertyIndex, docType, path, fileName];
}

final class DocFileRemoved extends RegistrationEvent {
  const DocFileRemoved(this.propertyIndex, this.docType);
  final int propertyIndex;
  final String docType;

  @override
  List<Object?> get props => [propertyIndex, docType];
}

// ---- Step 3: urgent contact + nominees -----------------------------------

final class UrgentContactFieldChanged extends RegistrationEvent {
  const UrgentContactFieldChanged(this.field, this.value);
  final UrgentField field;
  final String value;

  @override
  List<Object?> get props => [field, value];
}

enum UrgentField { name, relation, mobile, address }

final class NomineeAdded extends RegistrationEvent {
  const NomineeAdded();
}

final class NomineeRemoved extends RegistrationEvent {
  const NomineeRemoved(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

final class NomineeFieldChanged extends RegistrationEvent {
  const NomineeFieldChanged(this.index, this.field, this.value);
  final int index;
  final NomineeField field;
  final String value;

  @override
  List<Object?> get props => [index, field, value];
}

enum NomineeField { name, relation, mobile, address }

final class SameAsUrgentToggled extends RegistrationEvent {
  const SameAsUrgentToggled(this.value);
  final bool value;

  @override
  List<Object?> get props => [value];
}

// ---- Step 4: payment ------------------------------------------------------

final class ReceiptNoChanged extends RegistrationEvent {
  const ReceiptNoChanged(this.value);
  final String value;

  @override
  List<Object?> get props => [value];
}

final class ReceiptFileAttached extends RegistrationEvent {
  const ReceiptFileAttached(this.path, this.fileName);
  final String path;
  final String fileName;

  @override
  List<Object?> get props => [path, fileName];
}

final class ReceiptFileRemoved extends RegistrationEvent {
  const ReceiptFileRemoved();
}

final class PaymentMethodSelected extends RegistrationEvent {
  const PaymentMethodSelected(this.method);
  final PaymentMethod method;

  @override
  List<Object?> get props => [method];
}

final class FeeRetryRequested extends RegistrationEvent {
  const FeeRetryRequested();
}

final class SubscriptionRetryRequested extends RegistrationEvent {
  const SubscriptionRetryRequested();
}

/// Internal: debounced quote refresh tick (scheduled by the bloc when property
/// share amounts change).
final class QuoteRefreshRequested extends RegistrationEvent {
  const QuoteRefreshRequested();
}

// ---- Step 5: declaration + signature -------------------------------------

final class SubmissionDateChanged extends RegistrationEvent {
  const SubmissionDateChanged(this.value);
  final String value;

  @override
  List<Object?> get props => [value];
}

final class DeclarationToggled extends RegistrationEvent {
  const DeclarationToggled(this.value);
  final bool value;

  @override
  List<Object?> get props => [value];
}

final class SignatureSaved extends RegistrationEvent {
  const SignatureSaved(this.filePath);
  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

final class SignatureCleared extends RegistrationEvent {
  const SignatureCleared();
}

// ---- Navigation + submit --------------------------------------------------

final class StepGoToRequested extends RegistrationEvent {
  const StepGoToRequested(this.step);
  final int step;

  @override
  List<Object?> get props => [step];
}

final class StepNextRequested extends RegistrationEvent {
  const StepNextRequested();
}

final class StepPrevRequested extends RegistrationEvent {
  const StepPrevRequested();
}

final class SubmitRequested extends RegistrationEvent {
  const SubmitRequested();
}

final class SubmitSuccessAcknowledged extends RegistrationEvent {
  const SubmitSuccessAcknowledged();
}
