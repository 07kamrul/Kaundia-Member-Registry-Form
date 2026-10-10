import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/plot_boundary/domain/boundary_validation.dart';
import 'package:kaundia_app/features/plot_boundary/domain/geo.dart';
import 'package:latlong2/latlong.dart';

// ~ 111 m x 102 m square near Uttar Kaundia (~ 2.8 shotangsho per 100 m²).
const _square = [
  LatLng(23.800, 90.320),
  LatLng(23.801, 90.320),
  LatLng(23.801, 90.321),
  LatLng(23.800, 90.321),
];

const _society = SocietyBbox(
  minLng: 90.3000,
  minLat: 23.7800,
  maxLng: 90.3470,
  maxLat: 23.8380,
);

void main() {
  group('parseDeclaredShotangsho', () {
    test('parses plain and Bangla numerals', () {
      expect(parseDeclaredShotangsho('5'), 5);
      expect(parseDeclaredShotangsho('৫.৫'), 5.5);
      expect(parseDeclaredShotangsho(' 12 '), 12);
    });

    test('ignores free text such as shares', () {
      expect(parseDeclaredShotangsho('3/1'), isNull);
      expect(parseDeclaredShotangsho('about 5'), isNull);
      expect(parseDeclaredShotangsho(''), isNull);
      expect(parseDeclaredShotangsho(null), isNull);
    });
  });

  group('area mismatch warning', () {
    final drawn = validate(_square).areaShotangsho;

    test('is raised when the drawn area is far from the declared one', () {
      final v = validate(_square, declaredShotangsho: drawn / 3);
      expect(v.areaMismatch, isTrue);
      expect(v.canSave, isTrue, reason: 'a warning must never block saving');
    });

    test('is not raised within the 35% tolerance', () {
      expect(
          validate(_square, declaredShotangsho: drawn).areaMismatch, isFalse);
      expect(
        validate(_square, declaredShotangsho: drawn * 1.2).areaMismatch,
        isFalse,
      );
    });

    test('is not raised without a usable declared quantity', () {
      expect(validate(_square).areaMismatch, isFalse);
      expect(validate(_square, declaredShotangsho: 0).areaMismatch, isFalse);
    });
  });

  group('outside-society check', () {
    test('passes for a ring inside the society bbox', () {
      expect(validate(_square, bbox: _society).error, isNull);
    });

    test('blocks a ring that leaves the society bbox', () {
      final outside = [
        for (final p in _square) LatLng(p.latitude, p.longitude + 0.1),
      ];
      expect(
        validate(outside, bbox: _society).error,
        BoundaryError.outsideSociety,
      );
    });
  });
}
