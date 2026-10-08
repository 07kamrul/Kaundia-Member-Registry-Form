import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';
import '../../domain/finance_entities.dart';

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
    SocietyCostSummary? Function() summary = _same,
    bool? loading,
    Object? Function() error = _same,
    int? Function() expandedId = _same,
    String? dateFrom,
    String? dateTo,
    String? Function() categoryFilter = _same,
    CostPaymentSource? Function() sourceFilter = _same,
    bool? Function() billedFilter = _same,
    String? search,
    SocietyCost? Function() splitCost = _same,
    CostSplitMethod? splitMethod,
    List<SplitPreviewRow>? splitPreview,
    List<ManualAmount>? manualAmounts,
    bool? splitLoading,
    Object? Function() splitError = _same,
    Object? Function() actionError = _same,
    bool? busy,
  }) =>
      SocietyCostsState(
        costs: costs ?? this.costs,
        categories: categories ?? this.categories,
        summary: summary == _same ? this.summary : summary(),
        loading: loading ?? this.loading,
        error: error == _same ? this.error : error(),
        expandedId: expandedId == _same ? this.expandedId : expandedId(),
        dateFrom: dateFrom ?? this.dateFrom,
        dateTo: dateTo ?? this.dateTo,
        categoryFilter:
            categoryFilter == _same ? this.categoryFilter : categoryFilter(),
        sourceFilter:
            sourceFilter == _same ? this.sourceFilter : sourceFilter(),
        billedFilter:
            billedFilter == _same ? this.billedFilter : billedFilter(),
        search: search ?? this.search,
        splitCost: splitCost == _same ? this.splitCost : splitCost(),
        splitMethod: splitMethod ?? this.splitMethod,
        splitPreview: splitPreview ?? this.splitPreview,
        manualAmounts: manualAmounts ?? this.manualAmounts,
        splitLoading: splitLoading ?? this.splitLoading,
        splitError: splitError == _same ? this.splitError : splitError(),
        actionError: actionError == _same ? this.actionError : actionError(),
        busy: busy ?? this.busy,
      );

  static T _same<T>() => throw UnsupportedError('sentinel');

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

class SocietyCostsCubit extends Cubit<SocietyCostsState> {
  SocietyCostsCubit(
      {required AdminRepository adminRepository,
      required SocietyCostRepository costRepository})
      : _admin = adminRepository,
        _costs = costRepository,
        super(const SocietyCostsState());

  final AdminRepository _admin;
  final SocietyCostRepository _costs;

  Future<void> init() async {
    loadCategories();
    refresh();
  }

  Future<void> loadCategories() async {
    try {
      final items = await _admin.listConfigListItems('cost_category');
      emit(state.copyWith(categories: items.where((i) => i.isActive).toList()));
    } catch (_) {
      emit(state.copyWith(categories: const []));
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final costs = await _costs.listCosts(
        categoryId:
            state.categoryFilter == null || state.categoryFilter!.isEmpty
                ? null
                : int.tryParse(state.categoryFilter!),
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        paymentSource: state.sourceFilter,
        billed: state.billedFilter,
        search: state.search,
      );
      SocietyCostSummary? summary;
      try {
        summary = await _costs.getSummary(
            dateFrom: state.dateFrom, dateTo: state.dateTo);
      } catch (_) {
        summary = null;
      }
      emit(
          state.copyWith(costs: costs, summary: () => summary, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: () => e));
    }
  }

  void setFilters({
    String? categoryFilter,
    String? dateFrom,
    String? dateTo,
    CostPaymentSource? sourceFilter,
    bool? billedFilter,
    String? search,
  }) {
    emit(state.copyWith(
      categoryFilter: () => categoryFilter,
      dateFrom: dateFrom ?? state.dateFrom,
      dateTo: dateTo ?? state.dateTo,
      sourceFilter: () => sourceFilter,
      billedFilter: () => billedFilter,
      search: search ?? state.search,
    ));
    refresh();
  }

  void resetFilters() {
    emit(state.copyWith(
      categoryFilter: () => null,
      sourceFilter: () => null,
      billedFilter: () => null,
      dateFrom: '',
      dateTo: '',
      search: '',
    ));
    refresh();
  }

  void toggleExpanded(int id) => emit(
      state.copyWith(expandedId: () => state.expandedId == id ? null : id));

  /// Adds a cost_category config item from the form, returns its id.
  Future<String?> addCategory(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return null;
    try {
      final item = await _admin.createConfigListItem(
          category: 'cost_category', value: trimmed, label: trimmed);
      emit(state.copyWith(categories: [...state.categories, item]));
      return item.id;
    } catch (e) {
      emit(state.copyWith(actionError: () => e));
      return null;
    }
  }

