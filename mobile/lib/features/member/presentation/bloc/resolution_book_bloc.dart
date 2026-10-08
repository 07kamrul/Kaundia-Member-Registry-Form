import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/utils/download_utils.dart';
import '../../data/resolution_book_repository.dart';
import '../../domain/resolution_book_entities.dart';

// ---------------------------------------------------------------------------
// List bloc
// ---------------------------------------------------------------------------

sealed class ResolutionBookEvent extends Equatable {
  const ResolutionBookEvent();

  @override
  List<Object?> get props => const [];
}

class ResolutionBookLoaded extends ResolutionBookEvent {
  const ResolutionBookLoaded();
}

class ResolutionBookFiltersChanged extends ResolutionBookEvent {
  const ResolutionBookFiltersChanged({
    this.query,
    this.meetingType,
    this.meetingStatus,
    this.dateFrom,
    this.dateTo,
  });

  final String? query;
  final String? meetingType; // '' | 'online' | 'offline'
  final String? meetingStatus; // '' | 'scheduled' | 'completed' | 'cancelled'
  final String? dateFrom;
  final String? dateTo;

  @override
  List<Object?> get props => [query, meetingType, meetingStatus, dateFrom, dateTo];
}

class ResolutionBookFiltersCleared extends ResolutionBookEvent {
  const ResolutionBookFiltersCleared();
}

class ResolutionBookPageChanged extends ResolutionBookEvent {
  const ResolutionBookPageChanged(this.target);

  final int target;

  @override
  List<Object?> get props => [target];
}

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
        status, summary, error, meetings, total, listLoading, query,
        meetingType, meetingStatus, dateFrom, dateTo, page, pageSize,
      ];
}

class ResolutionBookBloc extends Bloc<ResolutionBookEvent, ResolutionBookState> {
  ResolutionBookBloc({ResolutionBookRepository? repository})
      : _repository = repository ?? ResolutionBookRepository(apiClient: sl<ApiClient>()),
        super(const ResolutionBookState()) {
    on<ResolutionBookLoaded>(_onLoaded);
    on<ResolutionBookFiltersChanged>(_onFiltersChanged);
    on<ResolutionBookFiltersCleared>(_onFiltersCleared);
    on<ResolutionBookPageChanged>(_onPageChanged);
  }

  final ResolutionBookRepository _repository;

  Future<void> _onLoaded(
    ResolutionBookLoaded event,
    Emitter<ResolutionBookState> emit,
  ) async {
    emit(state.copyWith(status: ResolutionBookStatus.loading, clearError: true));
    try {
      final summary = await _repository.summary();
      emit(state.copyWith(status: ResolutionBookStatus.loaded, summary: summary, clearError: true));
    } on ApiException {
      emit(state.copyWith(status: ResolutionBookStatus.failure, error: true));
    }
    await _loadMeetings(emit, page: 0);
  }

  Future<void> _onFiltersChanged(
    ResolutionBookFiltersChanged event,
    Emitter<ResolutionBookState> emit,
  ) async {
    emit(state.copyWith(
      query: event.query,
      meetingType: event.meetingType,
      meetingStatus: event.meetingStatus,
      dateFrom: event.dateFrom,
      dateTo: event.dateTo,
      page: 0,
      listLoading: true,
    ));
    await _loadMeetings(emit, page: 0);
  }

  Future<void> _onFiltersCleared(
    ResolutionBookFiltersCleared event,
    Emitter<ResolutionBookState> emit,
  ) async {
    emit(state.copyWith(
      query: '',
      meetingType: '',
      meetingStatus: '',
      dateFrom: '',
      dateTo: '',
      page: 0,
      listLoading: true,
    ));
    await _loadMeetings(emit, page: 0);
  }

  Future<void> _onPageChanged(
    ResolutionBookPageChanged event,
    Emitter<ResolutionBookState> emit,
  ) async {
    final clamped = event.target.clamp(0, state.totalPages - 1);
    emit(state.copyWith(page: clamped, listLoading: true));
    await _loadMeetings(emit, page: clamped);
  }

