import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/audit_repository.dart';
import '../../../data/rbac_repository.dart';
import '../../../domain/audit_entities.dart';
import '../../../../core/network/api_exception.dart';

const List<int> kAuditPageSizes = [10, 25, 50];

sealed class AuditLogEvent extends Equatable {
  const AuditLogEvent();
  @override
  List<Object?> get props => const [];
}

final class AuditLogStarted extends AuditLogEvent {
  const AuditLogStarted();
}

final class AuditLogFiltersChanged extends AuditLogEvent {
  const AuditLogFiltersChanged({
    this.dateFrom,
    this.dateTo,
    this.action,
    this.actor,
    this.entityType,
  });

  /// Null = unchanged; only non-null fields are applied. Page resets to 1.
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? action;
  final String? actor;
  final String? entityType;

  @override
  List<Object?> get props => [dateFrom, dateTo, action, actor, entityType];
}

final class AuditLogFiltersCleared extends AuditLogEvent {
  const AuditLogFiltersCleared();
}

final class AuditLogPageChanged extends AuditLogEvent {
  const AuditLogPageChanged(this.page);
  final int page;
  @override
  List<Object?> get props => [page];
}

final class AuditLogPageSizeChanged extends AuditLogEvent {
  const AuditLogPageSizeChanged(this.pageSize);
  final int pageSize;
  @override
  List<Object?> get props => [pageSize];
}

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

class AuditLogBloc extends Bloc<AuditLogEvent, AuditLogState> {
  AuditLogBloc(this._auditRepo, this._rbacRepo) : super(const AuditLogState()) {
    on<AuditLogStarted>(_onStarted);
    on<AuditLogFiltersChanged>(_onFiltersChanged);
    on<AuditLogFiltersCleared>(_onFiltersCleared);
    on<AuditLogPageChanged>(_onPageChanged);
    on<AuditLogPageSizeChanged>(_onPageSizeChanged);
  }

  final AuditRepository _auditRepo;
  final RbacRepository _rbacRepo;

  Future<void> _onStarted(AuditLogStarted event, Emitter<AuditLogState> emit) async {
    emit(state.copyWith(status: AuditLogStatus.loading, loadFailed: false));
    try {
      final entries = await _auditRepo.listAuditLog();
      emit(state.copyWith(status: AuditLogStatus.ready, entries: entries));
    } on ApiException {
      emit(state.copyWith(status: AuditLogStatus.failure, loadFailed: true));
    }
    // Best-effort actor enrichment; failure just leaves raw IDs visible.
    try {
      final users = await _rbacRepo.listUsers();
      emit(state.copyWith(actorLabels: {
        for (final u in users) u.id: u.role.isNotEmpty ? '${u.name} (${u.role})' : u.name,
      }));
    } on ApiException {
      // ignore
    }
  }

  void _onFiltersChanged(AuditLogFiltersChanged event, Emitter<AuditLogState> emit) {
    var filters = state.filters;
    if (event.dateFrom != null) filters = filters.copyWith(dateFrom: event.dateFrom);
    if (event.dateTo != null) filters = filters.copyWith(dateTo: event.dateTo);
    if (event.action != null) filters = filters.copyWith(action: event.action);
    if (event.actor != null) filters = filters.copyWith(actor: event.actor);
    if (event.entityType != null) filters = filters.copyWith(entityType: event.entityType);
    emit(state.copyWith(filters: filters, page: 1));
  }

  void _onFiltersCleared(AuditLogFiltersCleared event, Emitter<AuditLogState> emit) {
    emit(state.copyWith(filters: const AuditLogFilters(), page: 1));
  }

  void _onPageChanged(AuditLogPageChanged event, Emitter<AuditLogState> emit) {
    if (event.page < 1 || event.page > state.totalPages) return;
    emit(state.copyWith(page: event.page));
  }

  void _onPageSizeChanged(AuditLogPageSizeChanged event, Emitter<AuditLogState> emit) {
    emit(state.copyWith(pageSize: event.pageSize, page: 1));
  }
}
