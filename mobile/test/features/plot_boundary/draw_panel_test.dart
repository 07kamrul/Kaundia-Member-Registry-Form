import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_entities.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_repository.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/bloc/my_boundaries_cubit.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/widgets/draw_panel_sheet.dart';
import 'package:kaundia_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements PlotBoundaryRepository {}

const _free = OwnProperty(propertyId: 'p2', rsDag: '20', csDag: '21');
const _used = OwnProperty(propertyId: 'p1', rsDag: '10');

PlotBoundary _boundary({
  required String id,
  required String propertyId,
  required BoundaryStatus status,
  bool hasPending = false,
  String? note,
}) =>
    PlotBoundary(
      id: id,
      propertyId: propertyId,
      status: status,
      points: const [],
      isMine: true,
      hasPending: hasPending,
      reviewNote: note,
      rsDag: '10',
    );

void main() {
  late _MockRepo repo;
  DrawPanelResult? result;

  setUp(() {
    repo = _MockRepo();
    result = null;
    when(repo.getMyProperties).thenAnswer((_) async => [_used, _free]);
    when(repo.getMyBoundaries).thenAnswer((_) async => [
          _boundary(
            id: 'b1',
            propertyId: 'p1',
            status: BoundaryStatus.pendingReview,
            hasPending: true,
          ),
        ]);
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await showDrawPanelSheet(
              context,
              createCubit: () => MyBoundariesCubit(
                getMyProperties: GetMyProperties(repo),
                getMyBoundaries: GetMyBoundaries(repo),
                withdrawBoundary: WithdrawBoundary(repo),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('offers only plots without a boundary and starts disabled',
      (tester) async {
    await open(tester);

    expect(find.text('Draw your plot boundary'), findsOneWidget);
    expect(find.textContaining('RS dag 20 / CS dag 21'), findsOneWidget);
    expect(find.textContaining('RS dag 10 /'), findsNothing);
    final start = find.widgetWithText(FilledButton, 'Draw on map');
    expect(tester.widget<FilledButton>(start).onPressed, isNull);
  });

  testWidgets('selecting a plot enables drawing and returns it',
      (tester) async {
    await open(tester);

    await tester.tap(find.textContaining('RS dag 20'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Draw on map'));
    await tester.pumpAndSettle();

    expect(result, isA<DrawNewBoundary>());
    expect((result! as DrawNewBoundary).propertyId, 'p2');
  });

  testWidgets('lists my boundaries with status, timeline and pending hint',
      (tester) async {
    await open(tester);

    expect(find.text('My boundaries'), findsOneWidget);
    expect(find.text('Waiting for approval'), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
    expect(find.text('Others will see this after the admin verifies it.'),
        findsOneWidget);
  });

  testWidgets('edit returns the boundary to the page', (tester) async {
    await open(tester);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(result, isA<EditBoundary>());
    expect((result! as EditBoundary).boundary.id, 'b1');
  });

  testWidgets('withdraw asks for confirmation before calling the API',
      (tester) async {
    when(() => repo.withdrawBoundary('b1')).thenAnswer((_) async {});
    await open(tester);

    await tester.tap(find.text('Withdraw submission'));
    await tester.pumpAndSettle();
    expect(find.text('Withdraw submission?'), findsOneWidget);
    verifyNever(() => repo.withdrawBoundary(any()));

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.withdrawBoundary(any()));

    await tester.tap(find.text('Withdraw submission'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Withdraw submission'),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => repo.withdrawBoundary('b1')).called(1);
  });

  testWidgets('a rejected boundary shows the admin note and no withdraw',
      (tester) async {
    when(repo.getMyBoundaries).thenAnswer((_) async => [
          _boundary(
            id: 'b1',
            propertyId: 'p1',
            status: BoundaryStatus.rejected,
            note: 'Overlaps the road',
          ),
        ]);
    await open(tester);

    expect(find.text("Admin's note: Overlaps the road"), findsOneWidget);
    expect(find.text('Withdraw submission'), findsNothing);
  });

  testWidgets('shows the empty-plots message when every plot has a boundary',
      (tester) async {
    when(repo.getMyProperties).thenAnswer((_) async => [_used]);
    await open(tester);

    expect(find.textContaining('None of your properties is available'),
        findsOneWidget);
    expect(find.text('Draw on map'), findsNothing);
  });

  testWidgets('a load failure shows an error with retry', (tester) async {
    when(repo.getMyProperties)
        .thenThrow(const ApiException(type: ApiExceptionType.network));
    await open(tester);

    expect(
        find.text('Could not load your plots and boundaries.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
