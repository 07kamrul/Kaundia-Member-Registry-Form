part of 'plot_map_bloc.dart';

sealed class PlotMapEvent extends Equatable {
  const PlotMapEvent();
  @override
  List<Object?> get props => const [];
}

/// Camera moved; debounced before the refetch happens.
final class PlotMapMoved extends PlotMapEvent {
  const PlotMapMoved(this.bbox);
  final SocietyBbox bbox;
  @override
  List<Object?> get props => [bbox];
}

/// Manual retry / pull-to-refresh.
final class PlotMapRefreshRequested extends PlotMapEvent {
  const PlotMapRefreshRequested();
}

final class PlotMapLayerChanged extends PlotMapEvent {
  const PlotMapLayerChanged(this.layer);
  final MapLayer layer;
  @override
  List<Object?> get props => [layer];
}

/// Tap on a polygon; null closes the selection.
final class PlotMapBoundarySelected extends PlotMapEvent {
  const PlotMapBoundarySelected(this.boundaryId);
  final String? boundaryId;
  @override
  List<Object?> get props => [boundaryId];
}

/// Load the owner details of the selected polygon.
final class PlotMapOwnerRequested extends PlotMapEvent {
  const PlotMapOwnerRequested(this.boundaryId);
  final String boundaryId;
  @override
  List<Object?> get props => [boundaryId];
}

/// Search polygons by RS/CS dag number.
final class PlotMapSearchRequested extends PlotMapEvent {
  const PlotMapSearchRequested(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}
