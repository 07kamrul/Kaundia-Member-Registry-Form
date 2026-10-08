import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/resolution_book_repository.dart';
import '../../domain/resolution_book_entities.dart';

part 'resolution_book_form_event.dart';
part 'resolution_book_form_state.dart';

class ResolutionBookFormBloc
    extends Bloc<ResolutionBookFormEvent, ResolutionBookFormState> {
  ResolutionBookFormBloc({ResolutionBookRepository? repository})
      : _repository =
            repository ?? ResolutionBookRepository(apiClient: sl<ApiClient>()),
        super(const ResolutionBookFormState()) {
    on<ResolutionBookFormInitialized>(_onInitialized);
    on<ResolutionBookFormSuggestedNoRequested>(_onSuggestNo);
    on<ResolutionBookFormChanged>(_onChanged);
    on<ResolutionBookFormResolutionAdded>(_onResolutionAdded);
    on<ResolutionBookFormResolutionRemoved>(_onResolutionRemoved);
    on<ResolutionBookFormResolutionChanged>(_onResolutionChanged);
    on<ResolutionBookFormSubmitted>(_onSubmitted);
  }

  final ResolutionBookRepository _repository;

  Future<void> _onInitialized(
    ResolutionBookFormInitialized event,
    Emitter<ResolutionBookFormState> emit,
  ) async {
    final editId = event.editId;
    if (editId == null) {
      emit(state.copyWith(
          status: ResolutionBookFormStatus.ready, clearEditId: true));
      return;
    }
    emit(state.copyWith(
        status: ResolutionBookFormStatus.loading, editId: editId));
    try {
      final meeting = await _repository.getMeeting(editId);
      emit(ResolutionBookFormState(
        status: ResolutionBookFormStatus.ready,
        editId: editId,
        loadedMeeting: meeting,
        meetingNo: meeting.meetingNo,
        date: meeting.date,
        time: meeting.time ?? '',
        meetingType: meeting.meetingType,
        chairperson: meeting.chairperson,
        agenda: meeting.agenda,
        summary: meeting.summary ?? '',
        nextMeetingDate: meeting.nextMeetingDate ?? '',
        status_: meeting.status,
        resolutions: [
          for (final r in meeting.resolutions)
            FormResolutionRow(
              decision: r.decision,
              voteFor: r.voteFor,
              voteAgainst: r.voteAgainst,
              voteNeutral: r.voteNeutral,
              task: r.task ?? '',
              dueDate: r.dueDate ?? '',
            ),
        ],
      ));
    } on ApiException {
      emit(state.copyWith(status: ResolutionBookFormStatus.failure));
    }
  }

  Future<void> _onSuggestNo(
    ResolutionBookFormSuggestedNoRequested event,
    Emitter<ResolutionBookFormState> emit,
  ) async {
    try {
      final suggestion = await _repository.suggestMeetingNo(event.forDate);
      if (suggestion.available) {
        emit(state.copyWith(meetingNo: suggestion.meetingNo));
      }
    } on ApiException {
      // Suggestion is a nicety; ignore failures.
    }
  }

  void _onChanged(
    ResolutionBookFormChanged event,
    Emitter<ResolutionBookFormState> emit,
  ) {
    emit(state.copyWith(
      meetingNo: event.meetingNo,
      date: event.date,
      time: event.time,
      meetingType: event.meetingType,
      chairperson: event.chairperson,
      agenda: event.agenda,
      summary: event.summary,
      nextMeetingDate: event.nextMeetingDate,
      status_: event.status,
      clearSubmitError: true,
    ));
  }

  void _onResolutionAdded(
    ResolutionBookFormResolutionAdded event,
    Emitter<ResolutionBookFormState> emit,
  ) {
    emit(state.copyWith(
      resolutions: [...state.resolutions, const FormResolutionRow()],
      clearSubmitError: true,
    ));
  }

  void _onResolutionRemoved(
    ResolutionBookFormResolutionRemoved event,
    Emitter<ResolutionBookFormState> emit,
  ) {
    final rows = [...state.resolutions]..removeAt(event.index);
    emit(state.copyWith(resolutions: rows, clearSubmitError: true));
  }

  void _onResolutionChanged(
    ResolutionBookFormResolutionChanged event,
    Emitter<ResolutionBookFormState> emit,
  ) {
    final rows = [...state.resolutions];
    if (event.index < 0 || event.index >= rows.length) return;
    rows[event.index] = event.row;
    emit(state.copyWith(resolutions: rows, clearSubmitError: true));
  }

  Future<void> _onSubmitted(
    ResolutionBookFormSubmitted event,
    Emitter<ResolutionBookFormState> emit,
  ) async {
    emit(state.copyWith(submitAttempted: true, clearSubmitError: true));
    if (!state.formValid) return;
    emit(state.copyWith(status: ResolutionBookFormStatus.submitting));
    try {
      final input = MeetingCreateInput(
        meetingNo:
            state.meetingNo.trim().isEmpty ? null : state.meetingNo.trim(),
        date: state.date,
        time: state.time.trim().isEmpty ? null : state.time.trim(),
        meetingType: state.meetingType,
        chairperson: state.chairperson.trim(),
        agenda: state.agenda.trim(),
        summary: state.summary.trim().isEmpty ? null : state.summary.trim(),
        nextMeetingDate:
            state.nextMeetingDate.isEmpty ? null : state.nextMeetingDate,
        status: state.status_,
        resolutions: [
          for (final r in state.resolutions)
            ResolutionInput(
              decision: r.decision.trim(),
              voteFor: r.voteFor,
              voteAgainst: r.voteAgainst,
              voteNeutral: r.voteNeutral,
              task: r.task.trim().isEmpty ? null : r.task.trim(),
              dueDate: r.dueDate.isEmpty ? null : r.dueDate,
              status: ResolutionStatus.pending,
            ),
        ],
        attendance: const [],
      );
      if (state.isEdit) {
        await _repository.updateMeeting(state.editId!, input);
      } else {
        await _repository.createMeeting(input);
      }
      emit(state.copyWith(status: ResolutionBookFormStatus.success));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: ResolutionBookFormStatus.ready,
        submitError: e.isBusiness && e.businessMessage != null
            ? e.businessMessage
            : 'submitError',
      ));
    }
  }
}
