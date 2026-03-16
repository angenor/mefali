import 'package:flutter/material.dart';

/// Palette de couleurs mefali — marron M3 light + dark.
///
/// Modifier ici change les 4 apps simultanement.
abstract final class MefaliColors {
  // ─── Primary ──────────────────────────────────────────
  static const Color primaryLight = Color(0xFF5D4037); // Brown 700
  static const Color primaryDark = Color(0xFFD7CCC8); // Brown 100

  static const Color primaryContainerLight = Color(0xFFD7CCC8);
  static const Color primaryContainerDark = Color(0xFF5D4037);

  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFF3E2723);

  static const Color onPrimaryContainerLight = Color(0xFF3E2723);
  static const Color onPrimaryContainerDark = Color(0xFFD7CCC8);

  // ─── Surface ──────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF1C1B1F);

  static const Color onSurfaceLight = Color(0xFF212121);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);

  // ─── Error ────────────────────────────────────────────
  static const Color errorLight = Color(0xFFB3261E);
  static const Color errorDark = Color(0xFFEF9A9A);

  // ─── Success (custom — pas dans ColorScheme M3) ───────
  static const Color successLight = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF81C784);
}
