import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/plot_boundary/domain/land_entities.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_entities.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/widgets/boundary_timeline.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/widgets/land_info_sheet.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/widgets/map/map_disclaimer.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/widgets/map/map_legend.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/widgets/map/map_mode_tabs.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/widgets/map/map_top_bar.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/widgets/report_sheet.dart';
import 'package:kaundia_app/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

Widget _harness(Widget child, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

LandPlot _plot({String? dag, String? rs, double? area, String? sheet}) =>
    LandPlot(
      dag: dag,
      rsPlotNo: rs,
      areaSqm: area,
      sheet: sheet,
      rings: const [
        [
          LatLng(23.80, 90.30),
          LatLng(23.80, 90.31),
          LatLng(23.82, 90.31),
          LatLng(23.82, 90.30),
        ],
      ],
    );

PlotBoundary _boundary({
  BoundaryStatus status = BoundaryStatus.pendingReview,
  BoundaryStatus? live,
}) =>
    PlotBoundary(
      id: 'b1',
      propertyId: 'p1',
      status: status,
      points: const [],
      isMine: true,
      liveStatus: live,
    );

void main() {
  setUp(MapDisclaimer.resetSession);

  group('MapModeTabs', () {
    testWidgets('lists the three views and reports taps', (tester) async {
      final taps = <MapMode>[];
      await tester.pumpWidget(_harness(
        MapModeTabs(mode: MapMode.boundaries, onChanged: taps.add),
      ));

      expect(find.text('My plot boundary map'), findsOneWidget);
      expect(find.text('BDS dag map'), findsOneWidget);
      expect(find.text('RAJUK masterplan (DAP)'), findsOneWidget);

      await tester.tap(find.text('BDS dag map'));
      await tester.tap(find.text('RAJUK masterplan (DAP)'));
      expect(taps, [MapMode.bds, MapMode.rajuk]);
    });

    testWidgets('marks the active tab as selected for accessibility',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_harness(
        MapModeTabs(mode: MapMode.bds, onChanged: (_) {}),
      ));

      expect(
        tester.getSemantics(find.text('BDS dag map')),
        isSemantics(
          label: 'BDS dag map',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
        ),
      );
      handle.dispose();
    });
  });

  group('MapTopBar', () {
    Widget bar({
      MapMode mode = MapMode.boundaries,
      bool canDraw = true,
      List<String> notices = const [],
      VoidCallback? onDraw,
      VoidCallback? onLocate,
      bool isLocating = false,
    }) =>
        _harness(MapTopBar(
          mode: mode,
          searchController: TextEditingController(),
          searchHint: 'hint',
          onSearchChanged: (_) {},
          onSearchSubmitted: (_) {},
          onSearchCleared: () {},
          isLocating: isLocating,
          onLocate: onLocate ?? () {},
          canDraw: canDraw,
          onDraw: onDraw ?? () {},
          onModeChanged: (_) {},
          notices: notices,
        ));

    testWidgets('shows the draw button only in boundaries mode with permission',
        (tester) async {
      await tester.pumpWidget(bar());
      expect(find.text('Draw boundary'), findsOneWidget);

      await tester.pumpWidget(bar(mode: MapMode.bds));
      expect(find.text('Draw boundary'), findsNothing);

      await tester.pumpWidget(bar(canDraw: false));
      expect(find.text('Draw boundary'), findsNothing);
    });

    testWidgets('draw and locate buttons fire their callbacks', (tester) async {
      var drawn = 0;
      var located = 0;
      await tester.pumpWidget(bar(
        onDraw: () => drawn++,
        onLocate: () => located++,
      ));

      await tester.tap(find.text('Draw boundary'));
      await tester.tap(find.byIcon(Icons.my_location));

      expect(drawn, 1);
      expect(located, 1);
    });

    testWidgets('locate is disabled with a spinner while locating',
        (tester) async {
      var located = 0;
      await tester.pumpWidget(bar(isLocating: true, onLocate: () => located++));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(CircularProgressIndicator));
      expect(located, 0);
    });

    testWidgets('renders every notice', (tester) async {
      await tester.pumpWidget(bar(notices: const ['first', 'second']));

      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
    });
  });

  group('MapLegend', () {
    testWidgets('starts collapsed on phones and expands on tap',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_harness(const MapLegend()));

      expect(find.text('Legend'), findsOneWidget);
      expect(find.text('Disputed'), findsNothing);

      await tester.tap(find.text('Legend'));
      await tester.pumpAndSettle();

      for (final label in [
        'Approved',
        'Mine',
        'Waiting for approval',
        'Rejected',
        'Disputed',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('starts expanded on wide screens', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_harness(const MapLegend()));

      expect(find.text('Disputed'), findsOneWidget);
    });
  });

  group('MapDisclaimer', () {
    testWidgets('can be dismissed and stays dismissed for the session',
        (tester) async {
      await tester.pumpWidget(_harness(const MapDisclaimer()));
      expect(find.textContaining('member-marked approximate'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.textContaining('member-marked approximate'), findsNothing);

      await tester.pumpWidget(_harness(const SizedBox()));
      await tester.pumpWidget(_harness(const MapDisclaimer()));
      expect(find.textContaining('member-marked approximate'), findsNothing);
    });
  });

  group('LandInfoSheet', () {
    testWidgets('RAJUK card opens Street View at the plot centre',
        (tester) async {
      LatLng? streetView;
      await tester.pumpWidget(_harness(LandInfoSheet(
        plot: _plot(rs: '77'),
        onStreetView: (p) => streetView = p,
      )));

      await tester.tap(find.text('Google Street View'));
      expect(streetView?.latitude, closeTo(23.81, 1e-9));
      expect(streetView?.longitude, closeTo(90.305, 1e-9));
    });

    testWidgets('RAJUK card shows the RS plot and fixed JL number',
        (tester) async {
      await tester.pumpWidget(_harness(LandInfoSheet(
        plot: _plot(rs: '77'),
        onStreetView: (_) {},
      )));

      expect(find.text('RS Plot No: 77'), findsOneWidget);
      expect(find.text('245'), findsOneWidget);
      expect(find.text('Mouza: Uttar Kaundia'), findsOneWidget);
      expect(find.text('Savar Upazila, Dhaka'), findsOneWidget);
      expect(find.textContaining('Khatian'), findsNothing);
    });
  });

  group('BoundaryTimeline', () {
    testWidgets('pending: submitted done, under review active, approval todo',
        (tester) async {
      await tester
          .pumpWidget(_harness(BoundaryTimeline(boundary: _boundary())));

      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.byIcon(Icons.timelapse), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });

    testWidgets('approved with a live shape completes all three steps',
        (tester) async {
      await tester.pumpWidget(_harness(BoundaryTimeline(
        boundary: _boundary(
          status: BoundaryStatus.approved,
          live: BoundaryStatus.approved,
        ),
      )));

      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    });

    testWidgets('rejected ends in a rejected step instead of approval',
        (tester) async {
      await tester.pumpWidget(_harness(BoundaryTimeline(
        boundary: _boundary(status: BoundaryStatus.rejected),
      )));

      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Approved'), findsNothing);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });
  });

  group('ReportSheet', () {
    testWidgets('send is disabled until a note is typed, then thanks',
        (tester) async {
      var sent = 0;
      String? note;
      await tester.pumpWidget(_harness(ReportSheet(
        boundaryId: 'b1',
        submit: ReportSubmitter((id, n) async => note = n),
        onSent: () => sent++,
      )));

      final send = find.widgetWithText(FilledButton, 'Send report');
      expect(tester.widget<FilledButton>(send).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '  wrong shape  ');
      await tester.pump();
      await tester.tap(send);
      await tester.pumpAndSettle();

      expect(note, 'wrong shape');
      expect(sent, 1);
      expect(find.text('Report received.'), findsOneWidget);
    });

    testWidgets('a failed send shows the error and allows a retry',
        (tester) async {
      var sent = 0;
      await tester.pumpWidget(_harness(ReportSheet(
        boundaryId: 'b1',
        submit: ReportSubmitter((_, __) async => throw Exception('boom')),
        onSent: () => sent++,
      )));

      await tester.enterText(find.byType(TextField), 'note');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Send report'));
      await tester.pumpAndSettle();

      expect(find.text('Could not send the report.'), findsOneWidget);
      expect(sent, 0);
      expect(find.widgetWithText(FilledButton, 'Send report'), findsOneWidget);
    });
  });
}
