part of 'stats_bloc.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class StatsEvent extends Equatable {
  const StatsEvent();
  @override
  List<Object?> get props => const [];
}

final class StatsLoadRequested extends StatsEvent {
  const StatsLoadRequested();
}
