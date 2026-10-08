/// Port of Angular submission-error.mapper.ts: turns a failed
/// POST /submissions response into structured, localizable messages plus the
/// wizard step holding the first offending field.
library;

import '../../../core/network/api_exception.dart';

/// Backend payload field (top-level segment) -> wizard step that owns it
/// (FIELD_STEPS in the Angular mapper).
const submissionFieldSteps = <String, int>{
  'full_name': 1,
  'father_or_husband': 1,
  'mother': 1,
  'dob': 1,
  'nationality': 1,
  'occupation': 1,
  'nid': 1,
  'mobile': 1,
  'gender': 1,
  'email': 1,
  'permanent_address': 1,
  'current_address': 1,
  'properties': 2,
  'urgent_contact_name': 3,
  'urgent_contact_relation': 3,
  'urgent_contact_mobile': 3,
  'urgent_contact_address': 3,
  'nominees': 3,
  'admission_fee': 4,
  'subscription': 4,
  'receipt_no': 4,
  'payment_method': 4,
  'member_signature': 5,
  'submission_date': 5,
};

enum SubmitErrorKind {
  network,
  fileTooLarge,
  server,
  feeNotConfigured,
  invalidShareQuantity,
  invalidData,
  generic,
  field,
}

enum SubmitErrorReason { required, invalid }

/// One server-side error message. [kind] == field entries render as
/// "field label, optional position: reason"; other kinds map to a single key.
class SubmitErrorItem {
  const SubmitErrorItem._({
    required this.kind,
    this.fieldRoot,
    this.position,
    this.reason,
    this.status,
  });

  factory SubmitErrorItem.field(String key, String messageOrCode) {
    final segments = key.split('.');
    final root = segments.first;
    final index = segments.length > 1 ? int.tryParse(segments[1]) : null;
    final code = messageOrCode.toLowerCase();
    return SubmitErrorItem._(
      kind: SubmitErrorKind.field,
      fieldRoot: root,
      position: index,
      reason: code == 'missing' ? SubmitErrorReason.required : SubmitErrorReason.invalid,
    );
  }

  factory SubmitErrorItem.plain(SubmitErrorKind kind, {int? status}) =>
      SubmitErrorItem._(kind: kind, status: status);

  final SubmitErrorKind kind;

  /// snake_case top-level payload segment (field errors only).
  final String? fieldRoot;
  final int? position; // 0-based list index, when present.
  final SubmitErrorReason? reason;
  final int? status; // for the generic variant's status code.

  int? get step => kind == SubmitErrorKind.field ? submissionFieldSteps[fieldRoot] : switch (kind) {
        SubmitErrorKind.feeNotConfigured => 4,
        SubmitErrorKind.invalidShareQuantity => 2,
        _ => null,
      };
}

class MappedSubmissionError {
  const MappedSubmissionError({required this.items, this.step});

  final List<SubmitErrorItem> items;

  /// Wizard step holding the first offending field, when known.
  final int? step;
}

const _serverFailureStatuses = {500, 502, 503, 504};

/// Mirrors mapSubmissionError(): duplicate-submission 409s are handled
/// separately (DuplicateSubmissionException).
MappedSubmissionError mapSubmissionError(ApiException err) {
  if (err.isNetwork) {
    return MappedSubmissionError(items: [SubmitErrorItem.plain(SubmitErrorKind.network)]);
  }
  if (err.statusCode == 413) {
    return MappedSubmissionError(items: [SubmitErrorItem.plain(SubmitErrorKind.fileTooLarge)]);
  }
  if (_serverFailureStatuses.contains(err.statusCode) || err.isServer) {
    return MappedSubmissionError(items: [SubmitErrorItem.plain(SubmitErrorKind.server)]);
  }

  // Field errors: keys are 'root' or 'root.index' (snake_case), values are the
  // backend code ('missing') or message.
  if (err.isValidation && err.fieldErrors.isNotEmpty) {
    final items = [for (final e in err.fieldErrors.entries) SubmitErrorItem.field(e.key, e.value)];
    final steps = items.map((i) => i.step).whereType<int>().toList();
    return MappedSubmissionError(items: items, step: steps.isEmpty ? null : steps.reduce(_min));
  }

  if (err.businessMessage == 'FEE_NOT_CONFIGURED') {
    return MappedSubmissionError(items: [SubmitErrorItem.plain(SubmitErrorKind.feeNotConfigured)], step: 4);
  }
  if (err.businessMessage == 'INVALID_SHARE_QUANTITY') {
    return MappedSubmissionError(items: [SubmitErrorItem.plain(SubmitErrorKind.invalidShareQuantity)], step: 2);
  }

  if (err.isValidation) {
    return MappedSubmissionError(items: [SubmitErrorItem.plain(SubmitErrorKind.invalidData)]);
  }
  return MappedSubmissionError(
    items: [SubmitErrorItem.plain(SubmitErrorKind.generic, status: err.statusCode ?? 0)],
  );
}

int _min(int a, int b) => a < b ? a : b;

/// 409 duplicate-application responses (Angular DuplicateSubmissionError).
enum DuplicateSubmissionKind { applicationPending, alreadyRegistered }

class DuplicateSubmissionException implements Exception {
  const DuplicateSubmissionException(this.kind, this.message);

  final DuplicateSubmissionKind kind;
  final String message;
}
