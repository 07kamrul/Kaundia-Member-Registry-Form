import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/session.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_exception.dart';

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

/// AuthBloc holds the resolved session after login; permission checks read
/// from state.session.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository}) : _repo = repository, super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthForgotPasswordRequested>(_onForgot);
    on<AuthResetPasswordRequested>(_onReset);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthSessionRestored>((e, emit) => emit(AuthSuccess(session: e.session)));
  }

  final AuthRepository _repo;

  Future<void> _onLogin(AuthLoginRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final result = await _repo.login(e.identifier, e.password);
      sl<SessionManager>().set(result.session);
      emit(AuthSuccess(session: result.session, mustChangePassword: result.mustChangePassword));
    } on ApiException catch (err) {
      emit(AuthFailure(error: err));
    }
  }

  Future<void> _onForgot(AuthForgotPasswordRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _repo.forgotPassword(e.identifier);
      emit(const AuthActionSucceeded());
    } on ApiException catch (err) {
      emit(AuthFailure(error: err));
    }
  }

  Future<void> _onReset(AuthResetPasswordRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _repo.resetPassword(e.token, e.newPassword);
      emit(const AuthActionSucceeded());
    } on ApiException catch (err) {
      emit(AuthFailure(error: err));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    await _repo.logout();
    sl<SessionManager>().clear();
    emit(const AuthInitial());
  }
}
