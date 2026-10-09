import { parsePhoneNumberFromString } from 'libphonenumber-js';
import { DEFAULT_PHONE_COUNTRY } from './phone-number';

/**
 * Call / WhatsApp link builders for stored member mobiles.
 *
 * Stored values come in several shapes - E.164 ("+8801712345678"), the
 * calling code without "+" ("8801712345678"), legacy national numbers
 * ("01712345678"), Bangla digits, spaces or dashes - so everything is
 * normalised to international digits before a link is built. Anything that
 * is not a dialable number yields null so the caller can hide the button.
 */

const BENGALI_ZERO_CODE_POINT = 0x09e6;
const BENGALI_DIGIT = /[০-৯]/g;
const BD_CALLING_CODE = '880';
const INTERNATIONAL_PREFIX = '00';
/** Bangladeshi mobile in national form: 01 + operator digit 3-9 + 8 digits. */
const BD_NATIONAL_MOBILE = /^01[3-9]\d{8}$/;

/** "০১৭১২" -> "01712"; other characters are left untouched. */
export function toAsciiDigits(value: string): string {
  return value.replace(BENGALI_DIGIT, (digit) =>
    String(digit.charCodeAt(0) - BENGALI_ZERO_CODE_POINT),
  );
}

/** Strip formatting and make a leading calling code explicit with "+". */
function toDialableForm(raw: string): string {
  const ascii = toAsciiDigits(raw).trim();
  const digits = ascii.replace(/\D/g, '');
  if (!digits) return '';
  if (ascii.startsWith('+')) return `+${digits}`;
  if (digits.startsWith(INTERNATIONAL_PREFIX)) return `+${digits.slice(INTERNATIONAL_PREFIX.length)}`;
  if (digits.startsWith(BD_CALLING_CODE)) return `+${digits}`;
  return digits;
}

/**
 * International digits without "+" (e.g. "8801712345678"), or null when the
 * value is empty or not a valid phone number.
 */
export function toInternationalDigits(mobile: string | null | undefined): string | null {
  if (!mobile) return null;
  const candidate = toDialableForm(mobile);
  if (!candidate) return null;

  const parsed = parsePhoneNumberFromString(candidate, DEFAULT_PHONE_COUNTRY);
  if (parsed?.isValid()) return parsed.number.slice(1);

  // Metadata fallback: a well-formed BD mobile still dials as 8801XXXXXXXXX.
  if (BD_NATIONAL_MOBILE.test(candidate)) return `${BD_CALLING_CODE}${candidate.slice(1)}`;
  return null;
}

/** "tel:+8801712345678", or null when the number is unusable. */
export function telHref(mobile: string | null | undefined): string | null {
  const digits = toInternationalDigits(mobile);
  return digits ? `tel:+${digits}` : null;
}

/** "https://wa.me/8801712345678", or null when the number is unusable. */
export function whatsAppHref(mobile: string | null | undefined): string | null {
  const digits = toInternationalDigits(mobile);
  return digits ? `https://wa.me/${digits}` : null;
}
