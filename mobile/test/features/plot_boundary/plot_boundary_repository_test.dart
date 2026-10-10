import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/plot_boundary/data/plot_boundary_repository_impl.dart';
import 'package:kaundia_app/features/plot_boundary/domain/geo.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_entities.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_failure.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

ApiException _dioError(int status, Object? data) {
  final options = RequestOptions(path: '/member/plot-map');
  return ApiException.fromDio(DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: data),
  ));
}

const _plotMapPayload = {
  'disclaimer_en': 'approximate',
  'disclaimer_bn': 'আনুমানিক',
  'count': 1,
  'features': [
    {
      'boundary_id': 'b1',
      'property_id': 'p1',
      'rs_dag': '120',
      'status': 'approved',
      'is_mine': false,
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [90.41, 23.81],
            [90.42, 23.82],
            [90.41, 23.81],
          ]
        ],
      },
    }
  ],
};

void main() {
  late _MockApiClient api;
  late PlotBoundaryRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(SocietyBbox.parse('0,0,1,1'));
  });

  setUp(() {
    api = _MockApiClient();
    repo = PlotBoundaryRepositoryImpl(apiClient: api);
  });

  group('getPlotMap', () {
    test('sends bbox query and maps features', () async {
      when(() => api.getUri('/member/plot-map', query: any(named: 'query')))
          .thenAnswer((_) async => _plotMapPayload);
      final features =
          await repo.getPlotMap(SocietyBbox.parse('90.30,23.70,90.50,23.90'));
      expect(features, hasLength(1));
      expect(features.single.status, BoundaryStatus.approved);
      final q = verify(() =>
              api.getUri('/member/plot-map', query: captureAny(named: 'query')))
          .captured
          .single as Map<String, dynamic>;
      expect(q['bbox'], '90.3,23.7,90.5,23.9');
    });

    test('non-map payload throws FormatException', () async {
      when(() => api.getUri('/member/plot-map', query: any(named: 'query')))
          .thenAnswer((_) async => 'nope');
      await expectLater(
          repo.getPlotMap(SocietyBbox.parse('90.3,23.7,90.5,23.9')),
          throwsA(isA<FormatException>()));
    });
  });

  group('create / update', () {
    test('POST sends property_id + geometry and maps the response', () async {
      when(() => api.post('/member/plot-boundaries', any()))
          .thenAnswer((_) async => {
                'id': 'b2',
                'property_id': 'p2',
                'status': 'pending_review',
                'geometry': {
                  'coordinates': [
                    [
                      [90.41, 23.81],
                      [90.42, 23.82],
                      [90.43, 23.83],
                      [90.41, 23.81],
                    ]
                  ],
                },
              });
      final b = await repo.createBoundary(propertyId: 'p2', points: const [
        LatLng(23.81, 90.41),
        LatLng(23.82, 90.42),
        LatLng(23.83, 90.43),
      ]);
      expect(b.status, BoundaryStatus.pendingReview);
      final body =
          verify(() => api.post('/member/plot-boundaries', captureAny()))
              .captured
              .single as Map<String, dynamic>;
      expect(body['property_id'], 'p2');
      final ring = (body['geometry']['coordinates'] as List).first as List;
      expect(ring.first, [90.41, 23.81]);
    });

    test('PUT targets /{id} with geometry only', () async {
      when(() => api.put('/member/plot-boundaries/b2', any()))
          .thenAnswer((_) async => {
                'id': 'b2',
                'property_id': 'p2',
                'status': 'pending_review',
                'geometry': {'coordinates': []},
              });
      await repo.updateBoundary(id: 'b2', points: const [
        LatLng(23.81, 90.41),
        LatLng(23.82, 90.42),
        LatLng(23.83, 90.83),
      ]);
      verify(() => api.put('/member/plot-boundaries/b2', any())).called(1);
    });
  });

  group('getMyProperties', () {
    test('extracts the `own` plots from /member/neighbours', () async {
      when(() => api.getUri('/member/neighbours')).thenAnswer((_) async => {
            'properties': [
              {
                'own': {
                  'property_id': 'p1',
                  'rs_dag': '120',
                  'cs_dag': '55',
                  'land_quantity': '10',
                }
              },
              {'own': null},
            ],
          });
      final props = await repo.getMyProperties();
      expect(props, hasLength(1));
      expect(props.single.propertyId, 'p1');
      expect(props.single.rsDag, '120');
    });
  });

  group('error code -> failure mapping', () {
    Future<PlotBoundaryFailureKind> kindOf(ApiException e) async {
      try {
        await Future<void>.delayed(Duration.zero);
        throw e;
      } on ApiException catch (e) {
        return plotBoundaryFailureKindOf(e);
      }
    }

    final cases = <String, PlotBoundaryFailureKind>{
      'SELF_INTERSECTING': PlotBoundaryFailureKind.selfIntersecting,
      'OUTSIDE_SOCIETY_AREA': PlotBoundaryFailureKind.outsideSociety,
      'ZERO_AREA': PlotBoundaryFailureKind.zeroArea,
      'TOO_MANY_VERTICES': PlotBoundaryFailureKind.tooManyVertices,
      'INVALID_GEOMETRY': PlotBoundaryFailureKind.invalidGeometry,
      'NOT_YOUR_PROPERTY': PlotBoundaryFailureKind.notYourProperty,
      'BOUNDARY_EXISTS': PlotBoundaryFailureKind.boundaryExists,
      'BOUNDARY_OWNER_RATE_LIMITED': PlotBoundaryFailureKind.rateLimited,
      'BOUNDARY_NOT_APPROVED': PlotBoundaryFailureKind.notApproved,
    };
    for (final entry in cases.entries) {
      test('${entry.key} maps correctly', () async {
        final e = _dioError(400, {
          'detail': {'code': entry.key, 'message': 'x'},
        });
        expect(await kindOf(e), entry.value);
      });
    }

    test('plain 429 maps to rateLimited', () async {
      expect(await kindOf(_dioError(429, {'detail': 'slow down'})),
          PlotBoundaryFailureKind.rateLimited);
    });

    test('network failure maps to network', () async {
      final options = RequestOptions(path: '/member/plot-map');
      final e = ApiException.fromDio(DioException.connectionError(
          requestOptions: options, reason: 'offline'));
      expect(plotBoundaryFailureKindOf(e), PlotBoundaryFailureKind.network);
    });
  });
}
