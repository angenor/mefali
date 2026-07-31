/// **K5 — Caisse & historique** (CRS-06, T070/T071).
///
/// Réf. `docs/design/png/K5-caisse-historique.png` états 1a, 1b et 1c ; valeurs
/// de `docs/design/tokens.md`. Widgets Material 3 thémés via `mefali_core`,
/// aucune transposition DOM/CSS des exports HTML (constitution XI).
///
/// Ce que cet écran doit rendre vrai, et pourquoi il est produit :
///
/// - **le solde avancé en tête, en display danger** — c'est l'argent que Yao a
///   sorti de sa poche, et la seule façon qu'il a de vérifier que « le coursier
///   ne perd jamais » n'est pas une formule (FR-068) ;
/// - **trois chiffres par course** — avancé / remboursé / gain. Deux suffiraient
///   à faire un total juste et un écran inutilisable : c'est l'écart entre les
///   trois qui permet de contester une ligne (FR-069) ;
/// - **l'état vide montre le solde à 0**, il ne le masque pas (maquette 1b,
///   « jamais de carte manquante », FR-077) ;
/// - **hors ligne, la caisse s'ouvre quand même**, datée (FR-076).
///
/// **Deux surfaces de la maquette ne sont PAS construites** : la carte
/// « Signaler ou bloquer » de 1a et la feuille 1d appartiennent à **CRS-07**
/// (P1, tranche T4) — les poser ici demanderait un chemin serveur qui n'existe
/// pas. Écart assumé, consigné dans `rapport-ecarts.md`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import 'etat_caisse.dart';

/// L'écran caisse.
class EcranCaisse extends ConsumerWidget {
  /// Crée l'écran.
  const EcranCaisse({super.key, this.entete, this.onPasserEnLigne});

  /// Entête optionnel (bascule de rôle) — rendu DANS l'unique `Scaffold`,
  /// patron d'`EcranDisponibilite` : jamais de `Scaffold` imbriqué.
  final Widget? entete;

  /// Action « Passer en ligne » de l'état vide (K5-1b).
  ///
  /// Elle **ramène à K1** plutôt que de basculer ici : passer en ligne exige un
  /// plafond d'avance déclaré (`capacite_non_declaree`, cycle 009), et c'est sur
  /// K1 que Yao le règle. Un bouton qui échouerait faute de plafond serait pire
  /// qu'un bouton qui conduit là où la décision se prend.
  final VoidCallback? onPasserEnLigne;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(etatCaisseProvider);

    return Scaffold(
      backgroundColor: MefaliTokens.background,
      appBar: AppBar(
        // `min` + `Flexible` : la barre haute partage sa largeur avec le badge
        // de droite (une date, ou un décompte de litiges). Un `Row` naturel y
        // déborde dès que le badge s'allonge — sur 360 dp, ce n'est pas une
        // hypothèse d'écran de test.
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.account_balance_wallet_rounded,
                color: MefaliTokens.primary),
            const SizedBox(width: MefaliTokens.space2),
            Flexible(
              child: Text(l10n.crsCaisseTitre, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: MefaliTokens.screenMargin),
            child: _BadgeEntete(litiges: async.value?.litiges.length ?? 0),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (async) {
          // Une erreur SERVEUR (jamais le réseau : le porteur sert alors le
          // cache) — dite en clair plutôt que par un écran figé.
          AsyncError() => _Erreur(
              onReessayer: () => ref.read(etatCaisseProvider.notifier).rafraichir(),
            ),
          AsyncData(:final value) => RefreshIndicator.adaptive(
              onRefresh: () =>
                  ref.read(etatCaisseProvider.notifier).rafraichir(),
              child: _Corps(
                etat: value,
                entete: entete,
                onPasserEnLigne: onPasserEnLigne,
              ),
            ),
          _ => const Center(child: CircularProgressIndicator.adaptive()),
        },
      ),
    );
  }
}

