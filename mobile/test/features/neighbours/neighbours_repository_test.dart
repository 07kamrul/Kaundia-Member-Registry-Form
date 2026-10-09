import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/neighbours/data/neighbours_repository_impl.dart';
import 'package:kaundia_app/features/neighbours/domain/neighbour_entities.dart';
import 'package:kaundia_app/features/neighbours/domain/neighbours_failure.dart';
import 'package:kaundia_app/features/neighbours/domain/neighbours_repository.dart';
import 'package:mocktail/mocktail.dart';

import 'neighbours_fixtures.dart';

class _MockApiClient extends Mock implements ApiClient {}

ApiException _dioError(int status, Object? data) {
  final options = RequestOptions(path: '/member/neighbours');
  return ApiException.fromDio(DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: data),
  ));
}

void main() {
  late _MockApiClient api;
  late NeighboursRepositoryImpl repo;

  setUp(() {
    api = _MockApiClient();
    repo = NeighboursRepositoryImpl(apiClient: api);
  });

  test('omits dag_type when not provided', () async {
    when(() => api.getUri('/member/neighbours', query: any(named: 'query')))
        .thenAnswer((_) async => neighboursJson());
    final d = await repo.getNeighbours();
    expect(d.properties, hasLength(2));
    final q = verify(() => api.getUri('/member/neighbours',
        query: captureAny(named: 'query'))).captured.single;
    expect(q, isNull);
  });

  test('sends dag_type when provided and the use case forwards it', () async {
    when(() => api.getUri('/member/neighbours', query: any(named: 'query')))
        .thenAnswer((_) async => neighboursJson());
    await GetNeighbours(repo)(dagType: DagType.cs);
    final q = verify(() => api.getUri('/member/neighbours',
        query: captureAny(named: 'query'))).captured.single;
    expect(q, {'dag_type': 'cs'});
  });

  test('surfaces ApiException from the client', () async {
    when(() => api.getUri('/member/neighbours', query: any(named: 'query')))
        .thenThrow(_dioError(500, {'detail': 'boom'}));
    await expectLater(repo.getNeighbours(), throwsA(isA<ApiException>()));
  });

  test('non-map payload throws FormatException', () async {
    when(() => api.getUri('/member/neighbours', query: any(named: 'query')))
        .thenAnswer((_) async => []);
    await expectLater(repo.getNeighbours(), throwsA(isA<FormatException>()));
  });

  group('ApiException.errorCode + failure mapping', () {
    test('403 approved-only code', () {
      final e = _dioError(403, {
        'detail': {'code': neighbourApprovedOnlyCode, 'message': 'x'},
      });
      expect(e.errorCode, neighbourApprovedOnlyCode);
      expect(e.statusCode, 403);
      expect(e.message, isNull, reason: 'message semantics unchanged');
      expect(neighboursFailureKindOf(e), NeighboursFailureKind.approvedOnly);
    });

    test('429 rate limited', () {
      final e = _dioError(429, {
        'detail': {'code': neighbourRateLimitedCode, 'message': 'x'},
      });
      expect(neighboursFailureKindOf(e), NeighboursFailureKind.rateLimited);
    });

    test('plain 403 (missing permission) is a generic failure', () {
      final e = _dioError(403, {'detail': 'Forbidden'});
      expect(e.errorCode, isNull);
      expect(e.message, 'Forbidden');
      expect(neighboursFailureKindOf(e), NeighboursFailureKind.other);
    });

    test('network and business errors', () {
      expect(
        neighboursFailureKindOf(const ApiException(type: ApiExceptionType.network)),
        NeighboursFailureKind.network,
      );
      final business = _dioError(400, {'detail': 'nope'});
      expect(business.businessMessage, 'nope');
      expect(business.errorCode, isNull);
      expect(neighboursFailureKindOf(business), NeighboursFailureKind.other);
    });
  });
}
