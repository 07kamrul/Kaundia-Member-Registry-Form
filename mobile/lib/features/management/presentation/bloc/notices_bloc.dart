// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';
import 'content_list_state.dart';
export 'content_list_state.dart';

part 'notices_event.dart';
part 'notices_state.dart';

class NoticesBloc extends Bloc<NoticesEvent, ContentListState<Notice>> {
  NoticesBloc({required AdminRepository repository})
      : _repository = repository,
        super(const ContentListData<Notice>()) {
    on<NoticesInitRequested>((event, emit) => _init(emit));
    on<NoticesLoadRequested>((event, emit) => _load(emit));
    on<NoticesStatusFilterChanged>((event, emit) async {
      emit(_d.copyWith(
          publishedFilter: () =>
              switch (event.index) { 1 => true, 2 => false, _ => null }));
      await _load(emit);
    });
    on<NoticesCategoryFilterChanged>((event, emit) async {
      emit(_d.copyWith(categoryFilter: () => event.categoryId));
      await _load(emit);
    });
    on<NoticeSaveRequested>((event, emit) => _save(event, emit));
    on<NoticePublishToggled>(
        (event, emit) => _togglePublished(event.notice, emit));
    on<NoticeDeleteRequested>((event, emit) => _delete(event.notice, emit));
  }

  final AdminRepository _repository;

  /// Current state; copyWith returns the base state type, so never
  /// downcast here (that would silently reset to defaults).
  ContentListState<Notice> get _d => state;

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

  Future<void> _save(
      NoticeSaveRequested event, Emitter<ContentListState<Notice>> emit) async {
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

  Future<void> _togglePublished(
      Notice notice, Emitter<ContentListState<Notice>> emit) async {
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

  Future<void> _delete(
      Notice notice, Emitter<ContentListState<Notice>> emit) async {
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
