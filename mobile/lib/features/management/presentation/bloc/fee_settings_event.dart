part of 'fee_settings_bloc.dart';

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
  List<Object?> get props =>
      [baseAmount, additionalRate, baseThreshold, unit, startDate];
}
