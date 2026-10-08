part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => const [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess({required this.session, this.mustChangePassword = false});
  final Session session;
  final bool mustChangePassword;
  @override
  List<Object?> get props => [session, mustChangePassword];
}

class AuthActionSucceeded extends AuthState {
  const AuthActionSucceeded();
}

class AuthFailure extends AuthState {
  const AuthFailure({required this.error});
  final ApiException error;
  @override
  List<Object?> get props => [error];
}
