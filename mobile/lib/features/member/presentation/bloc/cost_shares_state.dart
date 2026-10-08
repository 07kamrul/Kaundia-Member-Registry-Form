part of 'cost_shares_bloc.dart';

enum CostSharesStatus { loading, loaded, failure }

class CostSharesState extends Equatable {
  const CostSharesState({
    this.status = CostSharesStatus.loading,
    this.shares = const [],
    this.error = false,
  });

  final CostSharesStatus status;
  final List<CostSplitShare> shares;
  final bool error;

  num get outstandingTotal => shares
      .where((s) => s.status != ShareStatus.paid)
      .fold<num>(0, (sum, s) => sum + (s.amountDue - s.amountPaid));

  bool get hasOutstanding => shares.any((s) => s.status != ShareStatus.paid);

  CostSharesState copyWith({
    CostSharesStatus? status,
    List<CostSplitShare>? shares,
    bool clearError = false,
    bool? error,
  }) {
    return CostSharesState(
      status: status ?? this.status,
      shares: shares ?? this.shares,
      error: clearError ? false : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, shares, error];
}
