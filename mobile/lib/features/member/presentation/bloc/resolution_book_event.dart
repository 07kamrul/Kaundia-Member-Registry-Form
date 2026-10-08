part of 'resolution_book_bloc.dart';

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
  List<Object?> get props =>
      [query, meetingType, meetingStatus, dateFrom, dateTo];
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
