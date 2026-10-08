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
    FinanceOverview? Function() overview = _same,
    List<FinanceCategory>? categories,
    FinanceLedgerPage? Function() ledger = _same,
    bool? loading,
    Object? Function() error = _same,
    FinanceStatus? Function() statusFilter = _same,
    FinanceType? Function() typeFilter = _same,
    String? dateFrom,
    String? dateTo,
    String? search,
    int? page,
    bool? busy,
    Object? Function() actionError = _same,
    int? Function() expandedId = _same,
    List<UnlinkedPayment>? unlinkedPayments,
    bool? unlinkedLoading,
    bool? noticeDone,
  }) =>
      FinanceState(
        overview: overview == _same ? this.overview : overview(),
        categories: categories ?? this.categories,
        ledger: ledger == _same ? this.ledger : ledger(),
        loading: loading ?? this.loading,
        error: error == _same ? this.error : error(),
        statusFilter: statusFilter == _same ? this.statusFilter : statusFilter(),
        typeFilter: typeFilter == _same ? this.typeFilter : typeFilter(),
        dateFrom: dateFrom ?? this.dateFrom,
        dateTo: dateTo ?? this.dateTo,
        search: search ?? this.search,
        page: page ?? this.page,
        busy: busy ?? this.busy,
        actionError: actionError == _same ? this.actionError : actionError(),
        expandedId: expandedId == _same ? this.expandedId : expandedId(),
        unlinkedPayments: unlinkedPayments ?? this.unlinkedPayments,
        unlinkedLoading: unlinkedLoading ?? this.unlinkedLoading,
        noticeDone: noticeDone ?? this.noticeDone,
      );

  static T _same<T>() => throw UnsupportedError('sentinel');

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

class FinanceCubit extends Cubit<FinanceState> {
  FinanceCubit({
    required AdminRepository adminRepository,
    required FinanceRepository financeRepository,
  })  : _admin = adminRepository,
        _finance = financeRepository,
        super(const FinanceState());

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

  void setFilters({FinanceStatus? statusFilter, FinanceType? typeFilter, String? search}) {
    emit(state.copyWith(
      statusFilter: () => statusFilter,
      typeFilter: () => typeFilter,
      search: search ?? state.search,
      page: 1,
    ));
    refresh();
  }

  void setDateRange({String? from, String? to}) {
    emit(state.copyWith(dateFrom: from ?? state.dateFrom, dateTo: to ?? state.dateTo, page: 1));
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

  void toggleExpanded(int id) =>
      emit(state.copyWith(expandedId: () => state.expandedId == id ? null : id));

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

  Future<bool> submitDraft(FinanceTransaction txn) => _action(() => _finance.submitTransaction(txn.id));

  Future<bool> approve(FinanceTransaction txn) => _action(() => _finance.approveTransaction(txn.id));

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

  Future<void> loadUnlinkedPayments({PaymentSourceType? sourceType, String? search}) async {
    emit(state.copyWith(unlinkedLoading: true));
    try {
      final payments = await _finance.unlinkedPayments(sourceType: sourceType, search: search);
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
      final item = await _admin.createConfigListItem(category: listKey, value: trimmed, label: trimmed);
      final category = FinanceCategory(
        id: int.tryParse(item.id) ?? 0,
        type: listKey == 'finance_expense_category' ? FinanceType.expense : FinanceType.income,
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

  Future<bool> publishReportNotice({FinancePeriod period = FinancePeriod.month}) async {
    emit(state.copyWith(busy: true, actionError: () => null, noticeDone: false));
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
    Object? Function() error = _same,
    int? Function() busyId = _same,
  }) =>
      PaymentVerificationsState(
        statusFilter: statusFilter ?? this.statusFilter,
        payments: payments ?? this.payments,
        loading: loading ?? this.loading,
        error: error == _same ? this.error : error(),
        busyId: busyId == _same ? this.busyId : busyId(),
      );

  static T _same<T>() => throw UnsupportedError('sentinel');

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
      final payments = await _repository.listForAdmin(status: state.statusFilter);
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
