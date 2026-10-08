part of 'finance_bloc.dart';

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
