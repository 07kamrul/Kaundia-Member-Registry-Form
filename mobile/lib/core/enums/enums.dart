/// Status variants used across the app — enum-based, never raw strings.
enum SubmissionStatus { pending, approved, rejected, unknown }

enum MemberStatus { pending, approved, rejected, unknown }

enum OwnershipType { single, joint, unknown }

enum SplitMethod { equal, byShare, manual, unknown }

enum PaymentSource { cash, bkash, nagad, bank, other, unknown }

enum InstallmentStatus { pending, paid, partial, overdue, unknown }

enum LandingTier { member, management, superAdmin }

extension SubmissionStatusX on SubmissionStatus {
  static SubmissionStatus fromName(String? name) => switch (name) {
        'pending' => SubmissionStatus.pending,
        'approved' => SubmissionStatus.approved,
        'rejected' => SubmissionStatus.rejected,
        _ => SubmissionStatus.unknown,
      };

  String get apiName => switch (this) {
        SubmissionStatus.pending => 'pending',
        SubmissionStatus.approved => 'approved',
        SubmissionStatus.rejected => 'rejected',
        SubmissionStatus.unknown => 'unknown',
      };
}

extension OwnershipTypeX on OwnershipType {
  /// The Angular app uses the Bengali sentinel 'যৌথ' for joint ownership.
  static const String jointSentinel = 'যৌথ';

  static OwnershipType fromApi(String? value) =>
      value == jointSentinel ? OwnershipType.joint : OwnershipType.single;

  String get apiValue =>
      this == OwnershipType.joint ? OwnershipTypeX.jointSentinel : 'একক';
}

extension PaymentSourceX on PaymentSource {
  static PaymentSource fromApi(String? raw) => switch (raw?.toLowerCase()) {
        'cash' => PaymentSource.cash,
        'bkash' => PaymentSource.bkash,
        'nagad' => PaymentSource.nagad,
        'bank' => PaymentSource.bank,
        'other' => PaymentSource.other,
        _ => PaymentSource.unknown,
      };
}
