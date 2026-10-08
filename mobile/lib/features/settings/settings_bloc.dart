import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../l10n/app_localizations.dart';

sealed class SettingsEvent {}

final class SettingsThemeChanged extends SettingsEvent {
  SettingsThemeChanged(this.mode);
  final String mode; // system | light | dark
}

final class SettingsLanguageChanged extends SettingsEvent {
  SettingsLanguageChanged(this.code); // bn | en
  final String code;
}

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

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc()
      : super(SettingsState(
          themeMode: sl<AppPreferences>().themeMode,
          languageCode: sl<AppPreferences>().language,
        )) {
    on<SettingsThemeChanged>(_onTheme);
    on<SettingsLanguageChanged>(_onLanguage);
  }

  Future<void> _onTheme(SettingsThemeChanged e, Emitter<SettingsState> emit) async {
    await sl<AppPreferences>().setThemeMode(e.mode);
    emit(SettingsState(themeMode: e.mode, languageCode: state.languageCode));
  }

  Future<void> _onLanguage(SettingsLanguageChanged e, Emitter<SettingsState> emit) async {
    await sl<AppPreferences>().setLanguage(e.code);
    emit(SettingsState(themeMode: state.themeMode, languageCode: e.code));
  }
}

/// Listens for 401-triggered unauthorized notifications and re-evaluates the
/// go_router redirect (forces nav to /login).
class AuthRedirectListenable extends ChangeNotifier {
  void Function()? _fn;

  void attach(GoRouter router) {
    _fn = () {
      router.refresh();
    };
    routerNotifier.addListener(_fn!);
  }

  void detach() {
    if (_fn != null) routerNotifier.removeListener(_fn!);
  }
}

AppLocalizations l10nOf(BuildContext context) => AppLocalizations.of(context);
