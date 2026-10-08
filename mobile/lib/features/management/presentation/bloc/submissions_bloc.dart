// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/enums.dart';
import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

// ----- Submissions queue -----

sealed class SubmissionsEvent extends Equatable {
  const SubmissionsEvent();

  @override
  List<Object?> get props => const [];
}

final class SubmissionsLoadRequested extends SubmissionsEvent {
  const SubmissionsLoadRequested();
}

final class SubmissionsFilterChanged extends SubmissionsEvent {
  const SubmissionsFilterChanged(this.filter);

  final SubmissionStatus? filter;

  @override
  List<Object?> get props => [filter];
}

class SubmissionsState extends Equatable {
  const SubmissionsState({
    this.filter,
    this.items = const [],
    this.loading = false,
    this.error,
  });

  final SubmissionStatus? filter;
  final List<SubmissionSummary> items;
  final bool loading;
  final Object? error;

  SubmissionsState copyWith({
    SubmissionStatus? Function()? filter,
    List<SubmissionSummary>? items,
    bool? loading,
    Object? Function()? error,
  }) =>
      SubmissionsState(
        filter: filter == null ? this.filter : filter(),
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
      );

  @override
  List<Object?> get props => [filter, items, loading, error];
}

final class SubmissionsData extends SubmissionsState {
  const SubmissionsData({super.filter, super.items, super.loading, super.error});
}

class SubmissionsBloc extends Bloc<SubmissionsEvent, SubmissionsState> {
  SubmissionsBloc({required AdminRepository repository})
      : _repository = repository,
        super(const SubmissionsData(filter: SubmissionStatus.pending, loading: true)) {
    on<SubmissionsLoadRequested>((event, emit) => _load(emit));
    on<SubmissionsFilterChanged>((event, emit) async {
      emit(_d.copyWith(filter: () => event.filter));
      await _load(emit);
    });
  }

  final AdminRepository _repository;

  /// Re-typed view of the current state (emits go through the base copyWith).
  SubmissionsData get _d =>
      state is SubmissionsData ? state as SubmissionsData : const SubmissionsData();

  Future<void> _load(Emitter<SubmissionsState> emit) async {
    emit(_d.copyWith(loading: true, error: () => null));
    try {
      final items = await _repository.listSubmissions(status: state.filter);
      emit(_d.copyWith(items: items, loading: false));
    } catch (e) {
      emit(_d.copyWith(loading: false, error: () => e));
    }
  }
}

// ----- Submission detail (review mode actions) -----

sealed class SubmissionDetailEvent extends Equatable {
  const SubmissionDetailEvent();

  @override
  List<Object?> get props => const [];
}

final class SubmissionDetailLoadRequested extends SubmissionDetailEvent {
  const SubmissionDetailLoadRequested();
}

final class SubmissionDetailApproveRequested extends SubmissionDetailEvent {
  const SubmissionDetailApproveRequested();
}

