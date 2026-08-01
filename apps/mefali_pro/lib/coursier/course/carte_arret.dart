import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import 'etat_course.dart';

/// La carte de l'arrêt COURANT (K3-1a) : rang, nom du vendeur, distance, et les
/// deux actions qui exigent le réseau.
///
/// Réf. `docs/design/png/K3-course-active.png` état 1a ; valeurs de
/// `docs/design/tokens.md`. Un seul arrêt est développé à la fois — c'est ce
/// qui rend l'écran lisible en plein soleil, une main sur le guidon.
///
/// **Itinéraire et Appeler sont les SEULES actions grisées hors connexion**
/// (FR-026), et le grisage s'accompagne toujours de son explication : un bouton
/// inerte sans raison passe pour une panne.
class CarteArretCourant extends StatelessWidget {
  /// Crée la carte de l'arrêt courant.
  const CarteArretCourant({
    super.key,
    required this.arret,
    required this.rang,
    required this.total,
    required this.enLigne,
    this.onItineraire,
    this.onAppeler,
  });

  /// L'arrêt développé.
  final ArretCourse arret;

  /// Rang de l'arrêt (1-based) — le « 1 » de « Arrêt 1 / 3 ».
  final int rang;

  /// Nombre total d'arrêts.
  final int total;

  /// Réseau disponible ? Décide du grisage des deux actions.
  final bool enLigne;

  /// Ouvre l'itinéraire (réseau requis).
  final VoidCallback? onItineraire;

  /// Appelle le vendeur — le numéro n'est JAMAIS affiché (FR-034).
  final VoidCallback? onAppeler;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
        side: const BorderSide(color: MefaliTokens.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PastilleRang(rang: rang),
                const SizedBox(width: MefaliTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        arret.nom,
                        style: textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.crsArretSurTotal(rang, total),
                        style: textTheme.bodySmall
                            ?.copyWith(color: MefaliTokens.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: MefaliTokens.space3),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: enLigne ? onItineraire : null,
                    icon: const Icon(Symbols.location_on_rounded),
                    label: Text(l10n.crsItineraire),
                  ),
                ),
                const SizedBox(width: MefaliTokens.space2),
                Expanded(
                  child: OutlinedButton.icon(
                    // Sans numéro connu, l'appel n'est pas proposé : un bouton
                    // qui ouvre un composeur vide est pire qu'un bouton absent.
                    onPressed: enLigne && arret.telephoneVendeur != null
                        ? onAppeler
                        : null,
                    icon: const Icon(Symbols.call_rounded),
                    label: Text(l10n.crsAppeler),
                  ),
                ),
              ],
            ),
            if (!enLigne) ...[
              const SizedBox(height: MefaliTokens.space2),
              Text(
                l10n.crsHorsLigneActionsGrisees,
                style: textTheme.bodySmall?.copyWith(color: MefaliTokens.warning),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un arrêt REPLIÉ (K3-1b) : le rang devient une coche verte, et l'heure de
/// collecte s'affiche à droite — « ✓ Collecté 14:32 ».
///
/// Le replier n'est pas cosmétique : c'est ce qui garde un seul arrêt développé
/// et empêche Yao de payer chez le mauvais vendeur.
class CarteArretReplie extends StatelessWidget {
  /// Crée la carte repliée.
  const CarteArretReplie({super.key, required this.arret, required this.rang});

  /// L'arrêt replié.
  final ArretCourse arret;

  /// Rang de l'arrêt (1-based).
  final int rang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final resolu = arret.collecte || arret.statut == 'indisponible';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space3),
        child: Row(
          children: [
            if (arret.collecte)
              const Icon(Symbols.check_circle_rounded,
                  color: MefaliTokens.success, size: 28)
            else if (arret.statut == 'indisponible')
              const Icon(Symbols.cancel_rounded,
                  color: MefaliTokens.danger, size: 28)
            else
              _PastilleRang(rang: rang, actif: false),
            const SizedBox(width: MefaliTokens.space3),
            Expanded(
              child: Text(
                arret.nom,
                style: textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _ChipEtatArret(arret: arret, resolu: resolu, l10n: l10n),
          ],
        ),
      ),
    );
  }
}

class _ChipEtatArret extends StatelessWidget {
  const _ChipEtatArret({
    required this.arret,
    required this.resolu,
    required this.l10n,
  });

  final ArretCourse arret;
  final bool resolu;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (fond, accent, libelle) = switch (arret.statut) {
      // Sans horodatage connu, « Collecté » tout court : l'heure de collecte
      // n'est pas conservée localement, et le tiret qui la remplaçait donnait
      // un « Collecté — » que T087 a relevé sur tous les arrêts repliés.
      'collecte' => (
          MefaliTokens.successTint,
          MefaliTokens.success,
          arret.collecteLe == null
              ? l10n.courseArretCollecte
              : l10n.crsArretCollecteA(_heure(arret.collecteLe)),
        ),
      'indisponible' => (
          MefaliTokens.dangerTint,
          MefaliTokens.danger,
          l10n.crsIndisponible,
        ),
      _ => (
          MefaliTokens.warningTint,
          MefaliTokens.warning,
          l10n.crsArretACollecter,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MefaliTokens.space2,
        vertical: MefaliTokens.space1,
      ),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusChip),
      ),
      child: Text(
        libelle,
        style: TextStyle(color: accent, fontWeight: MefaliTokens.weightSemiBold),
      ),
    );
  }

  /// Heure locale « 14:32 ». Sans horodatage connu, un tiret — jamais une heure
  /// inventée, qui ferait croire à une collecte qu'on ne sait pas dater.
  static String _heure(DateTime? quand) {
    if (quand == null) return '—';
    final local = quand.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _PastilleRang extends StatelessWidget {
  const _PastilleRang({required this.rang, this.actif = true});

  final int rang;
  final bool actif;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: actif ? MefaliTokens.primary : MefaliTokens.border,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rang',
        style: TextStyle(
          color: actif ? Colors.white : MefaliTokens.textMuted,
          fontWeight: MefaliTokens.weightBold,
        ),
      ),
    );
  }
}
