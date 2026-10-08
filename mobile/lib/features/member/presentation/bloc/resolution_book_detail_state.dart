part of 'resolution_book_detail_bloc.dart';

class ResolutionBookDetailState extends Equatable {
  const ResolutionBookDetailState({
    this.status = ResolutionBookStatus.loading,
    this.meeting,
    this.error = false,
    this.pdfDownloading = false,
    this.exportError = false,
    this.pdfSavedPath,
    this.statusSavingId,
    this.statusSaveFailed = false,
  });

  final ResolutionBookStatus status;
  final MeetingDetail? meeting;
  final bool error;
  final bool pdfDownloading;
  final bool exportError;
  final String? pdfSavedPath;

  /// Resolution whose status is being updated (manage permission only).
  final String? statusSavingId;
  final bool statusSaveFailed;

  ResolutionBookDetailState copyWith({
    ResolutionBookStatus? status,
    MeetingDetail? meeting,
    bool clearError = false,
    bool? error,
    bool? pdfDownloading,
    bool clearExportError = false,
    bool? exportError,
    String? pdfSavedPath,
    bool clearPdfSavedPath = false,
    String? statusSavingId,
    bool clearStatusSaving = false,
    bool clearStatusSaveFailed = false,
    bool? statusSaveFailed,
  }) {
    return ResolutionBookDetailState(
      status: status ?? this.status,
      meeting: meeting ?? this.meeting,
      error: clearError ? false : (error ?? this.error),
      pdfDownloading: pdfDownloading ?? this.pdfDownloading,
      exportError: clearExportError ? false : (exportError ?? this.exportError),
      pdfSavedPath:
          clearPdfSavedPath ? null : (pdfSavedPath ?? this.pdfSavedPath),
      statusSavingId:
          clearStatusSaving ? null : (statusSavingId ?? this.statusSavingId),
      statusSaveFailed: clearStatusSaveFailed
          ? false
          : (statusSaveFailed ?? this.statusSaveFailed),
    );
  }

  @override
  List<Object?> get props => [
        status,
        meeting,
        error,
        pdfDownloading,
        exportError,
        pdfSavedPath,
        statusSavingId,
        statusSaveFailed,
      ];
}
