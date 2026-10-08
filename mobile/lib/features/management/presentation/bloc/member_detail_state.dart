part of 'member_detail_bloc.dart';

// State

class MemberDetailState extends Equatable {
  const MemberDetailState({this.loading = true, this.profile, this.error});

  final bool loading;
  final MemberProfile? profile;
  final Object? error;

  @override
  List<Object?> get props => [loading, profile, error];
}
