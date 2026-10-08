import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/superadmin/data/audit_repository.dart';
import 'package:kaundia_app/features/superadmin/data/rbac_repository.dart';
import 'package:kaundia_app/features/superadmin/domain/audit_entities.dart';
import 'package:kaundia_app/features/superadmin/presentation/bloc/audit_log_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

AuditLogEntry _entry(
  String id,
  String action,
  String entityType,
  String createdAt, {
  String? actorId = '3',
}) =>
    AuditLogEntry(
      id: id,
      actorAdminId: actorId,
      action: action,
      entityType: entityType,
      entityId: '1',
      detail: null,
      createdAt: createdAt,
    );

void main() {
  late _MockApiClient client;
  late AuditLogBloc bloc;

  final entries = [
    _entry('1', 'submission.approve', 'submission', '2026-01-10T05:00:00Z'),
    _entry('2', 'submission.reject', 'submission', '2026-01-20T05:00:00Z'),
    _entry('3', 'member.create', 'member', '2026-02-05T05:00:00Z', actorId: '4'),
    _entry('4', 'role.update', 'role', '2026-02-06T05:00:00Z', actorId: null),
  ];

  setUp(() {
    client = _MockApiClient();
    when(() => client.getUri('/admin/audit-log')).thenAnswer((_) async => [
          for (final e in entries)
            {
              'id': int.parse(e.id),
              'actor_admin_id': e.actorAdminId == null ? null : int.parse(e.actorAdminId!),
              'action': e.action,
              'entity_type': e.entityType,
              'entity_id': e.entityId,
              'detail': e.detail,
              'created_at': e.createdAt,
            },
        ]);
    when(() => client.getUri('/admin/rbac/users')).thenAnswer((_) async => [
          {
            'id': 3,
            'name': 'Karim',
            'email': 'karim@example.com',
            'role': 'administrator',
            'role_id': 2,
          },
        ]);
    bloc = AuditLogBloc(AuditRepository(client), RbacRepository(client));
  });

  blocTest<AuditLogBloc, AuditLogState>(
    'loads entries then enriches actor labels (best-effort)',
    build: () => bloc,
    act: (bloc) => bloc.add(const AuditLogStarted()),
    expect: () => [
      isA<AuditLogState>().having((s) => s.status, 'status', AuditLogStatus.loading),
      isA<AuditLogState>()
          .having((s) => s.status, 'status', AuditLogStatus.ready)
          .having((s) => s.entries.length, 'entries.length', 4)
          .having((s) => s.total, 'total', 4)
          .having((s) => s.loadFailed, 'loadFailed', false),
      isA<AuditLogState>()
          .having((s) => s.actorLabels['3'], 'actor label', 'Karim (administrator)'),
    ],
  );

  blocTest<AuditLogBloc, AuditLogState>(
    'load failure sets loadFailed and keeps pageEntries empty',
    setUp: () {
      when(() => client.getUri('/admin/audit-log'))
          .thenThrow(const ApiException(type: ApiExceptionType.network));
    },
    build: () => bloc,
    act: (bloc) => bloc.add(const AuditLogStarted()),
    expect: () => [
      isA<AuditLogState>().having((s) => s.status, 'status', AuditLogStatus.loading),
      isA<AuditLogState>()
          .having((s) => s.status, 'status', AuditLogStatus.failure)
          .having((s) => s.loadFailed, 'loadFailed', true),
      // actor enrichment still attempted and applied
      isA<AuditLogState>().having((s) => s.actorLabels, 'actorLabels', isNotEmpty),
    ],
  );

  blocTest<AuditLogBloc, AuditLogState>(
    'action filter narrows results and resets page to 1',
    build: () => bloc,
    act: (bloc) async {
      bloc.add(const AuditLogStarted());
      await pumpEventQueue();
      bloc.add(const AuditLogFiltersChanged(action: 'submission.approve'));
      await pumpEventQueue();
    },
    expect: () => [
      isA<AuditLogState>().having((s) => s.status, 'status', AuditLogStatus.loading),
      isA<AuditLogState>().having((s) => s.status, 'status', AuditLogStatus.ready),
      isA<AuditLogState>().having((s) => s.actorLabels, 'actorLabels', isNotEmpty),
      isA<AuditLogState>()
          .having((s) => s.filters.action, 'filters.action', 'submission.approve')
          .having((s) => s.total, 'total', 1)
          .having((s) => s.page, 'page', 1),
    ],
  );

  blocTest<AuditLogBloc, AuditLogState>(
    'date range filter is inclusive of the whole end day',
    build: () => bloc,
    act: (bloc) async {
      bloc.add(const AuditLogStarted());
      await pumpEventQueue();
      bloc.add(AuditLogFiltersChanged(
        dateFrom: DateTime(2026, 1, 15),
        dateTo: DateTime(2026, 1, 20),
      ));
      await pumpEventQueue();
    },
    expect: () => [
      isA<AuditLogState>().having((s) => s.status, 'status', AuditLogStatus.loading),
      isA<AuditLogState>().having((s) => s.status, 'status', AuditLogStatus.ready),
      isA<AuditLogState>().having((s) => s.actorLabels, 'actorLabels', isNotEmpty),
      isA<AuditLogState>().having((s) => s.total, 'total', 1),
    ],
  );

  blocTest<AuditLogBloc, AuditLogState>(
    'pagination slices the filtered list; pageSize change resets page',
    build: () => bloc,
    act: (bloc) async {
      bloc.add(const AuditLogStarted());
      await pumpEventQueue();
      bloc.add(const AuditLogPageSizeChanged(2));
      bloc.add(const AuditLogPageChanged(2));
      await pumpEventQueue();
    },
    expect: () => [
      isA<AuditLogState>().having((s) => s.status, 'status', AuditLogStatus.loading),
      isA<AuditLogState>().having((s) => s.status, 'status', AuditLogStatus.ready),
      isA<AuditLogState>().having((s) => s.actorLabels, 'actorLabels', isNotEmpty),
      isA<AuditLogState>()
          .having((s) => s.pageSize, 'pageSize', 2)
          .having((s) => s.page, 'page', 1)
          .having((s) => s.totalPages, 'totalPages', 2)
          .having((s) => s.pageEntries.length, 'pageEntries.length', 2),
      isA<AuditLogState>()
          .having((s) => s.page, 'page', 2)
          .having((s) => s.pageEntries.length, 'pageEntries.length', 2)
          .having((s) => s.pageEntries.first.id, 'first entry', '3')
          .having((s) => s.rangeFrom, 'rangeFrom', 3)
          .having((s) => s.rangeTo, 'rangeTo', 4),
    ],
  );

  blocTest<AuditLogBloc, AuditLogState>(
    'clear filters restores the unfiltered list',
    build: () => bloc,
    act: (bloc) async {
      bloc.add(const AuditLogStarted());
      await pumpEventQueue();
      bloc.add(const AuditLogFiltersChanged(entityType: 'member'));
      bloc.add(const AuditLogFiltersCleared());
      await pumpEventQueue();
    },
    expect: () => [
      isA<AuditLogState>().having((s) => s.status, 'status', AuditLogStatus.loading),
      isA<AuditLogState>().having((s) => s.status, 'status', AuditLogStatus.ready),
      isA<AuditLogState>().having((s) => s.actorLabels, 'actorLabels', isNotEmpty),
      isA<AuditLogState>()
          .having((s) => s.filters.entityType, 'filters.entityType', 'member')
          .having((s) => s.total, 'total', 1),
      isA<AuditLogState>()
          .having((s) => s.filters.isActive, 'filters.isActive', false)
          .having((s) => s.total, 'total', 4)
          .having((s) => s.page, 'page', 1),
    ],
  );

  blocTest<AuditLogBloc, AuditLogState>(
    'out-of-range page changes are ignored',
    build: () => bloc,
    act: (bloc) async {
      bloc.add(const AuditLogStarted());
      await pumpEventQueue();
      bloc.add(const AuditLogPageChanged(99));
      await pumpEventQueue();
    },
    expect: () => [
      isA<AuditLogState>().having((s) => s.status, 'status', AuditLogStatus.loading),
      isA<AuditLogState>().having((s) => s.status, 'status', AuditLogStatus.ready),
      isA<AuditLogState>().having((s) => s.actorLabels, 'actorLabels', isNotEmpty),
    ],
  );

  test('distinct lists are sorted and de-duplicated', () async {
    bloc.add(const AuditLogStarted());
    await pumpEventQueue();
    expect(bloc.state.distinctActions, ['member.create', 'role.update', 'submission.approve', 'submission.reject']);
    expect(bloc.state.distinctActors, ['3', '4']);
    expect(bloc.state.distinctEntityTypes, ['member', 'role', 'submission']);
    expect(bloc.state.actorLabel('3'), 'Karim (administrator)');
    expect(bloc.state.actorLabel(null), '—');
    expect(bloc.state.actorLabel('99'), '#99');
  });
}
