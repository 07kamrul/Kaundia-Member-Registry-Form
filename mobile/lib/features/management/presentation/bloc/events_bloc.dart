// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';
import 'content_list_state.dart';
export 'content_list_state.dart';

part 'events_event.dart';
part 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, ContentListState<EventItem>> {
  EventsBloc({required AdminRepository repository})
      : _repository = repository,
        super(const ContentListData<EventItem>()) {
    on<EventsInitRequested>((event, emit) => _init(emit));
    on<EventsLoadRequested>((event, emit) => _load(emit));
    on<EventsStatusFilterChanged>((event, emit) async {
      emit(_d.copyWith(
          publishedFilter: () =>
              switch (event.index) { 1 => true, 2 => false, _ => null }));
      await _load(emit);
    });
    on<EventsCategoryFilterChanged>((event, emit) async {
      emit(_d.copyWith(categoryFilter: () => event.categoryId));
      await _load(emit);
    });
    on<EventSaveRequested>((event, emit) => _save(event, emit));
    on<EventPublishToggled>(
        (event, emit) => _togglePublished(event.event, emit));
    on<EventDeleteRequested>((event, emit) => _delete(event.event, emit));
  }

  final AdminRepository _repository;

  /// Current state; copyWith returns the base state type, so never
  /// downcast here (that would silently reset to defaults).
  ContentListState<EventItem> get _d => state;

  Future<void> _init(Emitter<ContentListState<EventItem>> emit) async {
    add(const EventsLoadRequested());
    try {
      final items = await _repository.listConfigListItems('event_category');
      emit(_d.copyWith(categories: items.where((i) => i.isActive).toList()));
    } catch (_) {
      // Categories are decoration; the list still loads.
    }
  }

  Future<void> _load(Emitter<ContentListState<EventItem>> emit) async {
    emit(_d.copyWith(loading: true, error: () => null));
    try {
      final items = await _repository.listEvents(
        published: state.publishedFilter,
        categoryId: state.categoryFilter,
      );
      emit(_d.copyWith(items: items, loading: false));
    } catch (e) {
      emit(_d.copyWith(loading: false, error: () => e));
    }
  }

  Future<void> _save(EventSaveRequested event,
      Emitter<ContentListState<EventItem>> emit) async {
    emit(_d.copyWith(saveError: () => null, busyId: () => event.editingId));
    try {
      final editingId = event.editingId;
      if (editingId == null) {
        await _repository.createEvent(event.payload);
      } else {
        await _repository.updateEvent(editingId, event.payload);
      }
      emit(_d.copyWith(busyId: () => null));
      event.completer?.complete(true);
      await _load(emit);
    } catch (e) {
      event.completer?.complete(false);
      emit(_d.copyWith(busyId: () => null, saveError: () => e));
    }
  }

  Future<void> _togglePublished(
      EventItem event, Emitter<ContentListState<EventItem>> emit) async {
    emit(_d.copyWith(busyId: () => event.id, saveError: () => null));
    try {
      await _repository.updateEvent(
        event.id,
        EventInput(
          title: event.title,
          description: event.description,
          location: event.location,
          categoryId: event.categoryId,
          startAt: event.startAt,
          endAt: event.endAt,
          isPublished: !event.isPublished,
          isMembersOnly: event.isMembersOnly,
        ),
      );
      emit(_d.copyWith(busyId: () => null));
      await _load(emit);
    } catch (e) {
      emit(_d.copyWith(busyId: () => null, saveError: () => e));
    }
  }

  Future<void> _delete(
      EventItem event, Emitter<ContentListState<EventItem>> emit) async {
    emit(_d.copyWith(busyId: () => event.id, saveError: () => null));
    try {
      await _repository.deleteEvent(event.id);
      emit(_d.copyWith(
        busyId: () => null,
        items: state.items.where((e) => e.id != event.id).toList(),
      ));
    } catch (e) {
      emit(_d.copyWith(busyId: () => null, saveError: () => e));
    }
  }
}
