import { HttpErrorResponse } from '@angular/common/http';
import { describe, expect, it } from 'vitest';
import { mapSubmissionError, TranslateFn } from './submission-error.mapper';

/** Echoes the key (plus params) so assertions don't depend on i18n files. */
const t: TranslateFn = (key, params) => (params ? `${key}${JSON.stringify(params)}` : key);

function httpError(status: number, error: unknown = null): HttpErrorResponse {
  return new HttpErrorResponse({ status, error });
}

describe('mapSubmissionError', () => {
  it('returns the network message when the request never reached the server', () => {
    expect(mapSubmissionError(httpError(0), t)).toEqual({
      messages: ['registration.submit.networkError'],
      step: null,
    });
  });

  it('explains oversized uploads on 413 even when the body is HTML', () => {
    const result = mapSubmissionError(httpError(413, '<html>Too Large</html>'), t);
    expect(result.messages).toEqual(['registration.submit.fileTooLarge']);
  });

  it.each([500, 502, 503, 504])('returns the server message for %i', (status) => {
    expect(mapSubmissionError(httpError(status), t).messages).toEqual([
      'registration.submit.serverError',
    ]);
  });

  it('names each invalid field and jumps to the earliest step', () => {
    const body = {
      detail: {
        code: 'VALIDATION_ERROR',
        errors: [
          { field: 'payment_method', code: 'missing', message: 'Field required' },
          { field: 'email', code: 'value_error', message: 'bad email' },
        ],
      },
    };

    const result = mapSubmissionError(httpError(422, body), t);

    expect(result.messages).toEqual([
      'registration.submit.fields.payment_method: registration.submit.reasons.required',
      'registration.submit.fields.email: registration.submit.reasons.invalid',
    ]);
    expect(result.step).toBe(1);
  });

  it('includes the 1-based item number for list fields', () => {
    const body = {
      detail: { errors: [{ field: 'nominees.1.mobile', code: 'string_type', message: 'x' }] },
    };

    const result = mapSubmissionError(httpError(422, body), t);

    expect(result.messages).toEqual([
      'registration.submit.fields.nominees 2: registration.submit.reasons.invalid',
    ]);
    expect(result.step).toBe(3);
  });

  it('falls back to the raw field path for unknown fields without a step', () => {
    const body = { detail: { errors: [{ field: 'mystery', code: 'missing', message: 'x' }] } };
    expect(mapSubmissionError(httpError(422, body), t)).toEqual({
      messages: ['mystery: registration.submit.reasons.required'],
      step: null,
    });
  });

  it('maps a missing fee setting to the payment step', () => {
    const body = { detail: { code: 'FEE_NOT_CONFIGURED', message: 'x' } };
    expect(mapSubmissionError(httpError(409, body), t)).toEqual({
      messages: ['registration.submit.feeNotConfigured'],
      step: 4,
    });
  });

  it('maps an invalid share quantity to the property step', () => {
    const body = { detail: { code: 'INVALID_SHARE_QUANTITY', message: 'x' } };
    expect(mapSubmissionError(httpError(422, body), t).step).toBe(2);
  });

  it('uses the invalid-data message for an unstructured 422', () => {
    const body = { detail: "Unsupported file type '.gif'." };
    expect(mapSubmissionError(httpError(422, body), t).messages).toEqual([
      'registration.submit.invalidData',
    ]);
  });

  it('appends the status code to the generic message for anything else', () => {
    expect(mapSubmissionError(httpError(418), t).messages).toEqual([
      'registration.submit.genericError (registration.submit.errorCode{"status":418})',
    ]);
  });
});
