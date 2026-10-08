import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/member_repository.dart';

const minPasswordLength = 8;

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

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

/// Pure validation result shared by the bloc handler and the page's
/// submit gating (a bloc cannot return values from an event).
class ChangePasswordValidation {
  const ChangePasswordValidation({
    required this.currentError,
    required this.newError,
    required this.confirmError,
  });

  final ChangePasswordFieldError currentError;
  final ChangePasswordFieldError newError;
  final ChangePasswordFieldError confirmError;

  bool get ok =>
      currentError == ChangePasswordFieldError.none &&
      newError == ChangePasswordFieldError.none &&
      confirmError == ChangePasswordFieldError.none;
}

ChangePasswordValidation validateChangePassword({
  required String current,
  required String next,
  required String confirm,
}) {
  var currentError = ChangePasswordFieldError.none;
  var newError = ChangePasswordFieldError.none;
  var confirmError = ChangePasswordFieldError.none;

  if (current.isEmpty) {
    currentError = ChangePasswordFieldError.required;
  }
  if (next.isEmpty || next.length < minPasswordLength || !RegExp(r'\d').hasMatch(next)) {
    newError = ChangePasswordFieldError.policy;
  } else if (current.isNotEmpty && next == current) {
    newError = ChangePasswordFieldError.sameAsCurrent;
  }
  if (confirm.isEmpty || confirm != next) {
    confirmError = ChangePasswordFieldError.mismatch;
  }
  return ChangePasswordValidation(
    currentError: currentError, newError: newError, confirmError: confirmError);
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  ChangePasswordBloc({MemberRepository? repository})
      : _repository = repository ?? MemberRepository(apiClient: sl<ApiClient>()),
        super(const ChangePasswordState()) {
    on<ChangePasswordValidated>(_onValidated);
    on<ChangePasswordSubmitted>(_onSubmitted);
    on<ChangePasswordReset>((_, emit) => emit(const ChangePasswordState()));
  }

  final MemberRepository _repository;

  void _onValidated(
    ChangePasswordValidated e,
    Emitter<ChangePasswordState> emit,
  ) {
    final v = validateChangePassword(current: e.current, next: e.next, confirm: e.confirm);
    emit(state.copyWith(
      currentError: v.currentError,
      newError: v.newError,
      confirmError: v.confirmError,
      clearServerErrors: true,
      clearGeneralError: true,
    ));
  }

  Future<void> _onSubmitted(
    ChangePasswordSubmitted e,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(state.copyWith(submitting: true, clearGeneralError: true, clearServerErrors: true));
    try {
      await _repository.changePassword(currentPassword: e.current, newPassword: e.next);
      emit(state.copyWith(submitting: false, success: true));
    } on ApiException catch (err) {
      if (err.isValidation) {
        emit(state.copyWith(
          submitting: false,
          currentServerError: err.fieldErrors['current_password'],
          newServerError: err.fieldErrors['new_password'],
        ));
      } else {
        emit(state.copyWith(submitting: false, generalError: true));
      }
    }
  }
}
