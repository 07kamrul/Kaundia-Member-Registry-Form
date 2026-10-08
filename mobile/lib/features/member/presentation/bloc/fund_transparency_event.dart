part of 'fund_transparency_bloc.dart';

sealed class FundTransparencyEvent extends Equatable {
  const FundTransparencyEvent();

  @override
  List<Object?> get props => const [];
}

/// Initial load of the dashboard for a period.
final class FundStarted extends FundTransparencyEvent {
  const FundStarted(this.period, {this.dateFrom, this.dateTo});

  final FinancePeriod period;
  final String? dateFrom;
  final String? dateTo;

  @override
  List<Object?> get props => [period, dateFrom, dateTo];
}

final class FundPeriodChanged extends FundTransparencyEvent {
  const FundPeriodChanged(this.period, {this.dateFrom, this.dateTo});

  final FinancePeriod period;
  final String? dateFrom;
  final String? dateTo;

  @override
  List<Object?> get props => [period, dateFrom, dateTo];
}

final class FundLedgerFiltersChanged extends FundTransparencyEvent {
  const FundLedgerFiltersChanged({this.type, this.search});

  final FinanceType? type;
  final String? search;

  @override
  List<Object?> get props => [type, search];
}

final class FundLedgerPageChanged extends FundTransparencyEvent {
  const FundLedgerPageChanged(this.delta);

  final int delta;

  @override
  List<Object?> get props => [delta];
}

final class FundReportDownloaded extends FundTransparencyEvent {
  const FundReportDownloaded();
}

final class FundPdfSavedPathCleared extends FundTransparencyEvent {
  const FundPdfSavedPathCleared();
}
