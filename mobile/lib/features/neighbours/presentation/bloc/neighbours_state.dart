part of 'neighbours_bloc.dart';

enum NeighboursStatus { loading, loaded, empty, failure }

class NeighboursState extends Equatable {
  const NeighboursState({
    this.status = NeighboursStatus.loading,
    this.directory,
    this.dagType,
    this.selectedPropertyId,
    this.failureKind,
  });

  final NeighboursStatus status;
  final NeighbourDirectory? directory;

  /// Requested dag type; null until the server picks the member's default.
  final DagType? dagType;
  final String? selectedPropertyId;
  final NeighboursFailureKind? failureKind;

  NeighbourGroup? get selectedGroup {
    final groups = directory?.properties ?? const <NeighbourGroup>[];
    for (final g in groups) {
      if (g.own.propertyId == selectedPropertyId) return g;
    }
    return groups.isEmpty ? null : groups.first;
  }

  NeighboursState copyWith({
    NeighboursStatus? status,
    NeighbourDirectory? directory,
    DagType? dagType,
    String? selectedPropertyId,
    bool clearSelectedProperty = false,
    NeighboursFailureKind? failureKind,
    bool clearFailure = false,
  }) {
    return NeighboursState(
      status: status ?? this.status,
      directory: directory ?? this.directory,
      dagType: dagType ?? this.dagType,
      selectedPropertyId: clearSelectedProperty
          ? null
          : (selectedPropertyId ?? this.selectedPropertyId),
      failureKind: clearFailure ? null : (failureKind ?? this.failureKind),
    );
  }

  @override
  List<Object?> get props =>
      [status, directory, dagType, selectedPropertyId, failureKind];
}
