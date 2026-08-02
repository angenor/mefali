import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import '../../roles/choix_vehicules.dart';
import '../../roles/composants.dart';
import '../disponibilite/etat_disponibilite.dart';
import 'etat_vehicules.dart';

/// « Mes véhicules » — la sortie de l'impasse (CPT-04).
///
/// Un coursier dont le rôle est VALIDÉ mais qui n'a déclaré aucun véhicule ne
/// peut pas passer en ligne : le dispatch refuse par `capacite_non_declaree`.
/// Jusqu'ici, la seule surface de déclaration était le formulaire
/// d'inscription — que le routeur de rôles rend inatteignable dès que le rôle
/// est validé. Il ne pouvait plus travailler, et rien dans l'application ne
/// l'en sortait.
///
/// Aucune planche de `docs/design/png/` ne couvre cet écran : il emprunte les
/// motifs de K1 (carte, chips de transport, bouton principal). Écart consigné.

class EcranMesVehicules extends ConsumerStatefulWidget {
  /// Crée l'écran.
  const EcranMesVehicules({super.key});

  @override
  ConsumerState<EcranMesVehicules> createState() => _EcranMesVehiculesState();
}

class _EcranMesVehiculesState extends ConsumerState<EcranMesVehicules> {
  /// Sélection en cours. État strictement LOCAL (constitution XII) : tant que
  /// « Enregistrer » n'est pas touché, elle n'engage rien.
  Set<String>? _selection;
  bool _enCours = false;
  String? _refus;

  Future<void> _enregistrer(Set<String> choix) async {
    setState(() {
      _enCours = true;
      _refus = null;
    });
    final code =
        await ref.read(declarationVehiculesProvider.notifier).enregistrer(choix);
    if (!mounted) return;

    if (code != null) {
      setState(() {
        _enCours = false;
        _refus = code;
      });
      return;
    }

    // Le rechargement appartient à l'ÉCRAN, pas au porteur du geste : celui-ci
    // est auto-dispose et sa portée meurt avec cette page. `disponibilite` est
    // `keepAlive` et porte les capacités que K1 affiche — sans ce rappel, la
    // carte mentirait jusqu'à la prochaine session.
    await ref.read(disponibiliteProvider.notifier).charger();
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.proVehiculesEnregistres)));
    Navigator.of(context).pop(true);
  }

  String _message(AppLocalizations l10n, String code) => switch (code) {
        'role_requis' => l10n.proVehiculesRoleRequis,
        'sans_dossier' => l10n.proVehiculesAucunDossier,
        'refuse' => l10n.proVehiculesRefuse,
        _ => l10n.proErreurAide,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final etat = ref.watch(declarationVehiculesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.proVehiculesTitre)),
      body: etat.when(
        loading: () => const SqueletteListe(),
        error: (_, _) => MessageEtat(
          texte: l10n.proErreurAide,
          picto: Symbols.wifi_off,
          action: () => ref.invalidate(declarationVehiculesProvider),
          libelleAction: l10n.proErreurAction,
        ),
        data: (v) {
          if (v.sansDossier) {
            return MessageEtat(
              texte: l10n.proVehiculesAucunDossier,
              picto: Symbols.assignment_late,
            );
          }

          final choix = _selection ?? v.declares;
          return ListView(
            padding: const EdgeInsets.all(MefaliTokens.screenMargin),
            children: [
              CarteMefali(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.proVehiculesAide),
                    const SizedBox(height: MefaliTokens.space3),
                    ChoixVehicules(
                      actifs: v.actifsZone,
                      selection: choix,
                      declaresInactifs: v.declaresInactifs,
                      onBascule: (slug, coche) => setState(() {
                        final suite = {...choix};
                        if (coche) {
                          suite.add(slug);
                        } else {
                          suite.remove(slug);
                        }
                        _selection = suite;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MefaliTokens.space3),

              // Refus SERVEUR, traduit par sa clé (constitution VII).
              if (_refus != null) ...[
                Text(
                  _message(l10n, _refus!),
                  key: const Key('vehicules-refus'),
                  style: const TextStyle(color: MefaliTokens.danger),
                ),
                const SizedBox(height: MefaliTokens.space3),
              ],

              // Refus LOCAL : inutile d'aller demander au serveur ce qu'on sait
              // déjà refusé, et une flotte vide recréerait l'impasse.
              if (choix.isEmpty) ...[
                Text(
                  l10n.proVehiculesAucunChoix,
                  style: const TextStyle(color: MefaliTokens.textMuted),
                ),
                const SizedBox(height: MefaliTokens.space2),
              ],

              BoutonPrincipal(
                key: const Key('vehicules-enregistrer'),
                libelle: l10n.proVehiculesEnregistrer,
                picto: Symbols.check,
                enCours: _enCours,
                actif: choix.isNotEmpty,
                onPresse: () => _enregistrer(choix),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Ouvre l'écran. Rend `true` si la flotte a été enregistrée.
Future<bool?> ouvrirMesVehicules(BuildContext context) =>
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const EcranMesVehicules()),
    );
