import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/utils/file_utils.dart';
import '../../data/payment_repository.dart';
import '../../domain/member_entities.dart';
import '../../domain/payment_entities.dart';

// Events -------------------------------------------------------------------

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

// State --------------------------------------------------------------------

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
      ..sort((a, b) => b.year - a.year || b.month - a.month);
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
    return (payable?.due ?? const []).where((i) => !pending.contains(i.id)).length;
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
      selectedYear: clearSelectedYear ? null : (selectedYear ?? this.selectedYear),
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
        status, installments, error, selectedYear, payable, payDialogOpen,
        submitting, submitError, successMessage,
      ];
}

class InstallmentsBloc extends Bloc<InstallmentsEvent, InstallmentsState> {
  InstallmentsBloc({
    MemberRepository? memberRepository,
    MemberPaymentRepository? paymentRepository,
  })  : _memberRepository =
            memberRepository ?? MemberRepository(apiClient: sl<ApiClient>()),
        _paymentRepository = paymentRepository ??
            MemberPaymentRepository(apiClient: sl<ApiClient>()),
        super(const InstallmentsState()) {
    on<InstallmentsLoaded>(_onLoaded);
    on<InstallmentsYearFilterChanged>(_onYearFilterChanged);
    on<PayDuesDialogOpened>(_onDialogOpened);
    on<PayDuesDialogClosed>(_onDialogClosed);
    on<InstallmentPaymentSubmitted>(_onPaymentSubmitted);
    on<InstallmentsMessageCleared>(_onMessageCleared);
  }

  final MemberRepository _memberRepository;
  final MemberPaymentRepository _paymentRepository;

  Future<void> _onLoaded(
    InstallmentsLoaded event,
    Emitter<InstallmentsState> emit,
  ) async {
    final keepDialog = state.payDialogOpen;
    emit(state.copyWith(
      status: InstallmentsStatus.loading,
      clearError: true,
      payDialogOpen: keepDialog,
    ));
    try {
      final installments = await _memberRepository.getInstallments();
      emit(state.copyWith(
        status: InstallmentsStatus.loaded,
        installments: installments,
        clearError: true,
      ));
      await _loadPayable(emit, openDialog: event.openPayDialog);
    } on ApiException {
      emit(state.copyWith(status: InstallmentsStatus.failure, error: true));
    }
  }

  /// Online pay is optional: if it fails to load, the history still shows.
  Future<void> _loadPayable(
    Emitter<InstallmentsState> emit, {
    bool openDialog = false,
  }) async {
    try {
      final payable = await _paymentRepository.getPayable();
      final count =
          payable.due.where((i) => !payable.pendingInstallmentIds.contains(i.id)).length;
      emit(state.copyWith(
        payable: payable,
        payDialogOpen: openDialog && payable.accounts.isNotEmpty && count > 0,
      ));
    } on ApiException {
      emit(state.copyWith(clearPayable: true, payDialogOpen: false));
    }
  }

  void _onYearFilterChanged(
    InstallmentsYearFilterChanged event,
    Emitter<InstallmentsState> emit,
  ) {
    emit(event.year == null
        ? state.copyWith(clearSelectedYear: true)
        : state.copyWith(selectedYear: event.year));
  }

  void _onDialogOpened(
    PayDuesDialogOpened event,
    Emitter<InstallmentsState> emit,
  ) {
    emit(state.copyWith(payDialogOpen: true, clearSubmitError: true));
  }

  void _onDialogClosed(
    PayDuesDialogClosed event,
    Emitter<InstallmentsState> emit,
  ) {
    emit(state.copyWith(payDialogOpen: false, clearSubmitError: true));
  }

  Future<void> _onPaymentSubmitted(
    InstallmentPaymentSubmitted event,
    Emitter<InstallmentsState> emit,
  ) async {
    emit(state.copyWith(submitting: true, clearSubmitError: true));
    try {
      ProofFile? proof;
      final path = event.proofPath;
      if (path != null) {
        final fileName = path.split(Platform.pathSeparator).last.split('/').last;
        final prepared = await prepareAnyFile(path, fileName);
        proof = ProofFile(
          bytes: await File(prepared.path).readAsBytes(),
          fileName: prepared.fileName,
          mimeType: prepared.mimeType,
        );
      }
      await _paymentRepository.submit(PaymentSubmission(
        installmentIds: event.submission.installmentIds,
        method: event.submission.method,
        transactionRef: event.submission.transactionRef,
        paidOn: event.submission.paidOn,
        senderAccount: event.submission.senderAccount,
        note: event.submission.note,
        proof: proof,
      ));
      emit(state.copyWith(
          submitting: false, payDialogOpen: false, successMessage: true));
      await _loadPayable(emit);
    } on ApiException catch (e) {
      emit(state.copyWith(
        submitting: false,
        submitError: e.isBusiness && e.businessMessage != null
            ? e.businessMessage
            : (e.isValidation && e.fieldErrors.isNotEmpty
                ? e.fieldErrors.values.first
                : 'submitError'),
      ));
    } on FileTooLargeError {
      emit(state.copyWith(submitting: false, submitError: 'proofSizeError'));
    }
  }

  void _onMessageCleared(
    InstallmentsMessageCleared event,
    Emitter<InstallmentsState> emit,
  ) {
    emit(state.copyWith(clearSuccessMessage: true));
  }
}
