import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kaundia_app/core/auth/auth_repository.dart';
import 'package:kaundia_app/core/di/injector.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/auth/bloc/auth_bloc.dart';
import 'package:kaundia_app/features/auth/pages/login_page.dart';
import 'package:kaundia_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;

  setUpAll(() {
    // AuthBloc's login handler touches sl<SessionManager>() on success only;
    // register it so GetIt does not throw if a success path ever runs.
    final sl = GetIt.instance;
    if (!sl.isRegistered<SessionManager>()) {
      sl.registerLazySingleton<SessionManager>(() => SessionManager());
    }
  });

  setUp(() {
    repo = _MockAuthRepository();
  });

  Widget harness() {
    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(repository: repo),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoginPage(),
      ),
    );
  }

  testWidgets('shows the business error message on AuthFailure',
      (tester) async {
    when(() => repo.login(any(), any())).thenThrow(
      const ApiException(
        type: ApiExceptionType.business,
        statusCode: 400,
        businessMessage: 'Account is locked',
      ),
    );

    await tester.pumpWidget(harness());

    await tester.enterText(find.byType(TextField).at(0), 'member01');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.tap(find.text('Enter'));
    await tester.pumpAndSettle();

    expect(find.text('Account is locked'), findsOneWidget);
    verify(() => repo.login('member01', 'secret123')).called(1);
  });

  testWidgets('shows the generic login failed message on 401',
      (tester) async {
    when(() => repo.login(any(), any())).thenThrow(
      const ApiException(type: ApiExceptionType.unauthorized, statusCode: 401),
    );

    await tester.pumpWidget(harness());

    await tester.enterText(find.byType(TextField).at(0), 'member01');
    await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
    await tester.tap(find.text('Enter'));
    await tester.pumpAndSettle();

    expect(find.text('Login failed. Information is incorrect.'),
        findsOneWidget);
  });

  testWidgets('shows required-field errors without calling the repository',
      (tester) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.text('Enter'));
    await tester.pump();

    expect(find.text('Username / email / member ID is required'),
        findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    verifyNever(() => repo.login(any(), any()));
  });
}
