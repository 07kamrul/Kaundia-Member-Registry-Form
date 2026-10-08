part of 'submission_detail_bloc.dart';

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
  const SubmissionDetailApproveRequested({this.completer});

  /// Optional result channel: true when approved.
  final Completer<bool>? completer;
}

final class SubmissionDetailRejectRequested extends SubmissionDetailEvent {
  const SubmissionDetailRejectRequested(this.reason, {this.completer});

  /// Optional result channel: true when the rejection email was sent.
  final Completer<bool>? completer;

  final String reason;

  @override
  List<Object?> get props => [reason];
}

final class SubmissionDetailResendNotificationRequested
    extends SubmissionDetailEvent {
  const SubmissionDetailResendNotificationRequested();
}

final class SubmissionDetailAttachmentReplaceRequested
    extends SubmissionDetailEvent {
  const SubmissionDetailAttachmentReplaceRequested(this.kind, this.filePath);

  final String kind;
  final String filePath;

  @override
  List<Object?> get props => [kind, filePath];
}

final class SubmissionDetailDocumentReplaceRequested
    extends SubmissionDetailEvent {
  const SubmissionDetailDocumentReplaceRequested(this.docId, this.filePath);

  final String docId;
  final String filePath;

  @override
  List<Object?> get props => [docId, filePath];
}
