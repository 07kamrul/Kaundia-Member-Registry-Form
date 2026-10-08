import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/member_repository.dart';
import '../../domain/member_entities.dart';

part 'picnic_payment_event.dart';
part 'picnic_payment_state.dart';

const maxAdditionalHeads = 20;

class PicnicPaymentBloc extends Bloc<PicnicPaymentEvent, PicnicPaymentState> {
  PicnicPaymentBloc({MemberRepository? repository})
      : _repository =
            repository ?? MemberRepository(apiClient: sl<ApiClient>()),
        super(const PicnicPaymentState()) {
    on<PicnicStarted>(_onStarted);
    on<PicnicHistoryRefreshRequested>(_onHistory);
    on<PicnicRatesRefreshRequested>(_onRates);
    on<PicnicDateChanged>(_onDateChanged);
    on<PicnicHeadsChanged>(_onHeadsChanged);
    on<PicnicLabelNameChanged>(_onLabelNameChanged);
    on<PicnicLabelRelationChanged>(_onLabelRelationChanged);
    on<PicnicReceiptNoChanged>(
      (e, emit) =>
          emit(state.copyWith(receiptNo: e.value, clearFormError: true)),
    );
    on<PicnicPaymentMethodChanged>(
      (e, emit) =>
          emit(state.copyWith(paymentMethod: e.value, clearFormError: true)),
    );
    on<PicnicSubmitted>(_onSubmitted);
  }

  final MemberRepository _repository;

  Future<void> _onStarted(
    PicnicStarted e,
    Emitter<PicnicPaymentState> emit,
  ) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    emit(state.copyWith(
      status: PicnicPageStatus.loading,
      clearHistoryError: true,
      paymentDate: state.paymentDate.isEmpty ? today : state.paymentDate,
    ));
    await _onHistory(const PicnicHistoryRefreshRequested(), emit);
    await _onRates(const PicnicRatesRefreshRequested(), emit);
  }

  Future<void> _onHistory(
    PicnicPaymentEvent e,
    Emitter<PicnicPaymentState> emit,
  ) async {
    emit(state.copyWith(historyLoading: true, clearHistoryError: true));
    try {
      final payments = await _repository.getPicnicPayments();
      emit(state.copyWith(
        status: PicnicPageStatus.loaded,
        payments: payments,
        historyLoading: false,
        clearHistoryError: true,
      ));
    } on ApiException {
      emit(state.copyWith(
        status: PicnicPageStatus.loaded,
        historyLoading: false,
        historyError: true,
      ));
    }
  }

  /// Rates must be re-resolved whenever the payment date changes.
  Future<void> _onRates(
    PicnicPaymentEvent e,
    Emitter<PicnicPaymentState> emit,
  ) async {
    if (state.paymentDate.isEmpty) return;
    emit(state.copyWith(
        feeLoading: true, ratesError: PicnicRatesError.none, clearRates: true));
    try {
      final rates = await _repository.getPicnicRates(state.paymentDate);
      emit(state.copyWith(
          rates: rates, feeLoading: false, ratesError: PicnicRatesError.none));
    } on ApiException catch (err) {
      emit(state.copyWith(
        clearRates: true,
        feeLoading: false,
        ratesError: switch (err.statusCode) {
          404 => PicnicRatesError.notConfigured,
          401 || 403 => PicnicRatesError.access,
          _ => PicnicRatesError.generic,
        },
      ));
    }
  }

  Future<void> _onDateChanged(
    PicnicDateChanged e,
    Emitter<PicnicPaymentState> emit,
  ) async {
    emit(state.copyWith(paymentDate: e.date));
    await _onRates(const PicnicRatesRefreshRequested(), emit);
  }

  void _onHeadsChanged(PicnicHeadsChanged e, Emitter<PicnicPaymentState> emit) {
    final clamped = e.count.clamp(0, maxAdditionalHeads);
    if (clamped == state.additionalHeads) return;
    var labels = state.labels;
    while (labels.length < clamped) {
      labels = [
        ...labels,
        const PicnicHeadLabel(name: '', relation: PicnicRelation.guest)
      ];
    }
    labels = labels.sublist(0, clamped);
    emit(state.copyWith(
        additionalHeads: clamped, labels: labels, clearFormError: true));
  }

  void _onLabelNameChanged(
    PicnicLabelNameChanged e,
    Emitter<PicnicPaymentState> emit,
  ) {
    final labels = [...state.labels];
    if (e.index < 0 || e.index >= labels.length) return;
    labels[e.index] =
        PicnicHeadLabel(name: e.name, relation: labels[e.index].relation);
    emit(state.copyWith(labels: labels, clearFormError: true));
  }

  void _onLabelRelationChanged(
    PicnicLabelRelationChanged e,
    Emitter<PicnicPaymentState> emit,
  ) {
    final labels = [...state.labels];
    if (e.index < 0 || e.index >= labels.length) return;
    labels[e.index] =
        PicnicHeadLabel(name: labels[e.index].name, relation: e.relation);
    emit(state.copyWith(labels: labels, clearFormError: true));
  }

  Future<void> _onSubmitted(
    PicnicSubmitted e,
    Emitter<PicnicPaymentState> emit,
  ) async {
    if (!state.canSubmit) return;
    emit(state.copyWith(
        saving: true, clearFormError: true, clearSuccessTotal: true));
    try {
      final payment = await _repository.createPicnicPayment(PicnicPaymentInput(
        additionalHeads: state.additionalHeads,
        additionalPeople: [
          for (final l in state.labels)
            PicnicAdditionalHead(
                name: l.name.trim(), relation: l.relation.apiName),
        ],
        paymentDate: state.paymentDate,
        receiptNo: state.receiptNo,
        paymentMethod: state.paymentMethod,
      ));
      emit(state.copyWith(
        saving: false,
        successTotal: payment.total,
        additionalHeads: 0,
        labels: const [],
        receiptNo: '',
      ));
      await _onHistory(const PicnicHistoryRefreshRequested(), emit);
    } on ApiException catch (err) {
      emit(state.copyWith(
        saving: false,
        formError: err.isBusiness && err.businessMessage != null
            ? err.businessMessage
            : (err.isValidation && err.fieldErrors.isNotEmpty
                ? err.fieldErrors.values.first
                : 'saveError'),
      ));
    }
  }
}
