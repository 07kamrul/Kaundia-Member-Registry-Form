import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/registration/domain/submission_error_mapper.dart';

void main() {
  test('network failure maps to networkError with no step', () {
    final mapped =
        mapSubmissionError(const ApiException(type: ApiExceptionType.network));
    expect(mapped.items.single.kind, SubmitErrorKind.network);
    expect(mapped.step, isNull);
  });

  test('413 maps to fileTooLarge', () {
    final mapped = mapSubmissionError(const ApiException(
      type: ApiExceptionType.server,
      statusCode: 413,
    ));
    expect(mapped.items.single.kind, SubmitErrorKind.fileTooLarge);
  });

  test('500/502/503/504 map to serverError', () {
    for (final status in [500, 502, 503, 504]) {
      final mapped = mapSubmissionError(ApiException(
        type: ApiExceptionType.server,
        statusCode: status,
      ));
      expect(mapped.items.single.kind, SubmitErrorKind.server,
          reason: '$status');
    }
  });

  test('field errors resolve step from FIELD_STEPS and preserve index', () {
    final mapped = mapSubmissionError(const ApiException(
      type: ApiExceptionType.validation,
      statusCode: 422,
      fieldErrors: {
        'full_name': 'missing',
        'properties.1': 'missing',
        'urgent_contact_mobile': 'invalid',
      },
    ));
    expect(mapped.items.length, 3);
    final steps = mapped.items.map((i) => i.step).toSet();
    expect(steps, {1, 2, 3});
    // First offending step is the minimum.
    expect(mapped.step, 1);

    final prop = mapped.items.firstWhere((i) => i.fieldRoot == 'properties');
    expect(prop.position, 1);
    expect(prop.reason, SubmitErrorReason.required);
  });

  test('unknown reason codes map to invalid', () {
    final mapped = mapSubmissionError(const ApiException(
      type: ApiExceptionType.validation,
      statusCode: 422,
      fieldErrors: {'nid': 'bad_format'},
    ));
    expect(mapped.items.single.reason, SubmitErrorReason.invalid);
    expect(mapped.step, 1);
  });

  test('FEE_NOT_CONFIGURED jumps to step 4', () {
    final mapped = mapSubmissionError(const ApiException(
      type: ApiExceptionType.business,
      statusCode: 400,
      businessMessage: 'FEE_NOT_CONFIGURED',
    ));
    expect(mapped.items.single.kind, SubmitErrorKind.feeNotConfigured);
    expect(mapped.step, 4);
  });

  test('INVALID_SHARE_QUANTITY jumps to step 2', () {
    final mapped = mapSubmissionError(const ApiException(
      type: ApiExceptionType.business,
      statusCode: 400,
      businessMessage: 'INVALID_SHARE_QUANTITY',
    ));
    expect(mapped.items.single.kind, SubmitErrorKind.invalidShareQuantity);
    expect(mapped.step, 2);
  });

  test('bare 422 maps to invalidData', () {
    final mapped = mapSubmissionError(const ApiException(
      type: ApiExceptionType.validation,
      statusCode: 422,
    ));
    expect(mapped.items.single.kind, SubmitErrorKind.invalidData);
  });

  test('generic failure carries the status code', () {
    final mapped = mapSubmissionError(const ApiException(
      type: ApiExceptionType.unknown,
      statusCode: 418,
    ));
    expect(mapped.items.single.kind, SubmitErrorKind.generic);
    expect(mapped.items.single.status, 418);
    expect(mapped.step, isNull);
  });
}
