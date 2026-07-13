import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import 'l10n/app_localizations.dart';

/// Écran de démarrage pro — preuve du thème (couleurs, police Inter,
/// pictogramme Material Symbols Rounded). Chaînes en clés i18n fr.
class SplashScreen extends StatelessWidget {
  /// Crée l'écran de démarrage pro.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(MefaliTokens.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Symbols.two_wheeler,
                size: 72,
                fill: 1,
                color: MefaliTokens.primary,
              ),
              const SizedBox(height: MefaliTokens.space3),
              Text(l10n.appTitle, style: textTheme.displayLarge),
              const SizedBox(height: MefaliTokens.space2),
              Text(
                l10n.splashTagline,
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
