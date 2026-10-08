part of 'society_costs_bloc.dart';

/// Manual-split entry row seeded from a preview.
class ManualAmount {
  const ManualAmount(
      {required this.memberId, required this.memberName, this.amount});

  final int memberId;
  final String memberName;
  final num? amount;
}

class SocietyCostsState extends Equatable {
  const SocietyCostsState({
    this.costs = const [],
    this.categories = const [],
    this.summary,
    this.loading = true,
    this.error,
    this.expandedId,
    this.dateFrom = '',
    this.dateTo = '',
    this.categoryFilter,
    this.sourceFilter,
    this.billedFilter,
    this.search = '',
    // Split flow
    this.splitCost,
    this.splitMethod = CostSplitMethod.equal,
    this.splitPreview = const [],
    this.manualAmounts = const [],
    this.splitLoading = false,
    this.splitError,
    // Generic action feedback
    this.actionError,
    this.busy = false,
  });

  final List<SocietyCost> costs;
  final List<ConfigListItem> categories;
  final SocietyCostSummary? summary;
  final bool loading;
  final Object? error;
  final int? expandedId;
  final String dateFrom;
  final String dateTo;
  final String? categoryFilter;
  final CostPaymentSource? sourceFilter;

  /// null = all, true = billed only, false = unbilled only.
  final bool? billedFilter;
  final String search;

  final SocietyCost? splitCost;
  final CostSplitMethod splitMethod;
  final List<SplitPreviewRow> splitPreview;
  final List<ManualAmount> manualAmounts;
  final bool splitLoading;
  final Object? splitError;
  final Object? actionError;
  final bool busy;

  SocietyCostsState copyWith({
    List<SocietyCost>? costs,
    List<ConfigListItem>? categories,
    SocietyCostSummary? Function()? summary,
    bool? loading,
    Object? Function()? error,
    int? Function()? expandedId,
    String? dateFrom,
    String? dateTo,
    String? Function()? categoryFilter,
    CostPaymentSource? Function()? sourceFilter,
    bool? Function()? billedFilter,
    String? search,
    SocietyCost? Function()? splitCost,
    CostSplitMethod? splitMethod,
    List<SplitPreviewRow>? splitPreview,
    List<ManualAmount>? manualAmounts,
    bool? splitLoading,
    Object? Function()? splitError,
    Object? Function()? actionError,
    bool? busy,
  }) =>
      SocietyCostsState(
        costs: costs ?? this.costs,
        categories: categories ?? this.categories,
        summary: summary == null ? this.summary : summary(),
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
        expandedId: expandedId == null ? this.expandedId : expandedId(),
        dateFrom: dateFrom ?? this.dateFrom,
        dateTo: dateTo ?? this.dateTo,
        categoryFilter:
            categoryFilter == null ? this.categoryFilter : categoryFilter(),
        sourceFilter: sourceFilter == null ? this.sourceFilter : sourceFilter(),
        billedFilter: billedFilter == null ? this.billedFilter : billedFilter(),
        search: search ?? this.search,
        splitCost: splitCost == null ? this.splitCost : splitCost(),
        splitMethod: splitMethod ?? this.splitMethod,
        splitPreview: splitPreview ?? this.splitPreview,
        manualAmounts: manualAmounts ?? this.manualAmounts,
        splitLoading: splitLoading ?? this.splitLoading,
        splitError: splitError == null ? this.splitError : splitError(),
        actionError: actionError == null ? this.actionError : actionError(),
        busy: busy ?? this.busy,
      );

  @override
  List<Object?> get props => [
        costs,
        categories,
        summary,
        loading,
        error,
        expandedId,
        dateFrom,
        dateTo,
        categoryFilter,
        sourceFilter,
        billedFilter,
        search,
        splitCost,
        splitMethod,
        splitPreview,
        manualAmounts,
        splitLoading,
        splitError,
        actionError,
        busy,
      ];
}
