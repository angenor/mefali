/// Bloc **« À la livraison »** — QR de réception + code à 4 chiffres.
///
/// Réf. `docs/design/png/C4-suivi-commande.png`, cadres **4a** et **4d**.
///
/// C'est l'élément le plus important de l'écran de suivi, et le seul qui doit
/// fonctionner **sans réseau** : au moment de la remise, le client est dans la
/// rue, souvent sans data. Le QR est donc dessiné LOCALEMENT depuis le jeton
/// déjà en cache (`CommandeCache`), jamais téléchargé — un QR servi en image
/// serait indisponible exactement quand on en a besoin (SC-009).
///
/// Le code à 4 chiffres n'est pas un ornement : c'est le mode DÉGRADÉ du scan
/// (cycle QRC 006). Un écran fêlé, un capteur sale, une nuit sans lumière — et
/// c'est lui qui sauve la livraison. Il est donc affiché aussi gros que le QR.
library;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../theme/tokens.dart';

/// Bloc de remise : QR de réception, code à 4 chiffres, et sa consigne.
class BlocRemise extends StatelessWidget {
  /// Crée le bloc de remise.
  const BlocRemise({
    required this.jetonReception,
    required this.codeLivraison,
    this.horsLigne = false,
    super.key,
  });

  /// Jeton encodé dans le QR — servi au client propriétaire seul (R6).
  final String jetonReception;

  /// Code à 4 chiffres, mode dégradé du scan.
  final String codeLivraison;

  /// Rend le titre « disponible sans réseau » (cadre 4d) : hors connexion, ce
  /// bloc est la seule chose que l'écran affirme encore, et il le DIT.
  final bool horsLigne;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
        side: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space4),
        child: Column(
          children: [
            Text(
              horsLigne ? l10n.suiviALaLivraisonHorsLigne : l10n.suiviALaLivraison,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MefaliTokens.space4),
            // Le lecteur d'écran ne peut rien faire d'un QR : on lui donne le
            // code, qui est l'information réellement transmissible à la voix.
            Semantics(
              label: l10n.commandeQrRemise,
              excludeSemantics: true,
              child: QrImageView(
                data: jetonReception,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
                // Correction ÉLEVÉE : le QR sera lu sur un écran rayé, en
                // plein soleil, par un capteur d'entrée de gamme.
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
            ),
            const SizedBox(height: MefaliTokens.space4),
            Semantics(
              label: '${l10n.commandeCodeRemise} $codeLivraison',
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final chiffre in codeLivraison.split(''))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MefaliTokens.space1,
                      ),
                      child: _Chiffre(chiffre: chiffre),
                    ),
                ],
              ),
            ),
            const SizedBox(height: MefaliTokens.space2),
            Text(
              l10n.commandeCodeRemise,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Un chiffre du code, dans sa case contrastée (maquette C4).
class _Chiffre extends StatelessWidget {
  const _Chiffre({required this.chiffre});

  final String chiffre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusButton),
      ),
      child: Text(
        chiffre,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.surface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
