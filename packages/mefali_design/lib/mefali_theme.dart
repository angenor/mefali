import 'package:flutter/material.dart';

import 'mefali_colors.dart';
import 'mefali_typography.dart';

/// Point d'entree unique du theme mefali.
///
/// Usage dans chaque app :
/// ```dart
/// MaterialApp(
///   theme: MefaliTheme.light(),
///   darkTheme: MefaliTheme.dark(),
///   themeMode: ThemeMode.system,
/// )
/// ```
abstract final class MefaliTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: MefaliColors.primaryLight,
      brightness: Brightness.light,
      primary: MefaliColors.primaryLight,
      primaryContainer: MefaliColors.primaryContainerLight,
      onPrimary: MefaliColors.onPrimaryLight,
      onPrimaryContainer: MefaliColors.onPrimaryContainerLight,
      surface: MefaliColors.surfaceLight,
      onSurface: MefaliColors.onSurfaceLight,
      error: MefaliColors.errorLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: MefaliTypography.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: MefaliColors.primaryLight,
      brightness: Brightness.dark,
      primary: MefaliColors.primaryDark,
      primaryContainer: MefaliColors.primaryContainerDark,
      onPrimary: MefaliColors.onPrimaryDark,
      onPrimaryContainer: MefaliColors.onPrimaryContainerDark,
      surface: MefaliColors.surfaceDark,
      onSurface: MefaliColors.onSurfaceDark,
      error: MefaliColors.errorDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: MefaliTypography.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}
