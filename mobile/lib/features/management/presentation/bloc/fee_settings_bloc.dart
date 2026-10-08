// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

part 'fee_settings_event.dart';
part 'fee_settings_state.dart';

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

class FeeSettingsBloc extends Bloc<FeeSettingsEvent, FeeSettingsState> {
  FeeSettingsBloc({required AdminRepository repository})
      : _repository = repository,
        super(const FeeSettingsData()) {
    on<FeeSettingsLoadRequested>((event, emit) => _loadActive(emit));
    on<FeeSettingsHistoryToggled>(
        (event, emit) => _toggleHistory(event.key, emit));
    on<FeeSettingVersionCreateRequested>(
        (event, emit) => _createVersion(event, emit));
    on<FeeSettingTieredVersionCreateRequested>(
        (event, emit) => _createTieredVersion(event, emit));
  }

  final AdminRepository _repository;

  /// Current state; copyWith returns the base state type, so never
  /// downcast here (that would silently reset to defaults).
  FeeSettingsState get _d => state;

  Future<void> _loadActive(Emitter<FeeSettingsState> emit) async {
    emit(_d.copyWith(loading: true, error: () => null));
    try {
      final active = await _repository.getActiveFeeSettings();
      emit(_d.copyWith(active: active, loading: false));
    } catch (e) {
      emit(_d.copyWith(loading: false, error: () => e));
    }
  }

  Future<void> _toggleHistory(
      String key, Emitter<FeeSettingsState> emit) async {
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
        final base = await _repository
            .getFeeSettingHistory(monthlySubscriptionTierKeys.base);
        emit(_d.copyWith(tieredHistory: base, loadingHistory: false));
      } else {
        final history = await _repository.getFeeSettingHistory(key);
        emit(_d.copyWith(history: history, loadingHistory: false));
      }
    } catch (e) {
      emit(_d.copyWith(loadingHistory: false, error: () => e));
    }
  }

  Future<void> _createVersion(FeeSettingVersionCreateRequested event,
      Emitter<FeeSettingsState> emit) async {
    emit(_d.copyWith(saving: true, saveError: () => null));
    try {
      if (event.key == monthlySubscriptionGroupKey) {
        // The tiered group is created through FeeSettingTieredVersionCreateRequested.
        throw StateError('use FeeSettingTieredVersionCreateRequested');
      }
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
      FeeSettingTieredVersionCreateRequested event,
      Emitter<FeeSettingsState> emit) async {
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
