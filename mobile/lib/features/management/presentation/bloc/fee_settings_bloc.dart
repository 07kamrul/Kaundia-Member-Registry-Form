// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

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

final monthlySubscriptionTierKeySet = <String>{
  monthlySubscriptionTierKeys.base,
  monthlySubscriptionTierKeys.rate,
  monthlySubscriptionTierKeys.threshold,
};

sealed class FeeSettingsEvent extends Equatable {
  const FeeSettingsEvent();

  @override
  List<Object?> get props => const [];
}

final class FeeSettingsLoadRequested extends FeeSettingsEvent {
  const FeeSettingsLoadRequested();
}

final class FeeSettingsHistoryToggled extends FeeSettingsEvent {
  const FeeSettingsHistoryToggled(this.key);

  final String key;

  @override
  List<Object?> get props => [key];
}

final class FeeSettingVersionCreateRequested extends FeeSettingsEvent {
  const FeeSettingVersionCreateRequested({
    required this.key,
    required this.value,
    this.unit,
    this.startDate,
    this.completer,
  });

  final String key;
  final num value;
  final String? unit;
  final String? startDate;

  /// Optional result channel: true when saved.
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [key, value, unit, startDate];
}

final class FeeSettingTieredVersionCreateRequested extends FeeSettingsEvent {
  const FeeSettingTieredVersionCreateRequested({
    required this.baseAmount,
    required this.additionalRate,
    required this.baseThreshold,
    this.unit,
    this.startDate,
    this.completer,
  });

  final num baseAmount;
  final num additionalRate;
  final num baseThreshold;
  final String? unit;
  final String? startDate;

  /// Optional result channel: true when saved.
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [baseAmount, additionalRate, baseThreshold, unit, startDate];
}

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

  /// Plain-key history rows.
  final List<FeeSetting> history;

  /// For the tiered key: base rows.
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
    Object? Function()? error,
    String? Function()? expandedKey,
    List<FeeSetting>? history,
    List<FeeSetting>? tieredHistory,
    bool? loadingHistory,
    bool? saving,
    Object? Function()? saveError,
  }) =>
      FeeSettingsState(
        active: active ?? this.active,
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
        expandedKey: expandedKey == null ? this.expandedKey : expandedKey(),
        history: history ?? this.history,
        tieredHistory: tieredHistory ?? this.tieredHistory,
        loadingHistory: loadingHistory ?? this.loadingHistory,
        saving: saving ?? this.saving,
        saveError: saveError == null ? this.saveError : saveError(),
      );

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

final class FeeSettingsData extends FeeSettingsState {
  const FeeSettingsData({
    super.active,
    super.loading,
    super.error,
    super.expandedKey,
    super.history,
    super.tieredHistory,
    super.loadingHistory,
    super.saving,
    super.saveError,
  });
}

class FeeSettingsBloc extends Bloc<FeeSettingsEvent, FeeSettingsState> {
  FeeSettingsBloc({required AdminRepository repository})
      : _repository = repository,
        super(const FeeSettingsData()) {
    on<FeeSettingsLoadRequested>((event, emit) => _loadActive(emit));
    on<FeeSettingsHistoryToggled>((event, emit) => _toggleHistory(event.key, emit));
    on<FeeSettingVersionCreateRequested>((event, emit) => _createVersion(event, emit));
    on<FeeSettingTieredVersionCreateRequested>(
        (event, emit) => _createTieredVersion(event, emit));
  }

  final AdminRepository _repository;

  FeeSettingsData get _d =>
      state is FeeSettingsData ? state as FeeSettingsData : const FeeSettingsData();

  Future<void> _loadActive(Emitter<FeeSettingsState> emit) async {
    emit(_d.copyWith(loading: true, error: () => null));
    try {
      final active = await _repository.getActiveFeeSettings();
      emit(_d.copyWith(active: active, loading: false));
    } catch (e) {
      emit(_d.copyWith(loading: false, error: () => e));
    }
  }

  Future<void> _toggleHistory(String key, Emitter<FeeSettingsState> emit) async {
    if (state.expandedKey == key) {
      emit(_d.copyWith(
          expandedKey: () => null, history: const [], tieredHistory: const []));
      return;
    }
    emit(_d.copyWith(
      expandedKey: () => key,
      loadingHistory: true,
      history: const [],
      tieredHistory: const [],
    ));
    try {
      if (key == monthlySubscriptionGroupKey) {
        final base = await _repository.getFeeSettingHistory(monthlySubscriptionTierKeys.base);
        emit(_d.copyWith(tieredHistory: base, loadingHistory: false));
      } else {
        final history = await _repository.getFeeSettingHistory(key);
        emit(_d.copyWith(history: history, loadingHistory: false));
      }
    } catch (e) {
      emit(_d.copyWith(loadingHistory: false, error: () => e));
    }
  }

  Future<void> _createVersion(
      FeeSettingVersionCreateRequested event, Emitter<FeeSettingsState> emit) async {
    emit(_d.copyWith(saving: true, saveError: () => null));
    try {
      await _repository.createFeeSettingVersion(
        key: event.key,
        value: event.value,
        unit: event.unit,
        startDate: event.startDate,
      );
      await _loadActive(emit);
      emit(_d.copyWith(saving: false));
      event.completer?.complete(true);
    } catch (e) {
      event.completer?.complete(false);
      emit(_d.copyWith(saving: false, saveError: () => e));
    }
  }

  Future<void> _createTieredVersion(
      FeeSettingTieredVersionCreateRequested event, Emitter<FeeSettingsState> emit) async {
    emit(_d.copyWith(saving: true, saveError: () => null));
    try {
      await _repository.createFeeSettingVersion(
        key: monthlySubscriptionTierKeys.base,
        value: event.baseAmount,
        unit: event.unit,
        startDate: event.startDate,
      );
      await _repository.createFeeSettingVersion(
        key: monthlySubscriptionTierKeys.rate,
        value: event.additionalRate,
        unit: event.unit,
        startDate: event.startDate,
      );
      await _repository.createFeeSettingVersion(
        key: monthlySubscriptionTierKeys.threshold,
        value: event.baseThreshold,
        startDate: event.startDate,
      );
      await _loadActive(emit);
      emit(_d.copyWith(saving: false));
      event.completer?.complete(true);
    } catch (e) {
      event.completer?.complete(false);
      emit(_d.copyWith(saving: false, saveError: () => e));
    }
  }
}