/// Le corps de K5 : solde, litiges, historique, indemnisations.
class _Corps extends StatelessWidget {
  const _Corps({required this.etat, this.entete, this.onPasserEnLigne});

  final EtatCaisseVue etat;
  final Widget? entete;
  final VoidCallback? onPasserEnLigne;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(MefaliTokens.screenMargin),
      children: [
        if (entete != null) ...[
          entete!,
          const SizedBox(height: MefaliTokens.space3),
        ],

        // Hors ligne : la caisse est DATÉE, jamais présentée comme fraîche
        // (FR-076). Le taire ferait prendre une avance soldée pour une avance
        // en cours — exactement l'erreur que cet écran doit empêcher.
        if (etat.horsLigne) ...[
          BandeauHorsLigne(message: l10n.crsCaisseHorsLigne),
          const SizedBox(height: MefaliTokens.space3),
        ],

        _CarteSolde(etat: etat),

        // FR-078 — l'agence est prévenue, et Yao le sait : un incident qu'on
        // signale sans le lui dire le laisserait découvrir le blocage au
        // moment d'accepter une course.
        if (etat.ecartPlafond) ...[
          const SizedBox(height: MefaliTokens.space3),
          _Alerte(message: l10n.crsCaisseEcartPlafond),
        ],

        // 1c — le litige en cours et son engagement de rappel.
        for (final litige in etat.litiges) ...[
          const SizedBox(height: MefaliTokens.space3),
          _CarteLitige(litige: litige, devise: etat.devise),
        ],

        if (etat.vide) ...[
          const SizedBox(height: MefaliTokens.space4),
          _EtatVide(onPasserEnLigne: onPasserEnLigne),
        ] else ...[
          if (etat.historique.isNotEmpty) ...[
            const SizedBox(height: MefaliTokens.space4),
            _TitreSection(l10n.crsCaisseHistoriqueTitre),
            const SizedBox(height: MefaliTokens.space2),
            _Carte(
              enfant: Column(
                children: [
                  for (final (i, ligne) in etat.historique.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    _LigneHistorique(ligne: ligne, devise: etat.devise),
                  ],
                ],
              ),
            ),
          ],
          if (etat.indemnisations.isNotEmpty) ...[
            const SizedBox(height: MefaliTokens.space4),
            _TitreSection(l10n.crsCaisseIndemnisationsTitre),
            const SizedBox(height: MefaliTokens.space2),
            _Carte(
              enfant: Column(
                children: [
                  for (final (i, ind) in etat.indemnisations.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    _LigneIndemnisation(indemnisation: ind),
                  ],
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Le solde avancé — display danger, tout en haut (K5-1a, FR-068).
class _CarteSolde extends StatelessWidget {
  const _CarteSolde({required this.etat});

  final EtatCaisseVue etat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // À zéro, le solde est NEUTRE : encadrer de rouge un compteur vide
    // apprendrait à Yao à ignorer le rouge (maquette 1b).
    final engage = etat.avanceEnCoursUnites > 0;

    return _Carte(
      bordure: engage ? MefaliTokens.danger : MefaliTokens.border,
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            engage
                ? l10n.crsCaisseAvanceEnCoursCourses(etat.coursesConcernees)
                : l10n.crsCaisseAvanceEnCours,
            key: const Key('caisse-solde-libelle'),
            style: const TextStyle(
              fontSize: MefaliTokens.bodySize,
              color: MefaliTokens.textMuted,
            ),
          ),
          const SizedBox(height: MefaliTokens.space1),
          Text(
            formaterMontant(etat.avanceEnCoursUnites, etat.devise),
            key: const Key('caisse-solde-montant'),
            style: TextStyle(
              fontSize: MefaliTokens.displaySize,
              height: MefaliTokens.displayHeight,
              fontWeight: MefaliTokens.weightBold,
              color: engage ? MefaliTokens.danger : MefaliTokens.text,
            ),
          ),
          if (engage) ...[
            const SizedBox(height: MefaliTokens.space1),
            Text(
              l10n.crsCaisseRembourseALEncaissement,
              style: const TextStyle(
                fontSize: MefaliTokens.captionSize,
                color: MefaliTokens.textMuted,
              ),
            ),
          ],
          // R10 / FR-117 — une avance sur commande PRÉPAYÉE ne sera jamais
          // soldée en espèces. La masquer ferait mentir le solde ; l'annoncer
          // est le seul choix honnête tant que PAY n'existe pas.
          if (etat.avancesEnAttenteReglementUnites > 0) ...[
            const SizedBox(height: MefaliTokens.space2),
            Text(
              l10n.crsCaisseEnAttenteReglement(
                formaterMontant(
                  etat.avancesEnAttenteReglementUnites,
                  etat.devise,
                ),
              ),
              key: const Key('caisse-en-attente-reglement'),
              style: const TextStyle(
                fontSize: MefaliTokens.captionSize,
                fontWeight: MefaliTokens.weightSemiBold,
                color: MefaliTokens.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Une course de l'historique — **les trois chiffres** (K5-1a, FR-069).
class _LigneHistorique extends StatelessWidget {
  const _LigneHistorique({required this.ligne, required this.devise});

  final LigneCaisseVue ligne;
  final String devise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final avance = formaterMontant(ligne.avanceUnites, devise);
    final gain = formaterMontant(ligne.gainUnites, devise);

    // Trois formes, parce qu'une course sans avance et une course en cours ne
    // se lisent pas comme une course soldée : afficher « remboursé ✓ » sur une
    // course où rien n'a été avancé serait faux.
    final detail = switch ((ligne.terminee, ligne.avanceUnites > 0)) {
      (_, false) => l10n.crsCaisseLigneSansAvance(gain),
      (true, true) => l10n.crsCaisseLigneAvanceGain(avance, gain),
      (false, true) => l10n.crsCaisseLigneEnCours(avance, gain),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MefaliTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.crsCaisseLigneCourse(ligne.reference),
                  key: Key('caisse-ligne-${ligne.reference}'),
                  style: const TextStyle(
                    fontSize: MefaliTokens.headingSize,
                    fontWeight: MefaliTokens.weightSemiBold,
                  ),
                ),
                const SizedBox(height: MefaliTokens.space1),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: MefaliTokens.captionSize,
                    color: MefaliTokens.textMuted,
                  ),
                ),
                if (ligne.enAttenteReglement)
                  Text(
                    l10n.crsCaisseLignePrepayee,
                    style: const TextStyle(
                      fontSize: MefaliTokens.captionSize,
                      color: MefaliTokens.warning,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: MefaliTokens.space2),
          _ChipEtat(
            libelle: ligne.terminee
                ? l10n.crsCaisseChipTerminee(_heure(ligne.heure))
                : l10n.crsCaisseChipEnCours,
            fond: ligne.terminee
                ? MefaliTokens.successTint
                : MefaliTokens.surface,
            texte: ligne.terminee
                ? MefaliTokens.success
                : MefaliTokens.textMuted,
          ),
        ],
      ),
    );
  }
}

/// Une indemnisation et son chip d'état (K5-1a, K5-1c).
class _LigneIndemnisation extends StatelessWidget {
  const _LigneIndemnisation({required this.indemnisation});

  final IndemnisationCaisseVue indemnisation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final montant = formaterMontant(
      indemnisation.montantUnites,
      // La devise d'une indemnisation est celle de sa zone d'origine, portée
      // par l'indemnisation elle-même — jamais celle de la caisse.
      _deviseIndemnisation(indemnisation),
    );

    final (libelle, fond, couleur) = switch (indemnisation.etat) {
      'validee' => (
          l10n.crsCaisseIndemnisationValidee,
          MefaliTokens.successTint,
          MefaliTokens.success,
        ),
      'refusee' => (
          l10n.crsCaisseIndemnisationRefusee,
          MefaliTokens.dangerTint,
          MefaliTokens.danger,
        ),
      _ => (
          l10n.crsCaisseIndemnisationDemandee,
          MefaliTokens.warningTint,
          MefaliTokens.warning,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MefaliTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.crsCaisseLigneCourse(indemnisation.commandeReference),
                  style: const TextStyle(
                    fontSize: MefaliTokens.headingSize,
                    fontWeight: MefaliTokens.weightSemiBold,
                  ),
                ),
                const SizedBox(height: MefaliTokens.space1),
                Text(
                  indemnisation.litigeId != null
                      ? l10n.crsCaisseIndemnisationLieeLitige(montant)
                      : l10n.crsCaisseIndemnisationMontant(montant),
                  key: Key('caisse-indemnisation-${indemnisation.id}'),
                  style: const TextStyle(
                    fontSize: MefaliTokens.captionSize,
                    color: MefaliTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MefaliTokens.space2),
          _ChipEtat(libelle: libelle, fond: fond, texte: couleur),
        ],
      ),
    );
  }
}

/// La carte de litige en cours et son engagement de rappel (K5-1c, FR-074).
class _CarteLitige extends StatelessWidget {
  const _CarteLitige({required this.litige, required this.devise});

  final LitigeCaisseVue litige;
  final String devise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      key: Key('caisse-litige-${litige.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.warningTint,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
        border: Border.all(color: MefaliTokens.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Symbols.warning_rounded,
                  size: 20, color: MefaliTokens.warning),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Text(
                  l10n.crsCaisseLitigeTitre(litige.reference),
                  style: const TextStyle(
                    fontSize: MefaliTokens.bodySize,
                    fontWeight: MefaliTokens.weightSemiBold,
                    color: MefaliTokens.warning,
                  ),
                ),
              ),
              const SizedBox(width: MefaliTokens.space2),
              _ChipEtat(
                libelle: l10n.crsCaisseLitigeEnExamen,
                fond: MefaliTokens.surface,
                texte: MefaliTokens.warning,
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space2),
          Text(
            // L'engagement de rappel de la maquette, sans l'heure qu'elle
            // affiche (« avant 17 h ») : aucun délai n'est tenu en base, et
            // en inventer un serait une promesse que rien ne garantit.
            l10n.crsCaisseLitigeEngagement(
              formaterMontant(litige.montantUnites, devise),
            ),
            style: const TextStyle(
              fontSize: MefaliTokens.captionSize,
              color: MefaliTokens.warning,
            ),
          ),
        ],
      ),
    );
  }
}

