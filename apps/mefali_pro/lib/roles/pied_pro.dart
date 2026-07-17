import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../l10n/app_localizations.dart';

/// Pied commun aux écrans d'accueil Pro : appareils connectés et déconnexion.
///
/// Mefali Pro n'a pas encore d'écran de paramètres — il arrivera avec les vraies
/// interfaces (CRS/VND). En attendant, ces deux entrées doivent rester
/// atteignables depuis TOUT accueil : un coursier qui perd son téléphone doit
/// pouvoir le révoquer même s'il est en attente de validation (US2).
class PiedPro extends StatelessWidget {
  /// Crée le pied.
  const PiedPro({super.key, required this.session});

  /// Session de l'appareil courant.
  final SessionAuth session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final core = MefaliCoreLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: MefaliTokens.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EcranAppareils(session: session),
                ),
              ),
              icon: const Icon(Symbols.devices),
              label: Text(core.parametresAppareils),
            ),
          ),
        ),
        const SizedBox(width: MefaliTokens.space2),
        Expanded(
          child: SizedBox(
            height: MefaliTokens.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: session.fermer,
              icon: const Icon(Symbols.logout),
              label: Text(l10n.proDeconnexion),
            ),
          ),
        ),
      ],
    );
  }
}
