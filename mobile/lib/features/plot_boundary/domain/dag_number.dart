const String _banglaDigits = '০১২৩৪৫৬৭৮৯';

/// Bangla digits -> ASCII digits (other characters untouched).
String toAsciiDigits(String text) => text.replaceAllMapped(
      RegExp('[$_banglaDigits]'),
      (m) => '${_banglaDigits.indexOf(m.group(0)!)}',
    );

/// Dag numbers compare as ASCII digits without the "RS-" prefix, so "4611",
/// "RS-4611" and Bangla digits all resolve to the same plot (mirrors the
/// Angular `normalizeDagNo`).
String normalizeDagNo(String value) => toAsciiDigits(value)
    .trim()
    .toUpperCase()
    .replaceFirst(RegExp(r'^RS-?'), '');