/// K5-1b — aucune course du jour (FR-077).
class _EtatVide extends StatelessWidget {
  const _EtatVide({this.onPasserEnLigne});

  final VoidCallback? onPasserEnLigne;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _Carte(
          enfant: Column(
            children: [
              const SizedBox(height: MefaliTokens.space3),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: MefaliTokens.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Symbols.local_shipping_rounded,
                    color: MefaliTokens.primary),
              ),
              const SizedBox(height: MefaliTokens.space3),
              Text(
                l10n.crsCaisseAucuneCourse,
                key: const Key('caisse-vide'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: MefaliTokens.headingSize,
                  fontWeight: MefaliTokens.weightSemiBold,
                ),
              ),
              const SizedBox(height: MefaliTokens.space2),
              Text(
                l10n.crsCaisseAucuneCourseTexte,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: MefaliTokens.bodySize,
                  color: MefaliTokens.textMuted,
                ),
              ),
              const SizedBox(height: MefaliTokens.space4),
            ],
          ),
        ),
        if (onPasserEnLigne != null) ...[
          const SizedBox(height: MefaliTokens.space4),
          SizedBox(
            height: MefaliTokens.buttonHeight,
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('caisse-passer-en-ligne'),
              onPressed: onPasserEnLigne,
              icon: const Icon(Symbols.check_rounded),
              label: Text(l10n.crsCaissePasserEnLigne),
              style: FilledButton.styleFrom(
                backgroundColor: MefaliTokens.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Badge d'entête : le nombre de litiges (K5-1c) ou la date du jour (K5-1a).
class _BadgeEntete extends StatelessWidget {
  const _BadgeEntete({required this.litiges});

  final int litiges;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final litige = litiges > 0;
    return _ChipEtat(
      libelle: litige
          ? l10n.crsCaisseLitigeBadge(litiges)
          : l10n.crsCaisseDate(DateTime.now()),
      fond: litige ? MefaliTokens.warningTint : MefaliTokens.surface,
      texte: litige ? MefaliTokens.warning : MefaliTokens.textMuted,
    );
  }
}

/// Alerte d'écart au plafond (FR-078).
class _Alerte extends StatelessWidget {
  const _Alerte({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('caisse-ecart-plafond'),
      width: double.infinity,
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.dangerTint,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Row(
        children: [
          const Icon(Symbols.error_outline_rounded,
              size: 20, color: MefaliTokens.danger),
          const SizedBox(width: MefaliTokens.space2),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: MefaliTokens.bodySize,
                color: MefaliTokens.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Refus SERVEUR — dit en clair, avec de quoi réessayer.
class _Erreur extends StatelessWidget {
  const _Erreur({required this.onReessayer});

  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.crsCaisseErreur,
              key: const Key('caisse-erreur'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: MefaliTokens.bodySize,
                color: MefaliTokens.textMuted,
              ),
            ),
            const SizedBox(height: MefaliTokens.space3),
            OutlinedButton.icon(
              key: const Key('caisse-reessayer'),
              onPressed: onReessayer,
              icon: const Icon(Symbols.refresh_rounded),
              label: Text(l10n.crsCaisseReessayer),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip d'état — la brique de K5 (états de course, d'indemnisation, de litige).
class _ChipEtat extends StatelessWidget {
  const _ChipEtat({
    required this.libelle,
    required this.fond,
    required this.texte,
  });

  final String libelle;
  final Color fond;
  final Color texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MefaliTokens.space3,
        vertical: MefaliTokens.space1,
      ),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusChip),
        border: Border.all(color: MefaliTokens.border),
      ),
      child: Text(
        libelle,
        style: TextStyle(
          fontSize: MefaliTokens.captionSize,
          fontWeight: MefaliTokens.weightSemiBold,
          color: texte,
        ),
      ),
    );
  }
}

/// Titre de section (« Historique du jour », « Indemnisations »).
class _TitreSection extends StatelessWidget {
  const _TitreSection(this.libelle);

  final String libelle;

  @override
  Widget build(BuildContext context) => Text(
        libelle,
        style: const TextStyle(
          fontSize: MefaliTokens.bodySize,
          color: MefaliTokens.textMuted,
        ),
      );
}

/// Carte blanche à bordure — la brique visuelle de K5 (patron de K1).
class _Carte extends StatelessWidget {
  const _Carte({required this.enfant, this.bordure});

  final Widget enfant;
  final Color? bordure;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.surface,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
        border: Border.all(color: bordure ?? MefaliTokens.border),
      ),
      child: enfant,
    );
  }
}

/// « 13:45 » — heure locale, sur l'horodatage SERVEUR (FR-010).
String _heure(DateTime quand) {
  final h = quand.hour.toString().padLeft(2, '0');
  final m = quand.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// La devise d'une indemnisation.
///
/// Le contrat la porte ligne à ligne (une indemnisation peut venir d'une zone
/// dont la devise diffère) ; la vue d'écran ne la retient pas encore, faute de
/// cas réel — elle retombe donc sur XOF, la seule devise en service.
String _deviseIndemnisation(IndemnisationCaisseVue _) => 'XOF';
