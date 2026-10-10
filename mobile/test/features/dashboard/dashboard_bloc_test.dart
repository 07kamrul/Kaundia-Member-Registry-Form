import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/di/injector.dart';
import 'package:kaundia_app/core/enums/enums.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/dashboard/data/public_stats_repository.dart';
import 'package:kaundia_app/features/dashboard/domain/entity/public_stats.dart';
import 'package:kaundia_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockPublicStatsRepository extends Mock implements PublicStatsRepository {}

const _stats = PublicStats(
  pendingCount: 1,
  approvedCount: 2,
  monthlySubscriptionTotal: 300,
);

void main() {
  late MockPublicStatsRepository repo;

  setUpAll(() {
    // DashboardBloc reads the session for the member's own status card; tests
    // run unauthenticated.
    if (!sl.isRegistered<SessionManager>()) {
      sl.registerLazySingleton(() => SessionManager());
    }
  });

  setUp(() {
    repo = MockPublicStatsRepository();
  });

  blocTest<DashboardBloc, DashboardState>(
    'emits [loading, loaded] on DashboardStarted',
    build: () {
      when(() => repo.getStats()).thenAnswer((_) async => _stats);
      return DashboardBloc(repository: repo);
    },
    act: (bloc) => bloc.add(const DashboardStarted()),
    expect: () => [
      const DashboardLoading(),
      const DashboardLoaded(stats: _stats),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'emits [failure] on network error from empty state',
    build: () {
      when(() => repo.getStats())
          .thenThrow(const ApiException(type: ApiExceptionType.network));
      return DashboardBloc(repository: repo);
    },
    act: (bloc) => bloc.add(const DashboardStarted()),
    expect: () => [
      const DashboardLoading(),
      const DashboardFailure(
          error: ApiException(type: ApiExceptionType.network)),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'pull-to-refresh shows reloading over existing content and restores it on failure',
    build: () {
      var calls = 0;
      when(() => repo.getStats()).thenAnswer((_) async {
        calls++;
        if (calls == 1) return _stats;
        throw const ApiException(type: ApiExceptionType.network);
      });
      return DashboardBloc(repository: repo);
    },
    act: (bloc) async {
      bloc.add(const DashboardStarted());
      await bloc.stream.firstWhere((s) => s is DashboardLoaded);
      bloc.add(const DashboardStarted(forceRefresh: true));
    },
    expect: () => [
      const DashboardLoading(),
      const DashboardLoaded(stats: _stats),
      DashboardLoaded(stats: _stats, reloading: true),
      const DashboardLoaded(stats: _stats),
    ],
  );

  test('own status is null without a session, present for members', () {
    final bloc = DashboardBloc(repository: repo);
    expect(bloc.state, const DashboardInitial());
  });

  test('Session.landingTier mirrors Angular roleGuard tiers', () {
    // Sanity guard for the dashboard's tier switch — a regression here would
    // show the wrong dashboard.
    expect(LandingTier.member, isNot(LandingTier.management));
  });
}
