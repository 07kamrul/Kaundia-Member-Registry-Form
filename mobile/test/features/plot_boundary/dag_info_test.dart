import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/plot_boundary/data/land_data_dtos.dart';
import 'package:kaundia_app/features/plot_boundary/domain/dag_details_entities.dart';
import 'package:kaundia_app/features/plot_boundary/domain/land_data_repository.dart';
import 'package:kaundia_app/features/plot_boundary/domain/land_mappers.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/bloc/dag_info_cubit.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/widgets/dag_info_sheet.dart';
import 'package:kaundia_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements LandDataRepository {}

const _json = {
  'survey': 'bds',
  'sheet': '022',
  'dag': '22',
  'mouza': {
    'name_bn': 'উত্তর কাউন্দিয়া',
    'name_en': 'Uttar Kaundia',
    'upazila_bn': 'সাভার',
    'upazila_en': 'Savar',
    'district_bn': 'ঢাকা',
    'district_en': 'Dhaka',
  },
  'total_land': {'value': 0.7649, 'unit': 'acre'},
  'khatians': [
    {
      'khatian_no': '12012',
      'owners': ['টেস্ট মালিক এক', 'টেস্ট মালিক দুই'],
      'stage_code': 'objection',
      'stage_bn': 'আপত্তি স্তর',
    },
    {
      'khatian_no': '7',
      'owners': ['টেস্ট মালিক তিন'],
      'stage_code': null,
      'stage_bn': 'অন্য স্তর',
    },
    {
      'khatian_no': '8',
      'owners': <String>[],
      'stage_code': 'mystery',
      'stage_bn': null,
    },
  ],
  'source_note': null,
  'source': {
    'name': 'settlement.gov.bd',
    'fetched_at': '2026-10-11T00:00:00+00:00',
    'dataset_version': '20261010',
  },
};

DagDetails _details(List<Khatian> khatians) => DagDetails(
      survey: 'bds',
      sheet: '022',
      dag: '22',
      mouza: const MouzaInfo(
        nameBn: 'উত্তর কাউন্দিয়া',
        nameEn: 'Uttar Kaundia',
        upazilaBn: 'সাভার',
        upazilaEn: 'Savar',
        districtBn: 'ঢাকা',
        districtEn: 'Dhaka',
      ),
      totalLand: const TotalLand(value: 0.7649, unit: 'acre'),
      khatians: khatians,
      sourceName: 'settlement.gov.bd',
      fetchedAt: DateTime.utc(2026, 10, 11, 12),
    );

