import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/utils/download_utils.dart';
import '../../data/finance_repository.dart';
import '../../domain/finance_entities.dart';
import '../../domain/payment_entities.dart';

part 'fund_transparency_event.dart';
part 'fund_transparency_state.dart';

class FundTransparencyBloc
    extends Bloc<FundTransparencyEvent, FundTransparencyState> {
  FundTransparencyBloc({FinanceRepository? repository})
      : _repository =
            repository ?? FinanceRepository(apiClient: sl<ApiClient>()),
        super(const FundTransparencyState()) {
    on<FundStarted>(_onPeriodApplied);
    on<FundPeriodChanged>(_onPeriodApplied);
    on<FundLedgerFiltersChanged>(_onFiltersChanged);
    on<FundLedgerPageChanged>(_onPageChanged);
    on<FundReportDownloaded>(_onReportDownloaded);
    on<FundPdfSavedPathCleared>(
      (_, emit) => emit(state.copyWith(clearPdfSavedPath: true)),
    );
  }

  final FinanceRepository _repository;

  /// Loads the summary, then chains the ledger with the summary's date bounds
  /// (mirrors Angular loadLedgerWithPeriodDates).
  Future<void> _onPeriodApplied(
    FundTransparencyEvent e,
    Emitter<FundTransparencyState> emit,
  ) async {
    final period = switch (e) {
      FundStarted(:final period, :final dateFrom, :final dateTo) ||
      FundPeriodChanged(:final period, :final dateFrom, :final dateTo) =>
        (period, dateFrom, dateTo),
      _ => (state.period, null as String?, null as String?),
    };
    if (period.$1 == FinancePeriod.custom &&
        ((period.$2 ?? '').isEmpty ||
            (period.$3 ?? '').isEmpty ||
            period.$2!.compareTo(period.$3!) > 0)) {
      // Caller surfaces the inline period error.
      return;
    }
    emit(state.copyWith(
        status: FundStatus.loading, clearError: true, period: period.$1));
    try {
      final summary = await _repository.getSummary(
        period.$1,
        dateFrom: period.$1 == FinancePeriod.custom ? period.$2 : null,
        dateTo: period.$1 == FinancePeriod.custom ? period.$3 : null,
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

  Future<void> _onFiltersChanged(
    FundLedgerFiltersChanged e,
    Emitter<FundTransparencyState> emit,
  ) async {
    emit(state.copyWith(
      typeFilter: e.type,
      clearTypeFilter: e.type == null,
      search: e.search,
      clearSearch: e.search == null,
      page: 1,
    ));
    await _loadLedger(emit);
  }

  Future<void> _onPageChanged(
    FundLedgerPageChanged e,
    Emitter<FundTransparencyState> emit,
  ) async {
    final next = state.page + e.delta;
    if (next < 1 || next > state.totalPages) return;
    emit(state.copyWith(page: next));
    await _loadLedger(emit);
  }

  Future<void> _loadLedger(Emitter<FundTransparencyState> emit) async {
    emit(state.copyWith(ledgerLoading: true, clearLedgerError: true));
    try {
      final ledger = await _repository.getTransactions(state.ledgerFilters);
      emit(state.copyWith(
          ledger: ledger, ledgerLoading: false, clearLedgerError: true));
    } on ApiException {
      emit(state.copyWith(ledgerLoading: false, ledgerError: true));
    }
  }

  Future<void> _onReportDownloaded(
    FundReportDownloaded e,
    Emitter<FundTransparencyState> emit,
  ) async {
    if (state.pdfDownloading) return;
    emit(state.copyWith(
        pdfDownloading: true, clearPdfError: true, clearPdfSavedPath: true));
    try {
      final bytes = await _repository.downloadReport(
        period: state.period,
        filters: state.ledgerFilters,
        dateFrom:
            state.period == FinancePeriod.custom ? state.ledgerDateFrom : null,
        dateTo:
            state.period == FinancePeriod.custom ? state.ledgerDateTo : null,
      );
      final file = await saveDownload(bytes, 'fund-transparency-report.pdf');
      emit(state.copyWith(pdfDownloading: false, pdfSavedPath: file.path));
    } on ApiException {
      emit(state.copyWith(pdfDownloading: false, pdfError: true));
    }
  }
}
