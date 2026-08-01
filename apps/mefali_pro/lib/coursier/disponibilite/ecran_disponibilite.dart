/// Écran **K1 — disponibilité du coursier** (tranche DSP de DSP-01).
///
/// Cible : `docs/design/png/K1-disponibilite.png`, valeurs exactes de
/// `docs/design/tokens.md`. Widgets Material 3 **thémés** via `mefali_core`,
/// constructeurs `.adaptive`, aucune transposition de la structure DOM/CSS des
/// exports HTML (constitution XI).
///
/// Ce que cet écran montre, et pourquoi :
///
/// - le **toggle segmenté** en ligne / hors ligne, côté actif plein `--success` ;
/// - le **plafond d'avance du jour**, éditable par pas de 1 000 tant que Yao
///   est hors ligne, **verrouillé** dès qu'il est en ligne (maquette 1a) ;
/// - les **deux** plafonds — déclaré et retenu — et **lequel** s'applique : un
///   coursier à qui l'on refuse une course sans lui dire que son palier le
///   limite croira à un bug (FR-010) ;
/// - le **bandeau de reconnexion** quand le réseau lâche. Il est honnête :
///   passé le TTL, Yao sera effectivement sorti du pool.
///
/// - les **gains du jour** et le **reste disponible** (CRS-01, T075) : le
///   nombre de courses livrées et la somme de leurs parts coursier, dans la
///   devise de la zone (FR-091, FR-095).
///
/// **Deux écarts de maquette assumés**, et pour la même raison — ne jamais
/// afficher un chiffre que rien ne peut alimenter :
///
/// - la **note du jour** reste un tiret tant qu'AVI n'est pas construit
///   (FR-094). Le cycle 009 avait déjà tranché ;
/// - l'état **1c « paie fixe »** n'est pas construit : la promotion de
///   lancement est un engagement opérationnel hors produit (cadrage §7.1). Le
///   bandeau montre ce que le produit sait calculer — la somme des parts
///   coursier des courses livrées.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../l10n/app_localizations.dart';
import '../service_continu/service_continu.dart';
import 'emetteur_position.dart';
import 'etat_disponibilite.dart';
import 'etat_journee.dart';

/// Pas d'édition du plafond, en unités mineures.
///
/// Ergonomie de saisie, **pas** un paramètre métier : il ne change aucun
/// comportement serveur (le montant retenu, lui, vient de la grille de zone).
const int pasPlafondUnites = 1000;

/// Plafond proposé par défaut à la première déclaration du jour.
const int plafondDefautUnites = 10000;

/// L'écran K1.
///
/// `@Dependencies` déclare que cet écran observe un provider **scopé**
/// (`EmetteurPosition`, qui dépend de `sourcePositions`). Sans cette
/// déclaration, `dart analyze` avertit — et surtout, un point de montage qui
/// surcharge la source de positions verrait son override ignoré.
@Dependencies([EmetteurPosition, ServiceContinu])
class EcranDisponibilite extends ConsumerStatefulWidget {
  /// Construit l'écran. [entete] (optionnel) est rendu en tête du corps, DANS
  /// l'unique `Scaffold` — la bascule de rôle du coursier bi-rôle y passe sans
  /// imbriquer un second `Scaffold` (patron d'`EcranCourseActive`, FR-046).
  const EcranDisponibilite({
    super.key,
    this.entete,
    this.barreBasse,
    this.onCaisse,
  });

  /// Entête optionnel (bascule de rôle).
  final Widget? entete;

  /// Navigation basse à trois destinations, injectée par l'aiguillage (T076).
  /// Absente quand l'écran est monté seul (tests, points de montage isolés).
  final Widget? barreBasse;

  /// Ouvre la caisse depuis le raccourci du tableau de bord (FR-096).
  final VoidCallback? onCaisse;

  @override
  ConsumerState<EcranDisponibilite> createState() => _EcranDisponibiliteState();
}

class _EcranDisponibiliteState extends ConsumerState<EcranDisponibilite> {
  /// Montant en cours de saisie — **état LOCAL du widget** : tant qu'il n'est
  /// pas confirmé, il n'appartient à personne d'autre (constitution XII).
  int? _saisie;

