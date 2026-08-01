/// Écran **suivi de commande** (CMD-05, US6).
///
/// Réf. `docs/design/png/C4-suivi-commande.png` — cadres **4a** (collecte en
/// cours), **4b** (recherche de coursier) et **4d** (hors-ligne).
///
/// Widgets Material 3 thémés par `mefali_core` depuis `docs/design/tokens.md` ;
/// aucune chaîne utilisateur en dur (constitutions VII et XI). L'état vient du
/// provider GÉNÉRÉ `suiviProvider` (constitution XII).
///
/// Ce que cet écran refuse de faire, et c'est le plus important :
/// - il n'affiche **jamais** une position sans son âge ;
/// - il ne compte **jamais** l'arrêt de remise comme une collecte ;
/// - hors ligne, il ne prétend pas connaître l'état courant : il annonce le
///   **dernier état connu**, et le bloc « À la livraison » — le seul dont le
///   client a vraiment besoin à ce moment-là — se rend depuis le cache local.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import 'etat_suivi.dart';

/// Écran de suivi d'une commande.
class EcranSuivi extends ConsumerWidget {
  /// Crée l'écran de suivi.
  const EcranSuivi({
    required this.commandeId,
    this.onAppeler,
    this.onAnnuler,
    this.entete,
    super.key,
  });

  /// Commande suivie.
  final String commandeId;

  /// Intention d'appel du coursier (`POST /commandes/{id}/appel`).
  final VoidCallback? onAppeler;

  /// Annulation sans frais depuis l'attente (C4-4b).
  final VoidCallback? onAnnuler;

  /// Bandeau posé **au-dessus** du suivi, quand le parcours en a un à dire.
  ///
  /// Sert au cycle PAY 011 : une commande en attente de paiement, ou annulée
  /// parce que le délai a été franchi, doit se lire ICI — c'est l'écran que la
  /// cliente rouvre depuis l'accueil. Le suivi ne connaît pas le paiement ; il
  /// se contente de faire de la place à ce que le parcours lui donne.
  final Widget? entete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final suivi = ref.watch(suiviProvider(commandeId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.suiviTitre)),
      body: suivi.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (_, _) => Center(child: Text(l10n.commandeErreurInterne)),
        data: (etat) => _CorpsSuivi(
          etat: etat,
          onAppeler: onAppeler,
          onAnnuler: onAnnuler,
          entete: entete,
        ),
      ),
    );
  }
}

class _CorpsSuivi extends StatelessWidget {
  const _CorpsSuivi({
    required this.etat,
    this.onAppeler,
    this.onAnnuler,
    this.entete,
  });

  final EtatSuivi etat;
  final VoidCallback? onAppeler;
  final VoidCallback? onAnnuler;
  final Widget? entete;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(MefaliTokens.screenMargin),
      children: [
        // Ce que le PARCOURS a à dire avant le suivi lui-même (paiement en
        // attente, annulation par expiration). Vide la plupart du temps.
        if (entete != null) ...[
          entete!,
          const SizedBox(height: MefaliTokens.space3),
        ],

        // C4-4d — hors connexion : l'écran DIT que son contenu peut avoir
        // changé, au lieu de le présenter comme frais.
        if (etat.horsLigne) ...[
          _Bandeau(
            icone: Symbols.wifi_off_rounded,
            titre: l10n.suiviHorsLigne,
            detail: '${l10n.suiviDernierEtatConnu} · ${_libelleEtat(l10n, etat)}',
          ),
          const SizedBox(height: MefaliTokens.space3),
        ],

        // C4-4b — recherche de coursier : le stepper n'a rien à montrer, on
        // explique et on offre la sortie (annulation SANS FRAIS).
        if (etat.chercheCoursier) ...[
          _CarteRechercheCoursier(etat: etat),
          const SizedBox(height: MefaliTokens.space3),
        ] else ...[
          // C4-4a — stepper. Masqué hors ligne au profit du « dernier état
          // connu » : un stepper affirme une progression, et hors ligne on ne
          // peut rien affirmer.
          if (!etat.horsLigne) ...[
            _Stepper(etat: etat),
            const SizedBox(height: MefaliTokens.space3),
          ],
        ],

        // La position, TOUJOURS avec son âge — ou l'aveu qu'on ne l'a pas.
        _CartePosition(etat: etat),
        const SizedBox(height: MefaliTokens.space3),

        if (etat.coursierId != null) ...[
          _CarteCoursier(onAppeler: onAppeler),
          const SizedBox(height: MefaliTokens.space3),
        ],

        // Le bloc qui doit marcher SANS RÉSEAU (SC-009).
        BlocRemise(
          jetonReception: etat.jetonReception,
          codeLivraison: etat.codeLivraison,
          horsLigne: etat.horsLigne,
        ),

        if (etat.annulationSansFrais) ...[
          const SizedBox(height: MefaliTokens.space3),
          OutlinedButton.icon(
            onPressed: onAnnuler,
            icon: const Icon(Symbols.close_rounded),
            label: Text(l10n.suiviAnnulerSansFrais),
          ),
        ],
      ],
    );
  }
}

