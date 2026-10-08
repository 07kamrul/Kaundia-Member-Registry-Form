part of 'resolution_book_detail_bloc.dart';

sealed class ResolutionBookDetailEvent extends Equatable {
  const ResolutionBookDetailEvent();

  @override
  List<Object?> get props => const [];
}

final class ResolutionBookDetailLoadRequested
    extends ResolutionBookDetailEvent {
  const ResolutionBookDetailLoadRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class ResolutionBookDetailPdfDownloadRequested
    extends ResolutionBookDetailEvent {
  const ResolutionBookDetailPdfDownloadRequested();
}

final class ResolutionBookDetailPdfSavedPathCleared
    extends ResolutionBookDetailEvent {
  const ResolutionBookDetailPdfSavedPathCleared();
}

final class ResolutionBookDetailResolutionStatusChanged
    extends ResolutionBookDetailEvent {
  const ResolutionBookDetailResolutionStatusChanged(
      this.resolutionId, this.status);

  final String resolutionId;
  final ResolutionStatus status;

  @override
  List<Object?> get props => [resolutionId, status];
}