  // Aucun `initState` : le chargement de l'intention appartient au PORTEUR
  // (`Disponibilite.build`), pas à cet écran. Tant qu'il était ici, un coursier
  // dont l'app est tuée en pleine course la rouvrait sur l'écran de course —
  // K1 jamais monté, aucune position publiée, course reprise par le serveur.

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final etat = ref.watch(disponibiliteProvider);
    // L'émetteur de position ne tourne que tant que cet écran est monté
    // (limite assumée, research R15) : en arrière-plan, Yao sort du pool par
    // expiration — comportement CONFORME à DSP-01, et son bandeau le dit.
    ref.watch(emetteurPositionProvider);
    // La journée est LUE, jamais bloquante : `.value` sans `when` — un réseau
    // muet efface le bandeau, il n'empêche pas Yao de se mettre en ligne.
    final journee = ref.watch(etatJourneeProvider).value;
    final service = ref.watch(serviceContinuProvider);

    final saisie = _saisie ?? etat.plafondDeclareUnites ?? plafondDefautUnites;

    return Scaffold(
      backgroundColor: MefaliTokens.background,
      bottomNavigationBar: widget.barreBasse,
      appBar: AppBar(
        title: Text(t.dispoTitre),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: MefaliTokens.screenMargin),
            child: _BadgeEtat(enLigne: etat.enLigne),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(MefaliTokens.screenMargin),
        children: [
          if (widget.entete != null) ...[
            widget.entete!,
            const SizedBox(height: MefaliTokens.space3),
          ],
          if (etat.horsLigne) ...[
            BandeauHorsLigne(message: t.dispoAucuneCourse),
            const SizedBox(height: MefaliTokens.space3),
          ],
          if (etat.codeErreur != null) ...[
            _Erreur(code: etat.codeErreur!),
            const SizedBox(height: MefaliTokens.space3),
          ],
          // FR-115 — un service qui ne tourne pas se DIT. Le silence ferait
          // croire à Yao qu'il n'y a pas de courses, alors qu'il n'y a plus
          // personne pour le réveiller.
          if (service.aUnProbleme) ...[
            BandeauHorsLigne(
              message: switch (service.motif) {
                MotifServiceArrete.permissionRefusee =>
                  t.crsServicePermissionRefusee,
                MotifServiceArrete.arreteParSysteme =>
                  t.crsServiceArreteParSysteme,
                MotifServiceArrete.aucun => '',
              },
            ),
            const SizedBox(height: MefaliTokens.space3),
          ],
          _CarteBascule(
            etat: etat,
            onEnLigne: () =>
                ref.read(disponibiliteProvider.notifier).passerEnLigne(saisie),
            onHorsLigne: () =>
                ref.read(disponibiliteProvider.notifier).passerHorsLigne(),
          ),
          const SizedBox(height: MefaliTokens.space3),
          _CartePlafond(
            etat: etat,
            saisie: saisie,
            onSaisie: (v) => setState(() => _saisie = v),
            journee: journee,
          ),
          // ── Ce que Yao a gagné aujourd'hui (CRS-01, K1-1a) ──────────────
          //
          // Absent tant que la journée n'a pas été lue : des zéros affichés
          // avant la première réponse passeraient pour un fait — « tu n'as
          // rien gagné » — au lieu d'un « on ne sait pas encore ».
          if (journee != null && journee.connue) ...[
            const SizedBox(height: MefaliTokens.space3),
            _CarteGains(journee: journee),
            const SizedBox(height: MefaliTokens.space3),
            _TuilesNoteEtAcceptation(journee: journee),
            if (widget.onCaisse != null &&
                journee.avancesEnCoursUnites > 0) ...[
              const SizedBox(height: MefaliTokens.space3),
              _RaccourciCaisse(
                montant: formaterMontant(
                  journee.avancesEnCoursUnites,
                  journee.devise,
                ),
                onOuvrir: widget.onCaisse!,
              ),
            ],
          ],
          const SizedBox(height: MefaliTokens.space4),
          if (!etat.enLigne)
            SizedBox(
              height: MefaliTokens.buttonHeight,
              child: FilledButton.icon(
                key: const Key('dispo-passer-en-ligne'),
                onPressed: etat.chargement
                    ? null
                    : () => ref
                        .read(disponibiliteProvider.notifier)
                        .passerEnLigne(saisie),
                icon: const Icon(Symbols.check_rounded),
                label: Text(
                  t.dispoPasserEnLigne(formaterMontant(saisie, etat.devise)),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: MefaliTokens.success,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          else
            SizedBox(
              height: MefaliTokens.buttonHeight,
              child: OutlinedButton.icon(
                key: const Key('dispo-passer-hors-ligne'),
                onPressed: etat.chargement
                    ? null
                    : () =>
                        ref.read(disponibiliteProvider.notifier).passerHorsLigne(),
                icon: const Icon(Symbols.do_not_disturb_on_rounded),
                label: Text(t.dispoPasserHorsLigne),
              ),
            ),
        ],
      ),
    );
  }
}

/// Badge d'en-tête « EN LIGNE » / « HORS LIGNE » (maquette 1a/1b).
class _BadgeEtat extends StatelessWidget {
  const _BadgeEtat({required this.enLigne});

