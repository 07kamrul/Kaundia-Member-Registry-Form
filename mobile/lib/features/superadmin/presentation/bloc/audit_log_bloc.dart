import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/audit_repository.dart';
import '../../data/rbac_repository.dart';
import '../../domain/audit_entities.dart';
import '../../../../core/network/api_exception.dart';

part 'audit_log_event.dart';
part 'audit_log_state.dart';

const List<int> kAuditPageSizes = [10, 25, 50];

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
