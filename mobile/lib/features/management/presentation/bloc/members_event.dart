part of 'members_bloc.dart';

// ----- Events -----

sealed class MembersEvent extends Equatable {
  const MembersEvent();
  @override
  List<Object?> get props => const [];
}

final class MembersLoadRequested extends MembersEvent {
  const MembersLoadRequested();
}

/// Mutating events carry an optional completer so callers can await the
/// outcome (replaces the cubit's `Future<bool>` returns).
final class MemberDeleted extends MembersEvent {
  const MemberDeleted(this.memberId, {this.completer});
  final String memberId;
  final Completer<bool>? completer;
  @override
  List<Object?> get props => [memberId];
}

final class MemberPasswordResetRequested extends MembersEvent {
  const MemberPasswordResetRequested(this.memberId, {this.completer});
  final String memberId;
  final Completer<bool>? completer;
  @override
  List<Object?> get props => [memberId];
}
