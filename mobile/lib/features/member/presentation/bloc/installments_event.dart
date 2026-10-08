part of 'installments_bloc.dart';

sealed class InstallmentsEvent extends Equatable {
  const InstallmentsEvent();

  @override
  List<Object?> get props => const [];
}

class InstallmentsLoaded extends InstallmentsEvent {
  const InstallmentsLoaded({this.openPayDialog = false});

  final bool openPayDialog;
}

class InstallmentsYearFilterChanged extends InstallmentsEvent {
  const InstallmentsYearFilterChanged(this.year);

  /// null = 'all'.
  final int? year;

  @override
  List<Object?> get props => [year];
}

class PayDuesDialogOpened extends InstallmentsEvent {
  const PayDuesDialogOpened();
}

class PayDuesDialogClosed extends InstallmentsEvent {
  const PayDuesDialogClosed();
}

class InstallmentPaymentSubmitted extends InstallmentsEvent {
  const InstallmentPaymentSubmitted({required this.submission, this.proofPath});

  final PaymentSubmission submission;

  /// Local proof file path; validated + attached as multipart `proof`.
  final String? proofPath;

  @override
  List<Object?> get props => [submission, proofPath];
}

class InstallmentsMessageCleared extends InstallmentsEvent {
  const InstallmentsMessageCleared();
}
