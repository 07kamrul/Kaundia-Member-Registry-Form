import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';
import '../../domain/finance_entities.dart';

part 'society_costs_event.dart';
part 'society_costs_state.dart';

class SocietyCostsBloc extends Bloc<SocietyCostsEvent, SocietyCostsState> {
  SocietyCostsBloc(
      {required AdminRepository adminRepository,
      required SocietyCostRepository costRepository})
      : _admin = adminRepository,
        _costs = costRepository,
        super(const SocietyCostsState()) {
    on<SocietyInitRequested>((e, emit) => _init(emit));
    on<SocietyCategoriesLoadRequested>((e, emit) => _loadCategories(emit));
    on<SocietyRefreshRequested>((e, emit) => _refresh(emit));
    on<SocietyFiltersChanged>((e, emit) => _setFilters(emit,
        categoryFilter: e.categoryFilter,
        dateFrom: e.dateFrom,
        dateTo: e.dateTo,
        sourceFilter: e.sourceFilter,
        billedFilter: e.billedFilter,
        search: e.search));
    on<SocietyFiltersReset>((e, emit) => _resetFilters(emit));
    on<SocietyRowToggled>((e, emit) => _toggleExpanded(e.id, emit));
    on<SocietyCategoryAdded>((e, emit) async {
      final result = await _addCategory(e.label, emit);
      e.completer?.complete(result);
    });
    on<SocietyCostSaved>((e, emit) async {
      final result = await _saveCost(emit,
          input: e.input, editingId: e.editingId, receiptPath: e.receiptPath);
      e.completer?.complete(result);
    });
    on<SocietyCostDeleted>((e, emit) async {
      final result = await _deleteCost(e.cost, emit);
      e.completer?.complete(result);
    });
    on<SocietySplitOpened>((e, emit) => _openSplit(e.cost, emit));
    on<SocietySplitClosed>((e, emit) => _closeSplit(emit));
    on<SocietySplitMethodChanged>((e, emit) => _setSplitMethod(e.method, emit));
    on<SocietyManualAmountChanged>(
        (e, emit) => _setManualAmount(e.memberId, e.amount, emit));
    on<SocietySplitPreviewRefreshed>((e, emit) => _refreshSplitPreview(emit));
    on<SocietySplitConfirmed>((e, emit) async {
      final result = await _confirmSplit(emit, allowMismatch: e.allowMismatch);
      e.completer?.complete(result);
    });
    on<SocietySharePaymentRecorded>((e, emit) async {
      final result = await _recordSharePayment(e.share, emit,
          additionalAmount: e.additionalAmount, receiptNo: e.receiptNo);
      e.completer?.complete(result);
    });
  }

  final AdminRepository _admin;
  final SocietyCostRepository _costs;

  Future<void> _init(Emitter<SocietyCostsState> emit) async {
    await Future.wait([_loadCategories(emit), _refresh(emit)]);
  }

  Future<void> _loadCategories(Emitter<SocietyCostsState> emit) async {
    try {
      final items = await _admin.listConfigListItems('cost_category');
      emit(state.copyWith(categories: items.where((i) => i.isActive).toList()));
    } catch (_) {
      emit(state.copyWith(categories: const []));
    }
  }

  Future<void> _refresh(Emitter<SocietyCostsState> emit) async {
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

  Future<void> _setFilters(
    Emitter<SocietyCostsState> emit, {
    String? categoryFilter,
    String? dateFrom,
    String? dateTo,
    CostPaymentSource? sourceFilter,
    bool? billedFilter,
    String? search,
  }) async {
    emit(state.copyWith(
      categoryFilter: () => categoryFilter,
      dateFrom: dateFrom ?? state.dateFrom,
      dateTo: dateTo ?? state.dateTo,
      sourceFilter: () => sourceFilter,
      billedFilter: () => billedFilter,
      search: search ?? state.search,
    ));
    await _refresh(emit);
  }

  Future<void> _resetFilters(Emitter<SocietyCostsState> emit) async {
    emit(state.copyWith(
      categoryFilter: () => null,
      sourceFilter: () => null,
      billedFilter: () => null,
      dateFrom: '',
      dateTo: '',
      search: '',
    ));
    await _refresh(emit);
  }

  void _toggleExpanded(int id, Emitter<SocietyCostsState> emit) => emit(
      state.copyWith(expandedId: () => state.expandedId == id ? null : id));

  /// Adds a cost_category config item from the form, returns its id.
  Future<String?> _addCategory(
      String label, Emitter<SocietyCostsState> emit) async {
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

  Future<bool> _saveCost(Emitter<SocietyCostsState> emit,
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
      await _refresh(emit);
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }

  Future<bool> _deleteCost(
      SocietyCost cost, Emitter<SocietyCostsState> emit) async {
    emit(state.copyWith(busy: true, actionError: () => null));
    try {
      await _costs.deleteCost(cost.id);
      emit(state.copyWith(busy: false));
      await _refresh(emit);
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }

  // ----- Split flow -----

  Future<void> _openSplit(
      SocietyCost cost, Emitter<SocietyCostsState> emit) async {
    emit(state.copyWith(
      splitCost: () => cost,
      splitMethod: cost.split?.splitMethod ?? CostSplitMethod.equal,
      splitPreview: const [],
      manualAmounts: const [],
      splitError: () => null,
    ));
    await _refreshSplitPreview(emit);
  }

  void _closeSplit(Emitter<SocietyCostsState> emit) =>
      emit(state.copyWith(splitCost: () => null));

  Future<void> _setSplitMethod(
      CostSplitMethod method, Emitter<SocietyCostsState> emit) async {
    emit(state.copyWith(splitMethod: method));
    await _refreshSplitPreview(emit);
  }

  void _setManualAmount(
      int memberId, num? amount, Emitter<SocietyCostsState> emit) {
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
  Future<void> _refreshSplitPreview(Emitter<SocietyCostsState> emit) async {
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
  Future<bool> _confirmSplit(Emitter<SocietyCostsState> emit,
      {bool allowMismatch = false}) async {
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
      await _refresh(emit);
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, splitError: () => e));
      return false;
    }
  }

  // ----- Share payment -----

  Future<bool> _recordSharePayment(
      CostSplitShare share, Emitter<SocietyCostsState> emit,
      {required num additionalAmount, String? receiptNo}) async {
    emit(state.copyWith(busy: true, actionError: () => null));
    try {
      await _costs.recordSharePayment(
        share.id,
        amountPaid: share.amountPaid + additionalAmount,
        receiptNo: receiptNo,
      );
      emit(state.copyWith(busy: false));
      await _refresh(emit);
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }
}
