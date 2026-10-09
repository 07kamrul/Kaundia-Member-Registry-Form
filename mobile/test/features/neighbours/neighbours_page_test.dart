import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/neighbours/domain/neighbour_entities.dart';
import 'package:kaundia_app/features/neighbours/domain/neighbours_repository.dart';
import 'package:kaundia_app/features/neighbours/presentation/bloc/neighbours_bloc.dart';
import 'package:kaundia_app/features/neighbours/presentation/pages/neighbours_page.dart';
import 'package:kaundia_app/l10n/app_localizations.dart';
import 'package:kaundia_app/shared/utils/external_link_launcher.dart';

import 'neighbours_fixtures.dart';

class _FakeRepo implements NeighboursRepository {
  _FakeRepo(this.result);
  final NeighbourDirectory result;
  @override
  Future<NeighbourDirectory> getNeighbours({DagType? dagType}) async => result;
}

class _FakeLauncher implements ExternalLinkLauncher {
  _FakeLauncher({this.succeed = true});
  final bool succeed;
  final opened = <Uri>[];
  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return succeed;
  }
}

Widget _harness(NeighbourDirectory d, ExternalLinkLauncher launcher) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: NeighboursPage(
        createBloc: () => NeighboursBloc(getNeighbours: GetNeighbours(_FakeRepo(d))),
        launcher: launcher,
      ),
    );

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(400, 1600);
    view.devicePixelRatio = 1;
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });

  final data = directory([ownGroup('12', same: [rahim], near: [karim])]);

  testWidgets('renders same-dag owner first with labels; hidden contact has no buttons',
      (tester) async {
    await tester.pumpWidget(_harness(data, _FakeLauncher()));
    await tester.pumpAndSettle();

    final rahimY = tester.getTopLeft(find.text(rahim.ownerName)).dy;
    final karimY = tester.getTopLeft(find.text(karim.ownerName)).dy;
    expect(rahimY, lessThan(karimY));
    expect(find.text('On your dag'), findsOneWidget);
    expect(find.text('Adjacent dag'), findsOneWidget);
    expect(find.text('Number kept private'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget, reason: 'only the visible contact');
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.textContaining('Your dag: 830'), findsWidgets);
  });

  testWidgets('tapping Call opens tel:+880…', (tester) async {
    final launcher = _FakeLauncher();
    await tester.pumpWidget(_harness(data, launcher));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Call'));
    await tester.pumpAndSettle();
    expect(launcher.opened.single.toString(), 'tel:+8801712345678');
  });

  testWidgets('launcher returning false shows the toast', (tester) async {
    await tester.pumpWidget(_harness(data, _FakeLauncher(succeed: false)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    expect(find.text("WhatsApp couldn't be opened."), findsOneWidget);
  });

  testWidgets('empty state text when no owners', (tester) async {
    await tester.pumpWidget(_harness(directory([ownGroup('12')]), _FakeLauncher()));
    await tester.pumpAndSettle();
    expect(find.text('No registered members were found around your dag'), findsOneWidget);
  });
}
