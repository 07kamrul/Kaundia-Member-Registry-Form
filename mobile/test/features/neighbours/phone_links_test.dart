import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/neighbours/domain/phone_links.dart';

void main() {
  group('toInternationalDigits', () {
    test('keeps +880 numbers as bare international digits', () {
      expect(toInternationalDigits('+8801712345678'), '8801712345678');
    });

    test('accepts 880 numbers without the plus sign', () {
      expect(toInternationalDigits('8801712345678'), '8801712345678');
    });

    test('prefixes local 01X numbers with the BD country code', () {
      expect(toInternationalDigits('01712345678'), '8801712345678');
    });

    test('converts Bangla digits and strips spaces, dashes and parens', () {
      expect(toInternationalDigits('০১৭১২-৩৪৫ ৬৭৮'), '8801712345678');
      expect(toInternationalDigits('+880 (1712) 345-678'), '8801712345678');
      expect(toInternationalDigits('+৮৮০১৭১২৩৪৫৬৭৮'), '8801712345678');
    });

    test('passes other E.164 numbers through as digits', () {
      expect(toInternationalDigits('+447911123456'), '447911123456');
    });

    test('returns null for missing or junk input', () {
      expect(toInternationalDigits(null), isNull);
      expect(toInternationalDigits(''), isNull);
      expect(toInternationalDigits('   '), isNull);
      expect(toInternationalDigits('not a number'), isNull);
      expect(toInternationalDigits('12345'), isNull);
      expect(toInternationalDigits('+88017'), isNull);
      expect(toInternationalDigits('0171234567'), isNull);
      expect(toInternationalDigits('+0123456789'), isNull);
      expect(toInternationalDigits('+1234567890123456'), isNull);
    });
  });

  group('telUri', () {
    test('builds a tel: URI with a leading plus', () {
      expect(telUri('01712345678').toString(), 'tel:+8801712345678');
    });

    test('is null when the number cannot be normalised', () {
      expect(telUri(null), isNull);
      expect(telUri('abc'), isNull);
    });
  });

  group('whatsAppUri', () {
    test('builds a wa.me link with bare digits', () {
      expect(
        whatsAppUri('+8801712345678').toString(),
        'https://wa.me/8801712345678',
      );
    });

    test('is null when the number cannot be normalised', () {
      expect(whatsAppUri(''), isNull);
    });
  });
}
