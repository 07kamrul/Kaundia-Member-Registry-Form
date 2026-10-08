part of 'dashboard_bloc.dart';

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
