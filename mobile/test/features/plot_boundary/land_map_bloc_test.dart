import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/plot_boundary/domain/geo.dart';
import 'package:kaundia_app/features/plot_boundary/domain/land_data_repository.dart';
import 'package:kaundia_app/features/plot_boundary/domain/land_entities.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/bloc/land_map_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements LandDataRepository {}

const _viewport = SocietyBbox(
  minLng: 90.30,
  minLat: 23.80,
  maxLng: 90.31,
  maxLat: 23.81,
);

LandPlot _plot(String dag) => LandPlot(
      dag: dag,
      rings: const [
        [LatLng(23.80, 90.30), LatLng(23.80, 90.31), LatLng(23.81, 90.31)],
      ],
    );

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(_viewport);
    registerFallbackValue(LandLayer.bds);
  });

  setUp(() {
    repo = _MockRepo();
    when(() => repo.plotsInBbox(any(), any()))
        .thenAnswer((_) async => LandCollection(plots: [_plot('1')]));
  });

  LandMapBloc build() => LandMapBloc(repository: repo, debounce: Duration.zero);

  test('starts in boundaries mode without a collection', () {
    final bloc = build();
    expect(bloc.state.mode, MapMode.boundaries);
    expect(bloc.state.collection, isNull);
    bloc.close();
  });

  blocTest<LandMapBloc, LandMapState>(
    'viewport moves in boundaries mode never hit the land API',
    build: build,
    act: (b) => b.add(const LandViewportChanged(_viewport)),
    wait: const Duration(milliseconds: 20),
    verify: (_) => verifyNever(() => repo.plotsInBbox(any(), any())),
  );

  blocTest<LandMapBloc, LandMapState>(
    'switching to BDS loads the known viewport padded by 25%',
    build: build,
    seed: () => const LandMapState(viewport: _viewport),
    act: (b) => b.add(const LandModeChanged(MapMode.bds)),
    verify: (b) {
      verify(() => repo.plotsInBbox(LandLayer.bds, _viewport.padded(0.25)))
          .called(1);
      expect(b.state.status, LandLoadStatus.loaded);
      expect(b.state.collection?.plots, hasLength(1));
    },
  );

  blocTest<LandMapBloc, LandMapState>(
    'a viewport inside the cached bounds does not refetch',
    build: build,
    seed: () => const LandMapState(viewport: _viewport),
    act: (b) async {
      b.add(const LandModeChanged(MapMode.bds));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      b.add(LandViewportChanged(_viewport.padded(0.1)));
    },
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => repo.plotsInBbox(any(), any())).called(1),
  );

  blocTest<LandMapBloc, LandMapState>(
    'a viewport outside the cached bounds refetches',
    build: build,
    seed: () => const LandMapState(viewport: _viewport),
    act: (b) async {
      b.add(const LandModeChanged(MapMode.bds));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      b.add(LandViewportChanged(_viewport.padded(1)));
    },
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => repo.plotsInBbox(any(), any())).called(2),
  );

  blocTest<LandMapBloc, LandMapState>(
    'a failed load reports failure and retry reloads',
    build: build,
    seed: () => const LandMapState(viewport: _viewport),
    setUp: () {
      var calls = 0;
      when(() => repo.plotsInBbox(any(), any())).thenAnswer((_) async {
        if (calls++ == 0) throw const FormatException('boom');
        return LandCollection(plots: [_plot('2')]);
      });
    },
    act: (b) async {
      b.add(const LandModeChanged(MapMode.rajuk));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(b.state.status, LandLoadStatus.failure);
      b.add(const LandRetryRequested());
    },
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.status, LandLoadStatus.loaded);
      expect(b.state.collection?.plots.single.dag, '2');
    },
  );

  blocTest<LandMapBloc, LandMapState>(
    'truncated responses are surfaced',
    build: build,
    seed: () => const LandMapState(viewport: _viewport),
    setUp: () => when(() => repo.plotsInBbox(any(), any()))
        .thenAnswer((_) async => const LandCollection(truncated: true)),
    act: (b) => b.add(const LandModeChanged(MapMode.bds)),
    verify: (b) => expect(b.state.isTruncated, isTrue),
  );

  group('dag search', () {
    blocTest<LandMapBloc, LandMapState>(
      'a hit highlights the normalised dag and requests a camera fit',
      build: build,
      seed: () => const LandMapState(mode: MapMode.rajuk),
      setUp: () => when(() => repo.lookup(LandLayer.rajuk, '4611'))
          .thenAnswer((_) async => LandCollection(plots: [
                LandPlot(rsPlotNo: 'RS-4611', rings: const [
                  [LatLng(23.80, 90.30), LatLng(23.81, 90.31)],
                ]),
              ])),
      act: (b) => b.add(const LandDagSearched('৪৬১১')),
      verify: (b) {
        expect(b.state.highlightDag, '4611');
        expect(b.state.dagNotFound, isFalse);
        expect(b.state.fitPoints, hasLength(2));
        expect(b.state.fitSerial, 1);
      },
    );

    blocTest<LandMapBloc, LandMapState>(
      'an empty result sets dagNotFound and clears the highlight',
      build: build,
      seed: () => const LandMapState(mode: MapMode.bds, highlightDag: '9'),
      setUp: () => when(() => repo.lookup(LandLayer.bds, '77'))
          .thenAnswer((_) async => const LandCollection()),
      act: (b) => b.add(const LandDagSearched('77')),
      verify: (b) {
        expect(b.state.dagNotFound, isTrue);
        expect(b.state.highlightDag, isNull);
        expect(b.state.fitSerial, 0);
      },
    );

    blocTest<LandMapBloc, LandMapState>(
      'a network error reports failure',
      build: build,
      seed: () => const LandMapState(mode: MapMode.bds),
      setUp: () => when(() => repo.lookup(any(), any()))
          .thenThrow(const ApiException(type: ApiExceptionType.network)),
      act: (b) => b.add(const LandDagSearched('5')),
      verify: (b) => expect(b.state.status, LandLoadStatus.failure),
    );

    blocTest<LandMapBloc, LandMapState>(
      'blank queries and boundaries mode are ignored',
      build: build,
      act: (b) => b.add(const LandDagSearched('7')),
      verify: (_) => verifyNever(() => repo.lookup(any(), any())),
    );

    blocTest<LandMapBloc, LandMapState>(
      'clearing the search drops highlight and not-found',
      build: build,
      seed: () => const LandMapState(
          mode: MapMode.bds, highlightDag: '4', dagNotFound: true),
      act: (b) => b.add(const LandSearchCleared()),
      verify: (b) {
        expect(b.state.highlightDag, isNull);
        expect(b.state.dagNotFound, isFalse);
      },
    );

    blocTest<LandMapBloc, LandMapState>(
      'switching mode resets search state',
      build: build,
      seed: () => const LandMapState(
          mode: MapMode.bds, highlightDag: '4', dagNotFound: true),
      act: (b) => b.add(const LandModeChanged(MapMode.boundaries)),
      verify: (b) {
        expect(b.state.mode, MapMode.boundaries);
        expect(b.state.highlightDag, isNull);
        expect(b.state.collection, isNull);
      },
    );
  });
}
