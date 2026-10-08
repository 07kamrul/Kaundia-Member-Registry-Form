import '../../../core/network/api_client.dart';
import '../domain/audit_entities.dart';
import 'audit_dtos.dart';

/// Ported from the Angular AdminService.listAuditLog — the endpoint takes no
/// query params; filtering/pagination are client-side.
class AuditRepository {
  AuditRepository(this._client);

  final ApiClient _client;

  Future<List<AuditLogEntry>> listAuditLog() async {
    final rows = await _client.getUri('/admin/audit-log') as List<dynamic>;
    return [for (final row in rows) AuditLogDto.fromApi(row as Map<String, dynamic>).toEntity()];
  }
}
