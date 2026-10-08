part of 'notices_bloc.dart';

// ----- Notices -----

sealed class NoticesEvent extends Equatable {
  const NoticesEvent();

  @override
  List<Object?> get props => const [];
}

final class NoticesInitRequested extends NoticesEvent {
  const NoticesInitRequested();
}

final class NoticesLoadRequested extends NoticesEvent {
  const NoticesLoadRequested();
}

final class NoticesStatusFilterChanged extends NoticesEvent {
  const NoticesStatusFilterChanged(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

final class NoticesCategoryFilterChanged extends NoticesEvent {
  const NoticesCategoryFilterChanged(this.categoryId);

  final String? categoryId;

  @override
  List<Object?> get props => [categoryId];
}

final class NoticeSaveRequested extends NoticesEvent {
  const NoticeSaveRequested(
      {required this.payload, this.editingId, this.completer});

  final NoticeInput payload;
  final String? editingId;

  /// Optional result channel: true when saved.
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [payload, editingId];
}

final class NoticePublishToggled extends NoticesEvent {
  const NoticePublishToggled(this.notice);

  final Notice notice;

  @override
  List<Object?> get props => [notice];
}

final class NoticeDeleteRequested extends NoticesEvent {
  const NoticeDeleteRequested(this.notice);

  final Notice notice;

  @override
  List<Object?> get props => [notice];
}
