import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/plot_boundary/domain/geo.dart';
import 'package:kaundia_app/features/plot_boundary/domain/land_data_repository.dart';
import 'package:kaundia_app/features/plot_boundary/domain/land_entities.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_entities.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_repository.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/bloc/land_map_bloc.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/bloc/my_location_cubit.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/bloc/plot_map_bloc.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/pages/plot_map_page.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/widgets/map/map_disclaimer.dart';
import 'package:kaundia_app/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/blank_tile_provider.dart';

class _MockPlotRepo extends Mock implements PlotBoundaryRepository {}

class _MockLandRepo extends Mock implements LandDataRepository {}

// Square of ~220 m around the default map centre (23.809, 90.323).
const _around = [
  LatLng(23.808, 90.322),
  LatLng(23.808, 90.324),
  LatLng(23.810, 90.324),
  LatLng(23.810, 90.322),
];

const _bbox = SocietyBbox(
  minLng: 90.30,
  minLat: 23.78,
  maxLng: 90.347,
  maxLat: 23.838,
);

void main() {
  late _MockPlotRepo plotRepo;
  late _MockLandRepo landRepo;
  late int locateCalls;
  late LatLng? devicePosition;

  setUpAll(() {
    registerFallbackValue(_bbox);
    registerFallbackValue(LandLayer.bds);
  });

  setUp(() {
    MapDisclaimer.resetSession();
    plotRepo = _MockPlotRepo();
    landRepo = _MockLandRepo();
    locateCalls = 0;
    devicePosition = const LatLng(23.809, 90.323);
    when(() => plotRepo.getPlotMap(any())).thenAnswer((_) async => [
          const BoundaryFeature(
            boundaryId: 'b1',
            propertyId: 'p1',
            status: BoundaryStatus.approved,
            isMine: false,
            points: _around,
            rsDag: '4611',
          ),
        ]);
    when(() => plotRepo.getOwner('b1'))
        .thenAnswer((_) async => const BoundaryOwner(
              boundaryId: 'b1',
              ownerName: 'Rahim Uddin',
              contactHidden: true,
              status: BoundaryStatus.approved,
              rsDag: '4611',
            ));
    when(() => landRepo.plotsInBbox(any(), any())).thenAnswer(
      (_) async => LandCollection(plots: [
        LandPlot(dag: '88', sheet: '2', areaSqm: 5000, rings: const [_around]),
      ]),
    );
    when(() => landRepo.lookup(any(), any()))
        .thenAnswer((_) async => const LandCollection());
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    bool canDraw = true,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
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
      home: PlotMapPage(
        canDraw: canDraw,
        tileProvider: BlankTileProvider(),
        createBloc: () => PlotMapBloc(
          getPlotMap: GetPlotMap(plotRepo),
          getBoundaryOwner: GetBoundaryOwner(plotRepo),
          debounce: Duration.zero,
        ),
        createLandBloc: () =>
            LandMapBloc(repository: landRepo, debounce: Duration.zero),
        createLocationCubit: () => MyLocationCubit(
          society: _bbox,
          positionProvider: () async {
            locateCalls++;
            return devicePosition;
          },
        ),
      ),
    ));
    await _settle(tester);
  }

  testWidgets('boundaries mode: toolbar, legend, disclaimer and data load',
      (tester) async {
    await pumpPage(tester);

    expect(find.text('Search by dag number'), findsOneWidget);
    expect(find.text('My plot boundary map'), findsOneWidget);
    expect(find.text('Draw boundary'), findsNothing,
        reason: 'compact width collapses the draw button to an icon');
    expect(find.byTooltip('Draw boundary'), findsOneWidget);
    expect(find.text('Legend'), findsOneWidget);
    expect(find.textContaining('member-marked approximate'), findsOneWidget);
    verify(() => plotRepo.getPlotMap(any())).called(greaterThanOrEqualTo(1));
    verifyNever(() => landRepo.plotsInBbox(any(), any()));
  });

  testWidgets('draw button is hidden without the permission', (tester) async {
    await pumpPage(tester, canDraw: false);

    expect(find.byTooltip('Draw boundary'), findsNothing);
  });

  testWidgets('switching to BDS loads the official layer and adapts the UI',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('BDS dag map'));
    await _settle(tester);

    verify(() => landRepo.plotsInBbox(LandLayer.bds, any())).called(1);
    expect(find.text('Search by BDS dag number'), findsOneWidget);
    expect(find.text('Legend'), findsNothing);
    expect(find.byTooltip('Draw boundary'), findsNothing);
  });

  testWidgets('RAJUK mode uses the RS dag search hint', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('RAJUK masterplan (DAP)'));
    await _settle(tester);

    verify(() => landRepo.plotsInBbox(LandLayer.rajuk, any())).called(1);
    expect(find.text('Search by RS dag number'), findsOneWidget);
  });

  testWidgets('a dag with no match shows the not-found notice', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('BDS dag map'));
    await _settle(tester);

    await tester.enterText(find.byType(TextField), '999');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);

    verify(() => landRepo.lookup(LandLayer.bds, '999')).called(1);
    expect(find.text('No plot found with this dag number.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).first);
    await _settle(tester);
    expect(find.text('No plot found with this dag number.'), findsNothing);
  });

  testWidgets('a failing official layer offers a retry', (tester) async {
    when(() => landRepo.plotsInBbox(any(), any()))
        .thenThrow(const FormatException('bad'));
    await pumpPage(tester);

    await tester.tap(find.text('BDS dag map'));
    await _settle(tester);
    expect(
      find.text(
          'Could not load the official map data. Please try again later.'),
      findsOneWidget,
    );

    when(() => landRepo.plotsInBbox(any(), any())).thenAnswer(
      (_) async => LandCollection(plots: [
        LandPlot(dag: '1', rings: const [_around])
      ]),
    );
    await tester.tap(find.text('Retry'));
    await _settle(tester);

    expect(
      find.text(
          'Could not load the official map data. Please try again later.'),
      findsNothing,
    );
  });

  testWidgets('tapping a boundary opens the owner sheet', (tester) async {
    await pumpPage(tester);

    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await _settle(tester);

    verify(() => plotRepo.getOwner('b1')).called(1);
    expect(find.text('Rahim Uddin'), findsOneWidget);
    expect(find.text('Contact hidden'), findsOneWidget);
  });

  testWidgets('tapping a BDS plot opens the dag info card', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('BDS dag map'));
    await _settle(tester);

    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await _settle(tester);

    expect(find.text('Dag / plot information'), findsOneWidget);
    expect(find.text('88'), findsWidgets);
    expect(find.text('0.5000'), findsOneWidget);
  });

  testWidgets('locating outside the society shows the notice', (tester) async {
    devicePosition = const LatLng(24.5, 91.0);
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.my_location));
    await _settle(tester);

    expect(locateCalls, 1);
    expect(
      find.textContaining('outside the Uttar Kaundia area'),
      findsOneWidget,
    );
  });

  testWidgets('a denied location permission shows the location error',
      (tester) async {
    devicePosition = null;
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.my_location));
    await _settle(tester);

    expect(find.text('Could not determine your location.'), findsOneWidget);
  });

  testWidgets('the basemap button toggles satellite and street',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byTooltip('Satellite'));
    await _settle(tester);

    expect(find.byTooltip('Street'), findsOneWidget);
  });
}

/// Frames without `pumpAndSettle`: the map's tile layer never goes idle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}
