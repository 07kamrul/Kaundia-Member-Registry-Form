import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/resolution_book_repository.dart';
import '../../domain/resolution_book_entities.dart';

// ---------------------------------------------------------------------------
// Form state helpers
// ---------------------------------------------------------------------------

class FormResolutionRow extends Equatable {
  const FormResolutionRow({
    this.decision = '',
    this.voteFor = 0,
    this.voteAgainst = 0,
    this.voteNeutral = 0,
    this.task = '',
    this.dueDate = '',
  });

  final String decision;
  final int voteFor;
  final int voteAgainst;
  final int voteNeutral;
  final String task;
  final String dueDate;

  bool get isValid => decision.trim().isNotEmpty && votesValid;
  bool get votesValid => voteFor + voteAgainst + voteNeutral >= 0;

  FormResolutionRow copyWith({
    String? decision,
    int? voteFor,
    int? voteAgainst,
    int? voteNeutral,
    String? task,
    String? dueDate,
  }) {
    return FormResolutionRow(
      decision: decision ?? this.decision,
      voteFor: voteFor ?? this.voteFor,
      voteAgainst: voteAgainst ?? this.voteAgainst,
      voteNeutral: voteNeutral ?? this.voteNeutral,
      task: task ?? this.task,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  @override
  List<Object?> get props => [decision, voteFor, voteAgainst, voteNeutral, task, dueDate];
}

// Events --------------------------------------------------------------------

sealed class ResolutionBookFormEvent extends Equatable {
  const ResolutionBookFormEvent();

  @override
  List<Object?> get props => const [];
}

class ResolutionBookFormInitialized extends ResolutionBookFormEvent {
  const ResolutionBookFormInitialized({this.editId});

  final String? editId;

  @override
  List<Object?> get props => [editId];
}

class ResolutionBookFormSuggestedNoRequested extends ResolutionBookFormEvent {
  const ResolutionBookFormSuggestedNoRequested(this.forDate);

  final String forDate;

  @override
  List<Object?> get props => [forDate];
}

class ResolutionBookFormChanged extends ResolutionBookFormEvent {
  const ResolutionBookFormChanged({
    this.meetingNo,
    this.date,
    this.time,
    this.meetingType,
    this.chairperson,
    this.agenda,
    this.summary,
    this.nextMeetingDate,
    this.status,
  });

  final String? meetingNo;
  final String? date;
  final String? time;
  final MeetingType? meetingType;
  final String? chairperson;
  final String? agenda;
  final String? summary;
  final String? nextMeetingDate;
  final MeetingStatus? status;

  @override
  List<Object?> get props => [
        meetingNo, date, time, meetingType, chairperson, agenda, summary,
        nextMeetingDate, status,
      ];
}

class ResolutionBookFormResolutionAdded extends ResolutionBookFormEvent {
  const ResolutionBookFormResolutionAdded();
}

class ResolutionBookFormResolutionRemoved extends ResolutionBookFormEvent {
  const ResolutionBookFormResolutionRemoved(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

class ResolutionBookFormResolutionChanged extends ResolutionBookFormEvent {
  const ResolutionBookFormResolutionChanged(this.index, this.row);

  final int index;
  final FormResolutionRow row;

  @override
  List<Object?> get props => [index, row];
}

class ResolutionBookFormSubmitted extends ResolutionBookFormEvent {
  const ResolutionBookFormSubmitted();
}

// State ---------------------------------------------------------------------

enum ResolutionBookFormStatus { idle, loading, ready, submitting, success, failure }

class ResolutionBookFormState extends Equatable {
  const ResolutionBookFormState({
    this.status = ResolutionBookFormStatus.idle,
    this.editId,
    this.loadedMeeting,
    this.meetingNo = '',
    this.date = '',
    this.time = '',
    this.meetingType = MeetingType.offline,
    this.chairperson = '',
    this.agenda = '',
    this.summary = '',
    this.nextMeetingDate = '',
    this.status_ = MeetingStatus.completed,
    this.resolutions = const [],
    this.submitAttempted = false,
    this.submitError,
  });

  final ResolutionBookFormStatus status;
  final String? editId;
  final MeetingDetail? loadedMeeting;

  final String meetingNo;
  final String date;
  final String time;
  final MeetingType meetingType;
  final String chairperson;
  final String agenda;
  final String summary;
  final String nextMeetingDate;
  final MeetingStatus status_;
  final List<FormResolutionRow> resolutions;
  final bool submitAttempted;
  final String? submitError;

  bool get isEdit => editId != null;

  bool get formValid =>
      date.isNotEmpty &&
      chairperson.trim().isNotEmpty &&
      agenda.trim().isNotEmpty &&
      resolutions.isNotEmpty &&
      resolutions.every((r) => r.isValid);

  ResolutionBookFormState copyWith({
    ResolutionBookFormStatus? status,
    String? editId,
    bool clearEditId = false,
    MeetingDetail? loadedMeeting,
    String? meetingNo,
    String? date,
    String? time,
    MeetingType? meetingType,
    String? chairperson,
    String? agenda,
    String? summary,
    String? nextMeetingDate,
    MeetingStatus? status_,
    List<FormResolutionRow>? resolutions,
    bool? submitAttempted,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return ResolutionBookFormState(
      status: status ?? this.status,
      editId: clearEditId ? null : (editId ?? this.editId),
      loadedMeeting: loadedMeeting ?? this.loadedMeeting,
      meetingNo: meetingNo ?? this.meetingNo,
      date: date ?? this.date,
      time: time ?? this.time,
      meetingType: meetingType ?? this.meetingType,
      chairperson: chairperson ?? this.chairperson,
      agenda: agenda ?? this.agenda,
      summary: summary ?? this.summary,
      nextMeetingDate: nextMeetingDate ?? this.nextMeetingDate,
      status_: status_ ?? this.status_,
      resolutions: resolutions ?? this.resolutions,
      submitAttempted: submitAttempted ?? this.submitAttempted,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }

  @override
  List<Object?> get props => [
        status, editId, loadedMeeting, meetingNo, date, time, meetingType,
        chairperson, agenda, summary, nextMeetingDate, status_, resolutions,
        submitAttempted, submitError,
      ];
}

class ResolutionBookFormBloc
    extends Bloc<ResolutionBookFormEvent, ResolutionBookFormState> {
  ResolutionBookFormBloc({ResolutionBookRepository? repository})
      : _repository = repository ?? ResolutionBookRepository(apiClient: sl<ApiClient>()),
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
      emit(state.copyWith(status: ResolutionBookFormStatus.ready, clearEditId: true));
      return;
    }
    emit(state.copyWith(status: ResolutionBookFormStatus.loading, editId: editId));
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
        meetingNo: state.meetingNo.trim().isEmpty ? null : state.meetingNo.trim(),
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
