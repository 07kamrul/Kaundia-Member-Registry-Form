part of 'installments_bloc.dart';

enum InstallmentsStatus { loading, loaded, failure }

class InstallmentsState extends Equatable {
  const InstallmentsState({
    this.status = InstallmentsStatus.loading,
    this.installments = const [],
    this.error = false,
    this.selectedYear,
    this.payable,
    this.payDialogOpen = false,
    this.submitting = false,
    this.submitError,
    this.successMessage = false,
  });

  final InstallmentsStatus status;
  final List<MemberInstallment> installments;
  final bool error;
  final int? selectedYear;
  final PayableSummary? payable;
  final bool payDialogOpen;
  final bool submitting;
  final String? submitError;

  /// True right after a successful submission (banner in the page).
  final bool successMessage;

  List<int> get years =>
      {...installments.map((i) => i.year)}.toList()..sort((a, b) => b - a);

  List<MemberInstallment> get filtered => selectedYear == null
      ? installments
      : installments.where((i) => i.year == selectedYear).toList();

  /// Newest first (mirrors the Angular sort).
  List<MemberInstallment> get sorted {
    final list = [...filtered]
      ..sort((a, b) => b.year != a.year ? b.year - a.year : b.month - a.month);
    return list;
  }

  num get paidTotal =>
      filtered.where((i) => i.isPaid).fold<num>(0, (s, i) => s + i.amount);
  num get dueTotal =>
      filtered.where((i) => !i.isPaid).fold<num>(0, (s, i) => s + i.amount);
  int get paidCount => filtered.where((i) => i.isPaid).length;

  bool isPending(String id) =>
      payable?.pendingInstallmentIds.contains(id) ?? false;

  int get payableCount {
    final pending = payable?.pendingInstallmentIds ?? const <String>{};
    return (payable?.due ?? const [])
        .where((i) => !pending.contains(i.id))
        .length;
  }

  bool get canPay =>
      payable != null && payable!.accounts.isNotEmpty && payableCount > 0;

  InstallmentsState copyWith({
    InstallmentsStatus? status,
    List<MemberInstallment>? installments,
    bool clearError = false,
    bool? error,
    int? selectedYear,
    bool clearSelectedYear = false,
    PayableSummary? payable,
    bool clearPayable = false,
    bool? payDialogOpen,
    bool? submitting,
    String? submitError,
    bool clearSubmitError = false,
    bool? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return InstallmentsState(
      status: status ?? this.status,
      installments: installments ?? this.installments,
      error: clearError ? false : (error ?? this.error),
      selectedYear:
          clearSelectedYear ? null : (selectedYear ?? this.selectedYear),
      payable: clearPayable ? null : (payable ?? this.payable),
      payDialogOpen: payDialogOpen ?? this.payDialogOpen,
      submitting: submitting ?? this.submitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      successMessage:
          clearSuccessMessage ? false : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        installments,
        error,
        selectedYear,
        payable,
        payDialogOpen,
        submitting,
        submitError,
        successMessage,
      ];
}
