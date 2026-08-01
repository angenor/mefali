import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import 'etat_course.dart';
import 'montant_a_encaisser.dart';

/// L'écran « en route vers le client » (K3-1c) : bandeau vert, récapitulatif
/// des arrêts avec leurs heures, repère du client, montant total à encaisser.
///
/// Réf. `docs/design/png/K3-course-active.png` état 1c. La bascule visuelle est
/// nette et voulue : la collecte est finie, tout est dans le sac, il ne reste
/// qu'une chose à faire.
class BandeauLivraison extends StatelessWidget {
  /// Crée l'écran de livraison.
  const BandeauLivraison({
    super.key,
    required this.etat,
    required this.enLigne,
    this.onItineraire,
    this.onAppelerClient,
    required this.onArriveChezClient,
  });

  /// La course, tous arrêts collectés.
  final EtatCourse etat;

  /// Réseau disponible ? Décide du grisage des deux actions réseau.
  final bool enLigne;

  /// Ouvre l'itinéraire vers le client.
  final VoidCallback? onItineraire;

  /// Appelle le client — le numéro n'est JAMAIS affiché (FR-034).
  final VoidCallback? onAppelerClient;

  /// « Je suis arrivé chez le client » — la transition qui ouvre K4.
  final VoidCallback onArriveChezClient;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final client = etat.client;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BandeauVert(nbArrets: etat.arrets.length),
        const SizedBox(height: MefaliTokens.space3),
        Expanded(
          child: ListView(
            children: [
              Card(
                child: Column(
                  children: [
                    for (final a in etat.arrets)
                      ListTile(
                        leading: Icon(
                          a.collecte
                              ? Symbols.check_circle_rounded
                              : Symbols.cancel_rounded,
                          color: a.collecte
                              ? MefaliTokens.success
                              : MefaliTokens.danger,
                        ),
                        title: Text(a.nom),
                        trailing: Text(
                          _heure(a.collecteLe),
                          style: textTheme.bodySmall
                              ?.copyWith(color: MefaliTokens.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: MefaliTokens.space3),
              _CarteClient(
                client: client,
                enLigne: enLigne,
                onItineraire: onItineraire,
                onAppeler: onAppelerClient,
              ),
              const SizedBox(height: MefaliTokens.space3),
              BlocMontantAEncaisser(
                montantUnites: etat.montantAEncaisserUnites,
                devise: etat.devise,
                modePaiement: etat.modePaiement,
              ),
            ],
          ),
        ),
        const SizedBox(height: MefaliTokens.space3),
        BoutonPrincipal(
          libelle: l10n.crsJeSuisArriveChezClient,
          picto: Symbols.location_on_rounded,
          onPresse: onArriveChezClient,
        ),
      ],
    );
  }

  static String _heure(DateTime? quand) {
    if (quand == null) return '—';
    final local = quand.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _BandeauVert extends StatelessWidget {
  const _BandeauVert({required this.nbArrets});

  final int nbArrets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.success,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.crsEnRouteVersClient,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: MefaliTokens.weightBold,
                ),
          ),
          Text(
            l10n.crsToutEstDansLeSac(nbArrets),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CarteClient extends StatelessWidget {
  const _CarteClient({
    required this.client,
    required this.enLigne,
    this.onItineraire,
    this.onAppeler,
  });

  final ClientCourseVue client;
  final bool enLigne;
  final VoidCallback? onItineraire;
  final VoidCallback? onAppeler;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final fichier = client.repereVocalFichier;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
        side: const BorderSide(color: MefaliTokens.primary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Le nom d'usage n'existe pas au MVP : le repère prend sa place,
            // et c'est de toute façon lui qui fait trouver la porte.
            Text(
              client.nomUsage ?? client.repereTexte ?? '',
              style: textTheme.titleMedium,
            ),
            if (client.nomUsage != null && client.repereTexte != null)
              Text(
                client.repereTexte!,
                style: textTheme.bodySmall
                    ?.copyWith(color: MefaliTokens.textMuted),
              ),
            if (fichier != null) ...[
              const SizedBox(height: MefaliTokens.space3),
              // Le fichier est LOCAL : la note se joue en mode avion (FR-024,
              // SC-012). Une URL présignée expire, et elle expire précisément
              // quand le réseau manque.
              LecteurNoteVocale(
                obtenirUrl: () async => fichier,
                dureeS: client.repereVocalDureeS,
              ),
            ] else if (client.repereVocalDureeS != null) ...[
              const SizedBox(height: MefaliTokens.space2),
              Text(
                l10n.crsRepereVocalIndisponible,
                style: textTheme.bodySmall?.copyWith(color: MefaliTokens.warning),
              ),
            ],
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
                    onPressed:
                        enLigne && client.telephone != null ? onAppeler : null,
                    icon: const Icon(Symbols.call_rounded),
                    label: Text(l10n.crsAppeler),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
