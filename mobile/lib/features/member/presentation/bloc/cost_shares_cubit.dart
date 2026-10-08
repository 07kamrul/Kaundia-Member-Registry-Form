import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/payment_repository.dart';
import '../../domain/payment_entities.dart';

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

enum CostSharesStatus { loading, loaded, failure }

class CostSharesCubit extends Cubit<CostSharesState> {
  CostSharesCubit({MemberPaymentRepository? repository})
      : _repository = repository ?? MemberPaymentRepository(apiClient: sl<ApiClient>()),
        super(const CostSharesState());

  final MemberPaymentRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: CostSharesStatus.loading, clearError: true));
    try {
      final shares = await _repository.myCostShares();
      emit(state.copyWith(status: CostSharesStatus.loaded, shares: shares, clearError: true));
    } on ApiException {
      emit(state.copyWith(status: CostSharesStatus.failure, error: true));
    }
  }
}
