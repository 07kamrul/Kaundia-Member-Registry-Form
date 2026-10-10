import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_entities.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/bloc/plot_map_bloc.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/widgets/boundary_disclaimer_banner.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/widgets/owner_bottom_sheet.dart';
import 'package:kaundia_app/l10n/app_localizations.dart';
import 'package:kaundia_app/shared/widgets/widgets.dart';
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
      home: Scaffold(body: child),
    );

BoundaryFeature get _feature => const BoundaryFeature(
      boundaryId: 'b1',
      propertyId: 'p1',
      status: BoundaryStatus.approved,
      isMine: false,
      points: [LatLng(23.81, 90.41), LatLng(23.82, 90.42)],
    );

void main() {
  testWidgets('disclaimer banner shows the standing text (en)',
      (tester) async {
    await tester.pumpWidget(
        _harness(const BoundaryDisclaimerBanner()));
    expect(
        find.text(
            'This is a member-marked approximate boundary; it is not a substitute for an official survey or legal documents.'),
        findsOneWidget);
  });

  testWidgets('disclaimer banner shows the standing text (bn)',
      (tester) async {
    await tester.pumpWidget(_harness(const BoundaryDisclaimerBanner(),
        locale: const Locale('bn')));
    expect(find.textContaining('সদস্য-চিহ্নিত আনুমানিক সীমানা'),
        findsOneWidget);
  });

  testWidgets('owner sheet shows owner, area in m² + shotangsho, contact buttons',
      (tester) async {
    await tester.pumpWidget(_harness(
      SingleChildScrollView(
        child: BoundaryOwnerSheet(
          status: OwnerLoadStatus.loaded,
          owner: const BoundaryOwner(
            boundaryId: 'b1',
            ownerName: 'Rahim Uddin',
            mobile: '01712345678',
            contactHidden: false,
            status: BoundaryStatus.approved,
            rsDag: '120',
            csDag: '55',
            landQuantity: '10',
            areaSqm: 404.7,
            areaShotangsho: 10.0,
          ),
          feature: _feature,
          onCall: () {},
          onWhatsApp: () {},
          onReport: () {},
          onRetry: () {},
        ),
      ),
    ));
    expect(find.text('Rahim Uddin'), findsOneWidget);
    expect(find.text('Owner details'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.textContaining('404.7 m²'), findsOneWidget);
    expect(find.textContaining('10.00 shotangsho'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
  });

  testWidgets('hidden contact shows the privacy note and no contact buttons',
      (tester) async {
    await tester.pumpWidget(_harness(
      SingleChildScrollView(
        child: BoundaryOwnerSheet(
          status: OwnerLoadStatus.loaded,
          owner: const BoundaryOwner(
            boundaryId: 'b1',
            ownerName: 'Rahim',
            mobile: null,
            contactHidden: true,
            status: BoundaryStatus.approved,
          ),
          feature: _feature,
          onCall: () {},
          onWhatsApp: () {},
          onReport: () {},
          onRetry: () {},
        ),
      ),
    ));
    expect(find.text('Contact hidden'), findsOneWidget);
    expect(find.text('Call'), findsNothing);
    expect(find.text('WhatsApp'), findsNothing);
  });

  testWidgets('failure state shows the error and a retry affordance',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(_harness(
      BoundaryOwnerSheet(
        status: OwnerLoadStatus.failure,
        failure: 'Could not load the owner details.',
        onCall: () {},
        onWhatsApp: () {},
        onReport: () {},
        onRetry: () => retried = true,
      ),
    ));
    expect(find.text('Could not load the owner details.'), findsOneWidget);
    await tester.tap(find.byType(AppButton).first);
    expect(retried, isTrue);
  });

  testWidgets('loading state shows a spinner', (tester) async {
    await tester.pumpWidget(_harness(
      const BoundaryOwnerSheet(
        status: OwnerLoadStatus.loading,
        onCall: _noop,
        onWhatsApp: _noop,
        onReport: _noop,
        onRetry: _noop,
      ),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

void _noop() {}
