part of 'events_bloc.dart';

// ----- Events -----

sealed class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => const [];
}

final class EventsInitRequested extends EventsEvent {
  const EventsInitRequested();
}

final class EventsLoadRequested extends EventsEvent {
  const EventsLoadRequested();
}

final class EventsStatusFilterChanged extends EventsEvent {
  const EventsStatusFilterChanged(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

final class EventsCategoryFilterChanged extends EventsEvent {
  const EventsCategoryFilterChanged(this.categoryId);

  final String? categoryId;

  @override
  List<Object?> get props => [categoryId];
}

final class EventSaveRequested extends EventsEvent {
  const EventSaveRequested(
      {required this.payload, this.editingId, this.completer});

  final EventInput payload;
  final String? editingId;

  /// Optional result channel: true when saved.
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [payload, editingId];
}

final class EventPublishToggled extends EventsEvent {
  const EventPublishToggled(this.event);

  final EventItem event;

  @override
  List<Object?> get props => [event];
}

final class EventDeleteRequested extends EventsEvent {
  const EventDeleteRequested(this.event);

  final EventItem event;

  @override
  List<Object?> get props => [event];
}
