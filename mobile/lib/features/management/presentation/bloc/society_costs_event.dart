part of 'society_costs_bloc.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class SocietyCostsEvent extends Equatable {
  const SocietyCostsEvent();
  @override
  List<Object?> get props => const [];
}

final class SocietyInitRequested extends SocietyCostsEvent {
  const SocietyInitRequested();

  @override
  List<Object?> get props => const [];
}

final class SocietyCategoriesLoadRequested extends SocietyCostsEvent {
  const SocietyCategoriesLoadRequested();

  @override
  List<Object?> get props => const [];
}

final class SocietyRefreshRequested extends SocietyCostsEvent {
  const SocietyRefreshRequested();

  @override
  List<Object?> get props => const [];
}

final class SocietyFiltersChanged extends SocietyCostsEvent {
  const SocietyFiltersChanged({
    this.categoryFilter,
    this.dateFrom,
    this.dateTo,
    this.sourceFilter,
    this.billedFilter,
    this.search,
  });

  final String? categoryFilter;
  final String? dateFrom;
  final String? dateTo;
  final CostPaymentSource? sourceFilter;
  final bool? billedFilter;
  final String? search;

  @override
  List<Object?> get props =>
      [categoryFilter, dateFrom, dateTo, sourceFilter, billedFilter, search];
}

final class SocietyFiltersReset extends SocietyCostsEvent {
  const SocietyFiltersReset();

  @override
  List<Object?> get props => const [];
}

final class SocietyRowToggled extends SocietyCostsEvent {
  const SocietyRowToggled({
    required this.id,
  });

  final int id;

  @override
  List<Object?> get props => [id];
}

final class SocietyCategoryAdded extends SocietyCostsEvent {
  const SocietyCategoryAdded({
    required this.label,
    this.completer,
  });

  final String label;
  final Completer<String?>? completer;

  @override
  List<Object?> get props => [label];
}

final class SocietyCostSaved extends SocietyCostsEvent {
  const SocietyCostSaved({
    required this.input,
    this.editingId,
    this.receiptPath,
    this.completer,
  });

  final SocietyCostInput input;
  final int? editingId;
  final String? receiptPath;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [input, editingId, receiptPath];
}

final class SocietyCostDeleted extends SocietyCostsEvent {
  const SocietyCostDeleted({
    required this.cost,
    this.completer,
  });

  final SocietyCost cost;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [cost];
}

final class SocietySplitOpened extends SocietyCostsEvent {
  const SocietySplitOpened({
    required this.cost,
  });

  final SocietyCost cost;

  @override
  List<Object?> get props => [cost];
}

final class SocietySplitClosed extends SocietyCostsEvent {
  const SocietySplitClosed();

  @override
  List<Object?> get props => const [];
}

final class SocietySplitMethodChanged extends SocietyCostsEvent {
  const SocietySplitMethodChanged({
    required this.method,
  });

  final CostSplitMethod method;

  @override
  List<Object?> get props => [method];
}

final class SocietyManualAmountChanged extends SocietyCostsEvent {
  const SocietyManualAmountChanged({
    required this.memberId,
    this.amount,
  });

  final int memberId;
  final num? amount;

  @override
  List<Object?> get props => [memberId, amount];
}

final class SocietySplitPreviewRefreshed extends SocietyCostsEvent {
  const SocietySplitPreviewRefreshed();

  @override
  List<Object?> get props => const [];
}

final class SocietySplitConfirmed extends SocietyCostsEvent {
  const SocietySplitConfirmed({
    this.allowMismatch = false,
    this.completer,
  });

  final bool allowMismatch;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [allowMismatch];
}

final class SocietySharePaymentRecorded extends SocietyCostsEvent {
  const SocietySharePaymentRecorded({
    required this.share,
    required this.additionalAmount,
    this.receiptNo,
    this.completer,
  });

  final CostSplitShare share;
  final num additionalAmount;
  final String? receiptNo;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [share, additionalAmount, receiptNo];
}
