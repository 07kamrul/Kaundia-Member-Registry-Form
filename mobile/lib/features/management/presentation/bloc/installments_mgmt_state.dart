part of 'installments_mgmt_bloc.dart';

class InstallmentsMgmtState extends Equatable {
  const InstallmentsMgmtState({
    this.members = const [],
    this.loadingMembers = true,
    this.selectedMemberId,
    this.installments = const [],
    this.loadingInstallments = false,
    this.markingId,
    this.error,
  });

  final List<Member> members;
  final bool loadingMembers;
  final String? selectedMemberId;
  final List<Installment> installments;
  final bool loadingInstallments;

  /// Installment currently being marked paid.
  final String? markingId;
  final Object? error;

  InstallmentsMgmtState copyWith({
    List<Member>? members,
    bool? loadingMembers,
    String? Function() selectedMemberId = _same,
    List<Installment>? installments,
    bool? loadingInstallments,
    String? Function() markingId = _same,
    Object? Function()? error,
  }) =>
      InstallmentsMgmtState(
        members: members ?? this.members,
        loadingMembers: loadingMembers ?? this.loadingMembers,
        selectedMemberId: selectedMemberId == _same
            ? this.selectedMemberId
            : selectedMemberId(),
        installments: installments ?? this.installments,
        loadingInstallments: loadingInstallments ?? this.loadingInstallments,
        markingId: markingId == _same ? this.markingId : markingId(),
        error: error == null ? this.error : error(),
      );

  @override
  List<Object?> get props => [
        members,
        loadingMembers,
        selectedMemberId,
        installments,
        loadingInstallments,
        markingId,
        error,
      ];
}
