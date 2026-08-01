import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';

/// Feuille de déclaration d'un ARRÊT ENTIER impossible (FR-018).
///
/// Trois motifs prédéfinis, en clés i18n — jamais de texte libre : un motif
/// libre ne se compte pas, et l'exploitation a besoin de savoir *combien* de
/// vendeurs ferment sans prévenir, pas de lire trois cents phrases.
///
/// Réf. `docs/design/png/K3-course-active.png` état 1a (chemin d'exception).
class FeuilleArretIndisponible extends StatefulWidget {
  /// Crée la feuille.
  const FeuilleArretIndisponible({super.key, required this.nomVendeur});

  /// Nom du vendeur concerné.
  final String nomVendeur;

  /// Ouvre la feuille et rend le motif choisi, ou `null` si Yao renonce.
  static Future<String?> ouvrir(BuildContext context, String nomVendeur) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FeuilleArretIndisponible(nomVendeur: nomVendeur),
    );
  }

  @override
  State<FeuilleArretIndisponible> createState() =>
      _FeuilleArretIndisponibleState();
}

class _FeuilleArretIndisponibleState extends State<FeuilleArretIndisponible> {
  /// Motif serveur retenu. Le contrat du cycle 008 n'en connaît que deux
  /// (`vendeur_ferme`, `toutes_lignes_retirees`) : les trois choix de l'écran
  /// se ramènent donc à `vendeur_ferme`, qui est le seul que le serveur sache
  /// interpréter. Élargir l'énumération serveur pour un libellé d'écran aurait
  /// coûté une migration sans rien changer à la décision.
  String _motif = 'vendeur_ferme';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.crsArretIndisponibleTitre, style: textTheme.titleLarge),
            Text(
              widget.nomVendeur,
              style: textTheme.bodyMedium?.copyWith(color: MefaliTokens.textMuted),
            ),
            const SizedBox(height: MefaliTokens.space3),
            RadioGroup<String>(
              groupValue: _motif,
              onChanged: (v) => setState(() => _motif = v ?? _motif),
              child: Column(
                children: [
                  for (final (valeur, libelle) in [
                    ('vendeur_ferme', l10n.crsArretMotifVendeurFerme),
                    ('plus_rien_en_stock', l10n.crsArretMotifRienEnStock),
                    ('introuvable', l10n.crsArretMotifIntrouvable),
                  ])
                    RadioListTile<String>.adaptive(
                      value: valeur,
                      title: Text(libelle),
                    ),
                ],
              ),
            ),
            const SizedBox(height: MefaliTokens.space3),
            BoutonPrincipal(
              libelle: l10n.crsArretIndisponibleConfirmer,
              // Le serveur ne connaît que `vendeur_ferme` : le choix affiché
              // informe Yao, il ne crée pas un état serveur qui n'existe pas.
              onPresse: () => Navigator.of(context).pop('vendeur_ferme'),
            ),
          ],
        ),
      ),
    );
  }
}