final class SubmissionDetailRejectRequested extends SubmissionDetailEvent {
  const SubmissionDetailRejectRequested(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

final class SubmissionDetailResendNotificationRequested extends SubmissionDetailEvent {
  const SubmissionDetailResendNotificationRequested();
}

final class SubmissionDetailAttachmentReplaceRequested extends SubmissionDetailEvent {
  const SubmissionDetailAttachmentReplaceRequested(this.kind, this.filePath);

  final String kind;
  final String filePath;

  @override
  List<Object?> get props => [kind, filePath];
}

final class SubmissionDetailDocumentReplaceRequested extends SubmissionDetailEvent {
  const SubmissionDetailDocumentReplaceRequested(this.docId, this.filePath);

  final String docId;
  final String filePath;

  @override
  List<Object?> get props => [docId, filePath];
}

class SubmissionDetailState extends Equatable {
  const SubmissionDetailState({
    this.loading = true,
    this.submission,
    this.error,
    this.actionError,
    this.busy = false,
    this.rejectionNotice,
    this.approveCompleted = false,
    this.rejectEmailSent = false,
  });

  final bool loading;
  final SubmissionDetail? submission;
  final Object? error;

  /// Error from approve/reject/upload actions (null when none).
  final Object? actionError;
  final bool busy;

  /// Set when a rejection succeeded but the applicant email did not go out.
  final String? rejectionNotice;

  /// Approve finished successfully (page navigates back to the queue).
  final bool approveCompleted;

  /// Rejection succeeded and the applicant was notified (page navigates back).
  final bool rejectEmailSent;

  SubmissionDetailState copyWith({
    bool? loading,
    SubmissionDetail? submission,
    Object? Function()? error,
    Object? Function()? actionError,
    bool? busy,
    String? Function()? rejectionNotice,
    bool? approveCompleted,
    bool? rejectEmailSent,
  }) =>
      SubmissionDetailState(
        loading: loading ?? this.loading,
        submission: submission ?? this.submission,
        error: error == null ? this.error : error(),
        actionError: actionError == null ? this.actionError : actionError(),
        busy: busy ?? this.busy,
        rejectionNotice: rejectionNotice == null ? this.rejectionNotice : rejectionNotice(),
        approveCompleted: approveCompleted ?? this.approveCompleted,
        rejectEmailSent: rejectEmailSent ?? this.rejectEmailSent,
      );

  @override
  List<Object?> get props => [
        loading,
        submission,
        error,
        actionError,
        busy,
        rejectionNotice,
        approveCompleted,
        rejectEmailSent,
      ];
}

final class SubmissionDetailData extends SubmissionDetailState {
  const SubmissionDetailData({
    super.loading,
    super.submission,
    super.error,
    super.actionError,
    super.busy,
    super.rejectionNotice,
    super.approveCompleted,
    super.rejectEmailSent,
  });
}

class SubmissionDetailBloc extends Bloc<SubmissionDetailEvent, SubmissionDetailState> {
  SubmissionDetailBloc({required AdminRepository repository, required this.id})
      : _repository = repository,
        super(const SubmissionDetailData()) {
    on<SubmissionDetailLoadRequested>((event, emit) => _load(emit));
    on<SubmissionDetailApproveRequested>((event, emit) => _approve(emit));
    on<SubmissionDetailRejectRequested>((event, emit) => _reject(event.reason, emit));
    on<SubmissionDetailResendNotificationRequested>(
        (event, emit) => _resendNotification(emit));
    on<SubmissionDetailAttachmentReplaceRequested>(
        (event, emit) => _replaceAttachment(event.kind, event.filePath, emit));
    on<SubmissionDetailDocumentReplaceRequested>(
        (event, emit) => _replaceDocument(event.docId, event.filePath, emit));
  }

  final String id;
  final AdminRepository _repository;

  SubmissionDetailData get _d => state is SubmissionDetailData
      ? state as SubmissionDetailData
      : const SubmissionDetailData();

  Future<void> _load(Emitter<SubmissionDetailState> emit) async {
    emit(const SubmissionDetailData(loading: true));
    try {
      final submission = await _repository.getSubmission(id);
      emit(SubmissionDetailData(loading: false, submission: submission));
    } catch (e) {
      emit(SubmissionDetailData(loading: false, error: e));
    }
  }

  Future<void> _approve(Emitter<SubmissionDetailState> emit) async {
    emit(_d.copyWith(busy: true, actionError: () => null));
    try {
      await _repository.approveSubmission(id);
      emit(_d.copyWith(busy: false, approveCompleted: true));
    } catch (e) {
      emit(_d.copyWith(busy: false, actionError: () => e));
    }
  }

  Future<void> _reject(String reason, Emitter<SubmissionDetailState> emit) async {
    emit(_d.copyWith(busy: true, actionError: () => null));
    try {
      final emailSent = await _repository.rejectSubmission(id, reason);
      if (emailSent) {
        emit(_d.copyWith(busy: false, rejectEmailSent: true));
        return;
      }
      final submission = state.submission;
      emit(_d.copyWith(
        busy: false,
        rejectionNotice: () => reason,
        submission: _rejected(submission, reason),
      ));
    } catch (e) {
      emit(_d.copyWith(busy: false, actionError: () => e));
    }
  }

  Future<void> _resendNotification(Emitter<SubmissionDetailState> emit) async {
    emit(_d.copyWith(busy: true, actionError: () => null));
    try {
      final sent = await _repository.resendRejectionNotification(id);
      if (!sent) {
        emit(_d.copyWith(busy: false, actionError: () => 'rejectEmailFailed'));
        return;
      }
      emit(_d.copyWith(busy: false, rejectionNotice: () => null));
    } catch (e) {
      emit(_d.copyWith(busy: false, actionError: () => e));
    }
  }

  Future<void> _replaceAttachment(
      String kind, String filePath, Emitter<SubmissionDetailState> emit) async {
    emit(_d.copyWith(busy: true, actionError: () => null));
    try {
      final submission = await _repository.replaceAttachment(id, kind, filePath);
      emit(_d.copyWith(busy: false, submission: submission));
    } catch (e) {
      emit(_d.copyWith(busy: false, actionError: () => e));
    }
  }

  Future<void> _replaceDocument(
      String docId, String filePath, Emitter<SubmissionDetailState> emit) async {
    emit(_d.copyWith(busy: true, actionError: () => null));
    try {
      final submission = await _repository.replaceDocument(id, docId, filePath);
      emit(_d.copyWith(busy: false, submission: submission));
    } catch (e) {
      emit(_d.copyWith(busy: false, actionError: () => e));
    }
  }

  /// Rejected snapshot of the current submission (status -> rejected).
  SubmissionDetail? _rejected(SubmissionDetail? s, String reason) {
    if (s == null) return null;
    return SubmissionDetail(
      id: s.id,
      fullName: s.fullName,
      mobile: s.mobile,
      status: SubmissionStatus.rejected,
      createdAt: s.createdAt,
      fatherOrHusband: s.fatherOrHusband,
      mother: s.mother,
      dob: s.dob,
      nationality: s.nationality,
      occupation: s.occupation,
      nid: s.nid,
      gender: s.gender,
      email: s.email,
      properties: s.properties,
      nominees: s.nominees,
      admissionFee: s.admissionFee,
      subscription: s.subscription,
      receiptNo: s.receiptNo,
      paymentMethod: s.paymentMethod,
      permanentHouse: s.permanentHouse,
      permanentRoad: s.permanentRoad,
      permanentPostOffice: s.permanentPostOffice,
      permanentUpazila: s.permanentUpazila,
      permanentDistrict: s.permanentDistrict,
      permanentDivision: s.permanentDivision,
      currentHouse: s.currentHouse,
      currentRoad: s.currentRoad,
      currentPostOffice: s.currentPostOffice,
      currentUpazila: s.currentUpazila,
      currentDistrict: s.currentDistrict,
      currentDivision: s.currentDivision,
      urgentContactName: s.urgentContactName,
      urgentContactRelation: s.urgentContactRelation,
      urgentContactMobile: s.urgentContactMobile,
      urgentContactAddress: s.urgentContactAddress,
      memberId: s.memberId,
      memberPhotoUrl: s.memberPhotoUrl,
      memberSignature: s.memberSignature,
      receiptPhotoUrl: s.receiptPhotoUrl,
      rejectionReason: reason,
    );
  }
}
