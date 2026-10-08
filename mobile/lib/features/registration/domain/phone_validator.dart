/// International phone validation mirroring Angular phone-number.ts
/// (isValidInternationalPhone with DEFAULT_PHONE_COUNTRY 'BD').
///
/// Simplification: without libphonenumber-js we cannot validate every country's
/// numbering plan. We accept any plausible E.164 number (+ up to 15 digits) and
/// apply the real BD numbering plan for the default region — the same cases the
/// form actually encounters (BD mobiles typed with or without +880).
bool isValidInternationalPhone(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return false;

  final digits = raw.replaceAll(RegExp(r'[\s\-().]'), '');

  // Explicit international format: +<countrycode><subscriber>.
  if (digits.startsWith('+')) {
    final e164 = digits.substring(1);
    if (!RegExp(r'^\d{8,15}$').hasMatch(e164)) return false;
    // +880 BD numbers must match the BD mobile plan (1[3-9]XXXXXXXX).
    if (e164.startsWith('880')) {
      return RegExp(r'^8801[3-9]\d{8}$').hasMatch(e164);
    }
    return true;
  }

  // No country code: assume BD (mirrors composePhoneNumber fallback).
  final national = digits.startsWith('0') ? digits : '0$digits';
  return RegExp(r'^01[3-9]\d{8}$').hasMatch(national);
}
