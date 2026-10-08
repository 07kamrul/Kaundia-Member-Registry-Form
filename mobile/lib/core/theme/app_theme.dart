import 'package:flutter/material.dart';

/// Design tokens ported from the Angular theme (frontend/src/styles.scss):
/// brand dark green + gold, cream-tinted grays, serif headings / sans body.
class AppColors {
  const AppColors._();

  static const emerald600 = Color(0xFF2E5138);
  static const emerald700 = Color(0xFF1F3D2A);
  static const emerald800 = Color(0xFF1F3D2A);
  static const emerald900 = Color(0xFF122718);
  static const emerald50 = Color(0xFFE5EDE1);
  static const gold = Color(0xFFA9791E);
  static const goldStrong = Color(0xFF8A611A);
  static const amber50 = Color(0xFFF1E4C3);
  static const amber200 = Color(0xFFC9A34C);
  static const gray50 = Color(0xFFFAF8F1);
  static const gray100 = Color(0xFFF3EFE3);
  static const gray200 = Color(0xFFE7E2D2);
  static const gray500 = Color(0xFF6B7A6E);
  static const gray700 = Color(0xFF34443A);
  static const gray800 = Color(0xFF1A2A20);
  static const red600 = Color(0xFF9C3A2C);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF3EFE3);

  // Dark-mode counterparts (Angular data-theme='dark' tokens).
  static const darkBg = Color(0xFF12211A);
  static const darkSurface = Color(0xFF1A2A20);
  static const darkSurface2 = Color(0xFF22352A);
  static const darkText = Color(0xFFE8EDE6);
  static const darkMuted = Color(0xFF9DB0A0);
}

class AppRadius {
  const AppRadius._();
  static const sm = 8.0; // 0.5rem
  static const md = 12.0; // 0.75rem
  static const lg = 16.0; // 1rem
}

class AppTheme {
  const AppTheme._();

  static const fontFamilyBody = 'Inter';
  static const fontFamilyBangla = 'Hind Siliguri';

  static ThemeData light() => _base(
        brightness: Brightness.light,
        scaffold: AppColors.gray50,
        surface: AppColors.surface,
        surface2: AppColors.surface2,
        onSurface: AppColors.gray800,
        muted: AppColors.gray500,
        primary: AppColors.emerald700,
        onPrimary: Colors.white,
        secondary: AppColors.gold,
        outline: AppColors.gray200,
        error: AppColors.red600,
      );

  static ThemeData dark() => _base(
        brightness: Brightness.dark,
        scaffold: AppColors.darkBg,
        surface: AppColors.darkSurface,
        surface2: AppColors.darkSurface2,
        onSurface: AppColors.darkText,
        muted: AppColors.darkMuted,
        primary: AppColors.emerald600,
        onPrimary: Colors.white,
        secondary: AppColors.amber200,
        outline: AppColors.darkSurface2,
        error: const Color(0xFFE08573),
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color surface2,
    required Color onSurface,
    required Color muted,
    required Color primary,
    required Color onPrimary,
    required Color secondary,
    required Color outline,
    required Color error,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surface2,
      outline: outline,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: fontFamilyBody,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: outline),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          disabledBackgroundColor: surface2,
          disabledForegroundColor: muted,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary, minimumSize: const Size(48, 48)),
      ),
      checkboxTheme: const CheckboxThemeData(
        fillColor: WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: Colors.black, width: 1.5),
        checkColor: WidgetStatePropertyAll(Colors.black),
      ),
      radioTheme: const RadioThemeData(
        fillColor: WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: Colors.black, width: 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onSurface,
        contentTextStyle: TextStyle(color: scaffold, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        labelStyle: TextStyle(color: onSurface, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: muted,
        indicatorColor: secondary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    );
  }
}
