part of 'dashboard_bloc.dart';

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
