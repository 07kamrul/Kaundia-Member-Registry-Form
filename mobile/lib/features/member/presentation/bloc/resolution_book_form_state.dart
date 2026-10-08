part of 'resolution_book_form_bloc.dart';

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
  List<Object?> get props =>
      [decision, voteFor, voteAgainst, voteNeutral, task, dueDate];
}

enum ResolutionBookFormStatus {
  idle,
  loading,
  ready,
  submitting,
  success,
  failure
}

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
        status,
        editId,
        loadedMeeting,
        meetingNo,
        date,
        time,
        meetingType,
        chairperson,
        agenda,
        summary,
        nextMeetingDate,
        status_,
        resolutions,
        submitAttempted,
        submitError,
      ];
}
