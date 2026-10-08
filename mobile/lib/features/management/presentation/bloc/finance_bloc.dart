// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/finance_entities.dart';

part 'finance_event.dart';
part 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  FinanceBloc({
    required AdminRepository adminRepository,
    required FinanceRepository financeRepository,
  })  : _admin = adminRepository,
        _finance = financeRepository,
        super(const FinanceState()) {
    on<FinanceInitRequested>((e, emit) => init());
    on<FinanceCategoriesLoadRequested>((e, emit) => loadCategories());
    on<FinanceOverviewLoadRequested>((e, emit) => loadOverview());
    on<FinanceRefreshRequested>((e, emit) => refresh());
    on<FinanceFiltersChanged>((e, emit) => setFilters(
        statusFilter: e.statusFilter,
        typeFilter: e.typeFilter,
        search: e.search));
    on<FinanceDateRangeChanged>(
        (e, emit) => setDateRange(from: e.from, to: e.to));
    on<FinanceFiltersReset>((e, emit) => resetFilters());
    on<FinancePageChanged>((e, emit) => changePage(e.delta));
    on<FinanceRowToggled>((e, emit) => toggleExpanded(e.id));
    on<FinanceTransactionSaved>((e, emit) async {
      final result = await saveTransaction(
          input: e.input,
          editingId: e.editingId,
          attachmentPath: e.attachmentPath);
      e.completer?.complete(result);
    });
    on<FinanceDraftSubmitted>((e, emit) async {
      final result = await submitDraft(e.txn);
      e.completer?.complete(result);
    });
    on<FinanceApproved>((e, emit) async {
      final result = await approve(e.txn);
      e.completer?.complete(result);
    });
    on<FinanceRejected>((e, emit) async {
      final result = await reject(e.txn, e.reason);
      e.completer?.complete(result);
    });
    on<FinanceReversed>((e, emit) async {
      final result = await reverse(e.txn, e.reason);
      e.completer?.complete(result);
    });
    on<FinanceDeleted>((e, emit) async {
      final result = await delete(e.txn, e.reason);
      e.completer?.complete(result);
    });
    on<FinanceUnlinkedPaymentsRequested>((e, emit) =>
        loadUnlinkedPayments(sourceType: e.sourceType, search: e.search));
    on<FinanceCategoryAdded>((e, emit) async {
      final result = await addCategory(e.label);
      e.completer?.complete(result);
    });
    on<FinanceReportNoticePublished>((e, emit) async {
      final result = await publishReportNotice(period: e.period);
      e.completer?.complete(result);
    });
  }

  final AdminRepository _admin;
  final FinanceRepository _finance;

  Future<void> init() async {
    loadCategories();
    refresh();
    loadOverview();
  }

  Future<void> loadCategories() async {
    try {
      final categories = await _finance.categories();
      emit(state.copyWith(categories: categories));
    } catch (_) {
      emit(state.copyWith(categories: const []));
    }
  }

  Future<void> loadOverview() async {
    try {
      final overview = await _finance.overview();
      emit(state.copyWith(overview: () => overview));
    } catch (_) {
      emit(state.copyWith(overview: () => null));
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final ledger = await _finance.adminTransactions(
        status: state.statusFilter,
        type: state.typeFilter,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        search: state.search,
        limit: FinanceState.pageSize,
        offset: (state.page - 1) * FinanceState.pageSize,
      );
      emit(state.copyWith(ledger: () => ledger, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: () => e));
    }
  }

  void setFilters(
      {FinanceStatus? statusFilter, FinanceType? typeFilter, String? search}) {
    emit(state.copyWith(
      statusFilter: () => statusFilter,
      typeFilter: () => typeFilter,
      search: search ?? state.search,
      page: 1,
    ));
    refresh();
  }

  void setDateRange({String? from, String? to}) {
    emit(state.copyWith(
        dateFrom: from ?? state.dateFrom, dateTo: to ?? state.dateTo, page: 1));
  }

  void resetFilters() {
    emit(state.copyWith(
      statusFilter: () => null,
      typeFilter: () => null,
      dateFrom: '',
      dateTo: '',
      search: '',
      page: 1,
    ));
    refresh();
  }

  int get totalPages {
    final total = state.ledger?.total ?? 0;
    return total == 0 ? 1 : (total / FinanceState.pageSize).ceil();
  }

  void changePage(int delta) {
    final next = state.page + delta;
    if (next < 1 || next > totalPages) return;
    emit(state.copyWith(page: next));
    refresh();
  }

  void toggleExpanded(int id) => emit(
      state.copyWith(expandedId: () => state.expandedId == id ? null : id));

  /// Creates (editingId == null) or updates a transaction, then uploads an
  /// optional attachment. Returns success.
  Future<bool> saveTransaction({
    required FinanceTransactionInput input,
    int? editingId,
    String? attachmentPath,
  }) async {
    emit(state.copyWith(busy: true, actionError: () => null));
    try {
      final txn = editingId == null
          ? await _finance.createTransaction(input)
          : await _finance.updateTransaction(editingId, input);
      if (attachmentPath != null) {
        await _finance.uploadAttachment(txn.id, attachmentPath);
      }
      emit(state.copyWith(busy: false));
      await refresh();
      await loadOverview();
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }

  Future<bool> submitDraft(FinanceTransaction txn) =>
      _action(() => _finance.submitTransaction(txn.id));

  Future<bool> approve(FinanceTransaction txn) =>
      _action(() => _finance.approveTransaction(txn.id));

  Future<bool> reject(FinanceTransaction txn, String reason) =>
      _action(() => _finance.rejectTransaction(txn.id, reason));

  Future<bool> reverse(FinanceTransaction txn, String reason) =>
      _action(() => _finance.reverseTransaction(txn.id, reason));

  Future<bool> delete(FinanceTransaction txn, String reason) =>
      _action(() => _finance.deleteTransaction(txn.id, reason));

  Future<bool> _action(Future<Object?> Function() run) async {
    emit(state.copyWith(busy: true, actionError: () => null));
    try {
      await run();
      emit(state.copyWith(busy: false));
      await refresh();
      await loadOverview();
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }

  Future<void> loadUnlinkedPayments(
      {PaymentSourceType? sourceType, String? search}) async {
    emit(state.copyWith(unlinkedLoading: true));
    try {
      final payments = await _finance.unlinkedPayments(
          sourceType: sourceType, search: search);
      emit(state.copyWith(unlinkedPayments: payments, unlinkedLoading: false));
    } catch (_) {
      emit(state.copyWith(unlinkedPayments: const [], unlinkedLoading: false));
    }
  }

  /// Adds a finance_*_category config item and returns the new category.
  Future<FinanceCategory?> addCategory(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return null;
    final listKey = state.typeFilter == FinanceType.expense
        ? 'finance_expense_category'
        : 'finance_income_category';
    try {
      final item = await _admin.createConfigListItem(
          category: listKey, value: trimmed, label: trimmed);
      final category = FinanceCategory(
        id: int.tryParse(item.id) ?? 0,
        type: listKey == 'finance_expense_category'
            ? FinanceType.expense
            : FinanceType.income,
        label: item.label,
        isActive: true,
      );
      emit(state.copyWith(categories: [...state.categories, category]));
      return category;
    } catch (e) {
      emit(state.copyWith(actionError: () => e));
      return null;
    }
  }

  Future<bool> publishReportNotice(
      {FinancePeriod period = FinancePeriod.month}) async {
    emit(
        state.copyWith(busy: true, actionError: () => null, noticeDone: false));
    try {
      await _finance.publishReportNotice(period);
      emit(state.copyWith(busy: false, noticeDone: true));
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }
}
