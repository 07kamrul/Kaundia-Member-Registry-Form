import 'package:equatable/equatable.dart';

import '../../../core/enums/enums.dart';

// ---------------------------------------------------------------------------
// Installment online payments (installment-payment.service.ts, member half)
// ---------------------------------------------------------------------------

class PayableInstallment extends Equatable {
  const PayableInstallment({
    required this.id,
    required this.year,
    required this.month,
    required this.amount,
  });

  final String id;
  final int year;
  final int month;
  final num amount;

  @override
  List<Object?> get props => [id, year, month, amount];
}

class PaymentAccount extends Equatable {
  const PaymentAccount({required this.method, required this.details});

  final String method;
  final String details;

  @override
  List<Object?> get props => [method, details];
}

class InstallmentPayment extends Equatable {
  const InstallmentPayment({
    required this.id,
    required this.method,
    required this.transactionRef,
    this.senderAccount,
    required this.amount,
    required this.paidOn,
    required this.proofUrl,
    this.note,
    required this.status,
    required this.rejectionReason,
    required this.reviewedAt,
    required this.createdAt,
    required this.installments,
  });

  final String id;
  final String method;
  final String transactionRef;
  final String? senderAccount;
  final num amount;
  final String paidOn;
  final String? proofUrl;
  final String? note;
  final SubmissionStatus status;
  final String? rejectionReason;
  final String? reviewedAt;
  final String createdAt;
  final List<PayableInstallment> installments;

  @override
  List<Object?> get props => [
        id, method, transactionRef, senderAccount, amount, paidOn, proofUrl,
        note, status, rejectionReason, reviewedAt, createdAt, installments,
      ];
}

class PayableSummary extends Equatable {
  const PayableSummary({
    required this.due,
    required this.pendingInstallmentIds,
    required this.totalDue,
    required this.accounts,
    required this.payments,
  });

  final List<PayableInstallment> due;
  final Set<String> pendingInstallmentIds;
  final num totalDue;
  final List<PaymentAccount> accounts;
  final List<InstallmentPayment> payments;

  @override
  List<Object?> get props => [
        due, pendingInstallmentIds, totalDue, accounts, payments,
      ];
}

class PaymentSubmission {
  const PaymentSubmission({
    required this.installmentIds,
    required this.method,
    required this.transactionRef,
    required this.paidOn,
    this.senderAccount,
    this.note,
    this.proof,
  });

  final List<String> installmentIds;
  final String method;
  final String transactionRef;
  final String paidOn;
  final String? senderAccount;
  final String? note;
  final ProofFile? proof;
}

/// Proof file bytes (image/pdf <=5MB validated in the UI/bloc).
class ProofFile {
  const ProofFile({required this.bytes, required this.fileName, required this.mimeType});

  final List<int> bytes;
  final String fileName;
  final String mimeType;
}

// ---------------------------------------------------------------------------
// Society cost shares (society-cost.service.ts myCostShares)
// ---------------------------------------------------------------------------

enum ShareStatus { unpaid, partial, paid, unknown }

extension ShareStatusX on ShareStatus {
  static ShareStatus fromName(String? name) => switch (name) {
        'unpaid' => ShareStatus.unpaid,
        'partial' => ShareStatus.partial,
        'paid' => ShareStatus.paid,
        _ => ShareStatus.unknown,
      };
}

class CostSplitShare extends Equatable {
  const CostSplitShare({
    required this.id,
    required this.costSplitId,
    required this.memberId,
    this.memberName,
    this.memberDisplayId,
    this.costTitle,
    this.costIncurredDate,
    this.costCategory,
    required this.amountDue,
    required this.amountPaid,
    required this.status,
    this.paidAt,
    required this.paymentMethodId,
    required this.paymentMethodLabel,
    required this.receiptNo,
  });

  final String id;
  final String costSplitId;
  final String memberId;
  final String? memberName;
  final String? memberDisplayId;
  final String? costTitle;
  final String? costIncurredDate;
  final String? costCategory;
  final num amountDue;
  final num amountPaid;
  final ShareStatus status;
  final String? paidAt;
  final String? paymentMethodId;
  final String? paymentMethodLabel;
  final String? receiptNo;

  bool get isOutstanding => status != ShareStatus.paid;
  num get outstanding => amountDue - amountPaid;

  @override
  List<Object?> get props => [
        id, costSplitId, memberId, memberName, memberDisplayId, costTitle,
        costIncurredDate, costCategory, amountDue, amountPaid, status, paidAt,
        paymentMethodId, paymentMethodLabel, receiptNo,
      ];
}

enum FinanceType { income, expense, unknown }

extension FinanceTypeX on FinanceType {
  static FinanceType fromName(String? name) => switch (name) {
        'income' => FinanceType.income,
        'expense' => FinanceType.expense,
        _ => FinanceType.unknown,
      };
}

enum FinanceStatus { draft, pending, approved, rejected, unknown }

extension FinanceStatusX on FinanceStatus {
  static FinanceStatus fromName(String? name) => switch (name) {
        'draft' => FinanceStatus.draft,
        'pending' => FinanceStatus.pending,
        'approved' => FinanceStatus.approved,
        'rejected' => FinanceStatus.rejected,
        _ => FinanceStatus.unknown,
      };
}
