import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/member_repository.dart';

const minPasswordLength = 8;

/// Validation error variants surfaced per field (mirrors Angular validators).
enum ChangePasswordFieldError { required, policy, mismatch, sameAsCurrent, none }

class ChangePasswordState extends Equatable {
  const ChangePasswordState({
    this.submitting = false,
    this.success = false,
    this.generalError = false,
    this.currentError = ChangePasswordFieldError.none,
    this.newError = ChangePasswordFieldError.none,
    this.confirmError = ChangePasswordFieldError.none,
    this.currentServerError,
    this.newServerError,
  });

  final bool submitting;
  final bool success;

  /// Non-validation failures (network / server / business).
  final bool generalError;
  final ChangePasswordFieldError currentError;
  final ChangePasswordFieldError newError;
  final ChangePasswordFieldError confirmError;

  /// 422 server field errors keyed to the camelCase control names.
  final String? currentServerError;
  final String? newServerError;

  bool get hasValidationErrors =>
      currentError != ChangePasswordFieldError.none ||
      newError != ChangePasswordFieldError.none ||
      confirmError != ChangePasswordFieldError.none;

  ChangePasswordState copyWith({
    bool? submitting,
    bool? success,
    bool clearGeneralError = false,
    bool? generalError,
    ChangePasswordFieldError? currentError,
    ChangePasswordFieldError? newError,
    ChangePasswordFieldError? confirmError,
    String? currentServerError,
    bool clearServerErrors = false,
    String? newServerError,
  }) {
    return ChangePasswordState(
      submitting: submitting ?? this.submitting,
      success: success ?? this.success,
      generalError: clearGeneralError ? false : (generalError ?? this.generalError),
      currentError: currentError ?? this.currentError,
      newError: newError ?? this.newError,
      confirmError: confirmError ?? this.confirmError,
      currentServerError: clearServerErrors ? null : (currentServerError ?? this.currentServerError),
      newServerError: clearServerErrors ? null : (newServerError ?? this.newServerError),
    );
  }

  @override
  List<Object?> get props => [
        submitting, success, generalError, currentError, newError,
        confirmError, currentServerError, newServerError,
      ];
}

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit({MemberRepository? repository})
      : _repository = repository ?? MemberRepository(apiClient: sl<ApiClient>()),
        super(const ChangePasswordState());

  final MemberRepository _repository;

  /// Client-side validation mirroring Angular passwordPolicy +
  /// passwordGroupValidator; returns false when invalid (state updated).
  bool validate({
    required String current,
    required String next,
    required String confirm,
  }) {
    var ok = true;
    ChangePasswordFieldError currentError = ChangePasswordFieldError.none;
    ChangePasswordFieldError newError = ChangePasswordFieldError.none;
    ChangePasswordFieldError confirmError = ChangePasswordFieldError.none;

    if (current.isEmpty) {
      currentError = ChangePasswordFieldError.required;
      ok = false;
    }
    if (next.isEmpty || next.length < minPasswordLength || !RegExp(r'\d').hasMatch(next)) {
      newError = ChangePasswordFieldError.policy;
      ok = false;
    } else if (current.isNotEmpty && next == current) {
      newError = ChangePasswordFieldError.sameAsCurrent;
      ok = false;
    }
    if (confirm.isEmpty || confirm != next) {
      confirmError = ChangePasswordFieldError.mismatch;
      ok = false;
    }
    emit(state.copyWith(
      currentError: currentError,
      newError: newError,
      confirmError: confirmError,
      clearServerErrors: true,
      clearGeneralError: true,
    ));
    return ok;
  }

  Future<void> submit({
    required String current,
    required String next,
  }) async {
    emit(state.copyWith(submitting: true, clearGeneralError: true, clearServerErrors: true));
    try {
      await _repository.changePassword(currentPassword: current, newPassword: next);
      emit(state.copyWith(submitting: false, success: true));
    } on ApiException catch (e) {
      if (e.isValidation) {
        emit(state.copyWith(
          submitting: false,
          currentServerError: e.fieldErrors['current_password'],
          newServerError: e.fieldErrors['new_password'],
        ));
      } else {
        emit(state.copyWith(submitting: false, generalError: true));
      }
    }
  }

  void reset() => emit(const ChangePasswordState());
}
