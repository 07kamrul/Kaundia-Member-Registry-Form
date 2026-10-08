import 'package:equatable/equatable.dart';

import '../../data/fee_repository.dart';
import '../../data/geo_repository.dart';
import '../../domain/registration_form.dart';
import '../../domain/registration_validators.dart';
import '../../domain/submission_error_mapper.dart';

enum RegistrationStatus { loading, ready }

enum FeeStatus { loading, loaded, error }

enum QuoteStatus { idle, loading, loaded, error }

enum SubmitStatus { idle, submitting, success, duplicate, failure }

enum FileErrorKind { type, size }

/// A failed file pick (doc / receipt): what was being attached and why.
class FilePickError extends Equatable {
  const FilePickError({required this.kind, this.propertyIndex, this.docType, this.isReceipt = false});

  final FileErrorKind kind;
  final int? propertyIndex;
  final String? docType;
  final bool isReceipt;

  @override
  List<Object?> get props => [kind, propertyIndex, docType, isReceipt];
}

class RegistrationState extends Equatable {
  const RegistrationState({
    this.status = RegistrationStatus.loading,
    this.form = const RegistrationForm(),
    this.currentStep = 1,
    this.submitAttempted = false,
    this.stepErrors = const [],
    this.geoData,
    this.geoError = false,
    this.propertyTypes = defaultPropertyTypes,
    this.documentOptions = defaultDocumentOptions,
    this.feeStatus = FeeStatus.loading,
    this.admissionFee,
    this.quote,
    this.quoteStatus = QuoteStatus.idle,
    this.submitStatus = SubmitStatus.idle,
    this.successId = '',
    this.duplicateKind,
    this.duplicateMessage = '',
    this.submitErrors = const [],
    this.fileError,
    this.draftRestored = false,
    this.draftLastSaved,
  });

  final RegistrationStatus status;
  final RegistrationForm form;
  final int currentStep;
  final bool submitAttempted;
  final List<RegError> stepErrors;

  final GeoData? geoData;
  final bool geoError;
  final List<String> propertyTypes;
  final List<String> documentOptions;

  final FeeStatus feeStatus;
  final double? admissionFee;
  final SubscriptionQuote? quote;
  final QuoteStatus quoteStatus;

  final SubmitStatus submitStatus;
  final String successId;
  final DuplicateSubmissionKind? duplicateKind;
  final String duplicateMessage;
  final List<SubmitErrorItem> submitErrors;
  final FilePickError? fileError;

  final bool draftRestored;
  final String? draftLastSaved;

  bool get hasAdmissionFee => admissionFee != null && admissionFee! > 0;
  bool get hasSubscription => quote != null && quoteStatus == QuoteStatus.loaded && quote!.total > 0;

  RegistrationState copyWith({
    RegistrationStatus? status,
    RegistrationForm? form,
    int? currentStep,
    bool? submitAttempted,
    List<RegError>? stepErrors,
    GeoData? geoData,
    bool? geoError,
    List<String>? propertyTypes,
    List<String>? documentOptions,
    FeeStatus? feeStatus,
    double? admissionFee,
    SubscriptionQuote? quote,
    QuoteStatus? quoteStatus,
    SubmitStatus? submitStatus,
    String? successId,
    DuplicateSubmissionKind? duplicateKind,
    String? duplicateMessage,
    List<SubmitErrorItem>? submitErrors,
    FilePickError? fileError,
    bool clearFileError = false,
    bool? draftRestored,
    String? draftLastSaved,
  }) =>
      RegistrationState(
        status: status ?? this.status,
        form: form ?? this.form,
        currentStep: currentStep ?? this.currentStep,
        submitAttempted: submitAttempted ?? this.submitAttempted,
        stepErrors: stepErrors ?? this.stepErrors,
        geoData: geoData ?? this.geoData,
        geoError: geoError ?? this.geoError,
        propertyTypes: propertyTypes ?? this.propertyTypes,
        documentOptions: documentOptions ?? this.documentOptions,
        feeStatus: feeStatus ?? this.feeStatus,
        admissionFee: admissionFee ?? this.admissionFee,
        quote: quote ?? this.quote,
        quoteStatus: quoteStatus ?? this.quoteStatus,
        submitStatus: submitStatus ?? this.submitStatus,
        successId: successId ?? this.successId,
        duplicateKind: duplicateKind ?? this.duplicateKind,
        duplicateMessage: duplicateMessage ?? this.duplicateMessage,
        submitErrors: submitErrors ?? this.submitErrors,
        fileError: clearFileError ? null : (fileError ?? this.fileError),
        draftRestored: draftRestored ?? this.draftRestored,
        draftLastSaved: draftLastSaved ?? this.draftLastSaved,
      );

  @override
  List<Object?> get props => [
        status,
        form,
        currentStep,
        submitAttempted,
        stepErrors,
        geoData,
        geoError,
        propertyTypes,
        documentOptions,
        feeStatus,
        admissionFee,
        quote,
        quoteStatus,
        submitStatus,
        successId,
        duplicateKind,
        duplicateMessage,
        submitErrors,
        fileError,
        draftRestored,
        draftLastSaved,
      ];
}
