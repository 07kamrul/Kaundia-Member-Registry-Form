import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_entities.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_repository.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/bloc/my_boundaries_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements PlotBoundaryRepository {}

const _p1 = OwnProperty(propertyId: 'p1', rsDag: '10');
const _p2 = OwnProperty(propertyId: 'p2', rsDag: '20');

PlotBoundary _boundary(String id, String propertyId, {bool pending = false}) =>
    PlotBoundary(
      id: id,
      propertyId: propertyId,
      status: pending ? BoundaryStatus.pendingReview : BoundaryStatus.approved,
      points: const [],
      isMine: true,
      hasPending: pending,
    );

void main() {
  late _MockRepo repo;
  late MyBoundariesCubit cubit;

  setUp(() {
    repo = _MockRepo();
    when(repo.getMyProperties).thenAnswer((_) async => [_p1, _p2]);
    when(repo.getMyBoundaries)
        .thenAnswer((_) async => [_boundary('b1', 'p1', pending: true)]);
    cubit = MyBoundariesCubit(
      getMyProperties: GetMyProperties(repo),
      getMyBoundaries: GetMyBoundaries(repo),
      withdrawBoundary: WithdrawBoundary(repo),
    );
  });

  tearDown(() => cubit.close());

  test('load exposes only plots without a boundary as available', () async {
    await cubit.load();

    expect(cubit.state.status, MyBoundariesStatus.ready);
    expect(cubit.state.availableProperties, [_p2]);
    expect(cubit.state.boundaries, hasLength(1));
  });

  test('load failure reports the failure kind', () async {
    when(repo.getMyProperties)
        .thenThrow(const ApiException(type: ApiExceptionType.network));

    await cubit.load();

    expect(cubit.state.status, MyBoundariesStatus.failure);
  });

  test('selection survives a reload while the plot is still available',
      () async {
    await cubit.load();
    cubit.selectProperty('p2');

    await cubit.load();

    expect(cubit.state.selectedPropertyId, 'p2');
  });

  test('selection is dropped once the plot gets a boundary', () async {
    await cubit.load();
    cubit.selectProperty('p2');
    when(repo.getMyBoundaries).thenAnswer(
        (_) async => [_boundary('b1', 'p1'), _boundary('b2', 'p2')]);

    await cubit.load();

    expect(cubit.state.selectedPropertyId, isNull);
  });

  test('withdraw calls the API and reloads the list', () async {
    when(() => repo.withdrawBoundary('b1')).thenAnswer((_) async {});
    await cubit.load();
    when(repo.getMyBoundaries).thenAnswer((_) async => [_boundary('b1', 'p1')]);

    await cubit.withdraw('b1');

    verify(() => repo.withdrawBoundary('b1')).called(1);
    expect(cubit.state.boundaries.single.hasPending, isFalse);
    expect(cubit.state.withdrawingId, isNull);
    expect(cubit.state.withdrawFailed, isFalse);
  });

  test('a failed withdraw flags the failure and clears the spinner', () async {
    when(() => repo.withdrawBoundary('b1'))
        .thenThrow(const ApiException(type: ApiExceptionType.server));
    await cubit.load();

    await cubit.withdraw('b1');

    expect(cubit.state.withdrawFailed, isTrue);
    expect(cubit.state.withdrawingId, isNull);
  });

  blocTest<MyBoundariesCubit, MyBoundariesState>(
    'withdraw is ignored while another withdraw is running',
    build: () => cubit,
    seed: () => const MyBoundariesState(withdrawingId: 'b9'),
    act: (c) => c.withdraw('b1'),
    expect: () => <MyBoundariesState>[],
    verify: (_) => verifyNever(() => repo.withdrawBoundary(any())),
  );
}
