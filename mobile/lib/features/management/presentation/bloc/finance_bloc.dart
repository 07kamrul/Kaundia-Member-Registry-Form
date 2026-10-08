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
    on<FinanceInitRequested>(_onInit);
    on<FinanceCategoriesLoadRequested>((e, emit) => _loadCategories(emit));
    on<FinanceOverviewLoadRequested>((e, emit) => _loadOverview(emit));
    on<FinanceRefreshRequested>((e, emit) => _refresh(emit));
    on<FinanceFiltersChanged>(_onFiltersChanged);
    on<FinanceDateRangeChanged>(_onDateRangeChanged);
    on<FinanceFiltersReset>(_onFiltersReset);
    on<FinancePageChanged>(_onPageChanged);
    on<FinanceRowToggled>(_onRowToggled);
    on<FinanceTransactionSaved>((e, emit) async {
      final result = await _saveTransaction(
        emit,
        input: e.input,
        editingId: e.editingId,
        attachmentPath: e.attachmentPath,
      );
      e.completer?.complete(result);
    });
    on<FinanceDraftSubmitted>((e, emit) async {
      final result =
          await _action(() => _finance.submitTransaction(e.txn.id), emit);
      e.completer?.complete(result);
    });
    on<FinanceApproved>((e, emit) async {
      final result =
          await _action(() => _finance.approveTransaction(e.txn.id), emit);
      e.completer?.complete(result);
    });
    on<FinanceRejected>((e, emit) async {
      final result = await _action(
          () => _finance.rejectTransaction(e.txn.id, e.reason), emit);
      e.completer?.complete(result);
    });
    on<FinanceReversed>((e, emit) async {
      final result = await _action(
          () => _finance.reverseTransaction(e.txn.id, e.reason), emit);
      e.completer?.complete(result);
    });
    on<FinanceDeleted>((e, emit) async {
      final result = await _action(
          () => _finance.deleteTransaction(e.txn.id, e.reason), emit);
      e.completer?.complete(result);
    });
    on<FinanceUnlinkedPaymentsRequested>(_onUnlinkedPaymentsRequested);
    on<FinanceCategoryAdded>((e, emit) async {
      final result = await _addCategory(e.label, emit);
      e.completer?.complete(result);
    });
    on<FinanceReportNoticePublished>((e, emit) async {
      final result = await _publishReportNotice(emit, period: e.period);
      e.completer?.complete(result);
    });
  }

  final AdminRepository _admin;
  final FinanceRepository _finance;

  /// Loads categories, ledger and overview concurrently.
  Future<void> _onInit(
    FinanceInitRequested event,
    Emitter<FinanceState> emit,
  ) async {
    await Future.wait([
      _loadCategories(emit),
      _refresh(emit),
      _loadOverview(emit),
    ]);
  }

  Future<void> _loadCategories(Emitter<FinanceState> emit) async {
    try {
      final categories = await _finance.categories();
      emit(state.copyWith(categories: categories));
    } catch (_) {
      emit(state.copyWith(categories: const []));
    }
  }

  Future<void> _loadOverview(Emitter<FinanceState> emit) async {
    try {
      final overview = await _finance.overview();
      emit(state.copyWith(overview: () => overview));
    } catch (_) {
      emit(state.copyWith(overview: () => null));
    }
  }

  Future<void> _refresh(Emitter<FinanceState> emit) async {
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

  Future<void> _onFiltersChanged(
    FinanceFiltersChanged event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(
      statusFilter: () => event.statusFilter,
      typeFilter: () => event.typeFilter,
      search: event.search ?? state.search,
      page: 1,
    ));
    await _refresh(emit);
  }

  void _onDateRangeChanged(
    FinanceDateRangeChanged event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(
        dateFrom: event.from ?? state.dateFrom,
        dateTo: event.to ?? state.dateTo,
        page: 1));
  }

  Future<void> _onFiltersReset(
    FinanceFiltersReset event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(
      statusFilter: () => null,
      typeFilter: () => null,
      dateFrom: '',
      dateTo: '',
      search: '',
      page: 1,
    ));
    await _refresh(emit);
  }

  int get totalPages {
    final total = state.ledger?.total ?? 0;
    return total == 0 ? 1 : (total / FinanceState.pageSize).ceil();
  }

  Future<void> _onPageChanged(
    FinancePageChanged event,
    Emitter<FinanceState> emit,
  ) async {
    final next = state.page + event.delta;
    if (next < 1 || next > totalPages) return;
    emit(state.copyWith(page: next));
    await _refresh(emit);
  }

  void _onRowToggled(FinanceRowToggled event, Emitter<FinanceState> emit) =>
      emit(state.copyWith(
          expandedId: () => state.expandedId == event.id ? null : event.id));

  /// Creates (editingId == null) or updates a transaction, then uploads an
  /// optional attachment. Returns success.
  Future<bool> _saveTransaction(
    Emitter<FinanceState> emit, {
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
      await _refresh(emit);
      await _loadOverview(emit);
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }

  Future<bool> _action(
    Future<Object?> Function() run,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(busy: true, actionError: () => null));
    try {
      await run();
      emit(state.copyWith(busy: false));
      await _refresh(emit);
      await _loadOverview(emit);
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }

  Future<void> _onUnlinkedPaymentsRequested(
    FinanceUnlinkedPaymentsRequested event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(unlinkedLoading: true));
    try {
      final payments = await _finance.unlinkedPayments(
          sourceType: event.sourceType, search: event.search);
      emit(state.copyWith(unlinkedPayments: payments, unlinkedLoading: false));
    } catch (_) {
      emit(state.copyWith(unlinkedPayments: const [], unlinkedLoading: false));
    }
  }

  /// Adds a finance_*_category config item and returns the new category.
  Future<FinanceCategory?> _addCategory(
    String label,
    Emitter<FinanceState> emit,
  ) async {
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

  Future<bool> _publishReportNotice(
    Emitter<FinanceState> emit, {
    FinancePeriod period = FinancePeriod.month,
  }) async {
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
