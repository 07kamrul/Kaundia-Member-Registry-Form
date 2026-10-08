// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/finance_entities.dart';

const roadmapTextMax = 500;
const roadmapOwnerMax = 120;
const roadmapNoteMax = 1000;

class RoadmapState extends Equatable {
  const RoadmapState({
    this.roadmap,
    this.loading = true,
    this.loadError,
    this.busyItemId,
    this.actionError,
    this.history,
    this.archiveCount,
  });

  final Roadmap? roadmap;
  final bool loading;
  final Object? loadError;

  /// Item currently being mutated (status/reorder/delete).
  final int? busyItemId;
  final Object? actionError;

  /// Archived cycles (lazy-loaded).
  final List<RoadmapArchivedCycle>? history;

  /// Set after a successful archive with the number of archived items.
  final int? archiveCount;

  RoadmapState copyWith({
    Roadmap? Function()? roadmap,
    bool? loading,
    Object? Function()? loadError,
    int? Function()? busyItemId,
    Object? Function()? actionError,
    List<RoadmapArchivedCycle>? history,
    int? Function()? archiveCount,
  }) =>
      RoadmapState(
        roadmap: roadmap == null ? this.roadmap : roadmap(),
        loading: loading ?? this.loading,
        loadError: loadError == null ? this.loadError : loadError(),
        busyItemId: busyItemId == null ? this.busyItemId : busyItemId(),
        actionError: actionError == null ? this.actionError : actionError(),
        history: history ?? this.history,
        archiveCount:
            archiveCount == null ? this.archiveCount : archiveCount(),
      );


  @override
  List<Object?> get props => [
        roadmap,
        loading,
        loadError,
        busyItemId,
        actionError,
        history,
        archiveCount,
      ];
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class RoadmapEvent extends Equatable {
  const RoadmapEvent();
  @override
  List<Object?> get props => const [];
}

final class RoadmapLoadRequested extends RoadmapEvent {
  const RoadmapLoadRequested();

  @override
  List<Object?> get props => const [];
}

final class RoadmapHistoryLoadRequested extends RoadmapEvent {
  const RoadmapHistoryLoadRequested();

  @override
  List<Object?> get props => const [];
}

final class RoadmapStatusSet extends RoadmapEvent {
  const RoadmapStatusSet({
    required this.item,
    required this.status,
    this.notify = true,
    this.completer,
  });

  final RoadmapItem item;
  final RoadmapStatus status;
  final bool notify;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [item, status, notify];
}

final class RoadmapItemDeleted extends RoadmapEvent {
  const RoadmapItemDeleted({
    required this.item,
    this.completer,
  });

  final RoadmapItem item;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [item];
}

final class RoadmapItemsReordered extends RoadmapEvent {
  const RoadmapItemsReordered({
    required this.timeframe,
    required this.index,
    required this.delta,
    this.completer,
  });

  final RoadmapTimeframe timeframe;
  final int index;
  final int delta;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [timeframe, index, delta];
}

final class RoadmapItemCreated extends RoadmapEvent {
  const RoadmapItemCreated({
    required this.timeframeId,
    required this.text,
    this.status = RoadmapStatus.planned,
    this.targetDate,
    this.owner,
    this.note,
    this.notify = true,
    this.completer,
  });

  final int timeframeId;
  final String text;
  final RoadmapStatus status;
  final String? targetDate;
  final String? owner;
  final String? note;
  final bool notify;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [timeframeId, text, status, targetDate, owner, note, notify];
}

final class RoadmapItemUpdated extends RoadmapEvent {
  const RoadmapItemUpdated({
    required this.item,
    required this.text,
    this.timeframeId,
    this.targetDate,
    this.owner,
    this.note,
    this.completer,
  });

  final RoadmapItem item;
  final String text;
  final int? timeframeId;
  final String? targetDate;
  final String? owner;
  final String? note;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [item, text, timeframeId, targetDate, owner, note];
}

final class RoadmapArchived extends RoadmapEvent {
  const RoadmapArchived({
    required this.onlyDone,
    this.completer,
  });

  final bool onlyDone;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [onlyDone];
}

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
      final result = await createItem(timeframeId: e.timeframeId, text: e.text, status: e.status, targetDate: e.targetDate, owner: e.owner, note: e.note, notify: e.notify);
      e.completer?.complete(result);
    });
    on<RoadmapItemUpdated>((e, emit) async {
      final result = await updateItem(e.item, text: e.text, timeframeId: e.timeframeId, targetDate: e.targetDate, owner: e.owner, note: e.note);
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
