import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

import '../l10n/app_localizations.dart';
import 'libelles_roles.dart';

/// Le choix des véhicules — partagé par les DEUX surfaces qui le posent.
///
/// Le formulaire de dossier (inscription) et l'écran « Mes véhicules » (coursier
/// déjà validé) demandent exactement la même chose. Dupliquer ce widget aurait
/// garanti que les deux divergent : un jour l'un accepte un transport que
/// l'autre refuse, et personne ne saurait lequel fait foi.
class ChoixVehicules extends StatelessWidget {
  /// Crée la grille de choix.
  const ChoixVehicules({
    required this.actifs,
    required this.selection,
    required this.onBascule,
    this.declaresInactifs = const <String>{},
    super.key,
  });

  /// Types de transport ACTIFS dans la zone (config, FR-021).
  final List<String> actifs;

  /// Slugs cochés.
  final Set<String> selection;

  /// Bascule d'un slug.
  final void Function(String slug, bool choisi) onBascule;

  /// Slugs DÉJÀ déclarés mais que la zone n'accepte plus.
  ///
  /// Ils s'affichent — sinon le coursier ne comprendrait pas pourquoi sa flotte
  /// a rétréci — mais ne se cochent pas : les renvoyer au serveur ferait
  /// refuser tout l'enregistrement (`vehicule_hors_zone`), y compris la partie
  /// qu'il vient de changer.
  final Set<String> declaresInactifs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Config jamais chargée : le dire. Un formulaire sans aucun choix de
    // véhicule serait un cul-de-sac silencieux (règle d'or 5).
    if (actifs.isEmpty && declaresInactifs.isEmpty) {
      return Text(
        l10n.proDossierVehiculesIndisponibles,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: MefaliTokens.textMuted),
      );
    }

    return Wrap(
      spacing: MefaliTokens.space2,
      runSpacing: MefaliTokens.space2,
      children: [
        for (final slug in actifs)
          SizedBox(
            height: MefaliTokens.tapMin,
            child: FilterChip(
              label: Text(l10n.transport(slug)),
              selected: selection.contains(slug),
              onSelected: (choisi) => onBascule(slug, choisi),
            ),
          ),
        for (final slug in declaresInactifs)
          SizedBox(
            height: MefaliTokens.tapMin,
            child: Tooltip(
              message: l10n.proVehiculesInactifZone,
              child: FilterChip(
                label: Text(l10n.transport(slug)),
                selected: false,
                // `null` et non un callback vide : c'est ce qui grise le chip
                // et le retire du parcours d'accessibilité.
                onSelected: null,
              ),
            ),
          ),
      ],
    );
  }
}
