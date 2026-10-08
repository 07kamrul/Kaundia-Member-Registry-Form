import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/enums/enums.dart';
import '../../../../shared/utils/file_utils.dart';
import '../../data/config_list_repository.dart';
import '../../data/fee_repository.dart';
import '../../data/geo_repository.dart';
import '../../data/registration_draft_service.dart';
import '../../data/registration_repository.dart';
import '../../domain/registration_form.dart';
import '../../domain/registration_validators.dart';
import '../../domain/submission_error_mapper.dart';
import 'registration_event.dart';
import 'registration_state.dart';

const _autosaveDebounce = Duration(milliseconds: 400);
const _quoteDebounce = Duration(milliseconds: 400);
const maxNominees = 5;

/// Orchestrates the whole 6-step registration wizard: form state, step
/// navigation with per-step validation, debounced draft autosave, fee/quote
/// fetching and multipart submission.
class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationBloc({
    required RegistrationRepository registrationRepository,
    required FeeRepository feeRepository,
    required GeoRepository geoRepository,
    required ConfigListRepository configListRepository,
    required RegistrationDraftService draftService,
  })  : _registrationRepository = registrationRepository,
        _feeRepository = feeRepository,
        _geoRepository = geoRepository,
        _configListRepository = configListRepository,
        _draftService = draftService,
        super(const RegistrationState()) {
    on<RegistrationStarted>(_onStarted);
    on<RegistrationDraftDiscarded>(_onDraftDiscarded);
    on<RegistrationDraftBannerDismissed>(_onDraftBannerDismissed);
    on<MemberFieldChanged>(_onMemberField);
    on<MemberGenderSelected>(_onGender);
    on<MemberPhotoAttached>(_onPhotoAttached);
    on<MemberPhotoCleared>(_onPhotoCleared);
    on<AddressFieldChanged>(_onAddressField);
    on<SameAsCurrentToggled>(_onSameAsCurrent);
    on<PropertyCountChanged>(_onPropertyCount);
    on<PropertyFieldChanged>(_onPropertyField);
    on<PropertyTypeToggled>(_onPropertyTypeToggled);
    on<OwnershipSelected>(_onOwnership);
    on<JointOwnerCountChanged>(_onJointOwnerCount);
    on<DocToggled>(_onDocToggled);
    on<DocFileAttached>(_onDocFileAttached);
    on<DocFileRemoved>(_onDocFileRemoved);
    on<UrgentContactFieldChanged>(_onUrgentField);
    on<NomineeAdded>(_onNomineeAdded);
    on<NomineeRemoved>(_onNomineeRemoved);
    on<NomineeFieldChanged>(_onNomineeField);
    on<SameAsUrgentToggled>(_onSameAsUrgent);
    on<ReceiptNoChanged>(_onReceiptNo);
    on<ReceiptFileAttached>(_onReceiptFileAttached);
    on<ReceiptFileRemoved>(_onReceiptFileRemoved);
    on<PaymentMethodSelected>(_onPaymentMethod);
    on<FeeRetryRequested>(_onFeeRetry);
    on<SubscriptionRetryRequested>(_onSubscriptionRetry);
    on<SubmissionDateChanged>(_onSubmissionDate);
    on<DeclarationToggled>(_onDeclaration);
    on<SignatureSaved>(_onSignatureSaved);
    on<SignatureCleared>(_onSignatureCleared);
    on<StepGoToRequested>(_onStepGoTo);
    on<StepNextRequested>(_onStepNext);
    on<StepPrevRequested>(_onStepPrev);
    on<SubmitRequested>(_onSubmit);
    on<SubmitSuccessAcknowledged>(_onSubmitAcknowledged);
    on<QuoteRefreshRequested>(_onQuoteRefreshTick);
  }

  final RegistrationRepository _registrationRepository;
  final FeeRepository _feeRepository;
  final GeoRepository _geoRepository;
  final ConfigListRepository _configListRepository;
  final RegistrationDraftService _draftService;

  Timer? _autosaveTimer;
  Timer? _quoteTimer;

  // -- lifecycle ------------------------------------------------------------

  Future<void> _onStarted(RegistrationStarted e, Emitter<RegistrationState> emit) async {
    final today = DateTime.now();
    final submissionDate = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    var form = RegistrationForm(submissionDate: submissionDate);
    var currentStep = 1;
    var draftRestored = false;
    String? draftLastSaved;

    final draft = _draftService.peekDraft();
    if (draft != null) {
      form = _draftService.decodeForm(draft.formValue).copyWith(submissionDate: submissionDate);
      currentStep = draft.currentStep.clamp(1, wizardStepCount);
      draftRestored = true;
      draftLastSaved = draft.lastSaved;
    }

    emit(state.copyWith(
      status: RegistrationStatus.ready,
      form: form,
      currentStep: currentStep,
      draftRestored: draftRestored,
      draftLastSaved: draftLastSaved,
    ));

    await _loadFee(emit);
    await _loadConfigLists(emit);
    await _loadGeo(emit);
    if (form.totalShareQuantity > 0) {
      await _refreshQuote(emit, form.totalShareQuantity);
    }
  }

  Future<void> _loadFee(Emitter<RegistrationState> emit) async {
    emit(state.copyWith(feeStatus: FeeStatus.loading));
    try {
      final fee = await _feeRepository.getAdmissionFee();
      emit(state.copyWith(
        feeStatus: fee == null || fee <= 0 ? FeeStatus.error : FeeStatus.loaded,
        admissionFee: fee,
      ));
    } catch (_) {
      emit(state.copyWith(feeStatus: FeeStatus.error));
    }
  }

  Future<void> _loadConfigLists(Emitter<RegistrationState> emit) async {
    final types = await _configListRepository.getValues('property_type', defaultPropertyTypes);
    final docs = await _configListRepository.getValues('document_type', defaultDocumentOptions);
    emit(state.copyWith(propertyTypes: types, documentOptions: docs));
  }

  Future<void> _loadGeo(Emitter<RegistrationState> emit) async {
    try {
      final geo = await _geoRepository.load();
      emit(state.copyWith(geoData: geo, geoError: false));
    } catch (_) {
      emit(state.copyWith(geoError: true));
    }
  }

  Future<void> _onFeeRetry(FeeRetryRequested e, Emitter<RegistrationState> emit) => _loadFee(emit);

  Future<void> _onDraftDiscarded(RegistrationDraftDiscarded e, Emitter<RegistrationState> emit) async {
    await _draftService.clear();
    final today = DateTime.now();
    emit(state.copyWith(
      form: RegistrationForm(
        submissionDate: '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
      ),
      currentStep: 1,
      draftRestored: false,
      draftLastSaved: null,
      submitAttempted: false,
      stepErrors: const [],
    ));
  }

  void _onDraftBannerDismissed(RegistrationDraftBannerDismissed e, Emitter<RegistrationState> emit) {
    emit(state.copyWith(draftRestored: false));
  }

  // -- shared helpers -------------------------------------------------------

  void _scheduleAutosave(RegistrationState nextState) {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDebounce, () {
      _draftService.save(nextState.form, nextState.currentStep);
    });
  }

  /// Emits a form change, reschedules autosave, and (for property inputs)
  /// reschedules the debounced চাঁদা quote refresh.
  void _emitFormChange(
    Emitter<RegistrationState> emit,
    RegistrationForm form, {
    bool affectsQuote = false,
  }) {
    var next = state.copyWith(form: form, fileError: null, clearFileError: true);
    emit(next);
    _scheduleAutosave(next);
    if (affectsQuote) {
      _quoteTimer?.cancel();
      _quoteTimer = Timer(_quoteDebounce, () => add(const QuoteRefreshRequested()));
    }
  }

  Future<void> _onQuoteRefreshTick(QuoteRefreshRequested e, Emitter<RegistrationState> emit) async {
    await _refreshQuote(emit, state.form.totalShareQuantity);
  }

  Future<void> _refreshQuote(Emitter<RegistrationState> emit, double totalDecimal) async {
    if (totalDecimal <= 0) {
      emit(state.copyWith(quote: null, quoteStatus: QuoteStatus.idle));
      return;
    }
    emit(state.copyWith(quoteStatus: QuoteStatus.loading));
    try {
      final quote = await _feeRepository.getSubscriptionQuote(totalDecimal);
      emit(state.copyWith(quote: quote, quoteStatus: QuoteStatus.loaded));
    } catch (_) {
      emit(state.copyWith(quote: null, quoteStatus: QuoteStatus.error));
    }
  }

  Future<void> _onSubscriptionRetry(SubscriptionRetryRequested e, Emitter<RegistrationState> emit) async {
    emit(state.copyWith(quoteStatus: QuoteStatus.idle));
    await _refreshQuote(emit, state.form.totalShareQuantity);
  }

  // -- step 1 ---------------------------------------------------------------

  void _onMemberField(MemberFieldChanged e, Emitter<RegistrationState> emit) {
    final form = switch (e.field) {
      MemberField.fullName => state.form.copyWith(fullName: e.value),
      MemberField.fatherOrHusband => state.form.copyWith(fatherOrHusband: e.value),
      MemberField.mother => state.form.copyWith(mother: e.value),
      MemberField.dob => state.form.copyWith(dob: e.value),
      MemberField.nationality => state.form.copyWith(nationality: e.value),
      MemberField.occupation => state.form.copyWith(occupation: e.value),
      MemberField.nid => state.form.copyWith(nid: e.value),
      MemberField.mobile => state.form.copyWith(mobile: e.value),
      MemberField.email => state.form.copyWith(email: e.value),
    };
    _emitFormChange(emit, form);
  }

  void _onGender(MemberGenderSelected e, Emitter<RegistrationState> emit) =>
      _emitFormChange(emit, state.form.copyWith(gender: e.gender));

  Future<void> _onPhotoAttached(MemberPhotoAttached e, Emitter<RegistrationState> emit) async {
    try {
      final prepared = await prepareImage(e.path);
      if (prepared == null) {
        emit(state.copyWith(fileError: const FilePickError(kind: FileErrorKind.size)));
        return;
      }
      _emitFormChange(
        emit,
        state.form.copyWith(memberPhoto: FileRef(fileName: prepared.fileName, path: prepared.path)),
      );
    } catch (_) {
      emit(state.copyWith(fileError: const FilePickError(kind: FileErrorKind.size)));
    }
  }

  void _onPhotoCleared(MemberPhotoCleared e, Emitter<RegistrationState> emit) =>
      _emitFormChange(emit, state.form.copyWith(clearMemberPhoto: true));

  void _onAddressField(AddressFieldChanged e, Emitter<RegistrationState> emit) {
    if (e.isCurrent) {
      final a = state.form.currentAddress;
      _emitFormChange(emit, state.form.copyWith(currentAddress: _withField(a, e.field, e.value)));
    } else {
      final a = state.form.permanentAddress;
      _emitFormChange(emit, state.form.copyWith(permanentAddress: _withField(a, e.field, e.value)));
    }
  }

  AddressDetail _withField(AddressDetail a, AddressField field, String value) => switch (field) {
        AddressField.division => a.copyWith(division: value),
        AddressField.district => a.copyWith(district: value),
        AddressField.upazila => a.copyWith(upazila: value),
        AddressField.postOffice => a.copyWith(postOffice: value),
        AddressField.road => a.copyWith(road: value),
        AddressField.house => a.copyWith(house: value),
      };

  void _onSameAsCurrent(SameAsCurrentToggled e, Emitter<RegistrationState> emit) {
    var form = state.form.copyWith(sameAsCurrentAddress: e.value);
    if (e.value) {
      form = form.copyWith(permanentAddress: form.currentAddress);
    }
    _emitFormChange(emit, form);
  }

  // -- step 2 ---------------------------------------------------------------

  List<PropertyItem> _updatedProperties(int index, PropertyItem Function(PropertyItem) update) {
    final props = List<PropertyItem>.of(state.form.properties);
    if (index < 0 || index >= props.length) return props;
    props[index] = update(props[index]);
    return props;
  }

  void _onPropertyCount(PropertyCountChanged e, Emitter<RegistrationState> emit) {
    var props = List<PropertyItem>.of(state.form.properties);
    while (props.length < e.count) {
      props = [...props, const PropertyItem()];
    }
    while (props.length > e.count) {
      props = props.sublist(0, e.count);
    }
    _emitFormChange(
      emit,
      state.form.copyWith(propertyCount: e.count, properties: props),
      affectsQuote: true,
    );
  }

  void _onPropertyField(PropertyFieldChanged e, Emitter<RegistrationState> emit) {
    final props = _updatedProperties(e.index, (p) => switch (e.field) {
          PropertyField.propertyTypeOther => p.copyWith(propertyTypeOther: e.value),
          PropertyField.khatianNo => p.copyWith(khatianNo: e.value),
          PropertyField.dagNoCs => p.copyWith(dagNoCs: e.value),
          PropertyField.dagNoRs => p.copyWith(dagNoRs: e.value),
          PropertyField.holdingNumber => p.copyWith(holdingNumber: e.value),
          PropertyField.landQuantity => p.copyWith(landQuantity: e.value),
          PropertyField.myShareQuantity => p.copyWith(myShareQuantity: e.value),
        });
    _emitFormChange(emit, state.form.copyWith(properties: props), affectsQuote: true);
  }

  void _onPropertyTypeToggled(PropertyTypeToggled e, Emitter<RegistrationState> emit) {
    final props = _updatedProperties(e.index, (p) {
      final next = p.propertyType.contains(e.type)
          ? p.propertyType.where((t) => t != e.type).toList()
          : [...p.propertyType, e.type];
      return p.copyWith(propertyType: next);
    });
    _emitFormChange(emit, state.form.copyWith(properties: props));
  }

  void _onOwnership(OwnershipSelected e, Emitter<RegistrationState> emit) {
    final props = _updatedProperties(e.index, (p) => p.copyWith(
          ownership: e.ownership,
          clearJointOwnerCount: e.ownership != OwnershipType.joint,
          jointOwnerCount: e.ownership == OwnershipType.joint ? p.jointOwnerCount : null,
        ));
    _emitFormChange(emit, state.form.copyWith(properties: props));
  }

  void _onJointOwnerCount(JointOwnerCountChanged e, Emitter<RegistrationState> emit) {
    final props = _updatedProperties(e.index, (p) => p.copyWith(
          jointOwnerCount: e.count,
          clearJointOwnerCount: e.count == null,
        ));
    _emitFormChange(emit, state.form.copyWith(properties: props));
  }

  void _onDocToggled(DocToggled e, Emitter<RegistrationState> emit) {
    final props = _updatedProperties(e.propertyIndex, (p) {
      final exists = p.applicableDocs.any((d) => d.type == e.docType);
      final docs = exists
          ? p.applicableDocs.where((d) => d.type != e.docType).toList()
          : [...p.applicableDocs, ApplicableDoc(type: e.docType)];
      return p.copyWith(applicableDocs: docs);
    });
    _emitFormChange(emit, state.form.copyWith(properties: props));
  }

  Future<void> _onDocFileAttached(DocFileAttached e, Emitter<RegistrationState> emit) async {
    final error = await _validateDocFile(e.path);
    if (error != null) {
      emit(state.copyWith(fileError: FilePickError(kind: error, propertyIndex: e.propertyIndex, docType: e.docType)));
      return;
    }
    final props = _updatedProperties(e.propertyIndex, (p) {
      final docs = [
        for (final d in p.applicableDocs)
          if (d.type == e.docType) d.copyWith(fileName: e.fileName, path: e.path) else d,
      ];
      return p.copyWith(applicableDocs: docs);
    });
    _emitFormChange(emit, state.form.copyWith(properties: props));
  }

  void _onDocFileRemoved(DocFileRemoved e, Emitter<RegistrationState> emit) {
    final props = _updatedProperties(e.propertyIndex, (p) {
      final docs = [
        for (final d in p.applicableDocs)
          if (d.type == e.docType) d.copyWith(fileName: '', clearFile: true) else d,
      ];
      return p.copyWith(applicableDocs: docs);
    });
    _emitFormChange(emit, state.form.copyWith(properties: props));
  }

  // -- step 3 ---------------------------------------------------------------

  void _onUrgentField(UrgentContactFieldChanged e, Emitter<RegistrationState> emit) {
    final form = switch (e.field) {
      UrgentField.name => state.form.copyWith(urgentContactName: e.value),
      UrgentField.relation => state.form.copyWith(urgentContactRelation: e.value),
      UrgentField.mobile => state.form.copyWith(urgentContactMobile: e.value),
      UrgentField.address => state.form.copyWith(urgentContactAddress: e.value),
    };
    _emitFormChange(emit, form);
  }

  void _onNomineeAdded(NomineeAdded e, Emitter<RegistrationState> emit) {
    if (state.form.nominees.length >= maxNominees) return;
    _emitFormChange(emit, state.form.copyWith(nominees: [...state.form.nominees, const Nominee()]));
  }

  void _onNomineeRemoved(NomineeRemoved e, Emitter<RegistrationState> emit) {
    if (state.form.nominees.length <= 1) return;
    final nominees = List<Nominee>.of(state.form.nominees)..removeAt(e.index);
    _emitFormChange(emit, state.form.copyWith(nominees: nominees));
  }

  void _onNomineeField(NomineeFieldChanged e, Emitter<RegistrationState> emit) {
    final nominees = List<Nominee>.of(state.form.nominees);
    if (e.index < 0 || e.index >= nominees.length) return;
    nominees[e.index] = switch (e.field) {
      NomineeField.name => nominees[e.index].copyWith(name: e.value),
      NomineeField.relation => nominees[e.index].copyWith(relation: e.value),
      NomineeField.mobile => nominees[e.index].copyWith(mobile: e.value),
      NomineeField.address => nominees[e.index].copyWith(address: e.value),
    };
    _emitFormChange(emit, state.form.copyWith(nominees: nominees));
  }

  void _onSameAsUrgent(SameAsUrgentToggled e, Emitter<RegistrationState> emit) {
    if (!e.value) return;
    final f = state.form;
    if (f.nominees.isEmpty) return;
    final nominees = List<Nominee>.of(f.nominees);
    nominees[0] = nominees[0].copyWith(
      name: f.urgentContactName,
      relation: f.urgentContactRelation,
      mobile: f.urgentContactMobile,
      address: f.urgentContactAddress,
    );
    _emitFormChange(emit, f.copyWith(nominees: nominees));
  }

  // -- step 4 ---------------------------------------------------------------

  void _onReceiptNo(ReceiptNoChanged e, Emitter<RegistrationState> emit) =>
      _emitFormChange(emit, state.form.copyWith(receiptNo: e.value));

  Future<void> _onReceiptFileAttached(ReceiptFileAttached e, Emitter<RegistrationState> emit) async {
    final error = await _validateDocFile(e.path);
    if (error != null) {
      emit(state.copyWith(fileError: FilePickError(kind: error, isReceipt: true)));
      return;
    }
    _emitFormChange(emit, state.form.copyWith(receiptFile: FileRef(fileName: e.fileName, path: e.path)));
  }

  void _onReceiptFileRemoved(ReceiptFileRemoved e, Emitter<RegistrationState> emit) =>
      _emitFormChange(emit, state.form.copyWith(clearReceiptFile: true));

  void _onPaymentMethod(PaymentMethodSelected e, Emitter<RegistrationState> emit) =>
      _emitFormChange(emit, state.form.copyWith(paymentMethod: e.method));

  // -- step 5 ---------------------------------------------------------------

  void _onSubmissionDate(SubmissionDateChanged e, Emitter<RegistrationState> emit) =>
      _emitFormChange(emit, state.form.copyWith(submissionDate: e.value));

  void _onDeclaration(DeclarationToggled e, Emitter<RegistrationState> emit) =>
      _emitFormChange(emit, state.form.copyWith(declarationAccepted: e.value));

  Future<void> _onSignatureSaved(SignatureSaved e, Emitter<RegistrationState> emit) async {
    try {
      final bytes = await File(e.filePath).readAsBytes();
      final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
      _emitFormChange(emit, state.form.copyWith(memberSignature: dataUrl));
    } catch (_) {
      // Signature stays unset; the pad can be redrawn.
    }
  }

  void _onSignatureCleared(SignatureCleared e, Emitter<RegistrationState> emit) =>
      _emitFormChange(emit, state.form.copyWith(memberSignature: ''));

  // -- navigation -----------------------------------------------------------

  void _onStepGoTo(StepGoToRequested e, Emitter<RegistrationState> emit) =>
      _goToStep(e.step, emit);

  void _onStepNext(StepNextRequested e, Emitter<RegistrationState> emit) =>
      _goToStep(state.currentStep + 1, emit);

  void _onStepPrev(StepPrevRequested e, Emitter<RegistrationState> emit) {
    if (state.currentStep > 1) _goToStep(state.currentStep - 1, emit, validate: false);
  }

  void _goToStep(int target, Emitter<RegistrationState> emit, {bool validate = true}) {
    if (target < 1 || target > wizardStepCount) return;
    if (validate && target > state.currentStep) {
      for (var s = state.currentStep; s < target; s++) {
        final errors = validateStep(s, state.form);
        if (errors.isNotEmpty) {
          // Stay on the offending step and surface the messages (mirrors the
          // Angular goToStep early return).
          emit(state.copyWith(
            stepErrors: errors,
            submitAttempted: true,
            currentStep: s,
            submitErrors: const [],
          ));
          _scheduleAutosave(state.copyWith(currentStep: s));
          return;
        }
      }
    }
    final next = state.copyWith(
      currentStep: target,
      stepErrors: const [],
      submitErrors: const [],
    );
    emit(next);
    _draftService.save(next.form, next.currentStep);
  }

  // -- submit ---------------------------------------------------------------

  Future<void> _onSubmit(SubmitRequested e, Emitter<RegistrationState> emit) async {
    final f = state.form;
    final clientErrors = [
      ...validateAllSteps(f, hasAdmissionFee: state.hasAdmissionFee, hasSubscription: state.hasSubscription),
    ];
    if (clientErrors.isNotEmpty) {
      final invalid = firstInvalidStep(f) ?? 1;
      emit(state.copyWith(
        stepErrors: clientErrors,
        submitAttempted: true,
        currentStep: invalid,
        submitStatus: SubmitStatus.idle,
      ));
      return;
    }

    emit(state.copyWith(submitStatus: SubmitStatus.submitting, stepErrors: const [], submitErrors: const []));

    try {
      final result = await _registrationRepository.submit(
        f,
        admissionFee: state.admissionFee?.toString() ?? '',
        subscription: state.hasSubscription ? _formatAmount(state.quote!.total) : '',
      );
      emit(state.copyWith(
        submitStatus: SubmitStatus.success,
        successId: result.id,
        draftRestored: false,
      ));
    } on DuplicateSubmissionException catch (dup) {
      emit(state.copyWith(
        submitStatus: SubmitStatus.duplicate,
        duplicateKind: dup.kind,
        duplicateMessage: dup.message,
      ));
    } on ApiException catch (apiError) {
      final mapped = mapSubmissionError(apiError);
      var next = state.copyWith(
        submitStatus: SubmitStatus.failure,
        submitErrors: mapped.items,
      );
      emit(next);
      if (mapped.step != null) {
        emit(next.copyWith(currentStep: mapped.step, stepErrors: const []));
        _draftService.save(next.form, mapped.step!);
      }
    } catch (_) {
      emit(state.copyWith(
        submitStatus: SubmitStatus.failure,
        submitErrors: [SubmitErrorItem.plain(SubmitErrorKind.generic, status: 0)],
      ));
    }
  }

  String _formatAmount(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();

  Future<void> _onSubmitAcknowledged(SubmitSuccessAcknowledged e, Emitter<RegistrationState> emit) async {
    // Draft is cleared only after a confirmed 201 submission.
    await _draftService.clear();
  }

  /// JPG/PNG/PDF ≤5MB guard mirroring the Angular doc checks.
  Future<FileErrorKind?> _validateDocFile(String path) async {
    final mime = lookupMimeType(path) ?? 'application/octet-stream';
    if (!isAllowedDocType(mime)) return FileErrorKind.type;
    try {
      final f = await prepareAnyFile(path, path.split(Platform.pathSeparator).last.split('/').last);
      if (!f.withinLimit) return FileErrorKind.size;
    } on FileTooLargeError {
      return FileErrorKind.size;
    }
    return null;
  }

  @override
  Future<void> close() {
    _autosaveTimer?.cancel();
    _quoteTimer?.cancel();
    return super.close();
  }
}