Khatian _khatian(String no, int owners,
        {KhatianStage stage = KhatianStage.objection, String? stageBn}) =>
    Khatian(
      khatianNo: no,
      owners: [for (var i = 0; i < owners; i++) 'Test Owner $no-$i'],
      stage: stage,
      stageBn: stageBn,
    );

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  group('DagDetailsDto mapper', () {
    final details = DagDetailsDto.fromJson(_json).toEntity();

    test('maps land, mouza and source', () {
      expect(details.dag, '22');
      expect(details.totalLand?.value, 0.7649);
      expect(details.totalLand?.shatangsho, closeTo(76.49, 1e-9));
      expect(
          details.mouza.display(bangla: true), 'উত্তর কাউন্দিয়া, সাভার, ঢাকা');
      expect(
          details.mouza.display(bangla: false), 'Uttar Kaundia, Savar, Dhaka');
      expect(details.sourceName, 'settlement.gov.bd');
      expect(details.fetchedAt, DateTime.utc(2026, 10, 11));
    });

    test('maps known stage codes', () {
      expect(details.khatians[0].stage, KhatianStage.objection);
      expect(details.khatians[0].owners, hasLength(2));
    });

    test('null stage_code falls back to unknown and keeps stage_bn', () {
      expect(details.khatians[1].stage, KhatianStage.unknown);
      expect(details.khatians[1].stageBn, 'অন্য স্তর');
    });

    test('unrecognised stage_code is unknown; missing owners tolerated', () {
      expect(details.khatians[2].stage, KhatianStage.unknown);
      expect(details.khatians[2].stageBn, isNull);
      expect(details.khatians[2].owners, isEmpty);
    });
  });

  group('DagInfoCubit', () {
    DagInfoCubit build() =>
        DagInfoCubit(sheet: '22', dag: '২২', repository: repo);

    blocTest<DagInfoCubit, DagInfoState>(
      'loading -> loaded, normalising sheet and dag digits',
      setUp: () => when(() => repo.dagDetails('bds', '022', '22'))
          .thenAnswer((_) async => _details([_khatian('1', 1)])),
      build: build,
      act: (c) => c.load(),
      expect: () => [
        const DagInfoLoading(),
        DagInfoLoaded(_details([_khatian('1', 1)])),
      ],
    );

    blocTest<DagInfoCubit, DagInfoState>(
      'empty khatians -> empty',
      setUp: () => when(() => repo.dagDetails(any(), any(), any()))
          .thenAnswer((_) async => _details(const [])),
      build: build,
      act: (c) => c.load(),
      expect: () => [const DagInfoLoading(), DagInfoEmpty(_details(const []))],
    );

    for (final (status, kind) in [
      (404, DagInfoFailureKind.notFound),
      (429, DagInfoFailureKind.rateLimited),
      (500, DagInfoFailureKind.other),
    ]) {
      blocTest<DagInfoCubit, DagInfoState>(
        'HTTP $status -> failure($kind)',
        setUp: () => when(() => repo.dagDetails(any(), any(), any())).thenThrow(
          ApiException(type: ApiExceptionType.server, statusCode: status),
        ),
        build: build,
        act: (c) => c.load(),
        expect: () => [const DagInfoLoading(), DagInfoFailure(kind)],
      );
    }

    blocTest<DagInfoCubit, DagInfoState>(
      'network error -> generic failure',
      setUp: () => when(() => repo.dagDetails(any(), any(), any()))
          .thenThrow(const ApiException(type: ApiExceptionType.network)),
      build: build,
      act: (c) => c.load(),
      expect: () => [
        const DagInfoLoading(),
        const DagInfoFailure(DagInfoFailureKind.other),
      ],
    );

    blocTest<DagInfoCubit, DagInfoState>(
      'retry after a failure reloads and succeeds',
      setUp: () {
        var calls = 0;
        when(() => repo.dagDetails(any(), any(), any())).thenAnswer((_) async {
          if (calls++ == 0) {
            throw const ApiException(type: ApiExceptionType.network);
          }
          return _details([_khatian('1', 1)]);
        });
      },
      build: build,
      act: (c) async {
        await c.load();
        await c.retry();
      },
      expect: () => [
        const DagInfoLoading(),
        const DagInfoFailure(DagInfoFailureKind.other),
        const DagInfoLoading(),
        DagInfoLoaded(_details([_khatian('1', 1)])),
      ],
      verify: (_) =>
          verify(() => repo.dagDetails('bds', '022', '22')).called(2),
    );

    blocTest<DagInfoCubit, DagInfoState>(
      'missing sheet fails as not found without a request',
      build: () => DagInfoCubit(sheet: '', dag: '1', repository: repo),
      act: (c) => c.load(),
      expect: () => [const DagInfoFailure(DagInfoFailureKind.notFound)],
      verify: (_) => verifyNever(() => repo.dagDetails(any(), any(), any())),
    );
  });

  group('DagInfoSheet', () {
    Future<DagInfoCubit> pump(
      WidgetTester tester,
      DagDetails? details, {
      String locale = 'en',
      Brightness brightness = Brightness.light,
      Object? error,
      Duration delay = Duration.zero,
    }) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(() => repo.dagDetails(any(), any(), any())).thenAnswer((_) async {
        if (delay > Duration.zero) await Future<void>.delayed(delay);
        if (error != null) throw error;
        return details!;
      });
      final cubit = DagInfoCubit(sheet: '22', dag: '22', repository: repo);
      addTearDown(cubit.close);
      cubit.load();
      await tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        theme: ThemeData(brightness: brightness),
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
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: const DagInfoSheet(dagNo: '22'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pump();
      return cubit;
    }

    Color? colorOf(WidgetTester tester, Key key) =>
        tester.widget<Container>(find.byKey(key)).color;

    testWidgets('header and skeleton render before data arrives',
        (tester) async {
      await pump(tester, _details([_khatian('1', 1)]),
          delay: const Duration(milliseconds: 50));
      expect(find.text('Plot/Dag No. 22 details'), findsOneWidget);
      expect(find.byKey(const Key('dag-info-skeleton')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dag-info-skeleton')), findsNothing);
    });

    for (final owners in [1, 3, 10]) {
      testWidgets('$owners-owner khatian is one group with striped rows',
          (tester) async {
        await pump(tester, _details([_khatian('5', owners)]));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('khatian-group-0')), findsOneWidget);
        expect(find.byKey(const Key('khatian-group-1')), findsNothing);
        expect(find.text('5'), findsOneWidget, reason: 'spans all owners');
        expect(find.text('Objection stage'), findsOneWidget);
        for (var j = 0; j < owners; j++) {
          expect(find.text('Test Owner 5-$j'), findsOneWidget);
        }
        final even = colorOf(tester, const Key('owner-0-0'));
        if (owners > 1) {
          expect(colorOf(tester, const Key('owner-0-1')), isNot(even));
        }
        if (owners > 2) {
          expect(colorOf(tester, const Key('owner-0-2')), even);
        }
        // Number cell is vertically centred relative to the whole group.
        final group = tester.getRect(find.byKey(const Key('khatian-group-0')));
        final no = tester.getCenter(find.text('5'));
        expect(no.dy, closeTo(group.center.dy, 2));
      });
    }

    testWidgets('empty khatians show the single notice row', (tester) async {
      await pump(tester, _details(const []));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('khatian-empty-row')), findsOneWidget);
      expect(find.text('No khatian information was found for this dag'),
          findsOneWidget);
    });

    testWidgets('English labels, ASCII digits, unknown stage verbatim',
        (tester) async {
      await pump(
        tester,
        _details([
          _khatian('12012', 2,
              stage: KhatianStage.unknown, stageBn: 'অন্য স্তর')
        ]),
      );
      await tester.pumpAndSettle();
      for (final t in [
        'Land Information',
        'Khatian Information',
        'Plot/Dag No.',
        'Survey Type',
        'Mouza',
        'Total Land',
        'Khatian No.',
        'Owner Name',
        'Current Stage',
        'Close',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.text('0.7649 acre\n≈ 76.49 decimal'), findsOneWidget);
      expect(find.text('Uttar Kaundia, Savar, Dhaka'), findsOneWidget);
      expect(find.text('12012'), findsOneWidget);
      expect(find.text('অন্য স্তর'), findsOneWidget);
      expect(find.text('Source: settlement.gov.bd · Collected: 2026-10-11'),
          findsOneWidget);
    });

    testWidgets('Bangla labels and digits', (tester) async {
      await pump(tester, _details([_khatian('12012', 1)]), locale: 'bn');
      await tester.pumpAndSettle();
      for (final t in [
        'প্লট/দাগ নাম্বার ২২ তথ্য বিবরণঃ',
        'ভূমি তথ্য বিবরণঃ',
        'খতিয়ানের তথ্যঃ',
        'সার্ভের ধরণ',
        'বিডিএস',
        'উত্তর কাউন্দিয়া, সাভার, ঢাকা',
        '০.৭৬৪৯ একর\n≈ ৭৬.৪৯ শতাংশ',
        'খতিয়ান নং',
        'মালিকের নাম',
        'চলমান স্তর',
        'আপত্তি স্তর',
        '১২০১২',
        'তথ্যসূত্র: settlement.gov.bd · সংগৃহীত: ২০২৬-১০-১১',
        'বন্ধ করুন',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      // Owner names are never translated.
      expect(find.text('Test Owner 12012-0'), findsOneWidget);
    });

    testWidgets('dark theme renders without overflow', (tester) async {
      await pump(tester, _details([_khatian('5', 3)]),
          brightness: Brightness.dark);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Test Owner 5-0'), findsOneWidget);
    });

    testWidgets('the X button dismisses the sheet', (tester) async {
      await pump(tester, _details([_khatian('5', 1)]));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dag-info-close-x')));
      await tester.pumpAndSettle();
      expect(find.byType(DagInfoSheet), findsNothing);
    });

    testWidgets('the Close footer button dismisses the sheet', (tester) async {
      await pump(tester, _details([_khatian('5', 1)]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(DagInfoSheet), findsNothing);
    });

    testWidgets('failure shows a message and Retry reloads', (tester) async {
      final cubit = await pump(
        tester,
        null,
        error:
            const ApiException(type: ApiExceptionType.server, statusCode: 429),
      );
      await tester.pumpAndSettle();
      expect(
          find.text('Too many requests. Please wait a moment and try again.'),
          findsOneWidget);

      when(() => repo.dagDetails(any(), any(), any()))
          .thenAnswer((_) async => _details([_khatian('5', 1)]));
      await tester.tap(find.byKey(const Key('dag-info-retry')));
      await tester.pumpAndSettle();
      expect(cubit.state, isA<DagInfoLoaded>());
      expect(find.text('Test Owner 5-0'), findsOneWidget);
    });
  });
}
