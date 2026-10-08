import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/config/app_config.dart';

void main() {
  test('fileUrl percent-encodes each path segment and strips /api', () {
    final url = AppConfig.fileUrl('/uploads/২০২৪/photo 1.jpg');
    expect(url, isNot(contains('/api/')));
    expect(url, contains('/uploads/'));
    expect(url, contains(Uri.encodeComponent('photo 1.jpg')));
  });
}
