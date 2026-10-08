import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app preferences: theme mode + language (krmf_theme / krmf_lang
/// equivalents) and the registration draft.
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _themeKey = 'app_theme_mode'; // system|light|dark
  static const _langKey = 'krmf_lang'; // bn (default) | en
  static const _draftKey = 'ukams_registration_draft';

  String get themeMode {
    final v = _prefs.getString(_themeKey);
    final normalized = (v == 'light' || v == 'dark') ? v : null;
    return normalized ?? 'system';
  }

  Future<void> setThemeMode(String mode) => _prefs.setString(_themeKey, mode);

  String get language => _prefs.getString(_langKey) ?? 'bn';

  Future<void> setLanguage(String code) => _prefs.setString(_langKey, code);

  String? get registrationDraft {
    final v = _prefs.getString(_draftKey);
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> setRegistrationDraft(String json) => _prefs.setString(_draftKey, json);

  Future<void> clearRegistrationDraft() => _prefs.remove(_draftKey);
}
