import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/finance_entities.dart';

part 'payment_verifications_event.dart';
part 'payment_verifications_state.dart';

class PaymentVerificationsBloc
    extends Bloc<PaymentVerificationsEvent, PaymentVerificationsState> {
  PaymentVerificationsBloc({required InstallmentPaymentRepository repository})
      : _repository = repository,
        super(const PaymentVerificationsState()) {
    on<PaymentVerificationsLoadRequested>((e, emit) => _load(emit));
    on<PaymentVerificationsStatusFilterChanged>((e, emit) async {
      emit(PaymentVerificationsState(statusFilter: e.status));
      await _load(emit);
    });
    on<PaymentVerificationsApproved>((e, emit) =>
        _decide(emit, e.payment, () => _repository.approve(e.payment.id)));
    on<PaymentVerificationsRejected>((e, emit) => _decide(
        emit, e.payment, () => _repository.reject(e.payment.id, e.reason)));
  }

  final InstallmentPaymentRepository _repository;

  Future<void> _load(Emitter<PaymentVerificationsState> emit) async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final payments =
          await _repository.listForAdmin(status: state.statusFilter);
      emit(state.copyWith(payments: payments, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: () => e));
    }
  }

  Future<void> _decide(
    Emitter<PaymentVerificationsState> emit,
    AdminInstallmentPayment payment,
    Future<Object?> Function() run,
  ) async {
    emit(state.copyWith(busyId: () => payment.id, error: () => null));
    try {
      await run();
      emit(state.copyWith(
        busyId: () => null,
        payments: state.payments.where((p) => p.id != payment.id).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(busyId: () => null, error: () => e));
      await _load(emit);
    }
  }
}
