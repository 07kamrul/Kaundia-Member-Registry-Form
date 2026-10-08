part of 'fund_transparency_bloc.dart';

enum FundStatus { loading, loaded, failure }

class FundTransparencyState extends Equatable {
  const FundTransparencyState({
    this.status = FundStatus.loading,
    this.summary,
    this.error = false,
    this.period = FinancePeriod.month,
    this.ledgerDateFrom,
    this.ledgerDateTo,
    this.typeFilter,
    this.search,
    this.ledger,
    this.ledgerLoading = false,
    this.ledgerError = false,
    this.page = 1,
    this.pageSize = 25,
    this.pdfDownloading = false,
    this.pdfError = false,
    this.pdfSavedPath,
  });

  final FundStatus status;
  final FinanceSummary? summary;
  final bool error;
  final FinancePeriod period;
  final String? ledgerDateFrom;
  final String? ledgerDateTo;
  final FinanceType? typeFilter;
  final String? search;
  final FinanceLedgerPage? ledger;
  final bool ledgerLoading;
  final bool ledgerError;
  final int page;
  final int pageSize;
  final bool pdfDownloading;
  final bool pdfError;
  final String? pdfSavedPath;

  int get totalPages {
    final total = ledger?.total ?? 0;
    return total == 0 ? 1 : (total + pageSize - 1) ~/ pageSize;
  }

  bool get isEmptyState =>
      status == FundStatus.loaded &&
      summary != null &&
      summary!.transactionCount == 0 &&
      period == FinancePeriod.all &&
      typeFilter == null &&
      (search ?? '').isEmpty;

  FinanceLedgerFilters get ledgerFilters => FinanceLedgerFilters(
        type: typeFilter,
        dateFrom: ledgerDateFrom,
        dateTo: ledgerDateTo,
        search: (search ?? '').trim().isEmpty ? null : search!.trim(),
        limit: pageSize,
        offset: (page - 1) * pageSize,
      );

  FundTransparencyState copyWith({
    FundStatus? status,
    FinanceSummary? summary,
    bool clearError = false,
    bool? error,
    FinancePeriod? period,
    String? ledgerDateFrom,
    bool clearLedgerDates = false,
    String? ledgerDateTo,
    FinanceType? typeFilter,
    bool clearTypeFilter = false,
    String? search,
    bool clearSearch = false,
    FinanceLedgerPage? ledger,
    bool? ledgerLoading,
    bool clearLedgerError = false,
    bool? ledgerError,
    int? page,
    bool? pdfDownloading,
    bool clearPdfError = false,
    bool? pdfError,
    String? pdfSavedPath,
    bool clearPdfSavedPath = false,
  }) {
    return FundTransparencyState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      error: clearError ? false : (error ?? this.error),
      period: period ?? this.period,
      ledgerDateFrom:
          clearLedgerDates ? null : (ledgerDateFrom ?? this.ledgerDateFrom),
      ledgerDateTo:
          clearLedgerDates ? null : (ledgerDateTo ?? this.ledgerDateTo),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      search: clearSearch ? null : (search ?? this.search),
      ledger: ledger ?? this.ledger,
      ledgerLoading: ledgerLoading ?? this.ledgerLoading,
      ledgerError: clearLedgerError ? false : (ledgerError ?? this.ledgerError),
      page: page ?? this.page,
      pdfDownloading: pdfDownloading ?? this.pdfDownloading,
      pdfError: clearPdfError ? false : (pdfError ?? this.pdfError),
      pdfSavedPath:
          clearPdfSavedPath ? null : (pdfSavedPath ?? this.pdfSavedPath),
    );
  }

  @override
  List<Object?> get props => [
        status,
        summary,
        error,
        period,
        ledgerDateFrom,
        ledgerDateTo,
        typeFilter,
        search,
        ledger,
        ledgerLoading,
        ledgerError,
        page,
        pageSize,
        pdfDownloading,
        pdfError,
        pdfSavedPath,
      ];
}
