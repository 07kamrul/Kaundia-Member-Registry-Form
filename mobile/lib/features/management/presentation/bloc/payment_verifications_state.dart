part of 'payment_verifications_bloc.dart';

// ----- Installment payment verification queue -----

class PaymentVerificationsState extends Equatable {
  const PaymentVerificationsState({
    this.statusFilter = 'pending',
    this.payments = const [],
    this.loading = true,
    this.error,
    this.busyId,
  });

  final String statusFilter;
  final List<AdminInstallmentPayment> payments;
  final bool loading;
  final Object? error;
  final int? busyId;

  PaymentVerificationsState copyWith({
    String? statusFilter,
    List<AdminInstallmentPayment>? payments,
    bool? loading,
    Object? Function()? error,
    int? Function()? busyId,
  }) =>
      PaymentVerificationsState(
        statusFilter: statusFilter ?? this.statusFilter,
        payments: payments ?? this.payments,
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
        busyId: busyId == null ? this.busyId : busyId(),
      );

  @override
  List<Object?> get props => [statusFilter, payments, loading, error, busyId];
}
