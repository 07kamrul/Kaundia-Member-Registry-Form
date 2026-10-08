part of 'submission_detail_bloc.dart';

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
        rejectionNotice:
            rejectionNotice == null ? this.rejectionNotice : rejectionNotice(),
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
