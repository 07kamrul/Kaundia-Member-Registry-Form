part of 'submissions_bloc.dart';

// ----- Submissions queue -----

sealed class SubmissionsEvent extends Equatable {
  const SubmissionsEvent();

  @override
  List<Object?> get props => const [];
}

final class SubmissionsLoadRequested extends SubmissionsEvent {
  const SubmissionsLoadRequested();
}

final class SubmissionsFilterChanged extends SubmissionsEvent {
  const SubmissionsFilterChanged(this.filter);

  final SubmissionStatus? filter;

  @override
  List<Object?> get props => [filter];
}
