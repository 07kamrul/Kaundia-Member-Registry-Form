import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/plot_boundary/domain/phone_links.dart';
import 'package:kaundia_app/features/plot_boundary/domain/street_view.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('streetViewUri builds the Google pano deep link', () {
    final uri = streetViewUri(const LatLng(23.809, 90.323));

    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['map_action'], 'pano');
    expect(uri.queryParameters['viewpoint'], '23.809,90.323');
  });

  group('phone links', () {
    test('telUri accepts Bangla digits and local numbers', () {
      expect(telUri('০১৭১২৩৪৫৬৭৮')?.scheme, 'tel');
      expect(telUri('01712345678')?.toString(), contains('01712345678'));
    });

    test('whatsAppUri uses the international form', () {
      final uri = whatsAppUri('01712345678');
      expect(uri?.host, 'wa.me');
      expect(uri?.path, '/8801712345678');
    });

    test('blank or missing numbers yield no link', () {
      expect(telUri(null), isNull);
      expect(telUri('  '), isNull);
      expect(whatsAppUri(null), isNull);
    });
  });
}