  final bool enLigne;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MefaliTokens.space3,
        vertical: MefaliTokens.space1,
      ),
      decoration: BoxDecoration(
        color: enLigne ? MefaliTokens.successTint : MefaliTokens.surface,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusChip),
        border: Border.all(
          color: enLigne ? MefaliTokens.success : MefaliTokens.border,
        ),
      ),
      child: Text(
        enLigne ? t.dispoBadgeEnLigne : t.dispoBadgeHorsLigne,
        style: TextStyle(
          fontSize: MefaliTokens.captionSize,
          fontWeight: MefaliTokens.weightSemiBold,
          color: enLigne ? MefaliTokens.success : MefaliTokens.textMuted,
        ),
      ),
    );
  }
}

/// Le toggle segmenté et l'état d'attente qui le suit.
class _CarteBascule extends StatelessWidget {
  const _CarteBascule({
    required this.etat,
    required this.onEnLigne,
    required this.onHorsLigne,
  });

  final EtatDisponibilite etat;
  final VoidCallback onEnLigne;
  final VoidCallback onHorsLigne;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _Carte(
      bordure: etat.enLigne ? MefaliTokens.success : MefaliTokens.border,
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Symbols.do_not_disturb_on_rounded),
                label: Text(t.dispoBasculeHorsLigne),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Symbols.check_rounded),
                label: Text(t.dispoBasculeEnLigne),
              ),
            ],
            selected: {etat.enLigne},
            showSelectedIcon: false,
            onSelectionChanged: etat.chargement
                ? null
                : (choix) => choix.first ? onEnLigne() : onHorsLigne(),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: MefaliTokens.success,
              selectedForegroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: MefaliTokens.space2),
          // ⚠ « En attente de courses » n'est vrai QUE si le serveur confirme
          // la présence au pool. Le contrat distingue `en_ligne` de
          // `dans_le_pool` précisément pour ça : une position refusée, un GPS
          // coupé ou un réseau muet laissent Yao en ligne et HORS du pool, et
          // lui dire qu'il attend des courses serait un mensonge — il croirait
          // travailler pendant qu'aucune offre ne peut lui parvenir. Défaut
          // constaté sur émulateur (T071), pool VIDE sous « en attente ».
          Row(
            children: [
              Icon(
                etat.attendDesCourses
                    ? Symbols.schedule_rounded
                    : Symbols.error_outline_rounded,
                size: 20,
                color: etat.attendDesCourses
                    ? MefaliTokens.success
                    : MefaliTokens.textMuted,
              ),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Text(
                  switch ((etat.enLigne, etat.dansLePool)) {
                    (true, true) => t.dispoAttenteCourses,
                    (true, false) => t.dispoPositionAbsente,
                    _ => t.dispoAucuneCourse,
                  },
                  style: TextStyle(
                    fontSize: MefaliTokens.bodySize,
                    fontWeight: MefaliTokens.weightSemiBold,
                    color: etat.attendDesCourses
                        ? MefaliTokens.success
                        : MefaliTokens.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Le plafond du jour : saisie par pas, montant retenu, source et palier.
class _CartePlafond extends StatelessWidget {
  const _CartePlafond({
    required this.etat,
    required this.saisie,
    required this.onSaisie,
    this.journee,
  });

  final EtatDisponibilite etat;
  final int saisie;
  final ValueChanged<int> onSaisie;

  /// Journée lue, pour le « reste disponible » de la maquette 1a.
  final EtatJourneeVue? journee;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    // Verrouillé en ligne (maquette 1a) : changer son plafond au milieu d'une
    // offre en vol changerait la course sous les pieds du dispatch.
    final verrouille = etat.enLigne;

    return _Carte(
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.dispoPlafondTitre,
                  style: const TextStyle(
                    fontSize: MefaliTokens.bodySize,
                    color: MefaliTokens.textMuted,
                  ),
                ),
              ),
              if (verrouille)
                Chip(
                  avatar: const Icon(Symbols.lock_rounded, size: 16),
                  label: Text(t.dispoPlafondVerrouille),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space2),
          if (etat.plafondADeclarer && !verrouille) ...[
            Text(
              t.dispoNouveauJour,
              key: const Key('dispo-nouveau-jour'),
              style: const TextStyle(
                fontSize: MefaliTokens.bodySize,
                fontWeight: MefaliTokens.weightSemiBold,
                color: MefaliTokens.warning,
              ),
            ),
            const SizedBox(height: MefaliTokens.space2),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!verrouille)
                IconButton.filledTonal(
                  key: const Key('dispo-plafond-moins'),
                  onPressed: saisie >= pasPlafondUnites
                      ? () => onSaisie(saisie - pasPlafondUnites)
                      : null,
                  icon: const Icon(Symbols.remove_rounded),
                ),
              Expanded(
                child: Text(
                  formaterMontant(
                    verrouille ? etat.plafondRetenuUnites : saisie,
                    etat.devise,
                  ),
                  key: const Key('dispo-plafond-montant'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: MefaliTokens.titleSize,
                    fontWeight: MefaliTokens.weightBold,
                    color: MefaliTokens.text,
                  ),
                ),
              ),
              if (!verrouille)
                IconButton.filledTonal(
                  key: const Key('dispo-plafond-plus'),
                  onPressed: () => onSaisie(saisie + pasPlafondUnites),
                  icon: const Icon(Symbols.add_rounded),
                ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space2),
          // ── Le plafond RETENU, et POURQUOI c'est lui (FR-010) ──────────
          Text(
            t.dispoPlafondRetenu(
              formaterMontant(etat.plafondRetenuUnites, etat.devise),
            ),
            key: const Key('dispo-plafond-retenu'),
            style: const TextStyle(
              fontSize: MefaliTokens.bodySize,
              fontWeight: MefaliTokens.weightSemiBold,
            ),
          ),
          Text(
            switch (etat.source) {
              SourcePlafond.grilleNote => t.dispoPlafondSourceGrille,
              SourcePlafond.declaration => t.dispoPlafondSourceDeclaration,
            },
            key: const Key('dispo-plafond-source'),
            style: const TextStyle(
              fontSize: MefaliTokens.captionSize,
              color: MefaliTokens.textMuted,
            ),
          ),
          Text(
            _libellePalier(t, etat.palierCle),
            key: const Key('dispo-palier'),
            style: const TextStyle(
              fontSize: MefaliTokens.captionSize,
              color: MefaliTokens.textMuted,
            ),
          ),
          // ── Reste disponible (FR-095) ──────────────────────────────────
          //
          // C'est le nombre qui dit à Yao s'il peut accepter la course
          // suivante. Sans lui, il découvrirait le refus au moment d'accepter,
          // sans comprendre pourquoi — le plafond affiché serait pourtant
          // « suffisant ».
          if (journee != null && journee!.connue) ...[
            const SizedBox(height: MefaliTokens.space1),
            Text(
              t.crsJourneeResteDisponible(
                formaterMontant(
                  journee!.resteDisponibleUnites,
                  journee!.devise.isEmpty ? etat.devise : journee!.devise,
                ),
              ),
              key: const Key('dispo-reste-disponible'),
              style: TextStyle(
                fontSize: MefaliTokens.captionSize,
                fontWeight: MefaliTokens.weightSemiBold,
                // À zéro, c'est un blocage à venir : il se voit.
                color: journee!.resteDisponibleUnites == 0
                    ? MefaliTokens.danger
                    : MefaliTokens.textMuted,
              ),
            ),
          ],
          if (!verrouille) ...[
            const SizedBox(height: MefaliTokens.space1),
            Text(
              t.dispoPlafondPas(formaterMontant(pasPlafondUnites, etat.devise)),
              style: const TextStyle(
                fontSize: MefaliTokens.captionSize,
                color: MefaliTokens.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Les gains du jour — display success (K1-1a, FR-091).
///
/// La somme est celle des **parts coursier du devis figé** (cycle 007) : jamais
/// un recalcul, sinon le gain bougerait après coup sous les yeux de Yao.
class _CarteGains extends StatelessWidget {
  const _CarteGains({required this.journee});

  final EtatJourneeVue journee;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _Carte(
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.payments_rounded,
                  size: 20, color: MefaliTokens.textMuted),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Text(
                  t.crsJourneeCoursesLivrees(journee.coursesLivrees),
                  key: const Key('dispo-gains-libelle'),
                  style: const TextStyle(
                    fontSize: MefaliTokens.bodySize,
                    color: MefaliTokens.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space1),
          Text(
            formaterMontant(journee.gainsUnites, journee.devise),
            key: const Key('dispo-gains-montant'),
            style: const TextStyle(
              fontSize: MefaliTokens.displaySize,
              height: MefaliTokens.displayHeight,
              fontWeight: MefaliTokens.weightBold,
              color: MefaliTokens.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Les deux tuiles de K1-1a : note du jour et taux d'acceptation.
///
/// La note reste un **tiret** tant qu'AVI n'est pas construit (FR-094) : le
/// cycle 009 avait tranché, l'absence vaut mieux qu'un 4,8 inventé. Le taux,
/// lui, est un compteur réellement tenu par le dispatch — mais absent tant
/// qu'aucune offre décidable n'a été émise, parce qu'un « 0 % » ferait croire à
/// Yao qu'il refuse tout.
class _TuilesNoteEtAcceptation extends StatelessWidget {
  const _TuilesNoteEtAcceptation({required this.journee});

  final EtatJourneeVue journee;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final taux = journee.tauxAcceptationPourcent;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Tuile(
            icone: Symbols.star_rounded,
            titre: t.crsJourneeNoteTitre,
            valeur: t.crsJourneeNoteAbsente,
            cle: const Key('dispo-note'),
          ),
        ),
        const SizedBox(width: MefaliTokens.space3),
        Expanded(
          child: _Tuile(
            icone: Symbols.check_rounded,
            titre: t.crsJourneeAcceptationTitre,
            valeur: taux == null
                ? t.crsJourneeNoteAbsente
                : t.crsJourneeAcceptationValeur(taux),
            cle: const Key('dispo-acceptation'),
          ),
        ),
      ],
    );
  }
}

/// Une tuile compacte « titre + valeur » (K1-1a).
class _Tuile extends StatelessWidget {
  const _Tuile({
    required this.icone,
    required this.titre,
    required this.valeur,
    required this.cle,
  });

  final IconData icone;
  final String titre;
  final String valeur;
  final Key cle;

  @override
  Widget build(BuildContext context) => _Carte(
        enfant: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 18, color: MefaliTokens.textMuted),
                const SizedBox(width: MefaliTokens.space1),
                Expanded(
                  child: Text(
                    titre,
                    style: const TextStyle(
                      fontSize: MefaliTokens.captionSize,
                      color: MefaliTokens.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MefaliTokens.space1),
            Text(
              valeur,
              key: cle,
              style: const TextStyle(
                fontSize: MefaliTokens.headingSize,
                fontWeight: MefaliTokens.weightBold,
              ),
            ),
          ],
        ),
      );
}

/// Raccourci vers la caisse depuis le tableau de bord (K1-1a, FR-096).
///
/// Affiché **seulement** quand de l'argent est engagé : une carte « 0 FCFA en
/// main » n'apprendrait rien et pousserait vers un écran vide. La navigation
/// basse, elle, mène toujours à la caisse.
class _RaccourciCaisse extends StatelessWidget {
  const _RaccourciCaisse({required this.montant, required this.onOuvrir});

  final String montant;
  final VoidCallback onOuvrir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return InkWell(
      key: const Key('dispo-raccourci-caisse'),
      onTap: onOuvrir,
      borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      child: _Carte(
        enfant: Row(
          children: [
            Container(
              width: MefaliTokens.tapMin,
              height: MefaliTokens.tapMin,
              decoration: const BoxDecoration(
                color: MefaliTokens.successTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Symbols.account_balance_wallet_rounded,
                  color: MefaliTokens.success),
            ),
            const SizedBox(width: MefaliTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.crsNavCaisse,
                    style: const TextStyle(
                      fontSize: MefaliTokens.headingSize,
                      fontWeight: MefaliTokens.weightSemiBold,
                    ),
                  ),
                  const SizedBox(height: MefaliTokens.space1),
                  Text(
                    t.crsCaisseRaccourci(montant),
                    style: const TextStyle(
                      fontSize: MefaliTokens.captionSize,
                      color: MefaliTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Symbols.chevron_right_rounded,
                color: MefaliTokens.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Traduit la clé de palier rendue par le serveur — jamais une chaîne en dur.
String _libellePalier(AppLocalizations t, String cle) => switch (cle) {
      'dispatch.palier.haut' => t.dispoPalierHaut,
      'dispatch.palier.intermediaire' => t.dispoPalierIntermediaire,
      _ => t.dispoPalierEntree,
    };

/// Refus métier du serveur, traduit par sa clé (constitution VII).
class _Erreur extends StatelessWidget {
  const _Erreur({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final message = switch (code) {
      'dossier_coursier_invalide' => t.dispoErreurDossier,
      'capacite_non_declaree' => t.dispoErreurCapacite,
      'course_active' => t.dispoErreurCourseActive,
      _ => t.dispoAucuneCourse,
    };
    return Container(
      key: const Key('dispo-erreur'),
      width: double.infinity,
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.dangerTint,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: MefaliTokens.bodySize,
          color: MefaliTokens.danger,
        ),
      ),
    );
  }
}

/// Carte blanche à bordure — la brique visuelle de K1.
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
