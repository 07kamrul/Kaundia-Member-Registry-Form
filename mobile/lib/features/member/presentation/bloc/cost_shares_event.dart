part of 'cost_shares_bloc.dart';

sealed class CostSharesEvent extends Equatable {
  const CostSharesEvent();
  @override
  List<Object?> get props => const [];
}

final class CostSharesLoadRequested extends CostSharesEvent {
  const CostSharesLoadRequested();
}
