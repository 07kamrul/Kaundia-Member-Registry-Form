import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/enums.dart';
import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

// ----- Submissions queue -----

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
    SubmissionStatus? Function() filter = _same,
    List<SubmissionSummary>? items,
    bool? loading,
    Object? Function() error = _same,
  }) =>
      SubmissionsState(
        filter: filter == _same ? this.filter : filter(),
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error == _same ? this.error : error(),
      );

  static T _same<T>() => throw UnsupportedError('sentinel');

  @override
  List<Object?> get props => [filter, items, loading, error];
}

class SubmissionsCubit extends Cubit<SubmissionsState> {
  SubmissionsCubit({required AdminRepository repository})
      : _repository = repository,
        super(const SubmissionsState(
            filter: SubmissionStatus.pending, loading: true));

  final AdminRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final items = await _repository.listSubmissions(status: state.filter);
      emit(state.copyWith(items: items, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: () => e));
    }
  }

  void setFilter(SubmissionStatus? filter) {
    emit(state.copyWith(filter: () => filter));
    load();
  }
}

// ----- Submission detail (review mode actions) -----

class SubmissionDetailState extends Equatable {
  const SubmissionDetailState({
    this.loading = true,
    this.submission,
    this.error,
    this.actionError,
    this.busy = false,
    this.rejectionNotice,
  });

  final bool loading;
  final SubmissionDetail? submission;
  final Object? error;

  /// Error from approve/reject/upload actions (null when none).
  final Object? actionError;
  final bool busy;

  /// Set when a rejection succeeded but the applicant email did not go out.
  final String? rejectionNotice;

  SubmissionDetailState copyWith({
    bool? loading,
    SubmissionDetail? submission,
    Object? Function() error = _sentinel,
    Object? Function() actionError = _sentinel,
    bool? busy,
    String? Function() rejectionNotice = _sentinel,
  }) =>
      SubmissionDetailState(
        loading: loading ?? this.loading,
        submission: submission ?? this.submission,
        error: error == _sentinel ? this.error : error(),
        actionError:
            actionError == _sentinel ? this.actionError : actionError(),
        busy: busy ?? this.busy,
        rejectionNotice: rejectionNotice == _sentinel
            ? this.rejectionNotice
            : rejectionNotice(),
      );

  static T _sentinel<T>() => throw UnsupportedError('sentinel');

  @override
  List<Object?> get props =>
      [loading, submission, error, actionError, busy, rejectionNotice];
}

class SubmissionDetailCubit extends Cubit<SubmissionDetailState> {
  SubmissionDetailCubit({required AdminRepository repository, required this.id})
      : _repository = repository,
        super(const SubmissionDetailState());

  final String id;
  final AdminRepository _repository;

  Future<void> load() async {
    emit(SubmissionDetailState(loading: true));
    try {
      final submission = await _repository.getSubmission(id);
      emit(SubmissionDetailState(loading: false, submission: submission));
    } catch (e) {
      emit(SubmissionDetailState(loading: false, error: e));
    }
  }

  Future<bool> approve() async {
    emit(state.copyWith(busy: true, actionError: () => null));
    try {
      await _repository.approveSubmission(id);
      emit(state.copyWith(busy: false));
      return true;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }

  /// Returns true when the rejection email went out (caller can navigate).
  Future<bool> reject(String reason) async {
    emit(state.copyWith(busy: true, actionError: () => null));
    try {
      final emailSent = await _repository.rejectSubmission(id, reason);
      if (emailSent) {
        emit(state.copyWith(busy: false));
        return true;
      }
      final submission = state.submission;
      emit(state.copyWith(
        busy: false,
        rejectionNotice: () => reason,
        submission: submission == null
            ? null
            : SubmissionDetail(
                id: submission.id,
                fullName: submission.fullName,
                mobile: submission.mobile,
                status: SubmissionStatus.rejected,
                createdAt: submission.createdAt,
                fatherOrHusband: submission.fatherOrHusband,
                mother: submission.mother,
                dob: submission.dob,
                nationality: submission.nationality,
                occupation: submission.occupation,
                nid: submission.nid,
                gender: submission.gender,
                email: submission.email,
                properties: submission.properties,
                nominees: submission.nominees,
                admissionFee: submission.admissionFee,
                subscription: submission.subscription,
                receiptNo: submission.receiptNo,
                paymentMethod: submission.paymentMethod,
                permanentHouse: submission.permanentHouse,
                permanentRoad: submission.permanentRoad,
                permanentPostOffice: submission.permanentPostOffice,
                permanentUpazila: submission.permanentUpazila,
                permanentDistrict: submission.permanentDistrict,
                permanentDivision: submission.permanentDivision,
                currentHouse: submission.currentHouse,
                currentRoad: submission.currentRoad,
                currentPostOffice: submission.currentPostOffice,
                currentUpazila: submission.currentUpazila,
                currentDistrict: submission.currentDistrict,
                currentDivision: submission.currentDivision,
                urgentContactName: submission.urgentContactName,
                urgentContactRelation: submission.urgentContactRelation,
                urgentContactMobile: submission.urgentContactMobile,
                urgentContactAddress: submission.urgentContactAddress,
                memberId: submission.memberId,
                memberPhotoUrl: submission.memberPhotoUrl,
                memberSignature: submission.memberSignature,
                receiptPhotoUrl: submission.receiptPhotoUrl,
                rejectionReason: reason,
              ),
      ));
      return false;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }

  Future<bool> resendNotification() async {
    emit(state.copyWith(busy: true, actionError: () => null));
    try {
      final sent = await _repository.resendRejectionNotification(id);
      if (!sent) {
        emit(state.copyWith(
            busy: false, actionError: () => 'rejectEmailFailed'));
        return false;
      }
      final submission = state.submission;
      emit(state.copyWith(busy: false, rejectionNotice: () => null));
      return submission != null;
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
      return false;
    }
  }

  Future<void> replaceAttachment(String kind, String filePath) async {
    emit(state.copyWith(busy: true, actionError: () => null));
    try {
      final submission =
          await _repository.replaceAttachment(id, kind, filePath);
      emit(state.copyWith(busy: false, submission: submission));
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
    }
  }

  Future<void> replaceDocument(String docId, String filePath) async {
    emit(state.copyWith(busy: true, actionError: () => null));
    try {
      final submission = await _repository.replaceDocument(id, docId, filePath);
      emit(state.copyWith(busy: false, submission: submission));
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: () => e));
    }
  }
}
