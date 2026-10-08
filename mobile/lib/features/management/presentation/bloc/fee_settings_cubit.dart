import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

/// Grouped (tiered) monthly subscription: the form key maps to three rows.
const monthlySubscriptionGroupKey = 'monthly_subscription';
const monthlySubscriptionTierKeys = (
  base: 'monthly_subscription_base_amount',
  rate: 'monthly_subscription_additional_rate',
  threshold: 'monthly_subscription_base_threshold',
);
const picnicFeeKeys = ['picnic_head_fee', 'picnic_additional_head_fee'];
const knownFeeKeys = [
  'admission_fee',
  'picnic_head_fee',
  'picnic_additional_head_fee',
  monthlySubscriptionGroupKey,
];

class FeeSettingsState extends Equatable {
  const FeeSettingsState({
    this.active = const [],
    this.loading = true,
    this.error,
    this.expandedKey,
    this.history = const [],
    this.tieredHistory = const [],
    this.loadingHistory = false,
    this.saving = false,
    this.saveError,
  });

  final List<FeeSetting> active;
  final bool loading;
  final Object? error;

  /// Key whose history is expanded (null = collapsed).
  final String? expandedKey;

  /// Plain-key history rows (status 1 = current active version).
  final List<FeeSetting> history;

  /// For the tiered key: base rows (parallel lists for rate/threshold are
  /// resolved in the page by index).
  final List<FeeSetting> tieredHistory;
  final bool loadingHistory;
  final bool saving;
  final Object? saveError;

  bool get picnicConfigured {
    final keys = active.map((s) => s.key).toSet();
    return picnicFeeKeys.every(keys.contains);
  }

  FeeSetting? tierRow(String key) {
    for (final s in active) {
      if (s.key == key) return s;
    }
    return null;
  }

  FeeSettingsState copyWith({
    List<FeeSetting>? active,
    bool? loading,
    Object? Function() error = _same,
    String? Function() expandedKey = _same,
    List<FeeSetting>? history,
    List<FeeSetting>? tieredHistory,
    bool? loadingHistory,
    bool? saving,
    Object? Function() saveError = _same,
  }) =>
      FeeSettingsState(
        active: active ?? this.active,
        loading: loading ?? this.loading,
        error: error == _same ? this.error : error(),
        expandedKey: expandedKey == _same ? this.expandedKey : expandedKey(),
        history: history ?? this.history,
        tieredHistory: tieredHistory ?? this.tieredHistory,
        loadingHistory: loadingHistory ?? this.loadingHistory,
        saving: saving ?? this.saving,
        saveError: saveError == _same ? this.saveError : saveError(),
      );

  static T _same<T>() => throw UnsupportedError('sentinel');

  @override
  List<Object?> get props => [
        active,
        loading,
        error,
        expandedKey,
        history,
        tieredHistory,
        loadingHistory,
        saving,
        saveError,
      ];
}

class FeeSettingsCubit extends Cubit<FeeSettingsState> {
  FeeSettingsCubit({required AdminRepository repository})
      : _repository = repository,
        super(const FeeSettingsState());

  final AdminRepository _repository;

  Future<void> loadActive() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final active = await _repository.getActiveFeeSettings();
      emit(state.copyWith(active: active, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: () => e));
    }
  }

  Future<void> toggleHistory(String key) async {
    if (state.expandedKey == key) {
      emit(state.copyWith(
          expandedKey: () => null, history: const [], tieredHistory: const []));
      return;
    }
    emit(state.copyWith(
      expandedKey: () => key,
      loadingHistory: true,
      history: const [],
      tieredHistory: const [],
    ));
    try {
      if (key == monthlySubscriptionGroupKey) {
        final base = await _repository
            .getFeeSettingHistory(monthlySubscriptionTierKeys.base);
        emit(state.copyWith(tieredHistory: base, loadingHistory: false));
      } else {
        final history = await _repository.getFeeSettingHistory(key);
        emit(state.copyWith(history: history, loadingHistory: false));
      }
    } catch (e) {
      emit(state.copyWith(loadingHistory: false, error: () => e));
    }
  }

  /// Creates one version (plain key) or three (tiered group). Returns success.
  Future<bool> createVersion({
    required String key,
    required num value,
    String? unit,
    String? startDate,
  }) async {
    emit(state.copyWith(saving: true, saveError: () => null));
    try {
      if (key == monthlySubscriptionGroupKey) {
        // value = base; the page supplies rate/threshold through [createTieredVersion].
        throw StateError('use createTieredVersion');
      }
      await _repository.createFeeSettingVersion(
        key: key,
        value: value,
        unit: unit,
        startDate: startDate,
      );
      await loadActive();
      emit(state.copyWith(saving: false));
      return true;
    } catch (e) {
      emit(state.copyWith(saving: false, saveError: () => e));
      return false;
    }
  }

  Future<bool> createTieredVersion({
    required num baseAmount,
    required num additionalRate,
    required num baseThreshold,
    String? unit,
    String? startDate,
  }) async {
    emit(state.copyWith(saving: true, saveError: () => null));
    try {
      await _repository.createFeeSettingVersion(
        key: monthlySubscriptionTierKeys.base,
        value: baseAmount,
        unit: unit,
        startDate: startDate,
      );
      await _repository.createFeeSettingVersion(
        key: monthlySubscriptionTierKeys.rate,
        value: additionalRate,
        unit: unit,
        startDate: startDate,
      );
      await _repository.createFeeSettingVersion(
        key: monthlySubscriptionTierKeys.threshold,
        value: baseThreshold,
        startDate: startDate,
      );
      await loadActive();
      emit(state.copyWith(saving: false));
      return true;
    } catch (e) {
      emit(state.copyWith(saving: false, saveError: () => e));
      return false;
    }
  }
}
