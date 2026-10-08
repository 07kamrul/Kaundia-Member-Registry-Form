part of 'change_password_bloc.dart';

sealed class ChangePasswordEvent extends Equatable {
  const ChangePasswordEvent();
  @override
  List<Object?> get props => const [];
}

/// Client-side validation mirroring Angular passwordPolicy +
/// passwordGroupValidator; emits per-field errors and success:false when
/// invalid.
final class ChangePasswordValidated extends ChangePasswordEvent {
  const ChangePasswordValidated({
    required this.current,
    required this.next,
    required this.confirm,
  });

  final String current;
  final String next;
  final String confirm;

  @override
  List<Object?> get props => [current, next, confirm];
}

final class ChangePasswordSubmitted extends ChangePasswordEvent {
  const ChangePasswordSubmitted({required this.current, required this.next});

  final String current;
  final String next;

  @override
  List<Object?> get props => [current, next];
}

final class ChangePasswordReset extends ChangePasswordEvent {
  const ChangePasswordReset();
}
