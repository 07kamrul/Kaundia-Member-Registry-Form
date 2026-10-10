import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/neighbours/domain/neighbour_entities.dart';
import 'package:kaundia_app/features/neighbours/domain/neighbours_failure.dart';
import 'package:kaundia_app/features/neighbours/domain/neighbours_repository.dart';
import 'package:kaundia_app/features/neighbours/presentation/bloc/neighbours_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'neighbours_fixtures.dart';

class _MockRepo extends Mock implements NeighboursRepository {}

void main() {
  late _MockRepo repo;
  NeighboursBloc build() => NeighboursBloc(getNeighbours: GetNeighbours(repo));

  final full = directory([
    ownGroup('12', same: [rahim], near: [karim])
  ]);
  final multi = directory([
    ownGroup('12', dagNumber: null),
    ownGroup('13', near: [karim]),
  ]);

  setUp(() => repo = _MockRepo());

  void answer(NeighbourDirectory d) =>
      when(() => repo.getNeighbours(dagType: any(named: 'dagType')))
          .thenAnswer((_) async => d);

  void fail(ApiException e) =>
      when(() => repo.getNeighbours(dagType: any(named: 'dagType')))
          .thenThrow(e);

  blocTest<NeighboursBloc, NeighboursState>(
    'load success emits [loading, loaded] with server dag type + selection',
    setUp: () => answer(full),
    build: build,
    act: (b) => b.add(const NeighboursLoadRequested()),
    expect: () => [
      const NeighboursState(),
      NeighboursState(
        status: NeighboursStatus.loaded,
        directory: full,
        dagType: DagType.rs,
        selectedPropertyId: '12',
      ),
    ],
    verify: (_) => verify(() => repo.getNeighbours(dagType: null)).called(1),
  );

  blocTest<NeighboursBloc, NeighboursState>(
    'every group without owners -> empty',
    setUp: () => answer(directory([ownGroup('12')])),
    build: build,
    act: (b) => b.add(const NeighboursLoadRequested()),
    skip: 1,
    expect: () => [
      isA<NeighboursState>()
          .having((s) => s.status, 'status', NeighboursStatus.empty)
          .having((s) => s.selectedPropertyId, 'selected', '12'),
    ],
  );

  blocTest<NeighboursBloc, NeighboursState>(
    'no properties -> empty with no selection',
    setUp: () => answer(directory(const [])),
    build: build,
    act: (b) => b.add(const NeighboursLoadRequested()),
    skip: 1,
    expect: () => [
      isA<NeighboursState>()
          .having((s) => s.status, 'status', NeighboursStatus.empty)
          .having((s) => s.selectedPropertyId, 'selected', isNull)
          .having((s) => s.selectedGroup, 'group', isNull),
    ],
  );

  for (final (name, error, kind) in [
    (
      'network',
      const ApiException(type: ApiExceptionType.network),
      NeighboursFailureKind.network
    ),
    (
      'rate limited',
      const ApiException(
          type: ApiExceptionType.server,
          statusCode: 429,
          errorCode: neighbourRateLimitedCode),
      NeighboursFailureKind.rateLimited
    ),
    (
      'approved only',
      const ApiException(
          type: ApiExceptionType.server,
          statusCode: 403,
          errorCode: neighbourApprovedOnlyCode),
      NeighboursFailureKind.approvedOnly
    ),
    (
      'server',
      const ApiException(type: ApiExceptionType.server, statusCode: 500),
      NeighboursFailureKind.other
    ),
  ]) {
    blocTest<NeighboursBloc, NeighboursState>(
      '$name error -> failure($kind)',
      setUp: () => fail(error),
      build: build,
      act: (b) => b.add(const NeighboursLoadRequested()),
      expect: () => [
        const NeighboursState(),
        NeighboursState(status: NeighboursStatus.failure, failureKind: kind),
      ],
    );
  }

  blocTest<NeighboursBloc, NeighboursState>(
    'DagTypeChanged re-requests with that type',
    setUp: () => answer(directory([
      ownGroup('12', near: [karim])
    ], type: DagType.cs)),
    build: build,
    seed: () => NeighboursState(
      status: NeighboursStatus.loaded,
      directory: full,
      dagType: DagType.rs,
      selectedPropertyId: '12',
    ),
    act: (b) => b.add(const NeighboursDagTypeChanged(DagType.cs)),
    expect: () => [
      isA<NeighboursState>()
          .having((s) => s.dagType, 'dagType', DagType.cs)
          .having((s) => s.status, 'status', NeighboursStatus.loaded),
      isA<NeighboursState>()
          .having((s) => s.status, 's', NeighboursStatus.loading),
      isA<NeighboursState>()
          .having((s) => s.status, 'status', NeighboursStatus.loaded)
          .having((s) => s.directory?.dagType, 'type', DagType.cs),
    ],
    verify: (_) =>
        verify(() => repo.getNeighbours(dagType: DagType.cs)).called(1),
  );

  blocTest<NeighboursBloc, NeighboursState>(
    'DagTypeChanged to the current type is ignored',
    build: build,
    seed: () => NeighboursState(
        status: NeighboursStatus.loaded, directory: full, dagType: DagType.rs),
    act: (b) => b.add(const NeighboursDagTypeChanged(DagType.rs)),
    expect: () => const <NeighboursState>[],
  );

  blocTest<NeighboursBloc, NeighboursState>(
    'defaults selection to the first group with owners; PropertySelected switches',
    setUp: () => answer(multi),
    build: build,
    act: (b) async {
      b.add(const NeighboursLoadRequested());
      await b.stream.firstWhere((s) => s.status != NeighboursStatus.loading);
      b.add(const NeighboursPropertySelected('12'));
      b.add(const NeighboursPropertySelected('999'));
    },
    skip: 1,
    expect: () => [
      isA<NeighboursState>().having((s) => s.selectedPropertyId, 'sel', '13'),
      isA<NeighboursState>()
          .having((s) => s.selectedPropertyId, 'sel', '12')
          .having((s) => s.selectedGroup?.own.hasDag, 'noDag', isFalse),
    ],
  );

  blocTest<NeighboursBloc, NeighboursState>(
    'retry after failure reloads with the selected dag type',
    setUp: () => answer(full),
    build: build,
    seed: () => const NeighboursState(
      status: NeighboursStatus.failure,
      dagType: DagType.cs,
      failureKind: NeighboursFailureKind.network,
    ),
    act: (b) => b.add(const NeighboursLoadRequested()),
    expect: () => [
      const NeighboursState(dagType: DagType.cs),
      isA<NeighboursState>()
          .having((s) => s.status, 'status', NeighboursStatus.loaded)
          .having((s) => s.failureKind, 'failure', isNull),
    ],
    verify: (_) =>
        verify(() => repo.getNeighbours(dagType: DagType.cs)).called(1),
  );
}
