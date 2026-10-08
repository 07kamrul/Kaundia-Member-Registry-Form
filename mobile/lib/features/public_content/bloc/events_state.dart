part of 'events_bloc.dart';

sealed class EventsState extends Equatable {
  const EventsState();
  @override
  List<Object?> get props => const [];
}

class EventsInitial extends EventsState {
  const EventsInitial();
}

class EventsLoading extends EventsState {
  const EventsLoading();
}

class EventsLoaded extends EventsState {
  const EventsLoaded({required this.events, required this.now});
  final List<EventItem> events;
  final DateTime now;

  /// The endpoint returns upcoming rows first; a single pass over the response
  /// keeps both sections in the server's order (mirrors Angular component).
  List<EventItem> get upcoming =>
      events.where((row) => _parse(row.startAt).isAfter(now)).toList();
  List<EventItem> get past =>
      events.where((row) => !_parse(row.startAt).isAfter(now)).toList();

  DateTime _parse(String iso) => DateTime.tryParse(iso) ?? DateTime(1970);

  @override
  List<Object?> get props => [events, now];
}

class EventsFailure extends EventsState {
  const EventsFailure({required this.error});
  final ApiException error;
  @override
  List<Object?> get props => [error];
}
