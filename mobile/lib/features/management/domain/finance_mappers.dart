import 'admin_mappers.dart' show fileUrlOf;
import 'finance_entities.dart';

/// Hand-written snake_case JSON -> entity mappers for the finance, roadmap,
/// society-cost and installment-payment areas.

String? _s(Map<String, dynamic> m, String k) => m[k] as String?;
String _sOr(Map<String, dynamic> m, String k) => (m[k] as String?) ?? '';
int _i(Map<String, dynamic> m, String k) => (m[k] as num?)?.toInt() ?? 0;
int? _iN(Map<String, dynamic> m, String k) => (m[k] as num?)?.toInt();
num _n(Map<String, dynamic> m, String k) => (m[k] as num?) ?? 0;
num _nOr(Map<String, dynamic> m, String k, {num fallback = 0}) {
  final v = m[k];
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? fallback;
  return fallback;
}

List<Map<String, dynamic>> _list(Map<String, dynamic> m, String k) => m[k]
        is List
    ? (m[k] as List).whereType<Map>().map(Map<String, dynamic>.from).toList()
    : const [];

extension FinanceTransactionApiX on Map<String, dynamic> {
  FinanceTransaction toTransactionEntity() => FinanceTransaction(
        id: _i(this, 'id'),
        txnDate: _sOr(this, 'txn_date'),
        type: financeTypeFromApi(this['type'] as String?),
        categoryId: _iN(this, 'category_id'),
        categoryLabel: _s(this, 'category_label'),
        amount: _nOr(this, 'amount'),
        description: _sOr(this, 'description'),
        referenceNo: _s(this, 'reference_no'),
        attachmentUrl: fileUrlOf(_s(this, 'attachment_url')),
        status: financeStatusFromApi(this['status'] as String?),
        approvedByName: _s(this, 'approved_by_name'),
        approvedAt: _s(this, 'approved_at'),
        reversalOfId: _iN(this, 'reversal_of_id'),
        createdAt: _sOr(this, 'created_at'),
        internalNotes: _s(this, 'internal_notes'),
        rejectionReason: _s(this, 'rejection_reason'),
        linkedPaymentType: this['linked_payment_type'] == null
            ? null
            : paymentSourceFromApi(this['linked_payment_type'] as String?),
        linkedPaymentId: _iN(this, 'linked_payment_id'),
        createdByName: _s(this, 'created_by_name'),
        isActive: this['is_active'] as bool? ?? true,
      );
}

extension FinanceLedgerApiX on Map<String, dynamic> {
  FinanceLedgerPage toLedgerEntity() {
    final totals = this['totals'];
    final t = totals is Map
        ? Map<String, dynamic>.from(totals)
        : const <String, dynamic>{};
    return FinanceLedgerPage(
      total: _i(this, 'total'),
      items: _list(this, 'items')
          .map((r) => r.toTransactionEntity())
          .toList(growable: false),
      totals: FinanceTotals(
        income: _nOr(t, 'income'),
        expense: _nOr(t, 'expense'),
        net: _nOr(t, 'net'),
      ),
    );
  }
}

extension FinanceCategoryApiX on Map<String, dynamic> {
  FinanceCategory toCategoryEntity() => FinanceCategory(
        id: _i(this, 'id'),
        type: financeTypeFromApi(this['type'] as String?),
        label: _sOr(this, 'label'),
        isActive: this['is_active'] == true,
      );
}

extension FinanceOverviewApiX on Map<String, dynamic> {
  FinanceOverview toOverviewEntity() => FinanceOverview(
        pendingCount: _i(this, 'pending_count'),
        monthIncome: _nOr(this, 'month_income'),
        monthExpense: _nOr(this, 'month_expense'),
        monthNet: _nOr(this, 'month_net'),
        balance: _nOr(this, 'balance'),
        recent: _list(this, 'recent')
            .map((r) => r.toTransactionEntity())
            .toList(growable: false),
      );
}

