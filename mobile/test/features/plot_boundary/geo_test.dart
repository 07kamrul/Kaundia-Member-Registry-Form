import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kaundia_app/features/plot_boundary/domain/geo.dart';

void main() {
  group('GeoJSON ring <-> LatLng axis conversion', () {
    test('ringToLatLng reads [lng, lat] into LatLng(lat, lng)', () {
      final points = ringToLatLng([
        [90.41, 23.81],
        [90.42, 23.82],
      ]);
      expect(points[0], const LatLng(23.81, 90.41));
      expect(points[1], const LatLng(23.82, 90.42));
    });

    test('latLngToRing writes [lng, lat] and closes the ring', () {
      final ring = latLngToRing(const [
        LatLng(23.81, 90.41),
        LatLng(23.82, 90.42),
        LatLng(23.83, 90.43),
      ]);
      expect(ring, hasLength(4));
      expect(ring.first, [90.41, 23.81]);
      expect(ring[1], [90.42, 23.82]);
      expect(ring.last, ring.first, reason: 'GeoJSON rings must be closed');
    });

    test('round trip is stable for an open ring', () {
      const open = [
        LatLng(23.81, 90.41),
        LatLng(23.82, 90.42),
        LatLng(23.83, 90.43),
      ];
      // The round trip yields the ring closed (first == last).
      expect(ringToLatLng(latLngToRing(open)), [...open, open.first]);
    });

    test('latLngToRing of an already-closed ring does not double-close', () {
      final ring = latLngToRing(const [
        LatLng(23.81, 90.41),
        LatLng(23.82, 90.42),
        LatLng(23.81, 90.41),
      ]);
      expect(ring, hasLength(3));
    });

    test('ringToLatLng skips malformed positions', () {
      final points = ringToLatLng([
        'oops',
        [90.41],
        [90.41, 23.81],
        [double.nan, 23.82],
      ]);
      expect(points, const [LatLng(23.81, 90.41)]);
    });
  });

  group('SocietyBbox', () {
    const raw = '90.30,23.70,90.50,23.90';
    final bbox = SocietyBbox.parse(raw);

    test('parses minLng,minLat,maxLng,maxLat', () {
      expect(bbox.minLng, 90.30);
      expect(bbox.minLat, 23.70);
      expect(bbox.maxLng, 90.50);
      expect(bbox.maxLat, 23.90);
      expect(bbox.queryValue, '90.3,23.7,90.5,23.9');
    });

    test('contains / rejects points', () {
      expect(bbox.contains(const LatLng(23.80, 90.40)), isTrue);
      expect(bbox.contains(const LatLng(23.95, 90.40)), isFalse);
      expect(bbox.contains(const LatLng(23.80, 90.60)), isFalse);
    });

    test('parse rejects garbage', () {
      expect(() => SocietyBbox.parse('1,2,3'), throwsFormatException);
      expect(() => SocietyBbox.parse('a,b,c,d'), throwsFormatException);
    });
  });

  group('isSelfIntersecting', () {
    test('simple square is clean', () {
      expect(
        isSelfIntersecting(const [
          LatLng(23.80, 90.40),
          LatLng(23.81, 90.40),
          LatLng(23.81, 90.41),
          LatLng(23.80, 90.41),
        ]),
        isFalse,
      );
    });

    test('bowtie (figure-8) crosses itself', () {
      expect(
        isSelfIntersecting(const [
          LatLng(23.80, 90.40),
          LatLng(23.81, 90.41),
          LatLng(23.81, 90.40),
          LatLng(23.80, 90.41),
        ]),
        isTrue,
      );
    });

    test('closed ring input is handled (closing vertex ignored)', () {
      expect(
        isSelfIntersecting(const [
          LatLng(23.80, 90.40),
          LatLng(23.81, 90.40),
          LatLng(23.81, 90.41),
          LatLng(23.80, 90.41),
          LatLng(23.80, 90.40),
        ]),
        isFalse,
      );
    });

    test('fewer than 3 distinct points never intersects', () {
      expect(
        isSelfIntersecting(const [LatLng(23.8, 90.4), LatLng(23.81, 90.4)]),
        isFalse,
      );
    });
  });

  group('area estimate', () {
    test('roughly 100m x 100m square near Dhaka (estimate)', () {
      // 0.0009 deg lat ~ 100 m; 0.001 deg lng ~ 101.7 m at lat 23.8.
      final area = estimateAreaSqm(const [
        LatLng(23.8000, 90.4000),
        LatLng(23.8009, 90.4000),
        LatLng(23.8009, 90.4010),
        LatLng(23.8000, 90.4010),
      ]);
      expect(area, inInclusiveRange(9500, 10800));
      expect(sqmToShotangsho(area), inInclusiveRange(area / 40.5, area / 40.4));
    });

    test('degenerate ring has zero area', () {
      expect(
        estimateAreaSqm(const [
          LatLng(23.8, 90.4),
          LatLng(23.81, 90.4),
        ]),
        0,
      );
    });
  });
}
