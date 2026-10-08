import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/utils/download_utils.dart';
import '../../data/finance_repository.dart';
import '../../domain/finance_entities.dart';
import '../../domain/payment_entities.dart';

// Events --------------------------------------------------------------------

sealed class FundTransparencyEvent extends Equatable {
  const FundTransparencyEvent();

  @override
  List<Object?> get props => const [];
}

class FundPeriodChanged extends FundTransparencyEvent {
  const FundPeriodChanged(this.period, {this.dateFrom, this.dateTo});

  final FinancePeriod period;
  final String? dateFrom;
  final String? dateTo;

  @override
  List<Object?> get props => [period, dateFrom, dateTo];
}

class FundLedgerFiltersChanged extends FundTransparencyEvent {
  const FundLedgerFiltersChanged({this.type, this.search});

  final FinanceType? type;
  final String? search;

  @override
  List<Object?> get props => [type, search];
}

class FundLedgerPageChanged extends FundTransparencyEvent {
  const FundLedgerPageChanged(this.delta);

  final int delta;

  @override
  List<Object?> get props => [delta];
}

class FundReportDownloaded extends FundTransparencyEvent {
  const FundReportDownloaded();
}

// State ---------------------------------------------------------------------

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
      ledgerDateFrom: clearLedgerDates ? null : (ledgerDateFrom ?? this.ledgerDateFrom),
      ledgerDateTo: clearLedgerDates ? null : (ledgerDateTo ?? this.ledgerDateTo),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      search: clearSearch ? null : (search ?? this.search),
      ledger: ledger ?? this.ledger,
      ledgerLoading: ledgerLoading ?? this.ledgerLoading,
      ledgerError: clearLedgerError ? false : (ledgerError ?? this.ledgerError),
      page: page ?? this.page,
      pdfDownloading: pdfDownloading ?? this.pdfDownloading,
      pdfError: clearPdfError ? false : (pdfError ?? this.pdfError),
      pdfSavedPath: clearPdfSavedPath ? null : (pdfSavedPath ?? this.pdfSavedPath),
    );
  }

  @override
  List<Object?> get props => [
        status, summary, error, period, ledgerDateFrom, ledgerDateTo,
        typeFilter, search, ledger, ledgerLoading, ledgerError, page, pageSize,
        pdfDownloading, pdfError, pdfSavedPath,
      ];
}

class FundTransparencyCubit extends Cubit<FundTransparencyState> {
  FundTransparencyCubit({FinanceRepository? repository})
      : _repository = repository ?? FinanceRepository(apiClient: sl<ApiClient>()),
        super(const FundTransparencyState());

  final FinanceRepository _repository;

  /// Loads the summary, then chains the ledger with the summary's date bounds
  /// (mirrors Angular loadLedgerWithPeriodDates).
  Future<void> applyPeriod(
    FinancePeriod period, {
    String? dateFrom,
    String? dateTo,
  }) async {
    if (period == FinancePeriod.custom &&
        ((dateFrom ?? '').isEmpty || (dateTo ?? '').isEmpty || dateFrom! > dateTo!)) {
      // Caller surfaces the inline period error.
      return;
    }
    emit(state.copyWith(status: FundStatus.loading, clearError: true, period: period));
    try {
      final summary = await _repository.getSummary(
        period,
        dateFrom: period == FinancePeriod.custom ? dateFrom : null,
        dateTo: period == FinancePeriod.custom ? dateTo : null,
      );
      emit(state.copyWith(
        status: FundStatus.loaded,
        summary: summary,
        clearError: true,
        ledgerDateFrom: summary.periodDateFrom,
        ledgerDateTo: summary.periodDateTo,
        page: 1,
      ));
      await _loadLedger(emit);
    } on ApiException {
      emit(state.copyWith(status: FundStatus.failure, error: true));
    }
  }

  Future<void> setFilters({FinanceType? type, String? search}) async {
    emit(state.copyWith(
      typeFilter: type,
      clearTypeFilter: type == null,
      search: search,
      clearSearch: search == null,
      page: 1,
      ledgerLoading: true,
      clearLedgerError: true,
    ));
    await _loadLedger(emit);
  }

  Future<void> changePage(int delta) async {
    final next = state.page + delta;
    if (next < 1 || next > state.totalPages) return;
    emit(state.copyWith(page: next, ledgerLoading: true, clearLedgerError: true));
    await _loadLedger(emit);
  }

  Future<void> _loadLedger(Emitter<FundTransparencyState> emit) async {
    emit(state.copyWith(ledgerLoading: true, clearLedgerError: true));
    try {
      final ledger = await _repository.getTransactions(state.ledgerFilters);
      emit(state.copyWith(ledger: ledger, ledgerLoading: false, clearLedgerError: true));
    } on ApiException {
      emit(state.copyWith(ledgerLoading: false, ledgerError: true));
    }
  }

  Future<void> downloadReport() async {
    if (state.pdfDownloading) return;
    emit(state.copyWith(pdfDownloading: true, clearPdfError: true, clearPdfSavedPath: true));
    try {
      final bytes = await _repository.downloadReport(
        period: state.period,
        filters: state.ledgerFilters,
        dateFrom: state.period == FinancePeriod.custom ? state.ledgerDateFrom : null,
        dateTo: state.period == FinancePeriod.custom ? state.ledgerDateTo : null,
      );
      final file = await saveDownload(bytes, 'fund-transparency-report.pdf');
      emit(state.copyWith(pdfDownloading: false, pdfSavedPath: file.path));
    } on ApiException {
      emit(state.copyWith(pdfDownloading: false, pdfError: true));
    }
  }

  void clearPdfSavedPath() => emit(state.copyWith(clearPdfSavedPath: true));
}
