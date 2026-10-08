part of 'installments_mgmt_bloc.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class InstallmentsMgmtEvent extends Equatable {
  const InstallmentsMgmtEvent();
  @override
  List<Object?> get props => const [];
}

final class InstallmentsMembersLoadRequested extends InstallmentsMgmtEvent {
  const InstallmentsMembersLoadRequested();

  @override
  List<Object?> get props => const [];
}

final class InstallmentsMemberSelected extends InstallmentsMgmtEvent {
  const InstallmentsMemberSelected({
    required this.memberId,
  });

  final String memberId;

  @override
  List<Object?> get props => [memberId];
}

final class InstallmentMarkPaid extends InstallmentsMgmtEvent {
  const InstallmentMarkPaid({
    required this.installment,
  });

  final Installment installment;

  @override
  List<Object?> get props => [installment];
}
