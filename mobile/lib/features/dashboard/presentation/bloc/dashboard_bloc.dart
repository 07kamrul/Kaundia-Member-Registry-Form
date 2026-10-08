import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/public_stats_repository.dart';
import '../../domain/entity/public_stats.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required PublicStatsRepository repository}) : _repo = repository, super(const DashboardInitial()) {
    on<DashboardStarted>(_onStarted);
  }

  final PublicStatsRepository _repo;

  Future<void> _onStarted(DashboardStarted e, Emitter<DashboardState> emit) async {
    // Pull-to-refresh keeps current content visible with a reloading flag.
    DashboardLoaded? previous;
    final current = state;
    if (current is DashboardLoaded) {
      previous = current;
      emit(DashboardLoaded(
        stats: current.stats,
        ownStatus: current.ownStatus,
        reloading: true,
      ));
    } else {
      emit(const DashboardLoading());
    }

    try {
      final stats = await _repo.getStats();
      emit(DashboardLoaded(stats: stats, ownStatus: _loadOwnStatus()));
    } on ApiException catch (err) {
      // A refresh that fails over existing content keeps the old data.
      if (previous != null) {
        emit(previous);
        return;
      }
      emit(DashboardFailure(error: err));
    }
  }

  /// The member's own status comes from the cached session context; resolved
  /// by the member profile repository elsewhere — the dashboard only renders
  /// what the session already knows (status stored at login/profile load).
  OwnStatus? _loadOwnStatus() {
    final session = sl<SessionManager>().session;
    if (session == null || !session.can('profile.view_own')) return null;
    return const OwnStatus(status: SubmissionStatus.unknown);
  }
}