extension UnlinkedPaymentApiX on Map<String, dynamic> {
  UnlinkedPayment toUnlinkedPaymentEntity() => UnlinkedPayment(
        sourceType: paymentSourceFromApi(this['source_type'] as String?),
        sourceId: _i(this, 'source_id'),
        memberName: _s(this, 'member_name'),
        memberDisplayId: _s(this, 'member_display_id'),
        amount: _nOr(this, 'amount'),
        paidOn: _sOr(this, 'paid_on'),
        receiptNo: _s(this, 'receipt_no'),
        detail: _sOr(this, 'detail'),
      );
}

extension AdminInstallmentPaymentApiX on Map<String, dynamic> {
  AdminInstallmentPayment toAdminPaymentEntity() {
    final installments = _list(this, 'installments')
        .map((r) => PayableInstallment(
              id: _i(r, 'id'),
              year: _i(r, 'year'),
              month: _i(r, 'month'),
              amount: _nOr(r, 'amount'),
            ))
        .toList(growable: false);
    return AdminInstallmentPayment(
      id: _i(this, 'id'),
      method: _sOr(this, 'method'),
      transactionRef: _sOr(this, 'transaction_ref'),
      senderAccount: _s(this, 'sender_account'),
      amount: _nOr(this, 'amount'),
      paidOn: _sOr(this, 'paid_on'),
      proofUrl: fileUrlOf(_s(this, 'proof_url')),
      note: _s(this, 'note'),
      status: _sOr(this, 'status'),
      rejectionReason: _s(this, 'rejection_reason'),
      reviewedAt: _s(this, 'reviewed_at'),
      createdAt: _sOr(this, 'created_at'),
      memberId: _i(this, 'member_id'),
      memberName: _s(this, 'member_name'),
      memberDisplayId: _s(this, 'member_display_id'),
      installments: installments,
    );
  }
}

// ----- Roadmap -----

extension RoadmapItemApiX on Map<String, dynamic> {
  RoadmapItem toItemEntity() => RoadmapItem(
        id: _i(this, 'id'),
        timeframeId: _i(this, 'timeframe_id'),
        text: _sOr(this, 'text'),
        status: roadmapStatusFromApi(this['status'] as String?),
        targetDate: _s(this, 'target_date'),
        owner: _s(this, 'owner'),
        note: _s(this, 'note'),
        sortOrder: _i(this, 'sort_order'),
        completedAt: _s(this, 'completed_at'),
        updatedAt: _s(this, 'updated_at'),
      );
}

extension RoadmapApiX on Map<String, dynamic> {
  Roadmap toRoadmapEntity() => Roadmap(
        lastUpdated: _s(this, 'last_updated'),
        totals: _progress(this['totals'] is Map
            ? Map<String, dynamic>.from(this['totals'] as Map)
            : const <String, dynamic>{}),
        timeframes:
            _list(this, 'timeframes').map(_timeframe).toList(growable: false),
      );

  static RoadmapProgress _progress(Map<String, dynamic> m) => RoadmapProgress(
        total: _i(m, 'total'),
        done: _i(m, 'done'),
        inProgress: _i(m, 'in_progress'),
        planned: _i(m, 'planned'),
        percent: _n(m, 'percent'),
      );

  static RoadmapTimeframe _timeframe(Map<String, dynamic> m) {
    final items =
        _list(m, 'items').map((r) => r.toItemEntity()).toList(growable: false);
    return RoadmapTimeframe(
      total: _i(m, 'total'),
      done: _i(m, 'done'),
      inProgress: _i(m, 'in_progress'),
      planned: _i(m, 'planned'),
      percent: _n(m, 'percent'),
      id: _i(m, 'id'),
      key: _sOr(m, 'key'),
      nameBn: _sOr(m, 'name_bn'),
      nameEn: _sOr(m, 'name_en'),
      windowBn: _sOr(m, 'target_window_bn'),
      windowEn: _sOr(m, 'target_window_en'),
      sortOrder: _i(m, 'sort_order'),
      items: items,
    );
  }
}

