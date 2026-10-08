part of 'payment_verifications_bloc.dart';

sealed class PaymentVerificationsEvent extends Equatable {
  const PaymentVerificationsEvent();
  @override
  List<Object?> get props => const [];
}

final class PaymentVerificationsLoadRequested
    extends PaymentVerificationsEvent {
  const PaymentVerificationsLoadRequested();
}

final class PaymentVerificationsStatusFilterChanged
    extends PaymentVerificationsEvent {
  const PaymentVerificationsStatusFilterChanged({required this.status});

  final String status;

  @override
  List<Object?> get props => [status];
}

final class PaymentVerificationsApproved extends PaymentVerificationsEvent {
  const PaymentVerificationsApproved({required this.payment});

  final AdminInstallmentPayment payment;

  @override
  List<Object?> get props => [payment];
}

final class PaymentVerificationsRejected extends PaymentVerificationsEvent {
  const PaymentVerificationsRejected(
      {required this.payment, required this.reason});

  final AdminInstallmentPayment payment;
  final String reason;

  @override
  List<Object?> get props => [payment, reason];
}
