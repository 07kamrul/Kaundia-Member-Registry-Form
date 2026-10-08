import 'package:equatable/equatable.dart';

import 'payment_entities.dart';

class FinanceTotals extends Equatable {
  const FinanceTotals({required this.income, required this.expense, required this.net});

  final num income;
  final num expense;
  final num net;

  @override
  List<Object?> get props => [income, expense, net];
}

class FinanceCategoryBreakdown extends Equatable {
  const FinanceCategoryBreakdown({
    required this.categoryId,
    required this.category,
    required this.amount,
    required this.share,
  });

  final String? categoryId;
  final String category;
  final num amount;
  final num share;

  @override
  List<Object?> get props => [categoryId, category, amount, share];
}

class FinanceSeriesPoint extends Equatable {
  const FinanceSeriesPoint({
    required this.label,
    required this.income,
    required this.expense,
    required this.net,
  });

  /// "2026-03" (month) / "2026" (year).
  final String label;
  final num income;
  final num expense;
  final num net;

  @override
  List<Object?> get props => [label, income, expense, net];
}

enum FinancePeriod { month, year, custom, all }

extension FinancePeriodX on FinancePeriod {
  String get apiName => switch (this) {
        FinancePeriod.month => 'month',
        FinancePeriod.year => 'year',
        FinancePeriod.custom => 'custom',
        FinancePeriod.all => 'all',
      };
}

class FinanceSummary extends Equatable {
  const FinanceSummary({
    required this.totals,
    required this.balance,
    required this.previous,
    required this.incomeByCategory,
    required this.expenseByCategory,
    required this.previousIncomeByCategory,
    required this.previousExpenseByCategory,
    required this.series,
    required this.granularityIsYear,
    required this.transactionCount,
    required this.lastUpdated,
    this.periodDateFrom,
    this.periodDateTo,
  });

  final FinanceTotals totals;
  final num balance;
  final FinanceTotals? previous;
  final List<FinanceCategoryBreakdown> incomeByCategory;
  final List<FinanceCategoryBreakdown> expenseByCategory;
  final List<FinanceCategoryBreakdown> previousIncomeByCategory;
  final List<FinanceCategoryBreakdown> previousExpenseByCategory;
  final List<FinanceSeriesPoint> series;

  /// false = 'month', true = 'year'.
  final bool granularityIsYear;
  final int transactionCount;
  final String? lastUpdated;

  /// Resolved date bounds of the period (custom ranges only; else null).
  final String? periodDateFrom;
  final String? periodDateTo;

  @override
  List<Object?> get props => [
        totals, balance, previous, incomeByCategory, expenseByCategory,
        previousIncomeByCategory, previousExpenseByCategory, series,
        granularityIsYear, transactionCount, lastUpdated, periodDateFrom,
        periodDateTo,
      ];
}

class FinanceTransaction extends Equatable {
  const FinanceTransaction({
    required this.id,
    required this.txnDate,
    required this.type,
    required this.categoryId,
    required this.categoryLabel,
    required this.amount,
    required this.description,
    required this.referenceNo,
    required this.attachmentUrl,
    required this.status,
    required this.approvedByName,
    required this.approvedAt,
    required this.reversalOfId,
    required this.createdAt,
  });

  final String id;
  final String txnDate;
  final FinanceType type;
  final String? categoryId;
  final String? categoryLabel;
  final num amount;
  final String description;
  final String? referenceNo;
  final String? attachmentUrl;
  final FinanceStatus status;
  final String? approvedByName;
  final String? approvedAt;
  final String? reversalOfId;
  final String createdAt;

  @override
  List<Object?> get props => [
        id, txnDate, type, categoryId, categoryLabel, amount, description,
        referenceNo, attachmentUrl, status, approvedByName, approvedAt,
        reversalOfId, createdAt,
      ];
}