  Future<void> _loadMeetings(
    Emitter<ResolutionBookState> emit, {
    required int page,
  }) async {
    try {
      final result = await _repository.listMeetings(
        q: state.query.trim().isEmpty ? null : state.query.trim(),
        meetingType: state.meetingType.isEmpty ? null : state.meetingType,
        meetingStatus: state.meetingStatus.isEmpty ? null : state.meetingStatus,
        dateFrom: state.dateFrom.isEmpty ? null : state.dateFrom,
        dateTo: state.dateTo.isEmpty ? null : state.dateTo,
        limit: state.pageSize,
        offset: page * state.pageSize,
      );
      emit(state.copyWith(
        meetings: result.items,
        total: result.total,
        page: page,
        listLoading: false,
        clearError: true,
      ));
    } on ApiException {
      emit(state.copyWith(listLoading: false, error: true));
    }
  }
}

// ---------------------------------------------------------------------------
// Detail cubit
// ---------------------------------------------------------------------------

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
      pdfSavedPath: clearPdfSavedPath ? null : (pdfSavedPath ?? this.pdfSavedPath),
      statusSavingId: clearStatusSaving ? null : (statusSavingId ?? this.statusSavingId),
      statusSaveFailed: clearStatusSaveFailed ? false : (statusSaveFailed ?? this.statusSaveFailed),
    );
  }

  @override
  List<Object?> get props => [
        status, meeting, error, pdfDownloading, exportError, pdfSavedPath,
        statusSavingId, statusSaveFailed,
      ];
}

class ResolutionBookDetailCubit extends Cubit<ResolutionBookDetailState> {
  ResolutionBookDetailCubit({ResolutionBookRepository? repository})
      : _repository = repository ?? ResolutionBookRepository(apiClient: sl<ApiClient>()),
        super(const ResolutionBookDetailState());

  final ResolutionBookRepository _repository;

  Future<void> load(String id) async {
    emit(state.copyWith(status: ResolutionBookStatus.loading, clearError: true));
    try {
      final meeting = await _repository.getMeeting(id);
      emit(state.copyWith(status: ResolutionBookStatus.loaded, meeting: meeting, clearError: true));
    } on ApiException {
      emit(state.copyWith(status: ResolutionBookStatus.failure, error: true));
    }
  }

  Future<void> downloadPdf() async {
    final meeting = state.meeting;
    if (meeting == null || state.pdfDownloading) return;
    emit(state.copyWith(pdfDownloading: true, clearExportError: true, clearPdfSavedPath: true));
    try {
      final bytes = await _repository.downloadPdf(meeting.id);
      final file = await saveDownload(bytes, 'minutes-${meeting.meetingNo.isEmpty ? meeting.id : meeting.meetingNo}.pdf');
      emit(state.copyWith(pdfDownloading: false, pdfSavedPath: file.path));
    } on ApiException {
      emit(state.copyWith(pdfDownloading: false, exportError: true));
    }
  }

  void clearPdfSavedPath() => emit(state.copyWith(clearPdfSavedPath: true));

  Future<void> setResolutionStatus(String resolutionId, ResolutionStatus status) async {
    emit(state.copyWith(statusSavingId: resolutionId, clearStatusSaveFailed: true));
    try {
      final updated = await _repository.updateResolutionStatus(resolutionId, status);
      final meeting = state.meeting;
      if (meeting != null) {
        emit(state.copyWith(
          meeting: MeetingDetailShim.apply(meeting, updated),
          clearStatusSaving: true,
        ));
      } else {
        emit(state.copyWith(clearStatusSaving: true));
      }
    } on ApiException {
      emit(state.copyWith(clearStatusSaving: true, statusSaveFailed: true));
    }
  }
}

/// Pure helper replacing the Angular spread-update idiom.
class MeetingDetailShim {
  const MeetingDetailShim._();

  static MeetingDetail apply(MeetingDetail meeting, Resolution updated) {
    return MeetingDetail(
      id: meeting.id,
      meetingNo: meeting.meetingNo,
      date: meeting.date,
      time: meeting.time,
      meetingType: meeting.meetingType,
      chairperson: meeting.chairperson,
      nextMeetingDate: meeting.nextMeetingDate,
      status: meeting.status,
      resolutionCount: meeting.resolutionCount,
      attendancePresent: meeting.attendancePresent,
      attendanceTotal: meeting.attendanceTotal,
      attendancePercent: meeting.attendancePercent,
      agenda: meeting.agenda,
      summary: meeting.summary,
      createdBy: meeting.createdBy,
      updatedAt: meeting.updatedAt,
      resolutions: [
        for (final r in meeting.resolutions) r.id == updated.id ? updated : r,
      ],
      attendance: meeting.attendance,
      recordings: meeting.recordings,
    );
  }
}
