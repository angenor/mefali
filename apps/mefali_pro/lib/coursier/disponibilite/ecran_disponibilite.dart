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
/// **Hors périmètre, et c'est voulu** : les gains du jour, la note, le taux
/// d'acceptation et le raccourci Caisse de la maquette appartiennent à CRS-01
/// et AVI. Les afficher ici obligerait à inventer leurs données.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../l10n/app_localizations.dart';
import 'emetteur_position.dart';
import 'etat_disponibilite.dart';

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
@Dependencies([EmetteurPosition])
class EcranDisponibilite extends ConsumerStatefulWidget {
  /// Construit l'écran. [entete] (optionnel) est rendu en tête du corps, DANS
  /// l'unique `Scaffold` — la bascule de rôle du coursier bi-rôle y passe sans
  /// imbriquer un second `Scaffold` (patron d'`EcranCourseActive`, FR-046).
  const EcranDisponibilite({super.key, this.entete});

  /// Entête optionnel (bascule de rôle).
  final Widget? entete;

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

    final saisie = _saisie ?? etat.plafondDeclareUnites ?? plafondDefautUnites;

    return Scaffold(
      backgroundColor: MefaliTokens.background,
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
          ),
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
  });

  final EtatDisponibilite etat;
  final int saisie;
  final ValueChanged<int> onSaisie;

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
