import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/features/plot_boundary/data/land_data_dtos.dart';
import 'package:kaundia_app/features/plot_boundary/data/land_data_repository_impl.dart';
import 'package:kaundia_app/features/plot_boundary/domain/dag_number.dart';
import 'package:kaundia_app/features/plot_boundary/domain/geo.dart';
import 'package:kaundia_app/features/plot_boundary/domain/land_entities.dart';
import 'package:kaundia_app/features/plot_boundary/domain/land_mappers.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

const _square = [
  [90.30, 23.80],
  [90.31, 23.80],
  [90.31, 23.81],
  [90.30, 23.81],
  [90.30, 23.80],
];

Map<String, dynamic> _feature(
  String type,
  List<dynamic> coordinates, {
  Map<String, dynamic> props = const {},
}) =>
    {
      'type': 'Feature',
      'properties': props,
      'geometry': {'type': type, 'coordinates': coordinates},
    };

void main() {
  group('normalizeDagNo', () {
    test('strips the RS prefix and trims', () {
      expect(normalizeDagNo(' RS-4611 '), '4611');
      expect(normalizeDagNo('rs4611'), '4611');
    });

    test('converts Bangla digits to ASCII', () {
      expect(normalizeDagNo('৪৬১১'), '4611');
    });

    test('keeps plain numbers unchanged', () {
      expect(normalizeDagNo('4611'), '4611');
    });
  });

  group('land mappers', () {
    test('maps a Polygon to one ring with lat/lng order', () {
      final dto = LandCollectionDto.fromJson({
        'truncated': true,
        'features': [
          _feature('Polygon', [
            _square
          ], props: {
            'dag': '120',
            'sheet': '3',
            'area_sqm': 250.5,
          }),
        ],
      });
      final collection = dto.toEntity();

      expect(collection.truncated, isTrue);
      final plot = collection.plots.single;
      expect(plot.rings.single.first, const LatLng(23.80, 90.30));
      expect(plot.dag, '120');
      expect(plot.sheet, '3');
      expect(plot.areaSqm, 250.5);
    });

    test('maps a MultiPolygon to one ring per part, skipping holes', () {
      final collection = LandCollectionDto.fromJson({
        'features': [
          _feature('MultiPolygon', [
            [_square, _square],
            [_square],
          ]),
        ],
      }).toEntity();

      expect(collection.plots.single.rings, hasLength(2));
    });

    test('drops features without drawable geometry', () {
      final collection = LandCollectionDto.fromJson({
        'features': [
          _feature('Point', [90.3, 23.8]),
          _feature('Polygon', [
            [
              [90.3, 23.8],
              [90.4, 23.9],
            ],
          ]),
          'garbage',
        ],
      }).toEntity();

      expect(collection.plots, isEmpty);
    });

    test('dagKey falls back from dag to rs_plot_no to plot_no', () {
      final bds = LandPlot(rings: const [], dag: '৪৬১১');
      final rs = LandPlot(rings: const [], rsPlotNo: 'RS-77');
      final plain = LandPlot(rings: const [], plotNo: '9');

      expect(bds.dagKey, '4611');
      expect(rs.dagKey, '77');
      expect(plain.dagKey, '9');
      expect(LandPlot(rings: const []).dagKey, '');
    });
  });

  group('hit testing', () {
    final ring = [
      const LatLng(23.80, 90.30),
      const LatLng(23.80, 90.31),
      const LatLng(23.81, 90.31),
      const LatLng(23.81, 90.30),
    ];

    test('pointInRing is true inside and false outside', () {
      expect(pointInRing(const LatLng(23.805, 90.305), ring), isTrue);
      expect(pointInRing(const LatLng(23.82, 90.305), ring), isFalse);
    });

    test('plotAt returns the top-most plot under the point', () {
      final lower = LandPlot(rings: [ring], dag: 'lower');
      final upper = LandPlot(rings: [ring], dag: 'upper');
      final collection = LandCollection(plots: [lower, upper]);

      expect(collection.plotAt(const LatLng(23.805, 90.305))?.dag, 'upper');
      expect(collection.plotAt(const LatLng(24, 91)), isNull);
    });
  });

  group('SocietyBbox helpers', () {
    const bbox = SocietyBbox(
      minLng: 90.0,
      minLat: 23.0,
      maxLng: 91.0,
      maxLat: 24.0,
    );

    test('padded grows every side by the ratio of its size', () {
      final padded = bbox.padded(0.25);
      expect(padded.minLng, closeTo(89.75, 1e-9));
      expect(padded.maxLat, closeTo(24.25, 1e-9));
    });

    test('containsBox is true only for fully enclosed boxes', () {
      expect(bbox.padded(0.25).containsBox(bbox), isTrue);
      expect(bbox.containsBox(bbox.padded(0.25)), isFalse);
    });

    test('around builds the smallest box and is null when empty', () {
      final around = SocietyBbox.around(
        const [LatLng(23.1, 90.2), LatLng(23.9, 90.8)],
      );
      expect(around?.minLat, 23.1);
      expect(around?.maxLng, 90.8);
      expect(SocietyBbox.around(const []), isNull);
    });
  });

  group('LandDataRepositoryImpl', () {
    late _MockApiClient api;
    late LandDataRepositoryImpl repo;

    setUp(() {
      api = _MockApiClient();
      repo = LandDataRepositoryImpl(apiClient: api);
    });

    test('plotsInBbox hits /land/dags for BDS with the bbox query', () async {
      when(() => api.getUri('/land/dags', query: any(named: 'query')))
          .thenAnswer((_) async => {'features': const []});

      await repo.plotsInBbox(
        LandLayer.bds,
        const SocietyBbox(minLng: 1, minLat: 2, maxLng: 3, maxLat: 4),
      );

      verify(() => api.getUri('/land/dags', query: {'bbox': '1.0,2.0,3.0,4.0'}))
          .called(1);
    });

    test('plotsInBbox hits /land/masterplan for RAJUK', () async {
      when(() => api.getUri('/land/masterplan', query: any(named: 'query')))
          .thenAnswer((_) async => {'features': const []});

      await repo.plotsInBbox(
        LandLayer.rajuk,
        const SocietyBbox(minLng: 1, minLat: 2, maxLng: 3, maxLat: 4),
      );

      verify(() => api.getUri('/land/masterplan', query: any(named: 'query')))
          .called(1);
    });

    test('lookup targets the layer specific endpoint', () async {
      when(() => api.getUri(any()))
          .thenAnswer((_) async => {'features': const []});

      await repo.lookup(LandLayer.bds, '4611');
      await repo.lookup(LandLayer.rajuk, 'RS-4611');

      verify(() => api.getUri('/land/dag/bds/lookup/4611')).called(1);
      verify(() => api.getUri('/land/masterplan/lookup/RS-4611')).called(1);
    });

    test('throws FormatException on a non-object payload', () async {
      when(() => api.getUri(any())).thenAnswer((_) async => 'oops');

      expect(
        () => repo.lookup(LandLayer.bds, '1'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