class FinanceLedgerPage extends Equatable {
  const FinanceLedgerPage({
    required this.items,
    required this.total,
    required this.totals,
  });

  final List<FinanceTransaction> items;
  final int total;
  final FinanceTotals totals;

  @override
  List<Object?> get props => [items, total, totals];
}

class FinanceLedgerFilters extends Equatable {
  const FinanceLedgerFilters({
    this.type,
    this.categoryId,
    this.dateFrom,
    this.dateTo,
    this.minAmount,
    this.maxAmount,
    this.reference,
    this.search,
    this.limit,
    this.offset,
  });

  final FinanceType? type;
  final String? categoryId;
  final String? dateFrom;
  final String? dateTo;
  final num? minAmount;
  final num? maxAmount;
  final String? reference;
  final String? search;
  final int? limit;
  final int? offset;

  /// Mirrors finance.service.ts filterParams (member-usable subset).
  Map<String, String> toQuery() {
    final params = <String, String>{};
    final t = type;
    if (t != null && t != FinanceType.unknown) {
      params['type'] = t == FinanceType.income ? 'income' : 'expense';
    }
    final cat = categoryId;
    if (cat != null && cat.isNotEmpty) params['category_id'] = cat;
    if (dateFrom != null && dateFrom!.isNotEmpty) params['date_from'] = dateFrom!;
    if (dateTo != null && dateTo!.isNotEmpty) params['date_to'] = dateTo!;
    if (minAmount != null && minAmount! > 0) params['min_amount'] = '${minAmount!.toInt()}';
    if (maxAmount != null && maxAmount! > 0) params['max_amount'] = '${maxAmount!.toInt()}';
    if (reference != null && reference!.isNotEmpty) params['reference'] = reference!;
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    if (limit != null) params['limit'] = '$limit';
    if (offset != null) params['offset'] = '$offset';
    return params;
  }

  @override
  List<Object?> get props => [
        type, categoryId, dateFrom, dateTo, minAmount, maxAmount, reference,
        search, limit, offset,
      ];
}

// Bangla-first money formatting mirrors finance.service.ts helpers.

const String _bnDigits = '০১২৩৪৫৬৭৮৯';

String toBanglaDigits(String text) => text.replaceAllMapped(
      RegExp(r'[0-9]'),
      (m) => _bnDigits[int.parse(m.group(0)!)],
    );

/// 1250000.5 -> "12,50,000.50" (en) / "১২,৫০,০০০.৫০" (bn).
String formatFinanceAmount(num value, String lang) {
  final grouped = NumberFormatLike.enIn(value.toStringAsFixed(2));
  return lang == 'bn' ? toBanglaDigits(grouped) : grouped;
}

String formatTaka(num value, String lang) => '৳ ${formatFinanceAmount(value, lang)}';

String formatTakaCompact(num value, String lang) {
  final rounded = value.round();
  final grouped = NumberFormatLike.enInGrouped(rounded);
  return '৳ ${lang == 'bn' ? toBanglaDigits(grouped) : grouped}';
}

String formatPercent(num value, String lang) {
  final text = value.toDouble().toStringAsFixed(1);
  return '${lang == 'bn' ? toBanglaDigits(text) : text}%';
}

/// Minimal en-IN (lakh) grouping without relying on intl locale data.
class NumberFormatLike {
  const NumberFormatLike._();

  static String enInGrouped(int value) {
    final digits = value.abs().toString();
    if (digits.length <= 3) return (value < 0 ? '-' : '') + digits;
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${value < 0 ? '-' : ''}${parts.join(',')},$last3';
  }

  static String enIn(String valueWithDecimals) {
    final dot = valueWithDecimals.indexOf('.');
    final intPart = dot == -1 ? valueWithDecimals : valueWithDecimals.substring(0, dot);
    final decPart = dot == -1 ? '' : valueWithDecimals.substring(dot);
    return '${enInGrouped(int.parse(intPart))}$decPart';
  }
}
