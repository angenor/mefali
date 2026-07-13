import 'package:flutter/painting.dart';

/// Jetons de design Mefali — transcription **1:1** de `docs/design/tokens.md`
/// (source de vérité). Aucune valeur de style ne doit exister ailleurs dans les
/// apps (constitution XI). Identité : chaleureux, fiable, direct.
abstract final class MefaliTokens {
  // --- Couleurs (docs/design/tokens.md § Couleurs) ---
  /// Actions principales, marque, éléments actifs.
  static const Color primary = Color(0xFFF97316);

  /// Pressed/hover, texte primaire sur fond clair.
  static const Color primaryDark = Color(0xFFC2570C);

  /// Cash, confirmations, « collecté », toggle ouvert.
  static const Color success = Color(0xFF15803D);

  /// Erreurs, montants à avancer, suspension, fermé.
  static const Color danger = Color(0xFFDC2626);

  /// Escalade, litiges en cours, hors-ligne.
  static const Color warning = Color(0xFFB45309);

  /// Cartes.
  static const Color surface = Color(0xFFFFFFFF);

  /// Fond d'écran.
  static const Color background = Color(0xFFFAFAF7);

  /// Texte principal.
  static const Color text = Color(0xFF171717);

  /// Texte secondaire (contraste plancher).
  static const Color textMuted = Color(0xFF525252);

  /// Séparateurs, contours de carte.
  static const Color border = Color(0xFFE5E5E5);

  // Teintes claires (fonds de chips/badges/bandeaux — texte reste foncé, AAA).
  static const Color primaryTint = Color(0xFFFFEDD5);
  static const Color successTint = Color(0xFFDCFCE7);
  static const Color dangerTint = Color(0xFFFEE2E2);
  static const Color warningTint = Color(0xFFFEF3C7);

  // --- Typographie (docs/design/tokens.md § Typographie) ---
  /// Famille embarquée. Plancher : jamais < 16 px pour le texte courant.
  static const String fontFamily = 'Inter';

  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  /// Montants d'action, code livraison — 700 40/1.1.
  static const double displaySize = 40;
  static const double displayHeight = 1.1;

  /// Titres d'écran — 600 22/1.3.
  static const double titleSize = 22;
  static const double titleHeight = 1.3;

  /// Titres de carte, noms vendeurs — 600 18/1.35.
  static const double headingSize = 18;
  static const double headingHeight = 1.35;

  /// Texte courant — 400 16/1.5 (plancher 16 px).
  static const double bodySize = 16;
  static const double bodyHeight = 1.5;

  /// Métadonnées : horodatage, distances — 500 13/1.4.
  static const double captionSize = 13;
  static const double captionHeight = 1.4;

  // --- Espacement — grille 8 px (4 px autorisé en intra-composant) ---
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 16;
  static const double space4 = 24;
  static const double space5 = 32;
  static const double screenMargin = 16;

  // --- Rayons ---
  static const double radiusCard = 16;
  static const double radiusButton = 12;
  static const double radiusChip = 999;

  // --- Élévation & cibles tactiles ---
  /// Une seule élévation (pas de dégradés d'ombre).
  static const double elevation1 = 1;

  /// Toute cible tactile ≥ 48 dp.
  static const double tapMin = 48;

  /// Bouton primaire pleine largeur.
  static const double buttonHeight = 56;
}