/// Stepper « Commande reçue → Collecte n/N → En route vers vous → Livrée ».
class _Stepper extends StatelessWidget {
  const _Stepper({required this.etat});

  final EtatSuivi etat;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pas = _pasCourant(etat);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  _Pastille(
                    atteint: i <= pas,
                    // Le 2ᵉ pas porte le compteur « 2/3 » : la progression est
                    // dans la pastille, pas dans une phrase à côté.
                    texte: i == 1 && pas == 1
                        ? '${etat.collectesFaites}/${etat.collectesTotal}'
                        : null,
                  ),
                  if (i < 3)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i < pas
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: MefaliTokens.space2),
            Text(_libelleEtat(l10n, etat), style: theme.textTheme.titleMedium),
            if (etat.arretCourant?.prestataireNom != null) ...[
              const SizedBox(height: MefaliTokens.space1),
              Text(
                l10n.suiviChezVendeur(etat.arretCourant!.prestataireNom!),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Index du pas courant du stepper : 0 reçue, 1 collecte, 2 en route,
  /// 3 livrée. Dérivé de la CLÉ d'état, jamais d'un calcul parallèle — sinon
  /// l'écran pourrait dire autre chose que le serveur.
  static int _pasCourant(EtatSuivi etat) => switch (etat.etatCle) {
        'suivi.etat.en_route_vers_vous' => 2,
        'suivi.etat.livree' => 3,
        'suivi.etat.collecte_en_cours' => 1,
        _ => 0,
      };
}

/// Une pastille du stepper.
class _Pastille extends StatelessWidget {
  const _Pastille({required this.atteint, this.texte});

  final bool atteint;
  final String? texte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: atteint ? theme.colorScheme.primary : theme.colorScheme.surface,
        border: Border.all(
          color: atteint
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: 2,
        ),
      ),
      child: texte != null
          ? Text(
              texte!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            )
          : atteint
              ? Icon(Symbols.check_rounded,
                  size: 18, color: theme.colorScheme.onPrimary)
              : null,
    );
  }
}

/// C4-4b — « On cherche votre coursier… », avec le délai allongé.
class _CarteRechercheCoursier extends StatelessWidget {
  const _CarteRechercheCoursier({required this.etat});

  final EtatSuivi etat;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space4),
        child: Column(
          children: [
            Icon(Symbols.pedal_bike_rounded,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: MefaliTokens.space3),
            Text(
              l10n.suiviEtatRechercheCoursier,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MefaliTokens.space2),
            Text(
              l10n.suiviAttenteAllongee,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MefaliTokens.space3),
            Text(
              formaterMontant(etat.totalUnites, etat.devise),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// La position du coursier — avec son âge, ou l'aveu qu'on ne l'a pas.
class _CartePosition extends StatelessWidget {
  const _CartePosition({required this.etat});

  final EtatSuivi etat;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final position = etat.position;
    return Card(
      child: ListTile(
        leading: Icon(
          position == null
              ? Symbols.location_off_rounded
              : Symbols.my_location_rounded,
        ),
        // Une position sans âge serait pire que pas de position : le client
        // croirait le coursier là où il était il y a dix minutes (FR-040).
        title: Text(
          position == null
              ? l10n.suiviPositionInconnue
              : l10n.suiviPositionAge(position.ageS),
        ),
      ),
    );
  }
}

/// Le coursier et son bouton d'appel.
class _CarteCoursier extends StatelessWidget {
  const _CarteCoursier({this.onAppeler});

  final VoidCallback? onAppeler;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: const Icon(Symbols.sports_motorsports_rounded),
        title: Text(l10n.suiviAppelerCoursier),
        trailing: FilledButton.icon(
          onPressed: onAppeler,
          icon: const Icon(Symbols.call_rounded),
          label: Text(l10n.suiviAppelerCoursier),
        ),
      ),
    );
  }
}

/// Bandeau d'information (hors ligne, attente allongée).
class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.icone, required this.titre, this.detail});

  final IconData icone;
  final String titre;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Row(
        children: [
          Icon(icone, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: MefaliTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    )),
                if (detail != null)
                  Text(detail!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Traduit la **clé** d'état servie par l'API. L'app ne décide pas de l'état,
/// elle décide de sa formulation (constitution VII).
String _libelleEtat(MefaliCoreLocalizations l10n, EtatSuivi etat) =>
    switch (etat.etatCle) {
      'suivi.etat.commande_recue' => l10n.suiviEtatRecue,
      'suivi.etat.recherche_coursier' => l10n.suiviEtatRechercheCoursier,
      'suivi.etat.collecte_en_cours' => l10n.suiviEtatCollecteEnCours(
          etat.collectesFaites,
          etat.collectesTotal,
        ),
      'suivi.etat.en_route_vers_vous' => l10n.suiviEtatEnRoute,
      'suivi.etat.livree' => l10n.suiviEtatLivree,
      'suivi.etat.annulee' => l10n.suiviEtatAnnulee,
      'suivi.etat.echouee' => l10n.suiviEtatEchouee,
      // Clé inconnue = serveur plus récent que l'app. On rend le premier pas
      // plutôt qu'une chaîne technique : le client ne doit jamais lire une clé.
      _ => l10n.suiviEtatRecue,
    };