  Future<bool> saveCost(
      {required SocietyCostInput input,
      int? editingId,
      String? receiptPath}) async {
    emit(state.copyWith(busy: true, actionError: () => null));
    try {
      final cost = editingId == null
          ? await _costs.createCost(input)
          : await _costs.updateCost(editingId, input);
      if (receiptPath != null) {
        await _costs.uploadReceipt(cost.id, receiptPath);
      }
      emit(state.copyWith(busy: false));
      await refresh();
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }

  Future<bool> deleteCost(SocietyCost cost) async {
    emit(state.copyWith(busy: true, actionError: () => null));
    try {
      await _costs.deleteCost(cost.id);
      emit(state.copyWith(busy: false));
      await refresh();
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }

  // ----- Split flow -----

  Future<void> openSplit(SocietyCost cost) async {
    emit(state.copyWith(
      splitCost: () => cost,
      splitMethod: cost.split?.splitMethod ?? CostSplitMethod.equal,
      splitPreview: const [],
      manualAmounts: const [],
      splitError: () => null,
    ));
    await refreshSplitPreview();
  }

  void closeSplit() => emit(state.copyWith(splitCost: () => null));

  Future<void> setSplitMethod(CostSplitMethod method) async {
    emit(state.copyWith(splitMethod: method));
    await refreshSplitPreview();
  }

  void setManualAmount(int memberId, num? amount) {
    emit(state.copyWith(manualAmounts: [
      for (final m in state.manualAmounts)
        if (m.memberId == memberId)
          ManualAmount(
              memberId: m.memberId, memberName: m.memberName, amount: amount)
        else
          m,
    ]));
  }

  num get manualTotal =>
      state.manualAmounts.fold(0, (sum, m) => sum + (m.amount ?? 0));

  bool get manualMismatch {
    final cost = state.splitCost;
    if (state.splitMethod != CostSplitMethod.manual || cost == null)
      return false;
    return (manualTotal - cost.totalAmount).abs() >= 0.005;
  }

  /// dry_run preview; seeds manual entries when switching to manual.
  Future<void> refreshSplitPreview() async {
    final cost = state.splitCost;
    if (cost == null) return;
    emit(state.copyWith(splitLoading: true, splitError: () => null));
    try {
      var method = state.splitMethod;
      var manual = <({int memberId, num amountDue})>[];
      if (method == CostSplitMethod.manual) {
        manual = [
          for (final m in state.manualAmounts)
            if (m.amount != null && m.amount! >= 0)
              (memberId: m.memberId, amountDue: m.amount!),
        ];
        if (manual.isEmpty) {
          // Seed the member list via an equal-split preview.
          method = CostSplitMethod.equal;
        }
      }
      final result = await _costs.splitCost(
        cost.id,
        splitMethod: method,
        manualShares: manual,
        dryRun: true,
      );
      if (result is List<SplitPreviewRow>) {
        if (state.splitMethod == CostSplitMethod.manual && manual.isNotEmpty) {
          emit(state.copyWith(splitPreview: result, splitLoading: false));
        } else {
          emit(state.copyWith(
            splitPreview: const [],
            manualAmounts: [
              for (final row in result)
                ManualAmount(
                    memberId: row.memberId, memberName: row.memberName),
            ],
            splitLoading: false,
          ));
        }
      } else {
        emit(state.copyWith(splitLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(splitLoading: false, splitError: () => e));
    }
  }

  /// Confirms (saves) the split. Returns success.
  Future<bool> confirmSplit({bool allowMismatch = false}) async {
    final cost = state.splitCost;
    if (cost == null) return false;
    emit(state.copyWith(busy: true, splitError: () => null));
    try {
      await _costs.splitCost(
        cost.id,
        splitMethod: state.splitMethod,
        manualShares: [
          for (final m in state.manualAmounts)
            if (m.amount != null) (memberId: m.memberId, amountDue: m.amount!),
        ],
        allowMismatch: allowMismatch,
      );
      emit(state.copyWith(busy: false, splitCost: () => null));
      await refresh();
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, splitError: () => e));
      return false;
    }
  }

  // ----- Share payment -----

  Future<bool> recordSharePayment(CostSplitShare share,
      {required num additionalAmount, String? receiptNo}) async {
    emit(state.copyWith(busy: true, actionError: () => null));
    try {
      await _costs.recordSharePayment(
        share.id,
        amountPaid: share.amountPaid + additionalAmount,
        receiptNo: receiptNo,
      );
      emit(state.copyWith(busy: false));
      await refresh();
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }
}
