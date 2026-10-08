import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/member_repository.dart';
import '../../../../shared/utils/file_utils.dart';
import '../../data/payment_repository.dart';
import '../../domain/member_entities.dart';
import '../../domain/payment_entities.dart';

part 'installments_event.dart';
part 'installments_state.dart';

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
      final count = payable.due
          .where((i) => !payable.pendingInstallmentIds.contains(i.id))
          .length;
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
        final fileName =
            path.split(Platform.pathSeparator).last.split('/').last;
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
