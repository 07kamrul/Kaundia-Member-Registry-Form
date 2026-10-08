part of 'notices_bloc.dart';

sealed class NoticesState extends Equatable {
  const NoticesState();
  @override
  List<Object?> get props => const [];
}

class NoticesInitial extends NoticesState {
  const NoticesInitial();
}

class NoticesLoading extends NoticesState {
  const NoticesLoading();
}

class NoticesLoaded extends NoticesState {
  const NoticesLoaded({required this.notices});
  final List<Notice> notices;
  @override
  List<Object?> get props => [notices];
}

class NoticesFailure extends NoticesState {
  const NoticesFailure({required this.error});
  final ApiException error;
  @override
  List<Object?> get props => [error];
}
