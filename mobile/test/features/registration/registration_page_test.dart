import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/registration/data/fee_repository.dart';
import 'package:kaundia_app/features/registration/data/registration_draft_service.dart';
import 'package:kaundia_app/features/registration/presentation/bloc/registration_bloc.dart';
import 'package:kaundia_app/features/registration/presentation/bloc/registration_event.dart';
import 'package:kaundia_app/features/registration/presentation/bloc/registration_state.dart';
import 'package:kaundia_app/features/registration/presentation/widgets/payment_step.dart';
import 'package:kaundia_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import 'registration_bloc_test.dart';

void main() {
  late MockFeeRepository feeRepo;

  setUpAll(() {
    registerFallbackValue(FeeRetryRequested());
  });

  setUp(() {
    feeRepo = MockFeeRepository();
  });

  Widget host(RegistrationState state) {
    final bloc = RegistrationBloc(
      registrationRepository: MockRegistrationRepository(),
      feeRepository: feeRepo,
      geoRepository: MockGeoRepository(),
      configListRepository: MockConfigListRepository(),
      draftService: RegistrationDraftService(preferences: MockAppPreferences()),
    );
    bloc.emit(state);
    return MultiBlocProvider(
      providers: [BlocProvider<RegistrationBloc>.value(value: bloc)],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: SingleChildScrollView(child: PaymentStep()),
          ),
        ),
      ),
    );
  }

  testWidgets('payment step shows the admission fee read-only from the live fee setting',
      (tester) async {
    await tester.pumpWidget(host(const RegistrationState(
      status: RegistrationStatus.ready,
      feeStatus: FeeStatus.loaded,
      admissionFee: 500.0,
    )));
    await tester.pump();

    final field = find.byKey(const Key('admissionFeeField'));
    expect(field, findsOneWidget);
    final textField = tester.widget<TextField>(
      find.descendant(of: field, matching: find.byType(TextField)),
    );
    // Read-only AND populated from the live setting.
    expect(textField.readOnly, isTrue);
    expect(textField.controller!.text, '500');
  });

  testWidgets('fee is never restored from a draft: the field renders only the '
      'live setting, and a restored-looking form carries no fee value', (tester) async {
    // The form value below pretends it came from a draft that (incorrectly)
    // carried a fee; the payment step must not read any fee from the form.
    await tester.pumpWidget(host(const RegistrationState(
      status: RegistrationStatus.ready,
      feeStatus: FeeStatus.loaded,
      admissionFee: 500.0,
    )));
    await tester.pump();

    final feeField = find.byKey(const Key('admissionFeeField'));
    final subscriptionField = find.byKey(const Key('subscriptionField'));
    for (final field in [feeField, subscriptionField]) {
      final textField = tester.widget<TextField>(
        find.descendant(of: field, matching: find.byType(TextField)),
      );
      expect(textField.readOnly, isTrue);
    }
    // Subscription has no quote yet — stays empty (never a draft value).
    final sub = tester.widget<TextField>(
      find.descendant(of: subscriptionField, matching: find.byType(TextField)),
    );
    expect(sub.controller!.text, isEmpty);
  });
}
