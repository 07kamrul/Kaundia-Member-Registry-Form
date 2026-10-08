part of 'settings_bloc.dart';

sealed class SettingsEvent {}

final class SettingsThemeChanged extends SettingsEvent {
  SettingsThemeChanged(this.mode);
  final String mode; // system | light | dark
}

final class SettingsLanguageChanged extends SettingsEvent {
  SettingsLanguageChanged(this.code); // bn | en
  final String code;
}
