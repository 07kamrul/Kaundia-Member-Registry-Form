part of 'finance_bloc.dart';

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
        statusFilter: statusFilter == null ? this.statusFilter : statusFilter(),
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
