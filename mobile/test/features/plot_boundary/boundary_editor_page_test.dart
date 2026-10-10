import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/plot_boundary/domain/geo.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_entities.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_repository.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/bloc/boundary_editor_bloc.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/pages/boundary_editor_page.dart';
import 'package:kaundia_app/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/blank_tile_provider.dart';

class _MockRepo extends Mock implements PlotBoundaryRepository {}

const _society = SocietyBbox(
  minLng: 90.30,
  minLat: 23.78,
  maxLng: 90.347,
  maxLat: 23.838,
);

// ~55 m triangle inside the society (≈ 15 shotangsho).
const _triangle = [
  LatLng(23.8090, 90.3230),
  LatLng(23.8095, 90.3230),
  LatLng(23.8090, 90.3236),
];

PlotBoundary _boundary({bool hasPending = false}) => PlotBoundary(
      id: 'b1',
      propertyId: 'p1',
      status:
          hasPending ? BoundaryStatus.pendingReview : BoundaryStatus.approved,
      points: _triangle,
      isMine: true,
      hasPending: hasPending,
    );

/// Taps the map and waits past the double-tap window, as a real user would.
Future<void> _tapMap(WidgetTester tester, Offset offset) async {
  await tester.tapAt(tester.getCenter(find.byType(FlutterMap)) + offset);
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late _MockRepo repo;

  setUpAll(() => registerFallbackValue(<LatLng>[]));

  setUp(() {
    repo = _MockRepo();
    when(repo.getMyProperties).thenAnswer((_) async => const [
          OwnProperty(
            propertyId: 'p1',
            rsDag: '120',
            csDag: '55',
            landQuantity: '3',
          ),
          OwnProperty(propertyId: 'p2', rsDag: '121', landQuantity: '40'),
        ]);
    when(repo.getMyBoundaries).thenAnswer((_) async => const []);
    when(() => repo.updateBoundary(
          id: any(named: 'id'),
          points: any(named: 'points'),
        )).thenAnswer((_) async => _boundary(hasPending: true));
  });

  Future<void> pump(
    WidgetTester tester, {
    PlotBoundary? editing,
    String? propertyId,
  }) async {
    tester.view.physicalSize = const Size(420, 900);
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
      home: BoundaryEditorPage(
        editing: editing,
        initialPropertyId: propertyId,
        tileProvider: BlankTileProvider(),
        createBloc: () => BoundaryEditorBloc(
          getMyProperties: GetMyProperties(repo),
          getMyBoundaries: GetMyBoundaries(repo),
          saveBoundary: SaveBoundary(repo),
          society: _society,
        ),
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('shows the disclaimer, picker and the drawing hint',
      (tester) async {
    await pump(tester);

    expect(find.textContaining('member-marked approximate'), findsOneWidget);
    expect(find.text('Your plot'), findsOneWidget);
    expect(find.textContaining('Tap the map to add points'), findsOneWidget);
    final submit = find.widgetWithText(FilledButton, 'Submit');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
  });

  testWidgets('tapping the map adds vertices until the outline is valid',
      (tester) async {
    await pump(tester);

    await _tapMap(tester, const Offset(-60, 60));
    await _tapMap(tester, const Offset(60, 60));
    expect(find.text('At least 3 points are required.'), findsOneWidget);

    await _tapMap(tester, const Offset(0, -60));

    expect(find.text('The outline looks valid.'), findsOneWidget);
    expect(find.textContaining('Points: 3'), findsOneWidget);
    final submit = find.widgetWithText(FilledButton, 'Submit');
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });

  testWidgets('warns (without blocking) when area differs from declared land',
      (tester) async {
    // Plot p1 declares 3 shotangsho; the ~120 px triangle is far larger.
    await pump(tester, propertyId: 'p1');

    await _tapMap(tester, const Offset(-90, 90));
    await _tapMap(tester, const Offset(90, 90));
    await _tapMap(tester, const Offset(0, -90));

    expect(
      find.text(
          'The drawn area differs a lot from your declared land quantity.'),
      findsOneWidget,
    );
    final submit = find.widgetWithText(FilledButton, 'Submit');
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });

  testWidgets('editing a pending boundary asks before replacing it',
      (tester) async {
    await pump(tester, editing: _boundary(hasPending: true));

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Replace pending submission?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.updateBoundary(
          id: any(named: 'id'),
          points: any(named: 'points'),
        ));

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    verify(() => repo.updateBoundary(id: 'b1', points: any(named: 'points')))
        .called(1);
  });

  testWidgets('editing an approved boundary saves without a confirmation',
      (tester) async {
    await pump(tester, editing: _boundary());

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pump();

    expect(find.text('Replace pending submission?'), findsNothing);
    verify(() => repo.updateBoundary(id: 'b1', points: any(named: 'points')))
        .called(1);
  });

  testWidgets('a load failure shows the error with retry', (tester) async {
    when(repo.getMyProperties).thenThrow(const FormatException('bad'));
    await pump(tester);

    expect(find.text('Could not save the boundary.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
