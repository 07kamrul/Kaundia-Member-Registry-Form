import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/plot_boundary/domain/land_entities.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/widgets/map/land_label_layer.dart';
import 'package:kaundia_app/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

import '../../support/blank_tile_provider.dart';

LandPlot _plot(String dag, double lat, double lng) => LandPlot(
      dag: dag,
      rings: [
        [
          LatLng(lat, lng),
          LatLng(lat, lng + 0.0004),
          LatLng(lat + 0.0004, lng + 0.0004),
          LatLng(lat + 0.0004, lng),
        ],
      ],
    );

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required double zoom,
    required List<LandPlot> plots,
    int maxLabels = LandLabelLayer.kLandLabelMax,
  }) async {
    tester.view.physicalSize = const Size(400, 600);
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
      home: Scaffold(
        body: FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(23.809, 90.323),
            initialZoom: zoom,
          ),
          children: [
            TileLayer(
              urlTemplate: 'unused/{z}/{x}/{y}',
              tileProvider: BlankTileProvider(),
            ),
            LandLabelLayer(
              collection: LandCollection(plots: plots),
              maxLabels: maxLabels,
            ),
          ],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 60));
  }

  final visible = [
    _plot('101', 23.8089, 90.3228),
    _plot('102', 23.8091, 90.3232),
  ];

  testWidgets('shows dag labels once zoomed in', (tester) async {
    await pump(tester, zoom: 17, plots: visible);

    expect(find.text('101'), findsOneWidget);
    expect(find.text('102'), findsOneWidget);
  });

  testWidgets('hides labels below the minimum zoom', (tester) async {
    await pump(tester, zoom: 14, plots: visible);

    expect(find.text('101'), findsNothing);
  });

  testWidgets('skips plots that are outside the view', (tester) async {
    await pump(
      tester,
      zoom: 17,
      plots: [...visible, _plot('999', 23.90, 90.40)],
    );

    expect(find.text('999'), findsNothing);
  });

  testWidgets('never draws more labels than the cap', (tester) async {
    await pump(tester, zoom: 17, plots: visible, maxLabels: 1);

    expect(find.text('101'), findsOneWidget);
    expect(find.text('102'), findsNothing);
  });
}
