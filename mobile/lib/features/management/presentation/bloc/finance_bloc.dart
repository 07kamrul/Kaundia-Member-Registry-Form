// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/finance_entities.dart';

// ----- Finance management -----

class FinanceState extends Equatable {
  const FinanceState({
    this.overview,
    this.categories = const [],
    this.ledger,
    this.loading = true,
    this.error,
    this.statusFilter,
    this.typeFilter,
    this.dateFrom = '',
    this.dateTo = '',
    this.search = '',
    this.page = 1,
    this.busy = false,
    this.actionError,
    this.expandedId,
    this.unlinkedPayments = const [],
    this.unlinkedLoading = false,
    this.noticeDone = false,
  });

  final FinanceOverview? overview;
  final List<FinanceCategory> categories;
  final FinanceLedgerPage? ledger;
  final bool loading;
  final Object? error;

  /// null = all statuses.
  final FinanceStatus? statusFilter;
  final FinanceType? typeFilter;
  final String dateFrom;
  final String dateTo;
  final String search;
  final int page;
  final bool busy;
  final Object? actionError;
  final int? expandedId;
  final List<UnlinkedPayment> unlinkedPayments;
  final bool unlinkedLoading;
  final bool noticeDone;

  static const pageSize = 25;

  FinanceState copyWith({
    FinanceOverview? Function()? overview,
    List<FinanceCategory>? categories,
    FinanceLedgerPage? Function()? ledger,
    bool? loading,
    Object? Function()? error,
    FinanceStatus? Function()? statusFilter,
    FinanceType? Function()? typeFilter,
    String? dateFrom,
    String? dateTo,
    String? search,
    int? page,
    bool? busy,
    Object? Function()? actionError,
    int? Function()? expandedId,
    List<UnlinkedPayment>? unlinkedPayments,
    bool? unlinkedLoading,
    bool? noticeDone,
  }) =>
      FinanceState(
        overview: overview == null ? this.overview : overview(),
        categories: categories ?? this.categories,
        ledger: ledger == null ? this.ledger : ledger(),
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
        statusFilter:
            statusFilter == null ? this.statusFilter : statusFilter(),
        typeFilter: typeFilter == null ? this.typeFilter : typeFilter(),
        dateFrom: dateFrom ?? this.dateFrom,
        dateTo: dateTo ?? this.dateTo,
        search: search ?? this.search,
        page: page ?? this.page,
        busy: busy ?? this.busy,
        actionError: actionError == null ? this.actionError : actionError(),
        expandedId: expandedId == null ? this.expandedId : expandedId(),
        unlinkedPayments: unlinkedPayments ?? this.unlinkedPayments,
        unlinkedLoading: unlinkedLoading ?? this.unlinkedLoading,
        noticeDone: noticeDone ?? this.noticeDone,
      );


  @override
  List<Object?> get props => [
        overview,
        categories,
        ledger,
        loading,
        error,
        statusFilter,
        typeFilter,
        dateFrom,
        dateTo,
        search,
        page,
        busy,
        actionError,
        expandedId,
        unlinkedPayments,
        unlinkedLoading,
        noticeDone,
      ];
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class FinanceEvent extends Equatable {
  const FinanceEvent();
  @override
  List<Object?> get props => const [];
}

final class FinanceInitRequested extends FinanceEvent {
  const FinanceInitRequested();

  @override
  List<Object?> get props => const [];
}

final class FinanceCategoriesLoadRequested extends FinanceEvent {
  const FinanceCategoriesLoadRequested();

  @override
  List<Object?> get props => const [];
}

final class FinanceOverviewLoadRequested extends FinanceEvent {
  const FinanceOverviewLoadRequested();

  @override
  List<Object?> get props => const [];
}

final class FinanceRefreshRequested extends FinanceEvent {
  const FinanceRefreshRequested();

  @override
  List<Object?> get props => const [];
}

final class FinanceFiltersChanged extends FinanceEvent {
  const FinanceFiltersChanged({
    this.statusFilter,
    this.typeFilter,
    this.search,
  });

  final FinanceStatus? statusFilter;
  final FinanceType? typeFilter;
  final String? search;

  @override
  List<Object?> get props => [statusFilter, typeFilter, search];
}

final class FinanceDateRangeChanged extends FinanceEvent {
  const FinanceDateRangeChanged({
    this.from,
    this.to,
  });

  final String? from;
  final String? to;

  @override
  List<Object?> get props => [from, to];
}

final class FinanceFiltersReset extends FinanceEvent {
  const FinanceFiltersReset();

  @override
  List<Object?> get props => const [];
}

final class FinancePageChanged extends FinanceEvent {
  const FinancePageChanged({
    required this.delta,
  });

  final int delta;

  @override
  List<Object?> get props => [delta];
}

final class FinanceRowToggled extends FinanceEvent {
  const FinanceRowToggled({
    required this.id,
  });

  final int id;

  @override
  List<Object?> get props => [id];
}

final class FinanceTransactionSaved extends FinanceEvent {
  const FinanceTransactionSaved({
    required this.input,
    this.editingId,
    this.attachmentPath,
    this.completer,
  });

