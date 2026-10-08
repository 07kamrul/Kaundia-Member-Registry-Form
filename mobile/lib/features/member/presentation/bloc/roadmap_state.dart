part of 'roadmap_bloc.dart';

enum RoadmapStatusFilter { all, inProgress, done, planned }

enum RoadmapPageStatus { loading, loaded, failure }

class RoadmapState extends Equatable {
  const RoadmapState({
    this.status = RoadmapPageStatus.loading,
    this.roadmap,
    this.error = false,
    this.filter = RoadmapStatusFilter.all,
    this.pdfDownloading = false,
    this.exportError = false,
    this.pdfSavedPath,
  });

  final RoadmapPageStatus status;
  final Roadmap? roadmap;
  final bool error;
  final RoadmapStatusFilter filter;
  final bool pdfDownloading;
  final bool exportError;
  final String? pdfSavedPath;

  int get currentIndex {
    final data = roadmap;
    return data == null ? 0 : currentTimeframeIndex(data);
  }

  int filterCount(RoadmapStatusFilter f) {
    final totals = roadmap?.totals;
    if (totals == null) return 0;
    return switch (f) {
      RoadmapStatusFilter.all => totals.total,
      RoadmapStatusFilter.done => totals.done,
      RoadmapStatusFilter.inProgress => totals.inProgress,
      RoadmapStatusFilter.planned => totals.planned,
    };
  }

  bool itemMatches(RoadmapStatus status) => switch (filter) {
        RoadmapStatusFilter.all => true,
        RoadmapStatusFilter.inProgress => status == RoadmapStatus.inProgress,
        RoadmapStatusFilter.done => status == RoadmapStatus.done,
        RoadmapStatusFilter.planned => status == RoadmapStatus.planned,
      };

  RoadmapState copyWith({
    RoadmapPageStatus? status,
    Roadmap? roadmap,
    bool clearError = false,
    bool? error,
    RoadmapStatusFilter? filter,
    bool? pdfDownloading,
    bool clearExportError = false,
    bool? exportError,
    String? pdfSavedPath,
    bool clearPdfSavedPath = false,
  }) {
    return RoadmapState(
      status: status ?? this.status,
      roadmap: roadmap ?? this.roadmap,
      error: clearError ? false : (error ?? this.error),
      filter: filter ?? this.filter,
      pdfDownloading: pdfDownloading ?? this.pdfDownloading,
      exportError: clearExportError ? false : (exportError ?? this.exportError),
      pdfSavedPath:
          clearPdfSavedPath ? null : (pdfSavedPath ?? this.pdfSavedPath),
    );
  }

  @override
  List<Object?> get props => [
        status,
        roadmap,
        error,
        filter,
        pdfDownloading,
        exportError,
        pdfSavedPath,
      ];
}
