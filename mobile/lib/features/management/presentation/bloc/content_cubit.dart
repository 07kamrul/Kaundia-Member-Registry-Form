import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

/// Shared list state shape for notices/events management.
class ContentListState<T> extends Equatable {
  const ContentListState({
    this.items = const [],
    this.categories = const [],
    this.loading = true,
    this.error,
    this.statusFilterAll = true,
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
    Object? Function() error = _same,
    bool? Function() publishedFilter = _same,
    String? Function() categoryFilter = _same,
    String? Function() busyId = _same,
    Object? Function() saveError = _same,
  }) =>
      ContentListState<T>(
        items: items ?? this.items,
        categories: categories ?? this.categories,
        loading: loading ?? this.loading,
        error: error == _same ? this.error : error(),
        publishedFilter: publishedFilter == _same ? this.publishedFilter : publishedFilter(),
        categoryFilter: categoryFilter == _same ? this.categoryFilter : categoryFilter(),
        busyId: busyId == _same ? this.busyId : busyId(),
        saveError: saveError == _same ? this.saveError : saveError(),
      );

  static T _same<T>() => throw UnsupportedError('sentinel');

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

class NoticesCubit extends Cubit<ContentListState<Notice>> {
  NoticesCubit({required AdminRepository repository})
      : _repository = repository,
        super(const ContentListState<Notice>());

  final AdminRepository _repository;

  Future<void> init() async {
    load();
    try {
      final items = await _repository.listConfigListItems('notice_category');
      emit(state.copyWith(categories: items.where((i) => i.isActive).toList()));
    } catch (_) {
      // Categories are decoration; the list still loads.
    }
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final items = await _repository.listNotices(
        published: state.publishedFilter,
        categoryId: state.categoryFilter,
      );
      emit(state.copyWith(items: items, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: () => e));
    }
  }

  void setStatusFilter(int index) {
    // 0 = all, 1 = published, 2 = draft (matches Angular StatusFilter order).
    emit(state.copyWith(publishedFilter: () => switch (index) {
          1 => true,
          2 => false,
          _ => null,
        }));
    load();
  }

  void setCategoryFilter(String? categoryId) {
    emit(state.copyWith(categoryFilter: () => categoryId));
    load();
  }

  Future<bool> save({required NoticeInput payload, String? editingId}) async {
    emit(state.copyWith(saveError: () => null, busyId: () => editingId));
    try {
      if (editingId == null) {
        await _repository.createNotice(payload);
      } else {
        await _repository.updateNotice(editingId, payload);
      }
      emit(state.copyWith(busyId: () => null));
      await load();
      return true;
    } catch (e) {
      emit(state.copyWith(busyId: () => null, saveError: () => e));
      return false;
    }
  }

  Future<void> togglePublished(Notice notice) async {
    emit(state.copyWith(busyId: () => notice.id, saveError: () => null));
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
      emit(state.copyWith(busyId: () => null));
      await load();
    } catch (e) {
      emit(state.copyWith(busyId: () => null, saveError: () => e));
    }
  }

  Future<void> delete(Notice notice) async {
    emit(state.copyWith(busyId: () => notice.id, saveError: () => null));
    try {
      await _repository.deleteNotice(notice.id);
      emit(state.copyWith(
        busyId: () => null,
        items: state.items.where((n) => n.id != notice.id).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(busyId: () => null, saveError: () => e));
    }
  }
}

class EventsCubit extends Cubit<ContentListState<EventItem>> {
  EventsCubit({required AdminRepository repository})
      : _repository = repository,
        super(const ContentListState<EventItem>());

  final AdminRepository _repository;

  Future<void> init() async {
    load();
    try {
      final items = await _repository.listConfigListItems('event_category');
      emit(state.copyWith(categories: items.where((i) => i.isActive).toList()));
    } catch (_) {
      // Categories are decoration; the list still loads.
    }
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final items = await _repository.listEvents(
        published: state.publishedFilter,
        categoryId: state.categoryFilter,
      );
      emit(state.copyWith(items: items, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: () => e));
    }
  }

  void setStatusFilter(int index) {
    emit(state.copyWith(publishedFilter: () => switch (index) {
          1 => true,
          2 => false,
          _ => null,
        }));
    load();
  }

  void setCategoryFilter(String? categoryId) {
    emit(state.copyWith(categoryFilter: () => categoryId));
    load();
  }

  Future<bool> save({required EventInput payload, String? editingId}) async {
    emit(state.copyWith(saveError: () => null, busyId: () => editingId));
    try {
      if (editingId == null) {
        await _repository.createEvent(payload);
      } else {
        await _repository.updateEvent(editingId, payload);
      }
      emit(state.copyWith(busyId: () => null));
      await load();
      return true;
    } catch (e) {
      emit(state.copyWith(busyId: () => null, saveError: () => e));
      return false;
    }
  }

  Future<void> togglePublished(EventItem event) async {
    emit(state.copyWith(busyId: () => event.id, saveError: () => null));
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
      emit(state.copyWith(busyId: () => null));
      await load();
    } catch (e) {
      emit(state.copyWith(busyId: () => null, saveError: () => e));
    }
  }

  Future<void> delete(EventItem event) async {
    emit(state.copyWith(busyId: () => event.id, saveError: () => null));
    try {
      await _repository.deleteEvent(event.id);
      emit(state.copyWith(
        busyId: () => null,
        items: state.items.where((e) => e.id != event.id).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(busyId: () => null, saveError: () => e));
    }
  }
}