  final FinanceTransactionInput input;
  final int? editingId;
  final String? attachmentPath;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [input, editingId, attachmentPath];
}

final class FinanceDraftSubmitted extends FinanceEvent {
  const FinanceDraftSubmitted({
    required this.txn,
    this.completer,
  });

  final FinanceTransaction txn;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [txn];
}

final class FinanceApproved extends FinanceEvent {
  const FinanceApproved({
    required this.txn,
    this.completer,
  });

  final FinanceTransaction txn;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [txn];
}

final class FinanceRejected extends FinanceEvent {
  const FinanceRejected({
    required this.txn,
    required this.reason,
    this.completer,
  });

  final FinanceTransaction txn;
  final String reason;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [txn, reason];
}

final class FinanceReversed extends FinanceEvent {
  const FinanceReversed({
    required this.txn,
    required this.reason,
    this.completer,
  });

  final FinanceTransaction txn;
  final String reason;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [txn, reason];
}

final class FinanceDeleted extends FinanceEvent {
  const FinanceDeleted({
    required this.txn,
    required this.reason,
    this.completer,
  });

  final FinanceTransaction txn;
  final String reason;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [txn, reason];
}

final class FinanceUnlinkedPaymentsRequested extends FinanceEvent {
  const FinanceUnlinkedPaymentsRequested({
    this.sourceType,
    this.search,
  });

  final PaymentSourceType? sourceType;
  final String? search;

  @override
  List<Object?> get props => [sourceType, search];
}

final class FinanceCategoryAdded extends FinanceEvent {
  const FinanceCategoryAdded({
    required this.label,
    this.completer,
  });

  final String label;
  final Completer<FinanceCategory?>? completer;

  @override
  List<Object?> get props => [label];
}

final class FinanceReportNoticePublished extends FinanceEvent {
  const FinanceReportNoticePublished({
    this.period = FinancePeriod.month,
    this.completer,
  });

  final FinancePeriod period;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [period];
}

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
    on<FinanceFiltersChanged>((e, emit) => setFilters(statusFilter: e.statusFilter, typeFilter: e.typeFilter, search: e.search));
    on<FinanceDateRangeChanged>((e, emit) => setDateRange(from: e.from, to: e.to));
    on<FinanceFiltersReset>((e, emit) => resetFilters());
    on<FinancePageChanged>((e, emit) => changePage(e.delta));
    on<FinanceRowToggled>((e, emit) => toggleExpanded(e.id));
    on<FinanceTransactionSaved>((e, emit) async {
      final result = await saveTransaction(input: e.input, editingId: e.editingId, attachmentPath: e.attachmentPath);
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
    on<FinanceUnlinkedPaymentsRequested>((e, emit) => loadUnlinkedPayments(sourceType: e.sourceType, search: e.search));
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

// ----- Installment payment verification queue -----

class PaymentVerificationsState extends Equatable {
  const PaymentVerificationsState({
    this.statusFilter = 'pending',
    this.payments = const [],
    this.loading = true,
    this.error,
    this.busyId,
  });

  final String statusFilter;
  final List<AdminInstallmentPayment> payments;
  final bool loading;
  final Object? error;
  final int? busyId;

  PaymentVerificationsState copyWith({
    String? statusFilter,
    List<AdminInstallmentPayment>? payments,
    bool? loading,
    Object? Function()? error,
    int? Function()? busyId,
  }) =>
      PaymentVerificationsState(
        statusFilter: statusFilter ?? this.statusFilter,
        payments: payments ?? this.payments,
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
        busyId: busyId == null ? this.busyId : busyId(),
      );


  @override
  List<Object?> get props => [statusFilter, payments, loading, error, busyId];
}

class PaymentVerificationsCubit extends Cubit<PaymentVerificationsState> {
  PaymentVerificationsCubit({required InstallmentPaymentRepository repository})
      : _repository = repository,
        super(const PaymentVerificationsState());

  final InstallmentPaymentRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final payments =
          await _repository.listForAdmin(status: state.statusFilter);
      emit(state.copyWith(payments: payments, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: () => e));
    }
  }

  void setStatusFilter(String status) {
    emit(PaymentVerificationsState(statusFilter: status));
    load();
  }

  Future<void> approve(AdminInstallmentPayment payment) async {
    emit(state.copyWith(busyId: () => payment.id, error: () => null));
    try {
      await _repository.approve(payment.id);
      emit(state.copyWith(
        busyId: () => null,
        payments: state.payments.where((p) => p.id != payment.id).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(busyId: () => null, error: () => e));
      await load();
    }
  }

  Future<void> reject(AdminInstallmentPayment payment, String reason) async {
    emit(state.copyWith(busyId: () => payment.id, error: () => null));
    try {
      await _repository.reject(payment.id, reason);
      emit(state.copyWith(
        busyId: () => null,
        payments: state.payments.where((p) => p.id != payment.id).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(busyId: () => null, error: () => e));
      await load();
    }
  }
}
