import 'dart:convert';

/// Audit-log domain entity. Ported from the Angular `AuditLogEntry`
/// (frontend/src/app/core/models/admin.model.ts) and `toAuditLogEntry` mapper.
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.actorAdminId,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.detail,
    required this.createdAt,
  });

  final String id;
  final String? actorAdminId;
  final String action;
  final String entityType;
  final String entityId;
  final String? detail;
  final String createdAt;

  DateTime get created => DateTime.parse(createdAt).toLocal();

  /// The action verb before the first `.`/`_` drives the badge color, exactly
  /// like the Angular `actionClass()` helper.
  String get actionVerb {
    final verb = action.split(RegExp(r'[._]')).first;
    return const ['approve', 'reject', 'create', 'update', 'delete'].contains(verb) ? verb : '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogEntry &&
          id == other.id &&
          actorAdminId == other.actorAdminId &&
          action == other.action &&
          entityType == other.entityType &&
          entityId == other.entityId &&
          detail == other.detail &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, actorAdminId, action, entityType, entityId, detail, createdAt);
}

/// One parsed key-value pair of the JSON `detail` column.
class AuditDetailPair {
  const AuditDetailPair({required this.key, required this.value});

  final String key;
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditDetailPair && key == other.key && value == other.value;

  @override
  int get hashCode => Object.hash(key, value);
}

/// Parses the `detail` column as JSON into key-value pairs with a raw
/// fallback — a field-for-field port of the Angular `parseDetail()`.
List<AuditDetailPair> parseAuditDetail(String? detail) {
  if (detail == null || detail.isEmpty) return const [];
  try {
    final parsed = jsonDecode(detail);
    if (parsed is Map) {
      return [
        for (final entry in parsed.entries)
          AuditDetailPair(
            key: entry.key.toString(),
            value: entry.value is Map || entry.value is List
                ? jsonEncode(entry.value)
                : entry.value?.toString() ?? '',
          ),
      ];
    }
    return [AuditDetailPair(key: 'detail', value: jsonEncode(parsed))];
  } on FormatException {
    return [AuditDetailPair(key: 'detail', value: detail)];
  }
}
