// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

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
        sourceFilter:
            sourceFilter == null ? this.sourceFilter : sourceFilter(),
        billedFilter:
            billedFilter == null ? this.billedFilter : billedFilter(),
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

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class SocietyCostsEvent extends Equatable {
  const SocietyCostsEvent();
  @override
  List<Object?> get props => const [];
}

final class SocietyInitRequested extends SocietyCostsEvent {
  const SocietyInitRequested();

  @override
  List<Object?> get props => const [];
}

final class SocietyCategoriesLoadRequested extends SocietyCostsEvent {
  const SocietyCategoriesLoadRequested();

  @override
  List<Object?> get props => const [];
}

final class SocietyRefreshRequested extends SocietyCostsEvent {
  const SocietyRefreshRequested();

  @override
  List<Object?> get props => const [];
}

final class SocietyFiltersChanged extends SocietyCostsEvent {
  const SocietyFiltersChanged({
    this.categoryFilter,
    this.dateFrom,
    this.dateTo,
    this.sourceFilter,
  });

  final String? categoryFilter;
  final String? dateFrom;
  final String? dateTo;
  final CostPaymentSource? sourceFilter;

  @override
  List<Object?> get props => [categoryFilter, dateFrom, dateTo, sourceFilter];
}

final class SocietyFiltersReset extends SocietyCostsEvent {
  const SocietyFiltersReset();

  @override
  List<Object?> get props => const [];
}

final class SocietyRowToggled extends SocietyCostsEvent {
  const SocietyRowToggled({
    required this.id,
  });

  final int id;

  @override
  List<Object?> get props => [id];
}

final class SocietyCategoryAdded extends SocietyCostsEvent {
  const SocietyCategoryAdded({
    required this.label,
    this.completer,
  });

  final String label;
  final Completer<String?>? completer;

  @override
  List<Object?> get props => [label];
}

final class SocietyCostSaved extends SocietyCostsEvent {
  const SocietyCostSaved({
    required this.input,
    this.editingId,
    this.receiptPath,
    this.completer,
  });

  final SocietyCostInput input;
  final int? editingId;
  final String? receiptPath;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [input, editingId, receiptPath];
}

final class SocietyCostDeleted extends SocietyCostsEvent {
  const SocietyCostDeleted({
    required this.cost,
    this.completer,
  });

  final SocietyCost cost;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [cost];
}

final class SocietySplitOpened extends SocietyCostsEvent {
  const SocietySplitOpened({
    required this.cost,
  });

  final SocietyCost cost;

  @override
  List<Object?> get props => [cost];
}

final class SocietySplitClosed extends SocietyCostsEvent {
  const SocietySplitClosed();

  @override
  List<Object?> get props => const [];
}

final class SocietySplitMethodChanged extends SocietyCostsEvent {
  const SocietySplitMethodChanged({
    required this.method,
  });

  final CostSplitMethod method;

  @override
  List<Object?> get props => [method];
}

final class SocietyManualAmountChanged extends SocietyCostsEvent {
  const SocietyManualAmountChanged({
    required this.memberId,
    this.amount,
  });

  final int memberId;
  final num? amount;

  @override
  List<Object?> get props => [memberId, amount];
}

final class SocietySplitPreviewRefreshed extends SocietyCostsEvent {
  const SocietySplitPreviewRefreshed();

  @override
  List<Object?> get props => const [];
}

final class SocietySplitConfirmed extends SocietyCostsEvent {
  const SocietySplitConfirmed({
    this.allowMismatch = false,
    this.completer,
  });

  final bool allowMismatch;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [allowMismatch];
}

final class SocietySharePaymentRecorded extends SocietyCostsEvent {
  const SocietySharePaymentRecorded({
    required this.share,
    required this.additionalAmount,
    this.receiptNo,
    this.completer,
  });

  final CostSplitShare share;
  final num additionalAmount;
  final String? receiptNo;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [share, additionalAmount, receiptNo];
}

class SocietyCostsBloc extends Bloc<SocietyCostsEvent, SocietyCostsState> {
  SocietyCostsBloc(
      {required AdminRepository adminRepository,
      required SocietyCostRepository costRepository})
      : _admin = adminRepository,
        _costs = costRepository,
        super(const SocietyCostsState()) {
    on<SocietyInitRequested>((e, emit) => init());
    on<SocietyCategoriesLoadRequested>((e, emit) => loadCategories());
    on<SocietyRefreshRequested>((e, emit) => refresh());
    on<SocietyFiltersChanged>((e, emit) => setFilters(categoryFilter: e.categoryFilter, dateFrom: e.dateFrom, dateTo: e.dateTo, sourceFilter: e.sourceFilter));
    on<SocietyFiltersReset>((e, emit) => resetFilters());
    on<SocietyRowToggled>((e, emit) => toggleExpanded(e.id));
    on<SocietyCategoryAdded>((e, emit) async {
      final result = await addCategory(e.label);
      e.completer?.complete(result);
    });
    on<SocietyCostSaved>((e, emit) async {
      final result = await saveCost(input: e.input, editingId: e.editingId, receiptPath: e.receiptPath);
      e.completer?.complete(result);
    });
    on<SocietyCostDeleted>((e, emit) async {
      final result = await deleteCost(e.cost);
      e.completer?.complete(result);
    });
    on<SocietySplitOpened>((e, emit) => openSplit(e.cost));
    on<SocietySplitClosed>((e, emit) => closeSplit());
    on<SocietySplitMethodChanged>((e, emit) => setSplitMethod(e.method));
    on<SocietyManualAmountChanged>((e, emit) => setManualAmount(e.memberId, e.amount));
    on<SocietySplitPreviewRefreshed>((e, emit) => refreshSplitPreview());
    on<SocietySplitConfirmed>((e, emit) async {
      final result = await confirmSplit(allowMismatch: e.allowMismatch);
      e.completer?.complete(result);
    });
    on<SocietySharePaymentRecorded>((e, emit) async {
      final result = await recordSharePayment(e.share, additionalAmount: e.additionalAmount, receiptNo: e.receiptNo);
      e.completer?.complete(result);
    });
  }

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
    if (state.splitMethod != CostSplitMethod.manual || cost == null) {
      return false;
    }
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
