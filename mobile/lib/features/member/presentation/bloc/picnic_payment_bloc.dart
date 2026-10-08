import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/member_repository.dart';
import '../../domain/member_entities.dart';

const maxAdditionalHeads = 20;

enum PicnicRelation { spouse, child, guest }

extension PicnicRelationX on PicnicRelation {
  String get apiName => switch (this) {
        PicnicRelation.spouse => 'spouse',
        PicnicRelation.child => 'child',
        PicnicRelation.guest => 'guest',
      };
}

enum PicnicPageStatus { loading, loaded, failure }

/// Why the rates request failed (mirrors Angular ErrorKind).
enum PicnicRatesError { none, notConfigured, access, generic }

class PicnicHeadLabel {
  const PicnicHeadLabel({required this.name, required this.relation});

  final String name;
  final PicnicRelation relation;

  @override
  bool operator ==(Object other) =>
      other is PicnicHeadLabel && other.name == name && other.relation == relation;

  @override
  int get hashCode => Object.hash(name, relation);
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class PicnicPaymentEvent extends Equatable {
  const PicnicPaymentEvent();
  @override
  List<Object?> get props => const [];
}

final class PicnicStarted extends PicnicPaymentEvent {
  const PicnicStarted();
}

final class PicnicHistoryRefreshRequested extends PicnicPaymentEvent {
  const PicnicHistoryRefreshRequested();
}

final class PicnicRatesRefreshRequested extends PicnicPaymentEvent {
  const PicnicRatesRefreshRequested();
}

final class PicnicDateChanged extends PicnicPaymentEvent {
  const PicnicDateChanged(this.date);
  final String date;
  @override
  List<Object?> get props => [date];
}

final class PicnicHeadsChanged extends PicnicPaymentEvent {
  const PicnicHeadsChanged(this.count);
  final int count;
  @override
  List<Object?> get props => [count];
}

final class PicnicLabelNameChanged extends PicnicPaymentEvent {
  const PicnicLabelNameChanged(this.index, this.name);
  final int index;
  final String name;
  @override
  List<Object?> get props => [index, name];
}

final class PicnicLabelRelationChanged extends PicnicPaymentEvent {
  const PicnicLabelRelationChanged(this.index, this.relation);
  final int index;
  final PicnicRelation relation;
  @override
  List<Object?> get props => [index, relation];
}

final class PicnicReceiptNoChanged extends PicnicPaymentEvent {
  const PicnicReceiptNoChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

final class PicnicPaymentMethodChanged extends PicnicPaymentEvent {
  const PicnicPaymentMethodChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

final class PicnicSubmitted extends PicnicPaymentEvent {
  const PicnicSubmitted();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class PicnicPaymentState extends Equatable {
  const PicnicPaymentState({
    this.status = PicnicPageStatus.loading,
    this.payments = const [],
    this.historyLoading = false,
    this.historyError = false,
    this.rates,
    this.feeLoading = true,
    this.ratesError = PicnicRatesError.none,
    this.paymentDate = '',
    this.additionalHeads = 0,
    this.labels = const [],
    this.receiptNo = '',
    this.paymentMethod = 'Cash',
    this.saving = false,
    this.formError,
    this.successTotal,
  });

  final PicnicPageStatus status;
  final List<PicnicPayment> payments;
  final bool historyLoading;
  final bool historyError;
  final PicnicRates? rates;
  final bool feeLoading;
  final PicnicRatesError ratesError;
  final String paymentDate;
  final int additionalHeads;
  final List<PicnicHeadLabel> labels;
  final String receiptNo;
  final String paymentMethod;
  final bool saving;
  final String? formError;
  final num? successTotal;

  /// Breakdown for the fee card; null until rates are loaded.
  ({int count, num headFee, num additionalHeadFee, num additionalAmount, num total, String unit})?
      get breakdown {
    final r = rates;
    if (r == null) return null;
    final additionalAmount = r.additionalHeadFee * additionalHeads;
    return (
      count: additionalHeads,
      headFee: r.headFee,
      additionalHeadFee: r.additionalHeadFee,
      additionalAmount: additionalAmount,
      total: r.headFee + additionalAmount,
      unit: r.unit,
    );
  }

  bool get labelsValid => labels.every((l) => l.name.trim().isNotEmpty);

  bool get canSubmit =>
      !saving && !feeLoading && rates != null && paymentDate.isNotEmpty && labelsValid;

  PicnicPaymentState copyWith({
    PicnicPageStatus? status,
    List<PicnicPayment>? payments,
    bool? historyLoading,
    bool clearHistoryError = false,
    bool? historyError,
    PicnicRates? rates,
    bool clearRates = false,
    bool? feeLoading,
    PicnicRatesError? ratesError,
    String? paymentDate,
    int? additionalHeads,
    List<PicnicHeadLabel>? labels,
    String? receiptNo,
    String? paymentMethod,
    bool? saving,
    String? formError,
    bool clearFormError = false,
    num? successTotal,
    bool clearSuccessTotal = false,
  }) {
    return PicnicPaymentState(
      status: status ?? this.status,
      payments: payments ?? this.payments,
      historyLoading: historyLoading ?? this.historyLoading,
      historyError: clearHistoryError ? false : (historyError ?? this.historyError),
      rates: clearRates ? null : (rates ?? this.rates),
      feeLoading: feeLoading ?? this.feeLoading,
      ratesError: ratesError ?? this.ratesError,
      paymentDate: paymentDate ?? this.paymentDate,
      additionalHeads: additionalHeads ?? this.additionalHeads,
      labels: labels ?? this.labels,
      receiptNo: receiptNo ?? this.receiptNo,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      saving: saving ?? this.saving,
      formError: clearFormError ? null : (formError ?? this.formError),
      successTotal: clearSuccessTotal ? null : (successTotal ?? this.successTotal),
    );
  }

  @override
  List<Object?> get props => [
        status, payments, historyLoading, historyError, rates, feeLoading,
        ratesError, paymentDate, additionalHeads, labels, receiptNo,
        paymentMethod, saving, formError, successTotal,
      ];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class PicnicPaymentBloc extends Bloc<PicnicPaymentEvent, PicnicPaymentState> {
  PicnicPaymentBloc({MemberRepository? repository})
      : _repository = repository ?? MemberRepository(apiClient: sl<ApiClient>()),
        super(const PicnicPaymentState()) {
    on<PicnicStarted>(_onStarted);
    on<PicnicHistoryRefreshRequested>(_onHistory);
    on<PicnicRatesRefreshRequested>(_onRates);
    on<PicnicDateChanged>(_onDateChanged);
    on<PicnicHeadsChanged>(_onHeadsChanged);
    on<PicnicLabelNameChanged>(_onLabelNameChanged);
    on<PicnicLabelRelationChanged>(_onLabelRelationChanged);
    on<PicnicReceiptNoChanged>(
      (e, emit) => emit(state.copyWith(receiptNo: e.value, clearFormError: true)),
    );
    on<PicnicPaymentMethodChanged>(
      (e, emit) => emit(state.copyWith(paymentMethod: e.value, clearFormError: true)),
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
    emit(state.copyWith(feeLoading: true, ratesError: PicnicRatesError.none, clearRates: true));
    try {
      final rates = await _repository.getPicnicRates(state.paymentDate);
      emit(state.copyWith(rates: rates, feeLoading: false, ratesError: PicnicRatesError.none));
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
      labels = [...labels, const PicnicHeadLabel(name: '', relation: PicnicRelation.guest)];
    }
    labels = labels.sublist(0, clamped);
    emit(state.copyWith(additionalHeads: clamped, labels: labels, clearFormError: true));
  }

  void _onLabelNameChanged(
    PicnicLabelNameChanged e,
    Emitter<PicnicPaymentState> emit,
  ) {
    final labels = [...state.labels];
    if (e.index < 0 || e.index >= labels.length) return;
    labels[e.index] = PicnicHeadLabel(name: e.name, relation: labels[e.index].relation);
    emit(state.copyWith(labels: labels, clearFormError: true));
  }

  void _onLabelRelationChanged(
    PicnicLabelRelationChanged e,
    Emitter<PicnicPaymentState> emit,
  ) {
    final labels = [...state.labels];
    if (e.index < 0 || e.index >= labels.length) return;
    labels[e.index] = PicnicHeadLabel(name: labels[e.index].name, relation: e.relation);
    emit(state.copyWith(labels: labels, clearFormError: true));
  }

  Future<void> _onSubmitted(
    PicnicSubmitted e,
    Emitter<PicnicPaymentState> emit,
  ) async {
    if (!state.canSubmit) return;
    emit(state.copyWith(saving: true, clearFormError: true, clearSuccessTotal: true));
    try {
      final payment = await _repository.createPicnicPayment(PicnicPaymentInput(
        additionalHeads: state.additionalHeads,
        additionalPeople: [
          for (final l in state.labels)
            PicnicAdditionalHead(name: l.name.trim(), relation: l.relation.apiName),
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
