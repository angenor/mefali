import 'package:flutter/material.dart';

/// Typographie mefali — Roboto par defaut, modifiable en 1 ligne.
///
/// Body min 14sp, labels min 12sp.
abstract final class MefaliTypography {
  static const String _fontFamily = 'Roboto';

  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(fontFamily: _fontFamily),
    displayMedium: TextStyle(fontFamily: _fontFamily),
    displaySmall: TextStyle(fontFamily: _fontFamily),
    headlineLarge: TextStyle(fontFamily: _fontFamily),
    headlineMedium: TextStyle(fontFamily: _fontFamily),
    headlineSmall: TextStyle(fontFamily: _fontFamily),
    titleLarge: TextStyle(fontFamily: _fontFamily),
    titleMedium: TextStyle(fontFamily: _fontFamily),
    titleSmall: TextStyle(fontFamily: _fontFamily),
    bodyLarge: TextStyle(fontFamily: _fontFamily, fontSize: 16),
    bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 14),
    bodySmall: TextStyle(fontFamily: _fontFamily, fontSize: 12),
    labelLarge: TextStyle(fontFamily: _fontFamily, fontSize: 14),
    labelMedium: TextStyle(fontFamily: _fontFamily, fontSize: 12),
    labelSmall: TextStyle(fontFamily: _fontFamily, fontSize: 12),
  );
}
