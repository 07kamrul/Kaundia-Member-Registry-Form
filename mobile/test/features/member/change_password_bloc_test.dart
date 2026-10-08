import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/member/data/member_repository.dart';
import 'package:kaundia_app/features/member/presentation/bloc/change_password_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements MemberRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  group('ChangePasswordBloc.validate', () {
    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'flags policy, mismatch and same-as-current errors',
      build: () => ChangePasswordBloc(repository: repo),
      act: (bloc) {
        bloc.add(const ChangePasswordValidated(
            current: '', next: 'short', confirm: 'other'));
        bloc.add(const ChangePasswordValidated(
            current: 'abcdefgh1', next: 'abcdefgh1', confirm: 'abcdefgh1'));
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

    test('valid input passes the pure validator', () {
      final v = validateChangePassword(
        current: 'oldpass1',
        next: 'newpass1',
        confirm: 'newpass1',
      );
      expect(v.ok, isTrue);
    });
  });

  group('ChangePasswordBloc.submit', () {
    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'emits success when the API call succeeds',
      build: () {
        when(() => repo.changePassword(currentPassword: any(named: 'currentPassword'),
                newPassword: any(named: 'newPassword')))
            .thenAnswer((_) async {});
        return ChangePasswordBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const ChangePasswordSubmitted(current: 'old', next: 'Newpass1')),
      expect: () => [
        predicate<ChangePasswordState>((s) => s.submitting && !s.success),
        predicate<ChangePasswordState>((s) => !s.submitting && s.success),
      ],
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
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
        return ChangePasswordBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const ChangePasswordSubmitted(current: 'old', next: 'Newpass1')),
      expect: () => [
        predicate<ChangePasswordState>((s) => s.submitting),
        predicate<ChangePasswordState>((s) =>
            !s.submitting &&
            s.currentServerError == 'wrong password' &&
            s.newServerError == 'too common'),
      ],
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'maps network failure to the generic error state',
      build: () {
        when(() => repo.changePassword(currentPassword: any(named: 'currentPassword'),
                newPassword: any(named: 'newPassword')))
            .thenThrow(const ApiException(type: ApiExceptionType.network));
        return ChangePasswordBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const ChangePasswordSubmitted(current: 'old', next: 'Newpass1')),
      expect: () => [
        predicate<ChangePasswordState>((s) => s.submitting),
        predicate<ChangePasswordState>((s) =>
            !s.submitting && s.generalError && !s.success),
      ],
    );
  });
}
