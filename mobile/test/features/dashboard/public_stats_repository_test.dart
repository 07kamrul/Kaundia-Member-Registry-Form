import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/dashboard/data/public_stats_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late PublicStatsRepositoryImpl repo;

  setUp(() {
    api = MockApiClient();
    repo = PublicStatsRepositoryImpl(apiClient: api);
  });

  test('getStats maps /public/stats payload to entity', () async {
    when(() => api.getUri('/public/stats')).thenAnswer(
      (_) async => {
        'pending_count': 3,
        'approved_count': 9,
        'monthly_subscription_total': 500,
      },
    );

    final stats = await repo.getStats();
    expect(stats.pendingCount, 3);
    expect(stats.approvedCount, 9);
    expect(stats.monthlySubscriptionTotal, 500);
  });

  test('surfaces ApiException from the client', () async {
    when(() => api.getUri('/public/stats')).thenThrow(
      const ApiException(type: ApiExceptionType.network),
    );
    await expectLater(repo.getStats(), throwsA(isA<ApiException>()));
  });

  test('server 500 maps to ApiException.server', () async {
    when(() => api.getUri('/public/stats')).thenAnswer(
      (_) => Future.error(_serverError(500)),
    );
    await expectLater(
      repo.getStats(),
      throwsA(
          isA<ApiException>().having((e) => e.isServer, 'isServer', isTrue)),
    );
  });
}

RequestOptions _options(String path) => RequestOptions(path: path);

ApiException _serverError(int status) {
  final options = _options('/public/stats');
  final err = DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: {}),
  );
  return ApiException.fromDio(err);
}
