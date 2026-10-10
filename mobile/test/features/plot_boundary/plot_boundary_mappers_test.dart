import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kaundia_app/features/plot_boundary/data/plot_boundary_dtos.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_entities.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_mappers.dart';

void main() {
  group('MapFeatureDto -> BoundaryFeature', () {
    test('axis order: GeoJSON [lng, lat] becomes LatLng(lat, lng)', () {
      final dto = MapFeatureDto.fromJson({
        'boundary_id': 'b1',
        'property_id': 'p1',
        'status': 'approved',
        'is_mine': false,
        'rs_dag': '120',
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
      });
      final e = dto.toEntity();
      expect(e.boundaryId, 'b1');
      expect(e.status, BoundaryStatus.approved);
      expect(e.points.first, const LatLng(23.81, 90.41));
      expect(e.points.last, const LatLng(23.81, 90.41));
    });

    test('status names map to the enum', () {
      BoundaryStatus statusOf(String s) => MapFeatureDto.fromJson({
            'boundary_id': 'b',
            'property_id': 'p',
            'status': s,
            'is_mine': false,
            'geometry': null,
          }).toEntity().status;
      expect(statusOf('pending_review'), BoundaryStatus.pendingReview);
      expect(statusOf('disputed'), BoundaryStatus.disputed);
      expect(statusOf('rejected'), BoundaryStatus.rejected);
      expect(statusOf('draft'), BoundaryStatus.draft);
      expect(statusOf('bogus'), BoundaryStatus.draft);
    });
  });

  group('BoundaryOwnerDto -> BoundaryOwner', () {
    test('hidden contact nulls the mobile, visible contact keeps it', () {
      final hidden = BoundaryOwnerDto.fromJson({
        'boundary_id': 'b',
        'owner_name': 'Rahim',
        'mobile': '01712345678',
        'contact_hidden': true,
        'status': 'approved',
        'computed_area_sqm': 500.5,
        'computed_area_shotangsho': 12.37,
      }).toEntity();
      expect(hidden.mobile, isNull);
      expect(hidden.contactHidden, isTrue);
      expect(hidden.areaSqm, 500.5);

      final visible = BoundaryOwnerDto.fromJson({
        'boundary_id': 'b',
        'owner_name': 'Rahim',
        'mobile': '01712345678',
        'contact_hidden': false,
        'status': 'approved',
      }).toEntity();
      expect(visible.mobile, '01712345678');
    });
  });

  group('MyBoundaryDto -> PlotBoundary', () {
    test('maps id, warnings and area', () {
      final e = MyBoundaryDto.fromJson({
        'id': 'b9',
        'property_id': 'p9',
        'status': 'pending_review',
        'geometry': {
          'coordinates': [
            [
              [90.41, 23.81],
              [90.42, 23.82],
              [90.43, 23.81],
              [90.41, 23.81],
            ]
          ],
        },
        'computed_area_sqm': 404.7,
        'computed_area_shotangsho': 10.0,
        'current_version': 2,
        'review_note': 'check corners',
        'warnings': ['AREA_MISMATCH: 10 vs 8'],
      }).toEntity();
      expect(e.id, 'b9');
      expect(e.status, BoundaryStatus.pendingReview);
      expect(e.currentVersion, 2);
      expect(e.reviewNote, 'check corners');
      expect(e.warnings, hasLength(1));
      expect(e.areaShotangsho, 10.0);
      expect(e.points, hasLength(4));
    });
  });

  group('polygonBody (domain -> request)', () {
    test('produces RFC 7946 [lng, lat] with a closed ring', () {
      final body = polygonBody(const [
        LatLng(23.81, 90.41),
        LatLng(23.82, 90.42),
        LatLng(23.83, 90.43),
      ]);
      expect(body['type'], 'Polygon');
      final ring = (body['coordinates'] as List).first as List;
      expect(ring.first, [90.41, 23.81]);
      expect(ring.last, ring.first);
    });

    test('round trip through dtoRingToLatLng preserves the vertices', () {
      const pts = [
        LatLng(23.81, 90.41),
        LatLng(23.82, 90.42),
        LatLng(23.83, 90.43),
      ];
      final body = polygonBody(pts);
      final ring = (body['coordinates'] as List).first as List;
      expect(ringToLatLngTestHelper(ring), [...pts, pts.first]);
    });
  });
}

// Local helper mirroring the mapper entry point for request bodies.
List<LatLng> ringToLatLngTestHelper(List<dynamic> ring) =>
    dtoRingToLatLng(PolygonGeometryDto(ring));
