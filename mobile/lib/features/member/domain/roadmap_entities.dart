import 'package:equatable/equatable.dart';

enum RoadmapStatus { planned, inProgress, done, unknown }

extension RoadmapStatusX on RoadmapStatus {
  static RoadmapStatus fromName(String? name) => switch (name) {
        'planned' => RoadmapStatus.planned,
        'in_progress' => RoadmapStatus.inProgress,
        'done' => RoadmapStatus.done,
        _ => RoadmapStatus.unknown,
      };

  String get apiName => switch (this) {
        RoadmapStatus.planned => 'planned',
        RoadmapStatus.inProgress => 'in_progress',
        RoadmapStatus.done => 'done',
        RoadmapStatus.unknown => 'unknown',
      };
}

class RoadmapItem extends Equatable {
  const RoadmapItem({
    required this.id,
    required this.timeframeId,
    required this.text,
    required this.status,
    required this.targetDate,
    required this.owner,
    required this.note,
    required this.sortOrder,
    required this.completedAt,
    required this.updatedAt,
  });

  final String id;
  final String timeframeId;
  final String text;
  final RoadmapStatus status;
  final String? targetDate;
  final String? owner;
  final String? note;
  final int sortOrder;
  final String? completedAt;
  final String? updatedAt;

  @override
  List<Object?> get props => [
        id, timeframeId, text, status, targetDate, owner, note, sortOrder,
        completedAt, updatedAt,
      ];
}

class RoadmapProgress extends Equatable {
  const RoadmapProgress({
    required this.total,
    required this.done,
    required this.inProgress,
    required this.planned,
    required this.percent,
  });

  final int total;
  final int done;
  final int inProgress;
  final int planned;
  final num percent;

  @override
  List<Object?> get props => [total, done, inProgress, planned, percent];
}

class RoadmapTimeframe extends Equatable {
  const RoadmapTimeframe({
    required this.id,
    required this.key,
    required this.nameBn,
    required this.nameEn,
    required this.windowBn,
    required this.windowEn,
    required this.sortOrder,
    required this.progress,
    required this.items,
  });

  final String id;
  final String key;
  final String nameBn;
  final String nameEn;
  final String windowBn;
  final String windowEn;
  final int sortOrder;
  final RoadmapProgress progress;
  final List<RoadmapItem> items;

  @override
  List<Object?> get props => [
        id, key, nameBn, nameEn, windowBn, windowEn, sortOrder, progress, items,
      ];
}

class Roadmap extends Equatable {
  const Roadmap({required this.lastUpdated, required this.totals, required this.timeframes});

  final String? lastUpdated;
  final RoadmapProgress totals;
  final List<RoadmapTimeframe> timeframes;

  @override
  List<Object?> get props => [lastUpdated, totals, timeframes];
}

/// "আমরা এখন কোথায় আছি": earliest timeframe with unfinished work, else last.
int currentTimeframeIndex(Roadmap roadmap) {
  final index =
      roadmap.timeframes.indexWhere((tf) => tf.progress.total > 0 && tf.progress.done < tf.progress.total);
  return index == -1
      ? (roadmap.timeframes.isEmpty ? 0 : roadmap.timeframes.length - 1)
      : index;
}
