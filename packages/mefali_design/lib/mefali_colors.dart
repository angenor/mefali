import 'package:flutter/material.dart';

/// Palette de couleurs mefali — marron M3 light + dark.
///
/// Modifier ici change les 4 apps simultanement.
/// Les tokens secondary, tertiary, outline, surfaceVariant sont generes
/// automatiquement par [ColorScheme.fromSeed] a partir de [seedColor].
abstract final class MefaliColors {
  /// Couleur de base pour [ColorScheme.fromSeed].
  static const Color seedColor = Color(0xFF5D4037);

  // ─── Primary ──────────────────────────────────────────
  /// Boutons principaux, app bar, accents forts.
  static const Color primaryLight = Color(0xFF5D4037); // Brown 700
  static const Color primaryDark = Color(0xFFD7CCC8); // Brown 100

  /// Card backgrounds, selections, highlights.
  static const Color primaryContainerLight = Color(0xFFD7CCC8);
  static const Color primaryContainerDark = Color(0xFF5D4037);

  /// Texte sur boutons marron.
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFF3E2723);

  /// Texte sur fond marron clair.
  static const Color onPrimaryContainerLight = Color(0xFF3E2723);
  static const Color onPrimaryContainerDark = Color(0xFFD7CCC8);

  // ─── Surface ──────────────────────────────────────────
  /// Background ecran principal.
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF1C1B1F);

  /// Texte body.
  static const Color onSurfaceLight = Color(0xFF212121);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);

  // ─── Error ────────────────────────────────────────────
  /// Alertes, erreurs, actions destructives.
  static const Color errorLight = Color(0xFFB3261E);
  static const Color errorDark = Color(0xFFEF9A9A);

  // ─── Success (custom — pas dans ColorScheme M3) ───────
  /// "+350 FCFA", confirmations, stock OK.
  static const Color successLight = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF81C784);

  /// Texte sur fond success.
  static const Color onSuccessLight = Color(0xFFFFFFFF);
  static const Color onSuccessDark = Color(0xFF1B5E20);

  /// Container success (fond clair).
  static const Color successContainerLight = Color(0xFFC8E6C9);
  static const Color successContainerDark = Color(0xFF2E7D32);

  /// Texte sur container success.
  static const Color onSuccessContainerLight = Color(0xFF1B5E20);
  static const Color onSuccessContainerDark = Color(0xFFC8E6C9);

  // ─── Warning (custom — pas dans ColorScheme M3) ───────
  /// SnackBar orange 5s, etats "overwhelmed".
  static const Color warningLight = Color(0xFFFF9800);
  static const Color warningDark = Color(0xFFFFCC80);
}
