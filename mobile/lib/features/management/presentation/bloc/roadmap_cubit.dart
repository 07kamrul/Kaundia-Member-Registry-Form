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
    Roadmap? Function() roadmap = _same,
    bool? loading,
    Object? Function() loadError = _same,
    int? Function() busyItemId = _same,
    Object? Function() actionError = _same,
    List<RoadmapArchivedCycle>? history,
    int? Function() archiveCount = _same,
  }) =>
      RoadmapState(
        roadmap: roadmap == _same ? this.roadmap : roadmap(),
        loading: loading ?? this.loading,
        loadError: loadError == _same ? this.loadError : loadError(),
        busyItemId: busyItemId == _same ? this.busyItemId : busyItemId(),
        actionError: actionError == _same ? this.actionError : actionError(),
        history: history ?? this.history,
        archiveCount: archiveCount == _same ? this.archiveCount : archiveCount(),
      );

  static T _same<T>() => throw UnsupportedError('sentinel');

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

class RoadmapCubit extends Cubit<RoadmapState> {
  RoadmapCubit({required RoadmapRepository repository})
      : _repository = repository,
        super(const RoadmapState());

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

  Future<bool> setStatus(RoadmapItem item, RoadmapStatus status, {bool notify = true}) =>
      _mutate(item.id, () => _repository.setStatus(item.id, status, notify: notify));

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
      emit(state.copyWith(busyItemId: () => null, archiveCount: () => archived, history: null));
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
