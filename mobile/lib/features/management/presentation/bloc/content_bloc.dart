// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

// ----- Notices -----

sealed class NoticesEvent extends Equatable {
  const NoticesEvent();

  @override
  List<Object?> get props => const [];
}

final class NoticesInitRequested extends NoticesEvent {
  const NoticesInitRequested();
}

final class NoticesLoadRequested extends NoticesEvent {
  const NoticesLoadRequested();
}

final class NoticesStatusFilterChanged extends NoticesEvent {
  const NoticesStatusFilterChanged(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

final class NoticesCategoryFilterChanged extends NoticesEvent {
  const NoticesCategoryFilterChanged(this.categoryId);

  final String? categoryId;

  @override
  List<Object?> get props => [categoryId];
}

final class NoticeSaveRequested extends NoticesEvent {
  const NoticeSaveRequested({required this.payload, this.editingId, this.completer});

  final NoticeInput payload;
  final String? editingId;

  /// Optional result channel: true when saved.
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [payload, editingId];
}

final class NoticePublishToggled extends NoticesEvent {
  const NoticePublishToggled(this.notice);

  final Notice notice;

  @override
  List<Object?> get props => [notice];
}

final class NoticeDeleteRequested extends NoticesEvent {
  const NoticeDeleteRequested(this.notice);

  final Notice notice;

  @override
  List<Object?> get props => [notice];
}

/// Shared list state shape for notices/events management.
class ContentListState<T> extends Equatable {
  const ContentListState({
    this.items = const [],
    this.categories = const [],
    this.loading = true,
    this.error,
    this.publishedFilter,
    this.categoryFilter,
    this.busyId,
    this.saveError,
  });

  final List<T> items;
  final List<ConfigListItem> categories;
  final bool loading;
  final Object? error;

  /// null = all, true = published only, false = draft only.
  final bool? publishedFilter;
  final String? categoryFilter;
  final String? busyId;
  final Object? saveError;

  ContentListState<T> copyWith({
    List<T>? items,
    List<ConfigListItem>? categories,
    bool? loading,
    Object? Function()? error,
    bool? Function()? publishedFilter,
    String? Function()? categoryFilter,
    String? Function()? busyId,
    Object? Function()? saveError,
  }) =>
      ContentListState<T>(
        items: items ?? this.items,
        categories: categories ?? this.categories,
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
        publishedFilter: publishedFilter == null ? this.publishedFilter : publishedFilter(),
        categoryFilter: categoryFilter == null ? this.categoryFilter : categoryFilter(),
        busyId: busyId == null ? this.busyId : busyId(),
        saveError: saveError == null ? this.saveError : saveError(),
      );

  @override
  List<Object?> get props => [
        items,
        categories,
        loading,
        error,
        publishedFilter,
        categoryFilter,
        busyId,
        saveError,
      ];
}

final class ContentListData<T> extends ContentListState<T> {
  const ContentListData({
    super.items,
    super.categories,
    super.loading,
    super.error,
    super.publishedFilter,
    super.categoryFilter,
    super.busyId,
    super.saveError,
  });
}

class NoticesBloc extends Bloc<NoticesEvent, ContentListState<Notice>> {
  NoticesBloc({required AdminRepository repository})
      : _repository = repository,
        super(const ContentListData<Notice>()) {
    on<NoticesInitRequested>((event, emit) => _init(emit));
    on<NoticesLoadRequested>((event, emit) => _load(emit));
    on<NoticesStatusFilterChanged>((event, emit) async {
      emit(_d.copyWith(
          publishedFilter: () => switch (event.index) { 1 => true, 2 => false, _ => null }));
      await _load(emit);
    });
    on<NoticesCategoryFilterChanged>((event, emit) async {
      emit(_d.copyWith(categoryFilter: () => event.categoryId));
      await _load(emit);
    });
    on<NoticeSaveRequested>((event, emit) => _save(event, emit));
    on<NoticePublishToggled>((event, emit) => _togglePublished(event.notice, emit));
    on<NoticeDeleteRequested>((event, emit) => _delete(event.notice, emit));
  }

  final AdminRepository _repository;

  ContentListData<Notice> get _d => state is ContentListData<Notice>
      ? state as ContentListData<Notice>
      : const ContentListData<Notice>();

  Future<void> _init(Emitter<ContentListState<Notice>> emit) async {
    add(const NoticesLoadRequested());
    try {
      final items = await _repository.listConfigListItems('notice_category');
      emit(_d.copyWith(categories: items.where((i) => i.isActive).toList()));
    } catch (_) {
      // Categories are decoration; the list still loads.
    }
  }

  Future<void> _load(Emitter<ContentListState<Notice>> emit) async {
    emit(_d.copyWith(loading: true, error: () => null));
    try {
      final items = await _repository.listNotices(
        published: state.publishedFilter,
        categoryId: state.categoryFilter,
      );
      emit(_d.copyWith(items: items, loading: false));
    } catch (e) {
      emit(_d.copyWith(loading: false, error: () => e));
    }
  }

  Future<void> _save(NoticeSaveRequested event, Emitter<ContentListState<Notice>> emit) async {
    emit(_d.copyWith(saveError: () => null, busyId: () => event.editingId));
    try {
      final editingId = event.editingId;
      if (editingId == null) {
        await _repository.createNotice(event.payload);
      } else {
        await _repository.updateNotice(editingId, event.payload);
      }
      emit(_d.copyWith(busyId: () => null));
      event.completer?.complete(true);
      await _load(emit);
    } catch (e) {
      event.completer?.complete(false);
      emit(_d.copyWith(busyId: () => null, saveError: () => e));
    }
  }

  Future<void> _togglePublished(Notice notice, Emitter<ContentListState<Notice>> emit) async {
    emit(_d.copyWith(busyId: () => notice.id, saveError: () => null));
    try {
      await _repository.updateNotice(
        notice.id,
        NoticeInput(
          title: notice.title,
          body: notice.body,
          categoryId: notice.categoryId,
          isPublished: !notice.isPublished,
          isMembersOnly: notice.isMembersOnly,
          publishAt: notice.publishAt,
        ),
      );
      emit(_d.copyWith(busyId: () => null));
      await _load(emit);
    } catch (e) {
      emit(_d.copyWith(busyId: () => null, saveError: () => e));
    }
  }

  Future<void> _delete(Notice notice, Emitter<ContentListState<Notice>> emit) async {
    emit(_d.copyWith(busyId: () => notice.id, saveError: () => null));
    try {
      await _repository.deleteNotice(notice.id);
      emit(_d.copyWith(
        busyId: () => null,
        items: state.items.where((n) => n.id != notice.id).toList(),
      ));
    } catch (e) {
      emit(_d.copyWith(busyId: () => null, saveError: () => e));
    }
  }
}

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
  const EventSaveRequested({required this.payload, this.editingId, this.completer});

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

class EventsBloc extends Bloc<EventsEvent, ContentListState<EventItem>> {
  EventsBloc({required AdminRepository repository})
      : _repository = repository,
        super(const ContentListData<EventItem>()) {
    on<EventsInitRequested>((event, emit) => _init(emit));
    on<EventsLoadRequested>((event, emit) => _load(emit));
    on<EventsStatusFilterChanged>((event, emit) async {
      emit(_d.copyWith(
          publishedFilter: () => switch (event.index) { 1 => true, 2 => false, _ => null }));
      await _load(emit);
    });
    on<EventsCategoryFilterChanged>((event, emit) async {
      emit(_d.copyWith(categoryFilter: () => event.categoryId));
      await _load(emit);
    });
    on<EventSaveRequested>((event, emit) => _save(event, emit));
    on<EventPublishToggled>((event, emit) => _togglePublished(event.event, emit));
    on<EventDeleteRequested>((event, emit) => _delete(event.event, emit));
  }

  final AdminRepository _repository;

  ContentListData<EventItem> get _d => state is ContentListData<EventItem>
      ? state as ContentListData<EventItem>
      : const ContentListData<EventItem>();

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

  Future<void> _save(EventSaveRequested event, Emitter<ContentListState<EventItem>> emit) async {
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

  Future<void> _togglePublished(EventItem event, Emitter<ContentListState<EventItem>> emit) async {
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

  Future<void> _delete(EventItem event, Emitter<ContentListState<EventItem>> emit) async {
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
