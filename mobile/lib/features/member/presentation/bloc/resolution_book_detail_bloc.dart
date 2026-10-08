import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/utils/download_utils.dart';
import '../../data/resolution_book_repository.dart';
import '../../domain/resolution_book_entities.dart';
import 'resolution_book_bloc.dart' show ResolutionBookStatus;

export 'resolution_book_bloc.dart' show ResolutionBookStatus;

part 'resolution_book_detail_event.dart';
part 'resolution_book_detail_state.dart';

class ResolutionBookDetailBloc
    extends Bloc<ResolutionBookDetailEvent, ResolutionBookDetailState> {
  ResolutionBookDetailBloc({ResolutionBookRepository? repository})
      : _repository =
            repository ?? ResolutionBookRepository(apiClient: sl<ApiClient>()),
        super(const ResolutionBookDetailState()) {
    on<ResolutionBookDetailLoadRequested>(_onLoadRequested);
    on<ResolutionBookDetailPdfDownloadRequested>(_onPdfDownloadRequested);
    on<ResolutionBookDetailPdfSavedPathCleared>(_onPdfSavedPathCleared);
    on<ResolutionBookDetailResolutionStatusChanged>(_onResolutionStatusChanged);
  }

  final ResolutionBookRepository _repository;

  Future<void> _onLoadRequested(
    ResolutionBookDetailLoadRequested event,
    Emitter<ResolutionBookDetailState> emit,
  ) async {
    emit(
        state.copyWith(status: ResolutionBookStatus.loading, clearError: true));
    try {
      final meeting = await _repository.getMeeting(event.id);
      emit(state.copyWith(
          status: ResolutionBookStatus.loaded,
          meeting: meeting,
          clearError: true));
    } on ApiException {
      emit(state.copyWith(status: ResolutionBookStatus.failure, error: true));
    }
  }

  Future<void> _onPdfDownloadRequested(
    ResolutionBookDetailPdfDownloadRequested event,
    Emitter<ResolutionBookDetailState> emit,
  ) async {
    final meeting = state.meeting;
    if (meeting == null || state.pdfDownloading) return;
    emit(state.copyWith(
        pdfDownloading: true, clearExportError: true, clearPdfSavedPath: true));
    try {
      final bytes = await _repository.downloadPdf(meeting.id);
      final file = await saveDownload(bytes,
          'minutes-${meeting.meetingNo.isEmpty ? meeting.id : meeting.meetingNo}.pdf');
      emit(state.copyWith(pdfDownloading: false, pdfSavedPath: file.path));
    } on ApiException {
      emit(state.copyWith(pdfDownloading: false, exportError: true));
    }
  }

  void _onPdfSavedPathCleared(
    ResolutionBookDetailPdfSavedPathCleared event,
    Emitter<ResolutionBookDetailState> emit,
  ) {
    emit(state.copyWith(clearPdfSavedPath: true));
  }

  Future<void> _onResolutionStatusChanged(
    ResolutionBookDetailResolutionStatusChanged event,
    Emitter<ResolutionBookDetailState> emit,
  ) async {
    emit(state.copyWith(
        statusSavingId: event.resolutionId, clearStatusSaveFailed: true));
    try {
      final updated = await _repository.updateResolutionStatus(
          event.resolutionId, event.status);
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
