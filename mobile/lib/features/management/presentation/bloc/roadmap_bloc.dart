// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/finance_entities.dart';

part 'roadmap_event.dart';
part 'roadmap_state.dart';

const roadmapTextMax = 500;

const roadmapOwnerMax = 120;

const roadmapNoteMax = 1000;

class RoadmapBloc extends Bloc<RoadmapEvent, RoadmapState> {
  RoadmapBloc({required RoadmapRepository repository})
      : _repository = repository,
        super(const RoadmapState()) {
    on<RoadmapLoadRequested>((e, emit) => load());
    on<RoadmapHistoryLoadRequested>((e, emit) => loadHistory());
    on<RoadmapStatusSet>((e, emit) async {
      final result = await setStatus(e.item, e.status, notify: e.notify);
      e.completer?.complete(result);
    });
    on<RoadmapItemDeleted>((e, emit) async {
      final result = await deleteItem(e.item);
      e.completer?.complete(result);
    });
    on<RoadmapItemsReordered>((e, emit) async {
      final result = await reorder(e.timeframe, e.index, e.delta);
      e.completer?.complete(result);
    });
    on<RoadmapItemCreated>((e, emit) async {
      final result = await createItem(
          timeframeId: e.timeframeId,
          text: e.text,
          status: e.status,
          targetDate: e.targetDate,
          owner: e.owner,
          note: e.note,
          notify: e.notify);
      e.completer?.complete(result);
    });
    on<RoadmapItemUpdated>((e, emit) async {
      final result = await updateItem(e.item,
          text: e.text,
          timeframeId: e.timeframeId,
          targetDate: e.targetDate,
          owner: e.owner,
          note: e.note);
      e.completer?.complete(result);
    });
    on<RoadmapArchived>((e, emit) async {
      final result = await archive(onlyDone: e.onlyDone);
      e.completer?.complete(result);
    });
  }

  final RoadmapRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, loadError: () => null));
    try {
      final roadmap = await _repository.getRoadmap();
      emit(state.copyWith(roadmap: () => roadmap, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, loadError: () => e));
    }
  }

  Future<bool> _mutate(int itemId, Future<Roadmap> Function() run) async {
    emit(state.copyWith(busyItemId: () => itemId, actionError: () => null));
    try {
      final roadmap = await run();
      emit(state.copyWith(roadmap: () => roadmap, busyItemId: () => null));
      return true;
    } catch (e) {
      emit(state.copyWith(busyItemId: () => null, actionError: () => e));
      return false;
    }
  }

  Future<bool> setStatus(RoadmapItem item, RoadmapStatus status,
          {bool notify = true}) =>
      _mutate(item.id,
          () => _repository.setStatus(item.id, status, notify: notify));

  Future<bool> deleteItem(RoadmapItem item) =>
      _mutate(item.id, () => _repository.deleteItem(item.id));

  Future<bool> reorder(RoadmapTimeframe timeframe, int index, int delta) async {
    final target = index + delta;
    if (target < 0 || target >= timeframe.items.length) return false;
    final ids = [for (final i in timeframe.items) i.id];
    final moved = ids[index];
    ids[index] = ids[target];
    ids[target] = moved;
    return _mutate(moved, () => _repository.reorder(timeframe.id, ids));
  }

  Future<bool> createItem({
    required int timeframeId,
    required String text,
    RoadmapStatus status = RoadmapStatus.planned,
    String? targetDate,
    String? owner,
    String? note,
    bool notify = true,
  }) async {
    emit(state.copyWith(actionError: () => null, busyItemId: () => -1));
    try {
      final roadmap = await _repository.createItem(
        timeframeId: timeframeId,
        text: text,
        status: status,
        targetDate: targetDate,
        owner: owner,
        note: note,
        notify: notify,
      );
      emit(state.copyWith(roadmap: () => roadmap, busyItemId: () => null));
      return true;
    } catch (e) {
      emit(state.copyWith(busyItemId: () => null, actionError: () => e));
      return false;
    }
  }

  Future<bool> updateItem(
    RoadmapItem item, {
    required String text,
    int? timeframeId,
    String? targetDate,
    String? owner,
    String? note,
  }) async {
    emit(state.copyWith(actionError: () => null, busyItemId: () => item.id));
    try {
      final roadmap = await _repository.updateItem(
        item.id,
        text: text,
        timeframeId: timeframeId,
        targetDate: targetDate,
        owner: owner,
        note: note,
      );
      emit(state.copyWith(roadmap: () => roadmap, busyItemId: () => null));
      return true;
    } catch (e) {
      emit(state.copyWith(busyItemId: () => null, actionError: () => e));
      return false;
    }
  }

  Future<bool> archive({required bool onlyDone}) async {
    emit(state.copyWith(actionError: () => null, busyItemId: () => -1));
    try {
      final archived = await _repository.archive(onlyDone: onlyDone);
      emit(state.copyWith(
          busyItemId: () => null, archiveCount: () => archived, history: null));
      await load();
      return true;
    } catch (e) {
      emit(state.copyWith(busyItemId: () => null, actionError: () => e));
      return false;
    }
  }

  Future<void> loadHistory() async {
    if (state.history != null) return;
    try {
      final cycles = await _repository.getArchive();
      emit(state.copyWith(history: cycles));
    } catch (e) {
      emit(state.copyWith(history: const [], actionError: () => e));
    }
  }
}
