import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../domain/finance_entities.dart';
import '../domain/payment_entities.dart';

num _num(dynamic v) =>
    v is num ? v : (v is String ? num.tryParse(v) ?? 0 : (v == null ? 0 : 0));

String _str(dynamic v) => v?.toString() ?? '';
String? _s(dynamic v) => v?.toString();

FinanceCategoryBreakdown _breakdown(Map<dynamic, dynamic> row) =>
    FinanceCategoryBreakdown(
      categoryId: row['category_id']?.toString(),
      category: _str(row['category']),
      amount: _num(row['amount']),
      share: _num(row['share']),
    );

FinanceTotals _totals(Map<dynamic, dynamic>? t) => FinanceTotals(
      income: _num(t?['income']),
      expense: _num(t?['expense']),
      net: _num(t?['net']),
    );

FinanceTransaction financeTransactionFromApi(Map<dynamic, dynamic> api) => FinanceTransaction(
      id: _str(api['id']),
      txnDate: _str(api['txn_date']),
      type: FinanceTypeX.fromName(_s(api['type'])),
      categoryId: api['category_id']?.toString(),
      categoryLabel: _s(api['category_label']),
      amount: _num(api['amount']),
      description: _str(api['description']),
      referenceNo: _s(api['reference_no']),
      attachmentUrl: _attachmentUrl(api['attachment_url']),
      status: FinanceStatusX.fromName(_s(api['status'])),
      approvedByName: _s(api['approved_by_name']),
      approvedAt: _s(api['approved_at']),
      reversalOfId: api['reversal_of_id']?.toString(),
      createdAt: _str(api['created_at']),
    );

String? _attachmentUrl(dynamic path) {
  final raw = _s(path);
  if (raw == null || raw.isEmpty) return null;
  return AppConfig.fileUrl(raw);
}

FinanceSummary financeSummaryFromApi(Map<dynamic, dynamic> api) {
    final previous = api['previous'] as Map<dynamic, dynamic>?;
    return FinanceSummary(
      totals: _totals(api['totals'] as Map<dynamic, dynamic>?),
      balance: _num(api['balance']),
      previous: previous == null ? null : _totals(previous),
      incomeByCategory: [
        for (final row in (api['income_by_category'] as List<dynamic>? ?? const []))
          _breakdown(row as Map<dynamic, dynamic>),
      ],
      expenseByCategory: [
        for (final row in (api['expense_by_category'] as List<dynamic>? ?? const []))
          _breakdown(row as Map<dynamic, dynamic>),
      ],
      previousIncomeByCategory: [
        for (final row in (api['previous_income_by_category'] as List<dynamic>? ?? const []))
          _breakdown(row as Map<dynamic, dynamic>),
      ],
      previousExpenseByCategory: [
        for (final row in (api['previous_expense_by_category'] as List<dynamic>? ?? const []))
          _breakdown(row as Map<dynamic, dynamic>),
      ],
      series: [
        for (final row in (api['series'] as List<dynamic>? ?? const []))
          FinanceSeriesPoint(
            label: _str(row['label']),
            income: _num(row['income']),
            expense: _num(row['expense']),
            net: _num(row['net']),
          ),
      ],
      granularityIsYear: _s(api['granularity']) == 'year',
      transactionCount: (api['transaction_count'] as num?)?.toInt() ?? 0,
      lastUpdated: _s(api['last_updated']),
      periodDateFrom: _s((api['period'] as Map<dynamic, dynamic>?)?['date_from']),
      periodDateTo: _s((api['period'] as Map<dynamic, dynamic>?)?['date_to']),
    );
}

FinanceLedgerPage financeLedgerPageFromApi(Map<dynamic, dynamic> api) =>
    FinanceLedgerPage(
      items: [
        for (final row in (api['items'] as List<dynamic>? ?? const []))
          financeTransactionFromApi(row as Map<dynamic, dynamic>),
      ],
      total: (api['total'] as num?)?.toInt() ?? 0,
      totals: _totals(api['totals'] as Map<dynamic, dynamic>?),
    );

/// Member read-only finance endpoints (finance.service.ts member half).
class FinanceRepository {
  FinanceRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<FinanceSummary> getSummary(
    FinancePeriod period, {
    String? dateFrom,
    String? dateTo,
  }) async {
    final query = <String, String>{'period': period.apiName};
    if (period == FinancePeriod.custom) {
      if (dateFrom != null && dateFrom.isNotEmpty) query['date_from'] = dateFrom;
      if (dateTo != null && dateTo.isNotEmpty) query['date_to'] = dateTo;
    }
    final api = await _api.getUri('/member/finance/summary', query: query)
        as Map<dynamic, dynamic>;
    return financeSummaryFromApi(api);
  }

  Future<FinanceLedgerPage> getTransactions(FinanceLedgerFilters filters) async {
    final api = await _api.getUri('/member/finance/transactions',
        query: filters.toQuery()) as Map<dynamic, dynamic>;
    return financeLedgerPageFromApi(api);
  }
}
