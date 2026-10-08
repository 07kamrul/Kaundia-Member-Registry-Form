// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/enums.dart';
import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

part 'submission_detail_event.dart';
part 'submission_detail_state.dart';

class SubmissionDetailBloc
    extends Bloc<SubmissionDetailEvent, SubmissionDetailState> {
  SubmissionDetailBloc({required AdminRepository repository, required this.id})
      : _repository = repository,
        super(const SubmissionDetailData()) {
    on<SubmissionDetailLoadRequested>((event, emit) => _load(emit));
    on<SubmissionDetailApproveRequested>(
        (event, emit) => _approve(event.completer, emit));
    on<SubmissionDetailRejectRequested>(
        (event, emit) => _reject(event.reason, event.completer, emit));
    on<SubmissionDetailResendNotificationRequested>(
        (event, emit) => _resendNotification(emit));
    on<SubmissionDetailAttachmentReplaceRequested>(
        (event, emit) => _replaceAttachment(event.kind, event.filePath, emit));
    on<SubmissionDetailDocumentReplaceRequested>(
        (event, emit) => _replaceDocument(event.docId, event.filePath, emit));
  }

  final String id;
  final AdminRepository _repository;

  /// Current state; copyWith returns the base state type, so never
  /// downcast here (that would silently reset to defaults).
  SubmissionDetailState get _d => state;

  Future<void> _load(Emitter<SubmissionDetailState> emit) async {
    emit(const SubmissionDetailData(loading: true));
    try {
      final submission = await _repository.getSubmission(id);
      emit(SubmissionDetailData(loading: false, submission: submission));
    } catch (e) {
      emit(SubmissionDetailData(loading: false, error: e));
    }
  }

  Future<void> _approve(
      Completer<bool>? completer, Emitter<SubmissionDetailState> emit) async {
    emit(_d.copyWith(busy: true, actionError: () => null));
    try {
      await _repository.approveSubmission(id);
      emit(_d.copyWith(busy: false, approveCompleted: true));
      completer?.complete(true);
    } catch (e) {
      emit(_d.copyWith(busy: false, actionError: () => e));
      completer?.complete(false);
    }
  }

  Future<void> _reject(String reason, Completer<bool>? completer,
      Emitter<SubmissionDetailState> emit) async {
    emit(_d.copyWith(busy: true, actionError: () => null));
    try {
      final emailSent = await _repository.rejectSubmission(id, reason);
      if (emailSent) {
        emit(_d.copyWith(busy: false, rejectEmailSent: true));
        completer?.complete(true);
        return;
      }
      final submission = state.submission;
      emit(_d.copyWith(
        busy: false,
        rejectionNotice: () => reason,
        submission: _rejected(submission, reason),
      ));
      completer?.complete(false);
    } catch (e) {
      emit(_d.copyWith(busy: false, actionError: () => e));
      completer?.complete(false);
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
      final submission =
          await _repository.replaceAttachment(id, kind, filePath);
      emit(_d.copyWith(busy: false, submission: submission));
    } catch (e) {
      emit(_d.copyWith(busy: false, actionError: () => e));
    }
  }

  Future<void> _replaceDocument(String docId, String filePath,
      Emitter<SubmissionDetailState> emit) async {
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
