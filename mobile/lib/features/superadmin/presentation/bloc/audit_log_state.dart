part of 'audit_log_bloc.dart';

enum AuditLogStatus { initial, loading, ready, failure }

/// Client-side filters — the endpoint has no query params (mirrors Angular).
class AuditLogFilters extends Equatable {
  const AuditLogFilters({
    this.dateFrom,
    this.dateTo,
    this.action = '',
    this.actor = '',
    this.entityType = '',
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String action;
  final String actor;
  final String entityType;

  bool get isActive =>
      dateFrom != null || dateTo != null || action.isNotEmpty || actor.isNotEmpty || entityType.isNotEmpty;

  AuditLogFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? action,
    String? actor,
    String? entityType,
  }) {
    return AuditLogFilters(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      action: action ?? this.action,
      actor: actor ?? this.actor,
      entityType: entityType ?? this.entityType,
    );
  }

  @override
  List<Object?> get props => [dateFrom, dateTo, action, actor, entityType];
}

class AuditLogState extends Equatable {
  const AuditLogState({
    this.status = AuditLogStatus.initial,
    this.loadFailed = false,
    this.entries = const [],
    this.actorLabels = const {},
    this.filters = const AuditLogFilters(),
    this.page = 1,
    this.pageSize = 25,
  });

  final AuditLogStatus status;

  /// The Angular page keeps the table visible on load error and just shows
  /// an error box; this flag drives that inline error + retry.
  final bool loadFailed;
  final List<AuditLogEntry> entries;

  /// admin id -> "Name (role)" for actor resolution (best-effort enrichment).
  final Map<String, String> actorLabels;
  final AuditLogFilters filters;
  final int page;
  final int pageSize;

  List<AuditLogEntry> get filtered {
    Iterable<AuditLogEntry> rows = entries;
    final f = filters;
    if (f.action.isNotEmpty) {
      rows = rows.where((e) => e.action == f.action);
    }
    if (f.actor.isNotEmpty) {
      rows = rows.where((e) => e.actorAdminId == f.actor);
    }
    if (f.entityType.isNotEmpty) {
      rows = rows.where((e) => e.entityType == f.entityType);
    }
    final from = f.dateFrom;
    if (from != null) {
      final fromMs = DateTime(from.year, from.month, from.day).millisecondsSinceEpoch;
      rows = rows.where((e) => e.created.millisecondsSinceEpoch >= fromMs);
    }
    final to = f.dateTo;
    if (to != null) {
      // End date is inclusive: allow the whole day (Angular sets 23:59:59.999).
      final toMs =
          DateTime(to.year, to.month, to.day, 23, 59, 59, 999).millisecondsSinceEpoch;
      rows = rows.where((e) => e.created.millisecondsSinceEpoch <= toMs);
    }
    return List.of(rows);
  }

  List<String> get distinctActions =>
      ({for (final e in entries) e.action}).toList()..sort();

  List<String> get distinctActors {
    final ids = {
      for (final e in entries)
        if (e.actorAdminId != null) e.actorAdminId!,
    }.toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    return ids;
  }

  List<String> get distinctEntityTypes =>
      ({for (final e in entries) e.entityType}).toList()..sort();

  String actorLabel(String? id) {
    if (id == null) return '—';
    return actorLabels[id] ?? '#$id';
  }

  int get total => filtered.length;
  int get totalPages => total == 0 ? 1 : (total / pageSize).ceil();
  int get rangeFrom => total == 0 ? 0 : (page - 1) * pageSize + 1;
  int get rangeTo {
    final end = page * pageSize;
    return end > total ? total : end;
  }

  List<AuditLogEntry> get pageEntries {
    final rows = filtered;
    final start = (page - 1) * pageSize;
    if (start >= rows.length) return const [];
    final end = start + pageSize;
    return rows.sublist(start, end > rows.length ? rows.length : end);
  }

  AuditLogState copyWith({
    AuditLogStatus? status,
    bool? loadFailed,
    List<AuditLogEntry>? entries,
    Map<String, String>? actorLabels,
    AuditLogFilters? filters,
    int? page,
    int? pageSize,
  }) {
    return AuditLogState(
      status: status ?? this.status,
      loadFailed: loadFailed ?? this.loadFailed,
      entries: entries ?? this.entries,
      actorLabels: actorLabels ?? this.actorLabels,
      filters: filters ?? this.filters,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
        status,
        loadFailed,
        entries,
        actorLabels,
        filters,
        page,
        pageSize,
      ];
}
