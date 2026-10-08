part of 'stats_bloc.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

sealed class StatsState extends Equatable {
  const StatsState();
  @override
  List<Object?> get props => const [];
}

class StatsInitial extends StatsState {
  const StatsInitial();
}

class StatsLoading extends StatsState {
  const StatsLoading();
}

class StatsLoaded extends StatsState {
  const StatsLoaded({required this.stats});
  final PublicStats stats;
  @override
  List<Object?> get props => [stats];
}

class StatsFailure extends StatsState {
  const StatsFailure();
}
