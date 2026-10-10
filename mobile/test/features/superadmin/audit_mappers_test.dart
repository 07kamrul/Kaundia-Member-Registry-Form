import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/superadmin/data/audit_dtos.dart';
import 'package:kaundia_app/features/superadmin/domain/audit_entities.dart';

void main() {
  test('AuditLogDto maps every snake_case field to the camelCase entity', () {
    final dto = AuditLogDto.fromApi(const {
      'id': 42,
      'actor_admin_id': 3,
      'action': 'submission.approve',
      'entity_type': 'submission',
      'entity_id': '101',
      'detail': '{"status":"approved"}',
      'created_at': '2026-01-15T10:30:00Z',
    });
    expect(dto.id, 42);
    expect(dto.actorAdminId, 3);
    expect(dto.action, 'submission.approve');
    expect(dto.entityType, 'submission');
    expect(dto.entityId, '101');
    expect(dto.detail, '{"status":"approved"}');
    expect(dto.createdAt, '2026-01-15T10:30:00Z');

    final entity = dto.toEntity();
    expect(entity.id, '42');
    expect(entity.actorAdminId, '3');
    expect(entity.action, 'submission.approve');
    expect(entity.entityType, 'submission');
    expect(entity.entityId, '101');
    expect(entity.detail, '{"status":"approved"}');
    expect(entity.createdAt, '2026-01-15T10:30:00Z');
  });

  test('AuditLogDto handles null actor_admin_id and null detail', () {
    final dto = AuditLogDto.fromApi(const {
      'id': 9,
      'actor_admin_id': null,
      'action': 'member.create',
      'entity_type': 'member',
      'entity_id': '5',
      'detail': null,
      'created_at': '2026-02-01T08:00:00Z',
    });
    expect(dto.actorAdminId, isNull);
    final entity = dto.toEntity();
    expect(entity.actorAdminId, isNull);
    expect(entity.detail, isNull);
  });

  test('actionVerb extracts the first segment like the Angular actionClass()',
      () {
    AuditLogEntry entry(String action) => AuditLogEntry(
          id: '1',
          actorAdminId: null,
          action: action,
          entityType: 'submission',
          entityId: '1',
          detail: null,
          createdAt: '2026-01-15T10:30:00Z',
        );
    // Angular: verb = action.split(/[._]/)[0], badge only for known verbs.
    expect(entry('approve.submission').actionVerb, 'approve');
    expect(entry('reject_submission').actionVerb, 'reject');
    expect(entry('update_role').actionVerb, 'update');
    expect(entry('delete_user').actionVerb, 'delete');
    expect(entry('create_fee').actionVerb, 'create');
    expect(entry('submission.approve').actionVerb, '');
    expect(entry('weird.verb').actionVerb, '');
  });

  test('parseAuditDetail parses JSON objects into pairs', () {
    final pairs =
        parseAuditDetail('{"status":"approved","count":2,"nested":{"a":1}}');
    expect(pairs, const [
      AuditDetailPair(key: 'status', value: 'approved'),
      AuditDetailPair(key: 'count', value: '2'),
      AuditDetailPair(key: 'nested', value: '{"a":1}'),
    ]);
  });

  test('parseAuditDetail falls back to raw for non-JSON and non-object JSON',
      () {
    expect(parseAuditDetail('plain text'), const [
      AuditDetailPair(key: 'detail', value: 'plain text'),
    ]);
    expect(parseAuditDetail('[1,2]'), const [
      AuditDetailPair(key: 'detail', value: '[1,2]'),
    ]);
    expect(parseAuditDetail(null), isEmpty);
    expect(parseAuditDetail(''), isEmpty);
  });
}
