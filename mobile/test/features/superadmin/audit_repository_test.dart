import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/features/superadmin/data/audit_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient client;
  late AuditRepository repo;

  setUp(() {
    client = _MockApiClient();
    repo = AuditRepository(client);
  });

  test('listAuditLog GETs /admin/audit-log and maps every field', () async {
    when(() => client.getUri('/admin/audit-log')).thenAnswer((_) async => [
          {
            'id': 42,
            'actor_admin_id': 3,
            'action': 'submission.approve',
            'entity_type': 'submission',
            'entity_id': '101',
            'detail': '{"status":"approved"}',
            'created_at': '2026-01-15T10:30:00Z',
          },
          {
            'id': 43,
            'actor_admin_id': null,
            'action': 'member.create',
            'entity_type': 'member',
            'entity_id': '9',
            'detail': null,
            'created_at': '2026-01-16T09:00:00Z',
          },
        ]);
    final result = await repo.listAuditLog();
    expect(result, hasLength(2));

    expect(result[0].id, '42');
    expect(result[0].actorAdminId, '3');
    expect(result[0].action, 'submission.approve');
    expect(result[0].entityType, 'submission');
    expect(result[0].entityId, '101');
    expect(result[0].detail, '{"status":"approved"}');
    expect(result[0].createdAt, '2026-01-15T10:30:00Z');

    expect(result[1].actorAdminId, isNull);
    expect(result[1].detail, isNull);
    verify(() => client.getUri('/admin/audit-log')).called(1);
  });

  test('listAuditLog returns empty list for an empty payload', () async {
    when(() => client.getUri('/admin/audit-log')).thenAnswer((_) async => []);
    expect(await repo.listAuditLog(), isEmpty);
  });
}
