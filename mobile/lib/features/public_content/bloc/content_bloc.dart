import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/content_repository.dart';
import '../domain/content_entities.dart';

// ---------------------------------------------------------------------------
// Notices
// ---------------------------------------------------------------------------

sealed class NoticesEvent extends Equatable {
  const NoticesEvent();
  @override
  List<Object?> get props => const [];
}

final class NoticesRequested extends NoticesEvent {
  const NoticesRequested();
}

sealed class NoticesState extends Equatable {
  const NoticesState();
  @override
  List<Object?> get props => const [];
}

class NoticesInitial extends NoticesState {
  const NoticesInitial();
}

class NoticesLoading extends NoticesState {
  const NoticesLoading();
}

class NoticesLoaded extends NoticesState {
  const NoticesLoaded({required this.notices});
  final List<Notice> notices;
  @override
  List<Object?> get props => [notices];
}

class NoticesFailure extends NoticesState {
  const NoticesFailure({required this.error});
  final ApiException error;
  @override
  List<Object?> get props => [error];
}

class NoticesBloc extends Bloc<NoticesEvent, NoticesState> {
  NoticesBloc({ContentRepository? repository})
      : _repo = repository ?? ContentRepository(apiClient: sl<ApiClient>()),
        super(const NoticesInitial()) {
    on<NoticesRequested>(_onRequested);
  }

  final ContentRepository _repo;

  Future<void> _onRequested(NoticesRequested e, Emitter<NoticesState> emit) async {
    emit(const NoticesLoading());
    try {
      final notices = await _repo.listNotices();
      emit(NoticesLoaded(notices: notices));
    } on ApiException catch (err) {
      emit(NoticesFailure(error: err));
    }
  }
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class EventsEvent extends Equatable {
  const EventsEvent();
  @override
  List<Object?> get props => const [];
}

final class EventsRequested extends EventsEvent {
  const EventsRequested();
}

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

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  EventsBloc({ContentRepository? repository, DateTime? now})
      : _repo = repository ?? ContentRepository(apiClient: sl<ApiClient>()),
        super(const EventsInitial()) {
    on<EventsRequested>(_onRequested);
  }

  final ContentRepository _repo;

  Future<void> _onRequested(EventsRequested e, Emitter<EventsState> emit) async {
    emit(const EventsLoading());
    try {
      final events = await _repo.listEvents();
      emit(EventsLoaded(events: events, now: DateTime.now()));
    } on ApiException catch (err) {
      emit(EventsFailure(error: err));
    }
  }
}
