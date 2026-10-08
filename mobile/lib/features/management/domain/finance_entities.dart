import 'admin_entities.dart';

// ----- Finance management (FinanceService.ts) -----

enum FinanceType { income, expense, unknown }

enum FinanceStatus { draft, pending, approved, rejected, unknown }

enum FinancePeriod { month, year, custom, all }

enum PaymentSourceType { installment, picnicPayment, costShare, unknown }

FinanceType financeTypeFromApi(String? raw) => switch (raw) {
      'income' => FinanceType.income,
      'expense' => FinanceType.expense,
      _ => FinanceType.unknown,
    };

FinanceStatus financeStatusFromApi(String? raw) => switch (raw) {
      'draft' => FinanceStatus.draft,
      'pending' => FinanceStatus.pending,
      'approved' => FinanceStatus.approved,
      'rejected' => FinanceStatus.rejected,
      _ => FinanceStatus.unknown,
    };

PaymentSourceType paymentSourceFromApi(String? raw) => switch (raw) {
      'installment' => PaymentSourceType.installment,
      'picnic_payment' => PaymentSourceType.picnicPayment,
      'cost_share' => PaymentSourceType.costShare,
      _ => PaymentSourceType.unknown,
    };

extension FinanceTypeApiNameX on FinanceType {
  String get apiName => switch (this) {
        FinanceType.income => 'income',
        FinanceType.expense => 'expense',
        FinanceType.unknown => 'unknown',
      };
}

extension FinanceStatusApiNameX on FinanceStatus {
  String get apiName => switch (this) {
        FinanceStatus.draft => 'draft',
        FinanceStatus.pending => 'pending',
        FinanceStatus.approved => 'approved',
        FinanceStatus.rejected => 'rejected',
        FinanceStatus.unknown => 'unknown',
      };
}

extension PaymentSourceApiNameX on PaymentSourceType {
  String get apiName => switch (this) {
        PaymentSourceType.installment => 'installment',
        PaymentSourceType.picnicPayment => 'picnic_payment',
        PaymentSourceType.costShare => 'cost_share',
        PaymentSourceType.unknown => 'unknown',
      };
}

class FinanceTotals {
  const FinanceTotals({required this.income, required this.expense, required this.net});

  final num income;
  final num expense;
  final num net;
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.txnDate,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
    this.categoryId,
    this.categoryLabel,
    this.referenceNo,
    this.attachmentUrl,
    this.approvedByName,
    this.approvedAt,
    this.reversalOfId,
    this.internalNotes,
    this.rejectionReason,
    this.linkedPaymentType,
    this.linkedPaymentId,
    this.createdByName,
    this.isActive = true,
  });

  final int id;
  final String txnDate;
  final FinanceType type;
  final int? categoryId;
  final String? categoryLabel;
  final num amount;
  final String description;
  final String? referenceNo;

  /// Absolute URL (AppConfig.fileUrl) of the stored attachment.
  final String? attachmentUrl;
  final FinanceStatus status;
  final String? approvedByName;
  final String? approvedAt;
  final int? reversalOfId;
  final String createdAt;
  final String? internalNotes;
  final String? rejectionReason;
  final PaymentSourceType? linkedPaymentType;
  final int? linkedPaymentId;
  final String? createdByName;
  final bool isActive;
}

class FinanceLedgerPage {
  const FinanceLedgerPage({required this.items, required this.total, required this.totals});

  final List<FinanceTransaction> items;
  final int total;
  final FinanceTotals totals;
}

class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.type,
    required this.label,
    required this.isActive,
  });

  final int id;
  final FinanceType type;
  final String label;
  final bool isActive;
}

class FinanceOverview {
  const FinanceOverview({
    required this.pendingCount,
    required this.monthIncome,
    required this.monthExpense,
    required this.monthNet,
    required this.balance,
    required this.recent,
  });

  final int pendingCount;
  final num monthIncome;
  final num monthExpense;
  final num monthNet;
  final num balance;
  final List<FinanceTransaction> recent;
}

class UnlinkedPayment {
  const UnlinkedPayment({
    required this.sourceType,
    required this.sourceId,
    required this.amount,
    required this.paidOn,
    required this.detail,
    this.memberName,
    this.memberDisplayId,
    this.receiptNo,
  });

  final PaymentSourceType sourceType;
  final int sourceId;
  final String? memberName;
  final String? memberDisplayId;
  final num amount;
  final String paidOn;
  final String? receiptNo;
  final String detail;
}

