part of 'notices_bloc.dart';

sealed class NoticesEvent extends Equatable {
  const NoticesEvent();
  @override
  List<Object?> get props => const [];
}

final class NoticesRequested extends NoticesEvent {
  const NoticesRequested();
}
