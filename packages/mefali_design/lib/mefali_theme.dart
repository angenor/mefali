import 'package:flutter/material.dart';

import 'mefali_colors.dart';
import 'mefali_typography.dart';
import 'theme/mefali_custom_colors.dart';

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
  /// Hauteur minimum pour tous les boutons (touch target 48dp).
  static const double _minButtonHeight = 48;

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: MefaliColors.seedColor,
      brightness: Brightness.light,
      primary: MefaliColors.primaryLight,
      primaryContainer: MefaliColors.primaryContainerLight,
      onPrimary: MefaliColors.onPrimaryLight,
      onPrimaryContainer: MefaliColors.onPrimaryContainerLight,
      surface: MefaliColors.surfaceLight,
      onSurface: MefaliColors.onSurfaceLight,
      error: MefaliColors.errorLight,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: MefaliColors.seedColor,
      brightness: Brightness.dark,
      primary: MefaliColors.primaryDark,
      primaryContainer: MefaliColors.primaryContainerDark,
      onPrimary: MefaliColors.onPrimaryDark,
      onPrimaryContainer: MefaliColors.onPrimaryContainerDark,
      surface: MefaliColors.surfaceDark,
      onSurface: MefaliColors.onSurfaceDark,
      error: MefaliColors.errorDark,
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: MefaliTypography.textTheme,
      extensions: [
        isLight ? MefaliCustomColors.light : MefaliCustomColors.dark,
      ],

      // ─── AppBar ─────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? colorScheme.primary : colorScheme.surface,
        foregroundColor: isLight
            ? colorScheme.onPrimary
            : colorScheme.onSurface,
        elevation: isLight ? 2 : 0,
        scrolledUnderElevation: 4,
      ),

      // ─── Boutons — touch target 48dp minimum ───────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(_minButtonHeight),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(_minButtonHeight),
          side: BorderSide(color: colorScheme.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(_minButtonHeight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(_minButtonHeight),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(_minButtonHeight, _minButtonHeight),
        ),
      ),

      // ─── Card ───────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: isLight ? 1 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),

      // ─── NavigationBar (M3, remplace BottomNavigationBar) ─
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
      ),

      // ─── TabBar ─────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // ─── Input — labels au-dessus, pas en placeholder ──
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),

      // ─── SnackBar ──────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ─── Chip ──────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selectedColor: colorScheme.primaryContainer,
      ),

      // ─── Badge ─────────────────────────────────────────
      badgeTheme: const BadgeThemeData(smallSize: 8, largeSize: 16),

      // ─── Divers ────────────────────────────────────────
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