/// Input for create/update of a transaction (snake_case body built by repo).
class FinanceTransactionInput {
  const FinanceTransactionInput({
    required this.txnDate,
    required this.type,
    required this.categoryId,
    required this.amount,
    required this.description,
    this.referenceNo,
    this.internalNotes,
    this.status,
    this.linkedPaymentType,
    this.linkedPaymentId,
  });

  final String txnDate;
  final FinanceType type;
  final int categoryId;
  final num amount;
  final String description;
  final String? referenceNo;
  final String? internalNotes;

  /// Only set on create: 'draft' | 'pending'.
  final FinanceStatus? status;
  final PaymentSourceType? linkedPaymentType;
  final int? linkedPaymentId;
}

/// A pending member-reported installment payment awaiting committee review.
class AdminInstallmentPayment {
  const AdminInstallmentPayment({
    required this.id,
    required this.method,
    required this.transactionRef,
    required this.amount,
    required this.paidOn,
    required this.status,
    required this.createdAt,
    required this.installments,
    required this.memberId,
    this.senderAccount,
    this.proofUrl,
    this.note,
    this.rejectionReason,
    this.reviewedAt,
    this.memberName,
    this.memberDisplayId,
  });

  final int id;
  final String method;
  final String transactionRef;
  final String? senderAccount;
  final num amount;
  final String paidOn;
  final String? proofUrl;
  final String? note;

  /// 'pending' | 'approved' | 'rejected'
  final String status;
  final String? rejectionReason;
  final String? reviewedAt;
  final String createdAt;
  final int memberId;
  final String? memberName;
  final String? memberDisplayId;
  final List<PayableInstallment> installments;
}

class PayableInstallment {
  const PayableInstallment({required this.id, required this.year, required this.month, required this.amount});

  final int id;
  final int year;
  final int month;
  final num amount;
}

// ----- Roadmap management (RoadmapService.ts) -----

enum RoadmapStatus { planned, inProgress, done, unknown }

RoadmapStatus roadmapStatusFromApi(String? raw) => switch (raw) {
      'planned' => RoadmapStatus.planned,
      'in_progress' => RoadmapStatus.inProgress,
      'done' => RoadmapStatus.done,
      _ => RoadmapStatus.unknown,
    };

extension RoadmapStatusApiNameX on RoadmapStatus {
  String get apiName => switch (this) {
        RoadmapStatus.planned => 'planned',
        RoadmapStatus.inProgress => 'in_progress',
        RoadmapStatus.done => 'done',
        RoadmapStatus.unknown => 'unknown',
      };
}

class RoadmapItem {
  const RoadmapItem({
    required this.id,
    required this.timeframeId,
    required this.text,
    required this.status,
    required this.sortOrder,
    this.targetDate,
    this.owner,
    this.note,
    this.completedAt,
    this.updatedAt,
  });

  final int id;
  final int timeframeId;
  final String text;
  final RoadmapStatus status;
  final String? targetDate;
  final String? owner;
  final String? note;
  final int sortOrder;
  final String? completedAt;
  final String? updatedAt;
}

class RoadmapProgress {
  const RoadmapProgress({
    required this.total,
    required this.done,
    required this.inProgress,
    required this.planned,
    required this.percent,
  });

  final int total;
  final int done;
  final int inProgress;
  final int planned;
  final num percent;
}

class RoadmapTimeframe extends RoadmapProgress {
  const RoadmapTimeframe({
    required super.total,
    required super.done,
    required super.inProgress,
    required super.planned,
    required super.percent,
    required this.id,
    required this.key,
    required this.nameBn,
    required this.nameEn,
    required this.windowBn,
    required this.windowEn,
    required this.sortOrder,
    required this.items,
  });

  final int id;
  final String key;
  final String nameBn;
  final String nameEn;
  final String windowBn;
  final String windowEn;
  final int sortOrder;
  final List<RoadmapItem> items;
}

class Roadmap {
  const Roadmap({required this.totals, required this.timeframes, this.lastUpdated});

  final String? lastUpdated;
  final RoadmapProgress totals;
  final List<RoadmapTimeframe> timeframes;
}

class RoadmapArchivedCycle {
  const RoadmapArchivedCycle({
    required this.archivedAt,
    required this.total,
    required this.done,
    required this.items,
  });

  final String archivedAt;
  final int total;
  final int done;
  final List<RoadmapItem> items;
}

// ----- Society costs (SocietyCostService.ts) -----

