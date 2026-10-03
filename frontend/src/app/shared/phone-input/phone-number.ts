import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';
import {
  CountryCode,
  getCountries,
  getCountryCallingCode,
  isValidPhoneNumber,
  parsePhoneNumberFromString,
} from 'libphonenumber-js';

/**
 * Country preselected in the picker, and assumed for numbers typed without a
 * leading "+" (e.g. legacy "01712345678" values). Must match
 * DEFAULT_PHONE_REGION in backend/app/services/normalization.py.
 */
export const DEFAULT_PHONE_COUNTRY: CountryCode = 'BD';

export interface PhoneCountry {
  code: CountryCode;
  name: string;
  dialCode: string;
  flag: string;
}

export interface SplitPhoneNumber {
  country: CountryCode;
  nationalNumber: string;
}

const REGIONAL_INDICATOR_OFFSET = 0x1f1e6 - 'A'.charCodeAt(0);

function flagEmoji(code: string): string {
  return String.fromCodePoint(...[...code].map((c) => c.charCodeAt(0) + REGIONAL_INDICATOR_OFFSET));
}

function regionNames(locale: string): Intl.DisplayNames | null {
  try {
    return new Intl.DisplayNames([locale, 'en'], { type: 'region' });
  } catch {
    return null;
  }
}

/** Every country libphonenumber knows, sorted by localized name. */
export function listPhoneCountries(locale = 'en'): PhoneCountry[] {
  const names = regionNames(locale);
  return getCountries()
    .map((code) => ({
      code,
      name: names?.of(code) ?? code,
      dialCode: `+${getCountryCallingCode(code)}`,
      flag: flagEmoji(code),
    }))
    .sort((a, b) => a.name.localeCompare(b.name, locale));
}

export function filterPhoneCountries(countries: PhoneCountry[], query: string): PhoneCountry[] {
  const term = query.trim().toLowerCase();
  if (!term) return countries;
  const digits = term.replace(/\D/g, '');
  return countries.filter(
    (country) =>
      country.name.toLowerCase().includes(term) ||
      country.code.toLowerCase() === term ||
      (digits !== '' && country.dialCode.slice(1).startsWith(digits)),
  );
}

/** Split a stored value (E.164 or legacy national) into country + national digits. */
export function splitPhoneNumber(
  value: string | null | undefined,
  fallbackCountry: CountryCode = DEFAULT_PHONE_COUNTRY,
): SplitPhoneNumber {
  const raw = (value ?? '').trim();
  if (!raw) return { country: fallbackCountry, nationalNumber: '' };
  const parsed = parsePhoneNumberFromString(raw, fallbackCountry);
  if (parsed?.country) {
    return { country: parsed.country, nationalNumber: parsed.nationalNumber };
  }
  return { country: fallbackCountry, nationalNumber: raw.replace(/\D/g, '') };
}

/**
 * Combine the picker's country with what the user typed. Returns E.164 when
 * the number parses; otherwise a best-effort "+<code><digits>" string so the
 * validator can still flag it as invalid instead of the control looking empty.
 */
export function composePhoneNumber(country: CountryCode, input: string): string {
  const trimmed = input.trim();
  if (!trimmed) return '';
  const parsed = parsePhoneNumberFromString(trimmed, country);
  if (parsed) return parsed.number;
  return `+${getCountryCallingCode(country)}${trimmed.replace(/\D/g, '')}`;
}

export function isValidInternationalPhone(value: string | null | undefined): boolean {
  const raw = (value ?? '').trim();
  return raw !== '' && isValidPhoneNumber(raw, DEFAULT_PHONE_COUNTRY);
}

/** Empty values pass (pair with Validators.required); anything else must be a valid number. */
export const internationalPhoneValidator: ValidatorFn = (
  control: AbstractControl,
): ValidationErrors | null => {
  const value = control.value as string | null;
  if (!value?.trim()) return null;
  return isValidInternationalPhone(value) ? null : { phoneInvalid: true };
};
