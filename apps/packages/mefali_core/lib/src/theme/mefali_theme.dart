import 'package:flutter/material.dart';

import 'tokens.dart';

/// Thème Material 3 clair de Mefali, construit **depuis** [MefaliTokens]
/// (source de vérité `docs/design/tokens.md`).
///
/// `ColorScheme.fromSeed(#F97316)` ajusté aux tokens exacts, TextTheme Inter,
/// rayons/cibles des tokens. Pas de mode sombre (MVP clair uniquement).
///
/// **Conventions `.adaptive` (DESIGN §10)** : dans les apps, préférer les
/// constructeurs `.adaptive` (`Switch.adaptive`, `CircularProgressIndicator
/// .adaptive`, `showAdaptiveDialog`…) pour respecter les conventions iOS sans
/// dupliquer l'UI — une seule identité Android/iOS, jamais de widgets Cupertino
/// dédiés.
abstract final class MefaliTheme {
  /// Thème clair unique de l'application.
  static ThemeData get light => _build();

  static ThemeData _build() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: MefaliTokens.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: MefaliTokens.primary,
      onPrimary: Colors.white,
      surface: MefaliTokens.surface,
      onSurface: MefaliTokens.text,
      error: MefaliTokens.danger,
      outline: MefaliTokens.border,
      outlineVariant: MefaliTokens.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MefaliTokens.background,
      fontFamily: MefaliTokens.fontFamily,
      textTheme: _textTheme(),
      cardTheme: CardThemeData(
        color: MefaliTokens.surface,
        elevation: MefaliTokens.elevation1,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
          side: const BorderSide(color: MefaliTokens.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MefaliTokens.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(MefaliTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MefaliTokens.radiusButton),
          ),
          textStyle: const TextStyle(
            fontFamily: MefaliTokens.fontFamily,
            fontSize: MefaliTokens.bodySize,
            fontWeight: MefaliTokens.weightSemiBold,
          ),
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: StadiumBorder(),
        backgroundColor: MefaliTokens.primaryTint,
      ),
    );
  }

  static TextTheme _textTheme() {
    TextStyle style(double size, double height, FontWeight weight) => TextStyle(
          fontFamily: MefaliTokens.fontFamily,
          fontSize: size,
          height: height,
          fontWeight: weight,
          color: MefaliTokens.text,
        );

    return TextTheme(
      // Montants d'action, code de livraison.
      displayLarge: style(
        MefaliTokens.displaySize,
        MefaliTokens.displayHeight,
        MefaliTokens.weightBold,
      ),
      // Titres d'écran.
      titleLarge: style(
        MefaliTokens.titleSize,
        MefaliTokens.titleHeight,
        MefaliTokens.weightSemiBold,
      ),
      // Titres de carte, noms de vendeurs.
      titleMedium: style(
        MefaliTokens.headingSize,
        MefaliTokens.headingHeight,
        MefaliTokens.weightSemiBold,
      ),
      // Texte courant (plancher 16 px).
      bodyLarge: style(
        MefaliTokens.bodySize,
        MefaliTokens.bodyHeight,
        MefaliTokens.weightRegular,
      ),
      // Métadonnées : horodatage, distances.
      labelSmall: style(
        MefaliTokens.captionSize,
        MefaliTokens.captionHeight,
        MefaliTokens.weightMedium,
      ),
    );
  }
}
