import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/public_stats_repository.dart';
import '../../domain/entity/public_stats.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => const [];
}

/// Load the dashboard (public stats +, when authenticated, the member's own
/// submission status). Dispatched on first build and on pull-to-refresh.
final class DashboardStarted extends DashboardEvent {
  const DashboardStarted({this.forceRefresh = false});
  final bool forceRefresh;
  @override
  List<Object?> get props => [forceRefresh];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

sealed class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => const [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded({required this.stats, this.ownStatus, this.reloading = false});

  final PublicStats stats;

  /// Null for unauthenticated visitors.
  final OwnStatus? ownStatus;

  /// True while a pull-to-refresh reload is in flight over existing content.
  final bool reloading;

  @override
  List<Object?> get props => [stats, ownStatus, reloading];
}

class DashboardFailure extends DashboardState {
  const DashboardFailure({required this.error});
  final ApiException error;
  @override
  List<Object?> get props => [error];
}

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
