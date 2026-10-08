part of 'events_bloc.dart';

sealed class EventsEvent extends Equatable {
  const EventsEvent();
  @override
  List<Object?> get props => const [];
}

final class EventsRequested extends EventsEvent {
  const EventsRequested();
}
