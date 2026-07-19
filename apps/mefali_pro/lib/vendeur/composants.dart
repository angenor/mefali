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

/// Bascule « En stock / Rupture » de la maquette V2 (84×44 VISUEL, vert ou
/// rouge plein, libellé sous le pouce — `docs/design/png/V2-catalogue-stock.png`
/// vue 1a). La zone de TAP fait ≥ 48 dp (tap-min de tokens.md, analyse X1).
///
/// `verrouillee` : rupture posée par l'Admin — la bascule vendeur est refusée
/// (FR-041), le tap explique au lieu d'agir.
class BasculeStock extends StatelessWidget {
  /// Crée la bascule.
  const BasculeStock({
    super.key,
    required this.disponible,
    required this.onBascule,
    this.verrouillee = false,
    this.onVerrouillee,
  });

  /// Vrai = en stock (vert), faux = rupture (rouge).
  final bool disponible;

  /// Bascule demandée (UN geste — FR-045, SC-007).
  final VoidCallback onBascule;

  /// Rupture admin : bascule vendeur interdite (FR-041).
  final bool verrouillee;

  /// Appelé au tap quand la bascule est verrouillée (explication).
  final VoidCallback? onVerrouillee;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final couleur = disponible ? MefaliTokens.success : MefaliTokens.danger;

    return Semantics(
      button: true,
      label: disponible ? l10n.proArticleEnStock : l10n.proArticleRupture,
      child: InkWell(
        borderRadius: BorderRadius.circular(MefaliTokens.radiusChip),
        onTap: verrouillee ? onVerrouillee : onBascule,
        // Zone de tap ≥ 48 dp autour du visuel 84×44 (tokens tap-min).
        child: SizedBox(
          width: 92,
          height: MefaliTokens.tapMin + 8,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 84,
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: couleur,
                borderRadius: BorderRadius.circular(MefaliTokens.radiusChip),
              ),
              child: Row(
                mainAxisAlignment: disponible
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.spaceBetween,
                textDirection:
                    disponible ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: MefaliTokens.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      verrouillee
                          ? Symbols.lock
                          : disponible
                              ? Symbols.check
                              : Symbols.close,
                      size: 20,
                      color: couleur,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      disponible
                          ? l10n.proArticleEnStock
                          : l10n.proArticleRupture,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: MefaliTokens.weightSemiBold,
                        color: MefaliTokens.surface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
