part of 'roadmap_bloc.dart';

sealed class RoadmapEvent extends Equatable {
  const RoadmapEvent();
  @override
  List<Object?> get props => const [];
}

final class RoadmapLoadRequested extends RoadmapEvent {
  const RoadmapLoadRequested();
}

final class RoadmapFilterChanged extends RoadmapEvent {
  const RoadmapFilterChanged(this.filter);
  final RoadmapStatusFilter filter;
  @override
  List<Object?> get props => [filter];
}

final class RoadmapPdfDownloadRequested extends RoadmapEvent {
  const RoadmapPdfDownloadRequested();
}

final class RoadmapPdfSavedPathCleared extends RoadmapEvent {
  const RoadmapPdfSavedPathCleared();
}
