import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/session.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_exception.dart';

part 'auth_event.dart';
part 'auth_state.dart';

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
