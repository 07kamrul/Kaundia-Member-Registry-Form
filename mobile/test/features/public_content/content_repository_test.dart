import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/dashboard/data/public_stats_repository.dart';
import 'package:kaundia_app/features/public_content/data/content_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient api;

  setUp(() {
    api = _MockApiClient();
  });

  group('ContentRepository', () {
    test('listNotices GETs /public/notices and maps rows', () async {
      when(() => api.getUri('/public/notices')).thenAnswer(
        (_) async => [
          {
            'id': 5,
            'title': 'n',
            'body': 'b',
            'category_id': null,
            'is_published': true,
            'is_members_only': false,
            'publish_at': null,
            'created_by': null,
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
          },
        ],
      );
      final repo = ContentRepository(apiClient: api);
      final notices = await repo.listNotices();
      expect(notices, hasLength(1));
      expect(notices.first.id, '5');
      verify(() => api.getUri('/public/notices')).called(1);
    });

    test('listEvents GETs /public/events and maps rows', () async {
      when(() => api.getUri('/public/events')).thenAnswer(
        (_) async => [
          {
            'id': 6,
            'title': 'e',
            'description': null,
            'location': null,
            'category_id': null,
            'start_at': '2026-02-01T10:00:00Z',
            'end_at': null,
            'is_published': true,
            'is_members_only': false,
            'created_by': null,
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
          },
        ],
      );
      final repo = ContentRepository(apiClient: api);
      final events = await repo.listEvents();
      expect(events, hasLength(1));
      expect(events.first.id, '6');
      expect(events.first.startAt, '2026-02-01T10:00:00Z');
      verify(() => api.getUri('/public/events')).called(1);
    });

    test('rethrows ApiException from the client', () async {
      when(() => api.getUri('/public/notices')).thenThrow(
        const ApiException(type: ApiExceptionType.network),
      );
      final repo = ContentRepository(apiClient: api);
      await expectLater(repo.listNotices(), throwsA(isA<ApiException>()));
    });
  });

  group('PublicStatsRepositoryImpl', () {
    test('getStats maps snake_case fields to camelCase with defaults', () async {
      when(() => api.getUri('/public/stats')).thenAnswer(
        (_) async => {
          'pending_count': 4,
          'approved_count': 25,
          'monthly_subscription_total': 12500,
        },
      );
      final repo = PublicStatsRepositoryImpl(apiClient: api);
      final stats = await repo.getStats();
      expect(stats.pendingCount, 4);
      expect(stats.approvedCount, 25);
      expect(stats.monthlySubscriptionTotal, 12500);
    });

    test('missing keys fall back to zero', () async {
      when(() => api.getUri('/public/stats')).thenAnswer((_) async => {});
      final repo = PublicStatsRepositoryImpl(apiClient: api);
      final stats = await repo.getStats();
      expect(stats.pendingCount, 0);
      expect(stats.approvedCount, 0);
      expect(stats.monthlySubscriptionTotal, 0);
    });
  });
}
