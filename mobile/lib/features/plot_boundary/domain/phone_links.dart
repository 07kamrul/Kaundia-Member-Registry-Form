// Pure helpers turning a stored mobile number into dialer / WhatsApp links.
//
// Numbers arrive in mixed shapes ("+8801712345678", "01712345678", Bangla
// digits, spaces/dashes). Everything is normalised to bare international
// digits ("8801712345678"); anything that cannot be normalised is `null`, so
// the UI simply hides the contact buttons instead of opening a broken link.

const String _banglaDigits = '০১২৩৪৫৬৭৮৯';

final RegExp _separators = RegExp(r'[\s\-().]');
final RegExp _allDigits = RegExp(r'^\d+$');

/// Bangladesh mobile in international form: 880 + 1 + 9 digits.
final RegExp _bdInternational = RegExp(r'^8801\d{9}$');

/// Bangladesh mobile in local form: 01 + 9 digits.
final RegExp _bdLocal = RegExp(r'^01\d{9}$');

/// Any other E.164 number (country code cannot start with 0, max 15 digits).
final RegExp _e164 = RegExp(r'^[1-9]\d{6,14}$');

const String _bdCountryPrefix = '88';

String _toAsciiDigits(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final index = _banglaDigits.indexOf(char);
    buffer.write(index >= 0 ? '$index' : char);
  }
  return buffer.toString();
}

/// Normalises [mobile] to bare international digits, or `null` when it is not
/// a dialable number.
String? toInternationalDigits(String? mobile) {
  if (mobile == null) return null;
  final cleaned = _toAsciiDigits(mobile).replaceAll(_separators, '');
  if (cleaned.isEmpty) return null;

  final hasPlus = cleaned.startsWith('+');
  final digits = hasPlus ? cleaned.substring(1) : cleaned;
  if (!_allDigits.hasMatch(digits)) return null;

  if (digits.startsWith('880')) {
    return _bdInternational.hasMatch(digits) ? digits : null;
  }
  if (!hasPlus) {
    return _bdLocal.hasMatch(digits) ? '$_bdCountryPrefix$digits' : null;
  }
  return _e164.hasMatch(digits) ? digits : null;
}

/// `tel:+<digits>` for the platform dialer.
Uri? telUri(String? mobile) {
  final digits = toInternationalDigits(mobile);
  if (digits == null) return null;
  return Uri(scheme: 'tel', path: '+$digits');
}

/// `https://wa.me/<digits>` click-to-chat link.
Uri? whatsAppUri(String? mobile) {
  final digits = toInternationalDigits(mobile);
  if (digits == null) return null;
  return Uri.https('wa.me', '/$digits');
}
