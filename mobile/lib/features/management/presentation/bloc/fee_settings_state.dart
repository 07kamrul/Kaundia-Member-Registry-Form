part of 'fee_settings_bloc.dart';

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
