const MONTH_KEYS = [
  '',
  'common.months.january',
  'common.months.february',
  'common.months.march',
  'common.months.april',
  'common.months.may',
  'common.months.june',
  'common.months.july',
  'common.months.august',
  'common.months.september',
  'common.months.october',
  'common.months.november',
  'common.months.december',
];

/** Returns the translation key for the given 1-indexed month, to be resolved via the `translate` pipe/service. */
export function monthNameKey(month: number): string {
  return MONTH_KEYS[month] ?? String(month);
}
