part of 'resolution_book_bloc.dart';

enum ResolutionBookStatus { loading, loaded, failure }

class ResolutionBookState extends Equatable {
  const ResolutionBookState({
    this.status = ResolutionBookStatus.loading,
    this.summary,
    this.error = false,
    this.meetings = const [],
    this.total = 0,
    this.listLoading = false,
    this.query = '',
    this.meetingType = '',
    this.meetingStatus = '',
    this.dateFrom = '',
    this.dateTo = '',
    this.page = 0,
    this.pageSize = 10,
  });

  final ResolutionBookStatus status;
  final MeetingSummary? summary;
  final bool error;
  final List<MeetingListItem> meetings;
  final int total;
  final bool listLoading;
  final String query;
  final String meetingType;
  final String meetingStatus;
  final String dateFrom;
  final String dateTo;
  final int page;
  final int pageSize;

  int get totalPages => (total + pageSize - 1) ~/ pageSize;

  bool get hasFilters =>
      query.trim().isNotEmpty ||
      meetingType.isNotEmpty ||
      meetingStatus.isNotEmpty ||
      dateFrom.isNotEmpty ||
      dateTo.isNotEmpty;

  ResolutionBookState copyWith({
    ResolutionBookStatus? status,
    MeetingSummary? summary,
    bool clearError = false,
    bool? error,
    List<MeetingListItem>? meetings,
    int? total,
    bool? listLoading,
    String? query,
    String? meetingType,
    String? meetingStatus,
    String? dateFrom,
    String? dateTo,
    int? page,
  }) {
    return ResolutionBookState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      error: clearError ? false : (error ?? this.error),
      meetings: meetings ?? this.meetings,
      total: total ?? this.total,
      listLoading: listLoading ?? this.listLoading,
      query: query ?? this.query,
      meetingType: meetingType ?? this.meetingType,
      meetingStatus: meetingStatus ?? this.meetingStatus,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      page: page ?? this.page,
      pageSize: pageSize,
    );
  }

  @override
  List<Object?> get props => [
        status,
        summary,
        error,
        meetings,
        total,
        listLoading,
        query,
        meetingType,
        meetingStatus,
        dateFrom,
        dateTo,
        page,
        pageSize,
      ];
}
