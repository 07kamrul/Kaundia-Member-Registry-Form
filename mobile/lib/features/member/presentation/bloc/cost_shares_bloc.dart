import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/payment_repository.dart';
import '../../domain/payment_entities.dart';

part 'cost_shares_event.dart';
part 'cost_shares_state.dart';

class CostSharesBloc extends Bloc<CostSharesEvent, CostSharesState> {
  CostSharesBloc({MemberPaymentRepository? repository})
      : _repository =
            repository ?? MemberPaymentRepository(apiClient: sl<ApiClient>()),
        super(const CostSharesState()) {
    on<CostSharesLoadRequested>(_onLoad);
  }

  final MemberPaymentRepository _repository;

  Future<void> _onLoad(
    CostSharesLoadRequested e,
    Emitter<CostSharesState> emit,
  ) async {
    emit(state.copyWith(status: CostSharesStatus.loading, clearError: true));
    try {
      final shares = await _repository.myCostShares();
      emit(state.copyWith(
          status: CostSharesStatus.loaded, shares: shares, clearError: true));
    } on ApiException {
      emit(state.copyWith(status: CostSharesStatus.failure, error: true));
    }
  }
}
