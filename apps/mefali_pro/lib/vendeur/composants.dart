import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../l10n/app_localizations.dart';

/// Interrupteur OUVERT / FERMÉ de la maquette V1 (96 px, moitié active pleine,
/// `docs/design/png/V1-statut-boutique.png` — états 1a/1c). UN GESTE (FR-044).
class InterrupteurBoutique extends StatelessWidget {
  /// Crée l'interrupteur.
  const InterrupteurBoutique({
    super.key,
    required this.ouvert,
    required this.onOuvrir,
    required this.onFermer,
  });

  /// Position courante de l'interrupteur (statut DÉCLARÉ).
  final bool ouvert;

  /// Geste « ouvrir ».
  final VoidCallback onOuvrir;

  /// Geste « fermer ».
  final VoidCallback onFermer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 96,
      child: Row(
        children: [
          Expanded(
            child: _Moitie(
              libelle: l10n.proBoutiqueOuvert,
              picto: Symbols.check,
              actif: ouvert,
              couleur: MefaliTokens.success,
              onTap: onOuvrir,
              arrondiGauche: true,
            ),
          ),
          Expanded(
            child: _Moitie(
              libelle: l10n.proBoutiqueFerme,
              picto: Symbols.close,
              actif: !ouvert,
              couleur: MefaliTokens.danger,
              onTap: onFermer,
              arrondiGauche: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _Moitie extends StatelessWidget {
  const _Moitie({
    required this.libelle,
    required this.picto,
    required this.actif,
    required this.couleur,
    required this.onTap,
    required this.arrondiGauche,
  });

  final String libelle;
  final IconData picto;
  final bool actif;
  final Color couleur;
  final VoidCallback onTap;
  final bool arrondiGauche;

  @override
  Widget build(BuildContext context) {
    final rayon = Radius.circular(MefaliTokens.radiusCard);
    final bords = BorderRadius.horizontal(
      left: arrondiGauche ? rayon : Radius.zero,
      right: arrondiGauche ? Radius.zero : rayon,
    );
    return Material(
      color: actif ? couleur : MefaliTokens.surface,
      borderRadius: bords,
      child: InkWell(
        onTap: onTap,
        borderRadius: bords,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: bords,
            border: Border.all(
              color: actif ? couleur : MefaliTokens.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                picto,
                size: 28,
                color: actif ? MefaliTokens.surface : MefaliTokens.textMuted,
              ),
              const SizedBox(height: MefaliTokens.space1),
              Text(
                libelle,
                style: TextStyle(
                  fontSize: MefaliTokens.bodySize,
                  fontWeight: MefaliTokens.weightSemiBold,
                  color: actif ? MefaliTokens.surface : MefaliTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