extension RoadmapArchivedCycleApiX on Map<String, dynamic> {
  RoadmapArchivedCycle toCycleEntity() => RoadmapArchivedCycle(
        archivedAt: _sOr(this, 'archived_at'),
        total: _i(this, 'total'),
        done: _i(this, 'done'),
        items: _list(this, 'items')
            .map((r) => r.toItemEntity())
            .toList(growable: false),
      );
}

// ----- Society costs -----

extension CostSplitShareApiX on Map<String, dynamic> {
  CostSplitShare toShareEntity() => CostSplitShare(
        id: _i(this, 'id'),
        costSplitId: _i(this, 'cost_split_id'),
        memberId: _i(this, 'member_id'),
        memberName: _s(this, 'member_name'),
        memberDisplayId: _s(this, 'member_display_id'),
        costTitle: _s(this, 'cost_title'),
        costIncurredDate: _s(this, 'cost_incurred_date'),
        costCategory: _s(this, 'cost_category'),
        amountDue: _nOr(this, 'amount_due'),
        amountPaid: _nOr(this, 'amount_paid'),
        status: shareStatusFromApi(this['status'] as String?),
        paidAt: _s(this, 'paid_at'),
        paymentMethodId: _iN(this, 'payment_method_id'),
        paymentMethodLabel: _s(this, 'payment_method_label'),
        receiptNo: _s(this, 'receipt_no'),
      );
}

extension SocietyCostApiX on Map<String, dynamic> {
  SocietyCost toCostEntity() {
    final rawSplit = this['split'];
    CostSplit? split;
    if (rawSplit is Map) {
      final s = Map<String, dynamic>.from(rawSplit);
      split = CostSplit(
        id: _i(s, 'id'),
        societyCostId: _i(s, 'society_cost_id'),
        splitMethod: splitMethodFromApi(s['split_method'] as String?),
        createdAt: _sOr(s, 'created_at'),
        shares: _list(s, 'shares')
            .map((r) => r.toShareEntity())
            .toList(growable: false),
      );
    }
    return SocietyCost(
      id: _i(this, 'id'),
      title: _sOr(this, 'title'),
      description: _s(this, 'description'),
      categoryId: _iN(this, 'category_id'),
      categoryLabel: _s(this, 'category_label'),
      totalAmount: _nOr(this, 'total_amount'),
      incurredDate: _sOr(this, 'incurred_date'),
      paymentSource: costSourceFromApi(this['payment_source'] as String?),
      receiptFileUrl: fileUrlOf(_s(this, 'receipt_file_url')),
      notes: _s(this, 'notes'),
      createdAt: _sOr(this, 'created_at'),
      updatedAt: _sOr(this, 'updated_at'),
      split: split,
    );
  }
}

extension SplitPreviewApiX on Map<String, dynamic> {
  SplitPreviewRow toSplitPreviewRowEntity() => SplitPreviewRow(
        memberId: _i(this, 'member_id'),
        memberName: _sOr(this, 'member_name'),
        amountDue: _nOr(this, 'amount_due'),
      );
}

extension SocietyCostSummaryApiX on Map<String, dynamic> {
  SocietyCostSummary toSummaryEntity() => SocietyCostSummary(
        totalAmount: _nOr(this, 'total_amount'),
        societyFundTotal: _nOr(this, 'society_fund_total'),
        memberBilledTotal: _nOr(this, 'member_billed_total'),
        outstandingTotal: _nOr(this, 'outstanding_total'),
        collectedTotal: _nOr(this, 'collected_total'),
        byCategory: _list(this, 'by_category')
            .map((r) => CategoryTotal(
                  category: _sOr(r, 'category'),
                  total: _nOr(r, 'total'),
                ))
            .toList(growable: false),
      );
}
