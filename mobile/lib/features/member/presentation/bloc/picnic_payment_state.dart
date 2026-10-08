part of 'picnic_payment_bloc.dart';

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
      other is PicnicHeadLabel &&
      other.name == name &&
      other.relation == relation;

  @override
  int get hashCode => Object.hash(name, relation);
}

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
  ({
    int count,
    num headFee,
    num additionalHeadFee,
    num additionalAmount,
    num total,
    String unit
  })? get breakdown {
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
      !saving &&
      !feeLoading &&
      rates != null &&
      paymentDate.isNotEmpty &&
      labelsValid;

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
      historyError:
          clearHistoryError ? false : (historyError ?? this.historyError),
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
      successTotal:
          clearSuccessTotal ? null : (successTotal ?? this.successTotal),
    );
  }

  @override
  List<Object?> get props => [
        status,
        payments,
        historyLoading,
        historyError,
        rates,
        feeLoading,
        ratesError,
        paymentDate,
        additionalHeads,
        labels,
        receiptNo,
        paymentMethod,
        saving,
        formError,
        successTotal,
      ];
}
