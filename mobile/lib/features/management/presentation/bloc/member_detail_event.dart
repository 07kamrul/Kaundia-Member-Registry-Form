part of 'member_detail_bloc.dart';

// ----- Member detail (read-only profile) -----

// Events

sealed class MemberDetailEvent extends Equatable {
  const MemberDetailEvent();
  @override
  List<Object?> get props => const [];
}

final class MemberDetailLoadRequested extends MemberDetailEvent {
  const MemberDetailLoadRequested();
}
