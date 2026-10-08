import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/member/data/member_repository.dart';
import 'package:kaundia_app/features/member/presentation/bloc/change_password_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements MemberRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  group('ChangePasswordCubit.validate', () {
    blocTest<ChangePasswordCubit, ChangePasswordState>(
      'flags policy, mismatch and same-as-current errors',
      build: () => ChangePasswordCubit(repository: repo),
      act: (cubit) {
        cubit.validate(current: '', next: 'short', confirm: 'other');
        cubit.validate(current: 'abcdefgh1', next: 'abcdefgh1', confirm: 'abcdefgh1');
      },
      expect: () => [
        predicate<ChangePasswordState>((s) =>
            s.currentError == ChangePasswordFieldError.required &&
            s.newError == ChangePasswordFieldError.policy &&
            s.confirmError == ChangePasswordFieldError.mismatch),
        predicate<ChangePasswordState>((s) =>
            s.currentError == ChangePasswordFieldError.none &&
            s.newError == ChangePasswordFieldError.sameAsCurrent &&
            s.confirmError == ChangePasswordFieldError.none),
      ],
    );

    test('valid input passes', () {
      final cubit = ChangePasswordCubit(repository: repo);
      final ok = cubit.validate(
        current: 'oldpass1',
        next: 'newpass1',
        confirm: 'newpass1',
      );
      expect(ok, isTrue);
      expect(cubit.state.hasValidationErrors, isFalse);
      cubit.close();
    });
  });

  group('ChangePasswordCubit.submit', () {
    blocTest<ChangePasswordCubit, ChangePasswordState>(
      'emits success when the API call succeeds',
      build: () {
        when(() => repo.changePassword(currentPassword: any(named: 'currentPassword'),
                newPassword: any(named: 'newPassword')))
            .thenAnswer((_) async {});
        return ChangePasswordCubit(repository: repo);
      },
      act: (cubit) => cubit.submit(current: 'old', next: 'Newpass1'),
      expect: () => [
        predicate<ChangePasswordState>((s) => s.submitting && !s.success),
        predicate<ChangePasswordState>((s) => !s.submitting && s.success),
      ],
    );

    blocTest<ChangePasswordCubit, ChangePasswordState>(
      'maps 422 field errors to camelCase controls (current_password/new_password)',
      build: () {
        when(() => repo.changePassword(currentPassword: any(named: 'currentPassword'),
                newPassword: any(named: 'newPassword')))
            .thenThrow(const ApiException(
          type: ApiExceptionType.validation,
          fieldErrors: {
            'current_password': 'wrong password',
            'new_password': 'too common',
          },
        ));
        return ChangePasswordCubit(repository: repo);
      },
      act: (cubit) => cubit.submit(current: 'old', next: 'Newpass1'),
      expect: () => [
        predicate<ChangePasswordState>((s) => s.submitting),
        predicate<ChangePasswordState>((s) =>
            !s.submitting &&
            s.currentServerError == 'wrong password' &&
            s.newServerError == 'too common'),
      ],
    );

    blocTest<ChangePasswordCubit, ChangePasswordState>(
      'maps network failure to the generic error state',
      build: () {
        when(() => repo.changePassword(currentPassword: any(named: 'currentPassword'),
                newPassword: any(named: 'newPassword')))
            .thenThrow(const ApiException(type: ApiExceptionType.network));
        return ChangePasswordCubit(repository: repo);
      },
      act: (cubit) => cubit.submit(current: 'old', next: 'Newpass1'),
      expect: () => [
        predicate<ChangePasswordState>((s) => s.submitting),
        predicate<ChangePasswordState>((s) =>
            !s.submitting && s.generalError && !s.success),
      ],
    );
  });
}
