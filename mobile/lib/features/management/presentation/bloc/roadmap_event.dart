part of 'roadmap_bloc.dart';

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
  List<Object?> get props =>
      [timeframeId, text, status, targetDate, owner, note, notify];
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
