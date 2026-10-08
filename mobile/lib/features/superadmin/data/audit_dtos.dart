import '../domain/audit_entities.dart';

/// snake_case API DTO for GET /admin/audit-log with a hand-written
/// field-for-field mapper (ids become String client-side).
class AuditLogDto {
  const AuditLogDto({
    required this.id,
    required this.actorAdminId,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.detail,
    required this.createdAt,
  });

  final int id;
  final int? actorAdminId;
  final String action;
  final String entityType;
  final String entityId;
  final String? detail;
  final String createdAt;

  factory AuditLogDto.fromApi(Map<String, dynamic> json) => AuditLogDto(
        id: json['id'] as int,
        actorAdminId: json['actor_admin_id'] as int?,
        action: json['action'] as String,
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as String,
        detail: json['detail'] as String?,
        createdAt: json['created_at'] as String,
      );

  AuditLogEntry toEntity() => AuditLogEntry(
        id: id.toString(),
        actorAdminId: actorAdminId?.toString(),
        action: action,
        entityType: entityType,
        entityId: entityId,
        detail: detail,
        createdAt: createdAt,
      );
}
