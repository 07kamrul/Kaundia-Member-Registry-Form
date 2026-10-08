part of 'roadmap_bloc.dart';

class RoadmapState extends Equatable {
  const RoadmapState({
    this.roadmap,
    this.loading = true,
    this.loadError,
    this.busyItemId,
    this.actionError,
    this.history,
    this.archiveCount,
  });

  final Roadmap? roadmap;
  final bool loading;
  final Object? loadError;

  /// Item currently being mutated (status/reorder/delete).
  final int? busyItemId;
  final Object? actionError;

  /// Archived cycles (lazy-loaded).
  final List<RoadmapArchivedCycle>? history;

  /// Set after a successful archive with the number of archived items.
  final int? archiveCount;

  RoadmapState copyWith({
    Roadmap? Function()? roadmap,
    bool? loading,
    Object? Function()? loadError,
    int? Function()? busyItemId,
    Object? Function()? actionError,
    List<RoadmapArchivedCycle>? history,
    int? Function()? archiveCount,
  }) =>
      RoadmapState(
        roadmap: roadmap == null ? this.roadmap : roadmap(),
        loading: loading ?? this.loading,
        loadError: loadError == null ? this.loadError : loadError(),
        busyItemId: busyItemId == null ? this.busyItemId : busyItemId(),
        actionError: actionError == null ? this.actionError : actionError(),
        history: history ?? this.history,
        archiveCount: archiveCount == null ? this.archiveCount : archiveCount(),
      );

  @override
  List<Object?> get props => [
        roadmap,
        loading,
        loadError,
        busyItemId,
        actionError,
        history,
        archiveCount,
      ];
}
