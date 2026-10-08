part of 'resolution_book_form_bloc.dart';

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
        meetingNo,
        date,
        time,
        meetingType,
        chairperson,
        agenda,
        summary,
        nextMeetingDate,
        status,
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
