part of 'audit_log_bloc.dart';

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
