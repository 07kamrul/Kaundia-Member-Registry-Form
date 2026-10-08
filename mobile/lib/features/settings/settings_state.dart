part of 'settings_bloc.dart';

class SettingsState {
  SettingsState({required this.themeMode, required this.languageCode});
  final String themeMode;
  final String languageCode;

  ThemeMode get materialThemeMode => switch (themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Locale get locale => Locale(languageCode);
}
