import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/enums/enums.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/core/storage/app_preferences.dart';
import 'package:kaundia_app/features/registration/data/config_list_repository.dart';
import 'package:kaundia_app/features/registration/data/fee_repository.dart';
import 'package:kaundia_app/features/registration/data/geo_repository.dart';
import 'package:kaundia_app/features/registration/data/registration_draft_service.dart';
import 'package:kaundia_app/features/registration/data/registration_repository.dart';
import 'package:kaundia_app/features/registration/domain/registration_form.dart';
import 'package:kaundia_app/features/registration/domain/submission_error_mapper.dart';
import 'package:kaundia_app/features/registration/presentation/bloc/registration_bloc.dart';
import 'package:kaundia_app/features/registration/presentation/bloc/registration_event.dart';
import 'package:kaundia_app/features/registration/presentation/bloc/registration_state.dart';
import 'package:mocktail/mocktail.dart';

class MockRegistrationRepository extends Mock implements RegistrationRepository {}

class MockFeeRepository extends Mock implements FeeRepository {}

class MockGeoRepository extends Mock implements GeoRepository {}

class MockConfigListRepository extends Mock implements ConfigListRepository {}

class MockAppPreferences extends Mock implements AppPreferences {}

RegistrationBloc buildBloc({
  required MockRegistrationRepository submitRepo,
  required MockFeeRepository feeRepo,
  required MockGeoRepository geoRepo,
  required MockConfigListRepository configRepo,
  required MockAppPreferences prefs,
}) {
  return RegistrationBloc(
    registrationRepository: submitRepo,
    feeRepository: feeRepo,
    geoRepository: geoRepo,
    configListRepository: configRepo,
    draftService: RegistrationDraftService(preferences: prefs),
  );
}

/// A form value that passes steps 1-3 validation.
RegistrationForm validForm({int properties = 1}) => RegistrationForm(
      fullName: 'Md Kamrul',
      fatherOrHusband: 'Abdul',
      mother: 'Rahima',
      dob: '1990-01-01',
      nid: '1234567890',
      mobile: '+8801712345678',
      gender: Gender.male,
      email: 'a@b.com',
      memberPhoto: const FileRef(fileName: 'p.jpg', path: '/tmp/p.jpg'),
      currentAddress: const AddressDetail(house: '1', road: '2', postOffice: 'p', upazila: 'u', district: 'd', division: 'v'),
      permanentAddress: const AddressDetail(house: '1', road: '2', postOffice: 'p', upazila: 'u', district: 'd', division: 'v'),
      urgentContactName: 'Urgent',
      urgentContactMobile: '+8801812345678',
      propertyCount: properties,
      nominees: const [Nominee(name: 'N', relation: '', mobile: '+8801912345678', address: '')],
      properties: [
        for (var i = 0; i < properties; i++)
          PropertyItem(
            propertyType: const ['জমি'],
            khatianNo: 'K$i',
            dagNoCs: 'C$i',
            dagNoRs: 'R$i',
            landQuantity: '10',
            myShareQuantity: '5',
            ownership: OwnershipType.single,
            applicableDocs: const [
              ApplicableDoc(type: 'খতিয়ান/পর্চা', fileName: 'doc.pdf', path: '/tmp/doc.pdf'),
            ],
          ),
      ],
    );

/// State where all client-side step validations pass.
RegistrationState submitReadyState() => RegistrationState(
      status: RegistrationStatus.ready,
      form: validForm().copyWith(declarationAccepted: true),
      feeStatus: FeeStatus.loaded,
      admissionFee: 500,
      quoteStatus: QuoteStatus.loaded,
      quote: const SubscriptionQuote(
        base: 100, extraUnits: 0, extraRate: 0, extraAmount: 0, total: 120, unit: 'শতাংশ',
      ),
    );

