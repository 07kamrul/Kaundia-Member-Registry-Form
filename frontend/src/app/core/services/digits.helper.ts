const BANGLA_DIGITS = '০১২৩৪৫৬৭৮৯';

/**
 * Bangla digits -> ASCII; other characters are kept. Shared by the plot-map
 * pages for dag-number search and digit localisation. Kept dependency-free
 * so admin chunks never pull Leaflet/turf for it.
 */
export function toAsciiDigits(text: string): string {
  return text.replace(/[০-৯]/g, (digit) => String(BANGLA_DIGITS.indexOf(digit)));
}
