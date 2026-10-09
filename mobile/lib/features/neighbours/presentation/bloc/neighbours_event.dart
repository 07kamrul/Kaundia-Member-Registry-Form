part of 'neighbours_bloc.dart';

sealed class NeighboursEvent extends Equatable {
  const NeighboursEvent();
  @override
  List<Object?> get props => const [];
}

/// Initial load and retry; uses the currently selected dag type.
final class NeighboursLoadRequested extends NeighboursEvent {
  const NeighboursLoadRequested();
}

final class NeighboursDagTypeChanged extends NeighboursEvent {
  const NeighboursDagTypeChanged(this.dagType);
  final DagType dagType;
  @override
  List<Object?> get props => [dagType];
}

/// Picks which own property's neighbours are shown (members with several plots).
final class NeighboursPropertySelected extends NeighboursEvent {
  const NeighboursPropertySelected(this.propertyId);
  final String propertyId;
  @override
  List<Object?> get props => [propertyId];
}
