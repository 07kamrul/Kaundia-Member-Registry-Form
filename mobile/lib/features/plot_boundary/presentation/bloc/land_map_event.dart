part of 'land_map_bloc.dart';

sealed class LandMapEvent extends Equatable {
  const LandMapEvent();
  @override
  List<Object?> get props => const [];
}

/// Switch between member boundaries, the BDS map and the RAJUK masterplan.
final class LandModeChanged extends LandMapEvent {
  const LandModeChanged(this.mode);
  final MapMode mode;
  @override
  List<Object?> get props => [mode];
}

/// Camera moved; debounced before an official layer reloads.
final class LandViewportChanged extends LandMapEvent {
  const LandViewportChanged(this.viewport);
  final SocietyBbox viewport;
  @override
  List<Object?> get props => [viewport];
}

/// Dag-number search on the active official layer.
final class LandDagSearched extends LandMapEvent {
  const LandDagSearched(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

final class LandSearchCleared extends LandMapEvent {
  const LandSearchCleared();
}

/// Retry after a load error; drops the cache of the active layer.
final class LandRetryRequested extends LandMapEvent {
  const LandRetryRequested();
}
