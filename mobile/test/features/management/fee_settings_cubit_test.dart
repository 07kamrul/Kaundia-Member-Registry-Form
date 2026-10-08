import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/management/data/admin_repository.dart';
import 'package:kaundia_app/features/management/domain/admin_entities.dart';
import 'package:kaundia_app/features/management/presentation/bloc/fee_settings_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdminRepository extends Mock implements AdminRepository {}

FeeSetting _fee(String key, num value, {int status = 1}) => FeeSetting(
      id: '1',
      key: key,
      value: value,
      unit: 'taka',
      startDate: '2026-01-01',
      status: status,
    );

void main() {
  late _MockAdminRepository repository;

  setUpAll(() {
    registerFallbackValue(const ApiException(type: ApiExceptionType.network));
  });

  setUp(() {
    repository = _MockAdminRepository();
    when(() => repository.getActiveFeeSettings()).thenAnswer((_) async => []);
  });

  group('FeeSettingsCubit', () {
    blocTest<FeeSettingsCubit, FeeSettingsState>(
      'loadActive emits active rows',
      build: () {
        when(() => repository.getActiveFeeSettings())
            .thenAnswer((_) async => [_fee('admission_fee', 500)]);
        return FeeSettingsCubit(repository: repository)..loadActive();
      },
      expect: () => [
        predicate<FeeSettingsState>((s) => s.loading),
        predicate<FeeSettingsState>((s) =>
            !s.loading && s.active.length == 1 && s.active.single.key == 'admission_fee'),
      ],
    );

    blocTest<FeeSettingsCubit, FeeSettingsState>(
      'loadActive failure surfaces error state',
      build: () {
        when(() => repository.getActiveFeeSettings())
            .thenThrow(const ApiException(type: ApiExceptionType.network));
        return FeeSettingsCubit(repository: repository)..loadActive();
      },
      expect: () => [
        predicate<FeeSettingsState>((s) => s.loading),
        predicate<FeeSettingsState>((s) => !s.loading && s.error != null),
      ],
    );

    blocTest<FeeSettingsCubit, FeeSettingsState>(
      'createVersion posts the fee and reloads active settings',
      build: () {
        when(() => repository.createFeeSettingVersion(
              key: any(named: 'key'),
              value: any(named: 'value'),
              unit: any(named: 'unit'),
              startDate: any(named: 'startDate'),
            )).thenAnswer((_) async => _fee('admission_fee', 600));
        when(() => repository.getActiveFeeSettings())
            .thenAnswer((_) async => [_fee('admission_fee', 600)]);
        return FeeSettingsCubit(repository: repository);
      },
      act: (cubit) => cubit.createVersion(key: 'admission_fee', value: 600),
      expect: () => [
        predicate<FeeSettingsState>((s) => s.saving),
        predicate<FeeSettingsState>((s) =>
            !s.saving && s.saveError == null && s.active.single.value == 600),
      ],
      verify: (_) {
        verify(() => repository.createFeeSettingVersion(
              key: 'admission_fee',
              value: 600,
              unit: null,
              startDate: null,
            )).called(1);
        verify(() => repository.getActiveFeeSettings()).called(1);
      },
    );

    blocTest<FeeSettingsCubit, FeeSettingsState>(
      'createVersion failure keeps saving=false and exposes saveError',
      build: () {
        when(() => repository.createFeeSettingVersion(
              key: any(named: 'key'),
              value: any(named: 'value'),
              unit: any(named: 'unit'),
              startDate: any(named: 'startDate'),
            )).thenThrow(const ApiException(
          type: ApiExceptionType.business,
          businessMessage: 'overlap',
        ));
        return FeeSettingsCubit(repository: repository);
      },
      act: (cubit) => cubit.createVersion(key: 'admission_fee', value: 600),
      expect: () => [
        predicate<FeeSettingsState>((s) => s.saving),
        predicate<FeeSettingsState>((s) =>
            !s.saving &&
            s.saveError is ApiException &&
            (s.saveError as ApiException).businessMessage == 'overlap'),
      ],
    );

    blocTest<FeeSettingsCubit, FeeSettingsState>(
      'createTieredVersion posts the three tier rows',
      build: () {
        when(() => repository.createFeeSettingVersion(
              key: any(named: 'key'),
              value: any(named: 'value'),
              unit: any(named: 'unit'),
              startDate: any(named: 'startDate'),
            )).thenAnswer((_) async => _fee('x', 1));
        return FeeSettingsCubit(repository: repository);
      },
      act: (cubit) => cubit.createTieredVersion(
        baseAmount: 500,
        additionalRate: 50,
        baseThreshold: 10,
        unit: 'taka',
      ),
      verify: (_) {
        verify(() => repository.createFeeSettingVersion(
              key: 'monthly_subscription_base_amount',
              value: 500,
              unit: 'taka',
              startDate: null,
            )).called(1);
        verify(() => repository.createFeeSettingVersion(
              key: 'monthly_subscription_additional_rate',
              value: 50,
              unit: 'taka',
              startDate: null,
            )).called(1);
        verify(() => repository.createFeeSettingVersion(
              key: 'monthly_subscription_base_threshold',
              value: 10,
              unit: null,
              startDate: null,
            )).called(1);
      },
    );

    test('picnicConfigured requires both picnic keys active', () {
      final cubit = FeeSettingsCubit(repository: repository);
      // Initial state has no rows -> not configured.
      expect(cubit.state.picnicConfigured, isFalse);
    });
  });
}
