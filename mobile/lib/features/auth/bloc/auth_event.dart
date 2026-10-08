part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => const [];
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.identifier, required this.password, this.returnUrl});
  final String identifier;
  final String password;
  final String? returnUrl;
  @override
  List<Object?> get props => [identifier, password, returnUrl];
}

final class AuthForgotPasswordRequested extends AuthEvent {
  const AuthForgotPasswordRequested(this.identifier);
  final String identifier;
  @override
  List<Object?> get props => [identifier];
}

final class AuthResetPasswordRequested extends AuthEvent {
  const AuthResetPasswordRequested({required this.token, required this.newPassword});
  final String token;
  final String newPassword;
  @override
  List<Object?> get props => [token, newPassword];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthSessionRestored extends AuthEvent {
  const AuthSessionRestored(this.session);
  final Session session;
  @override
  List<Object?> get props => [session];
}
