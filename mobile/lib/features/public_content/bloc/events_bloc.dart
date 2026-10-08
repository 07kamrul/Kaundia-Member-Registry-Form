import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/content_repository.dart';
import '../domain/content_entities.dart';

part 'events_event.dart';
part 'events_state.dart';

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
