import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/member/data/member_repository.dart';
import 'package:kaundia_app/features/member/domain/member_entities.dart';
import 'package:kaundia_app/features/member/presentation/bloc/profile_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements MemberRepository {}

MemberProfile _profile({String status = 'approved'}) => MemberProfile(
      memberId: 'MBR-1',
      status: status,
      fullName: 'রহিম',
      fatherOrHusband: 'করিম',
      mother: 'রহিমা',
      dob: '1990-01-01',
      mobile: '+8801712345678',
      memberPhotoUrl: '',
      receiptPhotoUrl: '',
      properties: const [],
      nominees: [],
    );

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(const MemberProfileUpdate());
  });

  setUp(() {
    repo = _MockRepo();
    when(() => repo.getPropertyRequests()).thenAnswer((_) async => []);
  });

  group('ProfileBloc', () {
    blocTest<ProfileBloc, ProfileState>(
      'loads the profile and then the property requests',
      build: () {
        when(() => repo.getProfile()).thenAnswer((_) async => _profile());
        return ProfileBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const ProfileLoaded()),
      expect: () => [
        predicate<ProfileState>((s) => s.status == ProfileStatus.loading),
        predicate<ProfileState>((s) =>
            s.status == ProfileStatus.loaded &&
            s.profile?.fullName == 'রহিম' &&
            !s.requestsLoading),
      ],
      verify: (_) => verify(() => repo.getPropertyRequests()).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'maps a load failure to ProfileStatus.failure',
      build: () {
        when(() => repo.getProfile())
            .thenThrow(const ApiException(type: ApiExceptionType.network));
        return ProfileBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const ProfileLoaded()),
      expect: () => [
        predicate<ProfileState>((s) => s.status == ProfileStatus.loading),
        predicate<ProfileState>((s) => s.status == ProfileStatus.failure),
      ],
    );

    test('core-field draft change sets willRequeue for an approved profile', () async {
      when(() => repo.getProfile()).thenAnswer((_) async => _profile());
      final bloc = ProfileBloc(repository: repo);
      bloc.add(const ProfileLoaded());
      await bloc.stream.firstWhere((s) => s.status == ProfileStatus.loaded);
      bloc.add(const ProfileEditStarted());
      await bloc.stream.firstWhere((s) => s.editing);

      // Contact-only change: no re-queue warning.
      bloc.add(const ProfileDraftChanged(MemberProfileUpdate(mobile: '+8801800000000')));
      final contactOnly = await bloc.stream.first;
      expect(contactOnly.willRequeue, isFalse);

      // Core-field change: re-queue warning on.
      bloc.add(const ProfileDraftChanged(MemberProfileUpdate(fullName: 'নতুন')));
      final coreChanged = await bloc.stream.first;
      expect(coreChanged.willRequeue, isTrue);

      await bloc.close();
    });

    test('pending profile never triggers willRequeue', () async {
      when(() => repo.getProfile()).thenAnswer((_) async => _profile(status: 'pending'));
      final bloc = ProfileBloc(repository: repo);
      bloc.add(const ProfileLoaded());
      await bloc.stream.firstWhere((s) => s.status == ProfileStatus.loaded);
      bloc.add(const ProfileEditStarted());
      final editing = await bloc.stream.firstWhere((s) => s.editing);
      expect(editing.willRequeue, isFalse);
      bloc.add(const ProfileDraftChanged(MemberProfileUpdate(fullName: 'নতুন')));
      final changed = await bloc.stream.first;
      expect(changed.willRequeue, isFalse);
      await bloc.close();
    });

    blocTest<ProfileBloc, ProfileState>(
      'save exits edit mode on success and surfaces field errors on failure',
      build: () {
        when(() => repo.getProfile()).thenAnswer((_) async => _profile());
        var call = 0;
        when(() => repo.updateProfile(any())).thenAnswer((_) async {
          call++;
          if (call == 1) {
            throw const ApiException(
              type: ApiExceptionType.validation,
              fieldErrors: {'full_name': 'too short'},
            );
          }
          return _profile();
        });
        return ProfileBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const ProfileLoaded());
        await bloc.stream.firstWhere((s) => s.status == ProfileStatus.loaded);
        bloc.add(const ProfileEditStarted());
        bloc.add(const ProfileDraftChanged(MemberProfileUpdate(fullName: 'নতুন')));
        bloc.add(const ProfileSaved(update: MemberProfileUpdate(fullName: 'নতুন')));
      },
      skip: 3, // loading, loaded, editing (+draft emits are merged by bloc_test counting)
      expect: () => [
        predicate<ProfileState>((s) => s.saving),
        predicate<ProfileState>((s) => !s.saving && s.saveError == 'too short'),
        predicate<ProfileState>((s) => s.saving),
        predicate<ProfileState>((s) =>
            !s.saving && !s.editing && s.saveError == null && s.profile?.fullName == 'রহিম'),
      ],
    );
  });
}