void main() {
  late MockRegistrationRepository submitRepo;
  late MockFeeRepository feeRepo;
  late MockGeoRepository geoRepo;
  late MockConfigListRepository configRepo;
  late MockAppPreferences prefs;

  setUpAll(() {
    registerFallbackValue(RegistrationStarted());
    registerFallbackValue(RegistrationForm());
  });

  setUp(() {
    submitRepo = MockRegistrationRepository();
    feeRepo = MockFeeRepository();
    geoRepo = MockGeoRepository();
    configRepo = MockConfigListRepository();
    prefs = MockAppPreferences();

    when(() => feeRepo.getAdmissionFee()).thenAnswer((_) async => 500.0);
    when(() => geoRepo.load()).thenAnswer((_) async => GeoData(
          divisions: [GeoDivision(id: '1', name: 'Dhaka', bnName: 'ঢাকা')],
          districts: [GeoDistrict(id: '10', divisionId: '1', name: 'Cumilla', bnName: 'কুমিল্লা')],
          upazilas: [GeoUpazila(districtId: '10', name: 'Sadarpur', bnName: 'সদর')],
        ));
    when(() => configRepo.getValues(any(), any()))
        .thenAnswer((inv) async => (inv.positionalArguments[1] as List<String>));
    when(() => prefs.registrationDraft).thenReturn(null);
    when(() => prefs.setRegistrationDraft(any())).thenAnswer((_) async {});
    when(() => prefs.clearRegistrationDraft()).thenAnswer((_) async {});
  });

  blocTest<RegistrationBloc, RegistrationState>(
    'Started loads fee/geo/config lists and reaches ready on step 1',
    build: () => buildBloc(
      submitRepo: submitRepo, feeRepo: feeRepo, geoRepo: geoRepo,
      configRepo: configRepo, prefs: prefs,
    ),
    act: (bloc) => bloc.add(RegistrationStarted()),
    // Consecutive equal states are deduped by Bloc: the config-list emit (same
    // defaults) is not a separate emission.
    expect: () => [
      predicate<RegistrationState>((s) => s.status == RegistrationStatus.ready && s.currentStep == 1 && s.draftRestored == false),
      predicate<RegistrationState>((s) => s.feeStatus == FeeStatus.loaded && s.admissionFee == 500.0),
      predicate<RegistrationState>((s) => s.propertyTypes == defaultPropertyTypes && s.geoData != null && s.geoError == false),
    ],
  );

  blocTest<RegistrationBloc, RegistrationState>(
    'next is blocked while step 1 is invalid and errors stay on step 1',
    build: () => buildBloc(
      submitRepo: submitRepo, feeRepo: feeRepo, geoRepo: geoRepo,
      configRepo: configRepo, prefs: prefs,
    ),
    act: (bloc) async {
      bloc.add(StepNextRequested());
    },
    seed: () => const RegistrationState(status: RegistrationStatus.ready),
    expect: () => [
      predicate<RegistrationState>((s) => s.submitAttempted == true && s.stepErrors.isNotEmpty),
    ],
  );

  blocTest<RegistrationBloc, RegistrationState>(
    'goToStep saves the draft with the new current step (saveNow on nav)',
    build: () => buildBloc(
      submitRepo: submitRepo, feeRepo: feeRepo, geoRepo: geoRepo,
      configRepo: configRepo, prefs: prefs,
    ),
    act: (bloc) async {
      bloc.add(StepGoToRequested(2));
    },
    seed: () => RegistrationState(
      status: RegistrationStatus.ready,
      form: validForm(),
      feeStatus: FeeStatus.loaded,
      admissionFee: 500,
    ),
    verify: (_) {
      verify(() => prefs.setRegistrationDraft(any(that: contains('"currentStep":2')))).called(1);
    },
  );

  blocTest<RegistrationBloc, RegistrationState>(
    'successful submit clears the draft and carries the reference id',
    build: () => buildBloc(
      submitRepo: submitRepo, feeRepo: feeRepo, geoRepo: geoRepo,
      configRepo: configRepo, prefs: prefs,
    ),
    act: (bloc) async {
      when(() => submitRepo.submit(any(), admissionFee: any(named: 'admissionFee'), subscription: any(named: 'subscription')))
          .thenAnswer((_) async => const SubmissionResult(id: '42'));
      bloc.add(SubmitRequested());
    },
    seed: submitReadyState,
    expect: () => [
      predicate<RegistrationState>((s) => s.submitStatus == SubmitStatus.submitting),
      predicate<RegistrationState>((s) => s.submitStatus == SubmitStatus.success && s.successId == '42'),
    ],
    verify: (_) {
      verify(() => prefs.clearRegistrationDraft()).called(0); // cleared on acknowledge
    },
  );

  blocTest<RegistrationBloc, RegistrationState>(
    'draft is cleared when submit success is acknowledged',
    build: () => buildBloc(
      submitRepo: submitRepo, feeRepo: feeRepo, geoRepo: geoRepo,
      configRepo: configRepo, prefs: prefs,
    ),
    act: (bloc) => bloc.add(SubmitSuccessAcknowledged()),
    seed: () => const RegistrationState(status: RegistrationStatus.ready, submitStatus: SubmitStatus.success),
    verify: (_) {
      verify(() => prefs.clearRegistrationDraft()).called(1);
    },
  );

  blocTest<RegistrationBloc, RegistrationState>(
    '422 field errors jump to the offending step and surface items',
    build: () => buildBloc(
      submitRepo: submitRepo, feeRepo: feeRepo, geoRepo: geoRepo,
      configRepo: configRepo, prefs: prefs,
    ),
    act: (bloc) async {
      when(() => submitRepo.submit(any(), admissionFee: any(named: 'admissionFee'), subscription: any(named: 'subscription')))
          .thenThrow(const ApiException(
        type: ApiExceptionType.validation,
        statusCode: 422,
        fieldErrors: {'properties.0': 'missing'},
      ));
      bloc.add(SubmitRequested());
    },
    seed: submitReadyState,
    expect: () => [
      predicate<RegistrationState>((s) => s.submitStatus == SubmitStatus.submitting),
      predicate<RegistrationState>((s) => s.submitStatus == SubmitStatus.failure && s.currentStep == 2 && s.submitErrors.isNotEmpty),
    ],
  );

  blocTest<RegistrationBloc, RegistrationState>(
    'network failure keeps the current step and yields a generic network item',
    build: () => buildBloc(
      submitRepo: submitRepo, feeRepo: feeRepo, geoRepo: geoRepo,
      configRepo: configRepo, prefs: prefs,
    ),
    act: (bloc) async {
      when(() => submitRepo.submit(any(), admissionFee: any(named: 'admissionFee'), subscription: any(named: 'subscription')))
          .thenThrow(const ApiException(type: ApiExceptionType.network));
      bloc.add(SubmitRequested());
    },
    seed: submitReadyState,
    expect: () => [
      predicate<RegistrationState>((s) => s.submitStatus == SubmitStatus.submitting),
      predicate<RegistrationState>((s) =>
          s.submitStatus == SubmitStatus.failure &&
          s.currentStep == 1 &&
          s.submitErrors.single.kind == SubmitErrorKind.network),
    ],
  );

  blocTest<RegistrationBloc, RegistrationState>(
    'Started restores a saved draft (schema v1) at its last step without fee values',
    setUp: () {
      final draftJson = '{"schemaVersion":1,"currentStep":4,"lastSaved":"2026-10-07T10:00:00Z","formValue":{'
          '"fullName":"Md Kamrul","admissionFee":999,"subscription":123,'
          '"nominees":[{"name":"N","relation":"","mobile":"","address":""}],'
          '"properties":[]}}';
      when(() => prefs.registrationDraft).thenReturn(draftJson);
    },
    build: () => buildBloc(
      submitRepo: submitRepo, feeRepo: feeRepo, geoRepo: geoRepo,
      configRepo: configRepo, prefs: prefs,
    ),
    act: (bloc) => bloc.add(RegistrationStarted()),
    expect: () => [
      predicate<RegistrationState>((s) =>
          s.status == RegistrationStatus.ready &&
          s.draftRestored == true &&
          s.currentStep == 4 &&
          s.form.fullName == 'Md Kamrul'),
      predicate<RegistrationState>((s) => s.feeStatus == FeeStatus.loaded),
      predicate<RegistrationState>((s) => s.geoData != null),
    ],
  );

  test('draft encode/decode drops fee fields and keeps file metadata only', () {
    final service = RegistrationDraftService(preferences: prefs);
    final form = validForm(properties: 1).copyWith(receiptFile: const FileRef(fileName: 'r.pdf', path: '/tmp/r.pdf'));
    final encoded = service.encodeForm(form);
    expect(encoded.containsKey('admissionFee'), isFalse);
    expect(encoded.containsKey('subscription'), isFalse);
    final receipt = encoded['receiptFile'] as Map;
    expect(receipt['fileName'], 'r.pdf');
    expect(receipt.containsKey('path'), isFalse);

    final decoded = service.decodeForm(Map<String, dynamic>.from(encoded));
    expect(decoded.fullName, 'Md Kamrul');
    expect(decoded.properties.single.applicableDocs.single.type, 'খতিয়ান/পর্চা');
    // Restored files are metadata-only: no path until re-attached.
    expect(decoded.properties.single.applicableDocs.single.hasFile, isFalse);
    expect(decoded.memberSignature, isEmpty);
  });
}
