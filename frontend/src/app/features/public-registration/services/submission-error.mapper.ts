import { HttpErrorResponse } from '@angular/common/http';

/** Translates an i18n key (with optional params) into display text. */
export type TranslateFn = (key: string, params?: Record<string, unknown>) => string;

export interface MappedSubmissionError {
  messages: string[];
  /** Wizard step holding the first offending field, when it is known. */
  step: number | null;
}

interface FieldError {
  field: string;
  code: string;
}

const KEY_PREFIX = 'registration.submit';

/** Backend payload field (top-level segment) -> wizard step that owns it. */
const FIELD_STEPS: Readonly<Record<string, number>> = {
  full_name: 1,
  father_or_husband: 1,
  mother: 1,
  dob: 1,
  nationality: 1,
  occupation: 1,
  nid: 1,
  mobile: 1,
  gender: 1,
  email: 1,
  permanent_address: 1,
  current_address: 1,
  properties: 2,
  urgent_contact_name: 3,
  urgent_contact_relation: 3,
  urgent_contact_mobile: 3,
  urgent_contact_address: 3,
  nominees: 3,
  admission_fee: 4,
  subscription: 4,
  receipt_no: 4,
  payment_method: 4,
  member_signature: 5,
  submission_date: 5,
};

const SERVER_FAILURE_STATUSES = new Set([500, 502, 503, 504]);
const PAYLOAD_TOO_LARGE = 413;
const UNPROCESSABLE = 422;
const NETWORK_FAILURE = 0;

function detailOf(err: HttpErrorResponse): Record<string, unknown> | null {
  const detail = err.error?.detail;
  return detail && typeof detail === 'object' ? (detail as Record<string, unknown>) : null;
}

function isFieldError(value: unknown): value is FieldError {
  return (
    !!value &&
    typeof value === 'object' &&
    typeof (value as FieldError).field === 'string' &&
    typeof (value as FieldError).code === 'string'
  );
}

function fieldMessage(error: FieldError, t: TranslateFn): string {
  const [root, index] = error.field.split('.');
  const label = FIELD_STEPS[root] !== undefined ? t(`${KEY_PREFIX}.fields.${root}`) : error.field;
  const position = /^\d+$/.test(index ?? '') ? ` ${Number(index) + 1}` : '';
  const reason = error.code === 'missing' ? 'required' : 'invalid';
  return `${label}${position}: ${t(`${KEY_PREFIX}.reasons.${reason}`)}`;
}

function mapFieldErrors(errors: FieldError[], t: TranslateFn): MappedSubmissionError {
  const messages = [...new Set(errors.map((e) => fieldMessage(e, t)))];
  const steps = errors
    .map((e) => FIELD_STEPS[e.field.split('.')[0]])
    .filter((s): s is number => s !== undefined);
  return { messages, step: steps.length > 0 ? Math.min(...steps) : null };
}

function single(key: string, t: TranslateFn, step: number | null = null): MappedSubmissionError {
  return { messages: [t(`${KEY_PREFIX}.${key}`)], step };
}

/**
 * Turns a failed POST /submissions response into user-facing messages.
 * Duplicate-submission 409s are handled separately by the page (modal).
 */
export function mapSubmissionError(err: HttpErrorResponse, t: TranslateFn): MappedSubmissionError {
  if (err.status === NETWORK_FAILURE) return single('networkError', t);
  if (err.status === PAYLOAD_TOO_LARGE) return single('fileTooLarge', t);
  if (SERVER_FAILURE_STATUSES.has(err.status)) return single('serverError', t);

  const detail = detailOf(err);
  const rawErrors = detail?.['errors'];
  const errors = Array.isArray(rawErrors) ? rawErrors.filter(isFieldError) : [];
  if (errors.length > 0) return mapFieldErrors(errors, t);

  switch (detail?.['code']) {
    case 'FEE_NOT_CONFIGURED':
      return single('feeNotConfigured', t, 4);
    case 'INVALID_SHARE_QUANTITY':
      return single('invalidShareQuantity', t, 2);
  }

  if (err.status === UNPROCESSABLE) return single('invalidData', t);
  const generic = t(`${KEY_PREFIX}.genericError`);
  const code = t(`${KEY_PREFIX}.errorCode`, { status: err.status });
  return { messages: [`${generic} (${code})`], step: null };
}