enum CostPaymentSource { societyFund, memberBilled, unknown }

enum CostSplitMethod { equal, byLandQuantity, manual, unknown }

enum ShareStatus { unpaid, partial, paid, unknown }

CostPaymentSource costSourceFromApi(String? raw) => switch (raw) {
      'society_fund' => CostPaymentSource.societyFund,
      'member_billed' => CostPaymentSource.memberBilled,
      _ => CostPaymentSource.unknown,
    };

CostSplitMethod splitMethodFromApi(String? raw) => switch (raw) {
      'equal' => CostSplitMethod.equal,
      'by_land_quantity' => CostSplitMethod.byLandQuantity,
      'manual' => CostSplitMethod.manual,
      _ => CostSplitMethod.unknown,
    };

ShareStatus shareStatusFromApi(String? raw) => switch (raw) {
      'unpaid' => ShareStatus.unpaid,
      'partial' => ShareStatus.partial,
      'paid' => ShareStatus.paid,
      _ => ShareStatus.unknown,
    };

extension CostSourceApiNameX on CostPaymentSource {
  String get apiName => switch (this) {
        CostPaymentSource.societyFund => 'society_fund',
        CostPaymentSource.memberBilled => 'member_billed',
        CostPaymentSource.unknown => 'society_fund',
      };
}

extension SplitMethodApiNameX on CostSplitMethod {
  String get apiName => switch (this) {
        CostSplitMethod.equal => 'equal',
        CostSplitMethod.byLandQuantity => 'by_land_quantity',
        CostSplitMethod.manual => 'manual',
        CostSplitMethod.unknown => 'equal',
      };
}

class CostSplitShare {
  const CostSplitShare({
    required this.id,
    required this.costSplitId,
    required this.memberId,
    required this.amountDue,
    required this.amountPaid,
    required this.status,
    this.memberName,
    this.memberDisplayId,
    this.costTitle,
    this.costIncurredDate,
    this.costCategory,
    this.paidAt,
    this.paymentMethodId,
    this.paymentMethodLabel,
    this.receiptNo,
  });

  final int id;
  final int costSplitId;
  final int memberId;
  final String? memberName;
  final String? memberDisplayId;
  final String? costTitle;
  final String? costIncurredDate;
  final String? costCategory;
  final num amountDue;
  final num amountPaid;
  final ShareStatus status;
  final String? paidAt;
  final int? paymentMethodId;
  final String? paymentMethodLabel;
  final String? receiptNo;
}

class CostSplit {
  const CostSplit({
    required this.id,
    required this.societyCostId,
    required this.splitMethod,
    required this.createdAt,
    required this.shares,
  });

  final int id;
  final int societyCostId;
  final CostSplitMethod splitMethod;
  final String createdAt;
  final List<CostSplitShare> shares;
}

class SocietyCost {
  const SocietyCost({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.incurredDate,
    required this.paymentSource,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.categoryId,
    this.categoryLabel,
    this.receiptFileUrl,
    this.notes,
    this.split,
  });

  final int id;
  final String title;
  final String? description;
  final int? categoryId;
  final String? categoryLabel;
  final num totalAmount;
  final String incurredDate;
  final CostPaymentSource paymentSource;

  /// Absolute URL (AppConfig.fileUrl).
  final String? receiptFileUrl;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final CostSplit? split;
}

class SocietyCostInput {
  const SocietyCostInput({
    required this.title,
    required this.totalAmount,
    required this.incurredDate,
    required this.paymentSource,
    this.description,
    this.categoryId,
    this.notes,
  });

  final String title;
  final String? description;
  final int? categoryId;
  final num totalAmount;
  final String incurredDate;
  final CostPaymentSource paymentSource;
  final String? notes;
}

class SplitPreviewRow {
  const SplitPreviewRow({required this.memberId, required this.memberName, required this.amountDue});

  final int memberId;
  final String memberName;
  final num amountDue;
}

class SocietyCostSummary {
  const SocietyCostSummary({
    required this.totalAmount,
    required this.societyFundTotal,
    required this.memberBilledTotal,
    required this.outstandingTotal,
    required this.collectedTotal,
    required this.byCategory,
  });

  final num totalAmount;
  final num societyFundTotal;
  final num memberBilledTotal;
  final num outstandingTotal;
  final num collectedTotal;
  final List<CategoryTotal> byCategory;
}

class CategoryTotal {
  const CategoryTotal({required this.category, required this.total});

  final String category;
  final num total;
}
