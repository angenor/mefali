import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import 'bandeau_livraison.dart';
import 'carte_arret.dart';
import 'checklist_articles.dart';
import 'ecran_scan.dart';
import 'etat_course.dart';
import 'feuille_arret_indisponible.dart';
import 'feuille_remplacement.dart';

/// Écran K3 — course active du coursier.
///
/// Réf. `docs/design/png/K3-course-active.png`. Widgets M3 thémés
/// `mefali_core` (constitution XI), constructeurs `.adaptive`.
///
/// Trois états, un seul écran : l'arrêt courant développé avec sa checklist
/// (1a), le même en mode hors-ligne (1b), et « en route vers le client » quand
/// tout est collecté (1c). La bascule est automatique — aucune action de Yao
/// n'est nécessaire pour passer de l'un à l'autre (FR-021).
class EcranCourseActive extends ConsumerWidget {
  /// Crée l'écran de course active. [entete] (optionnel) est rendu en tête du
  /// corps, DANS l'unique Scaffold — la bascule de rôle du coursier bi-rôle y
  /// passe sans imbriquer un second Scaffold.
  const EcranCourseActive({super.key, this.entete});

  /// Widget d'entête optionnel (ex. bascule de rôle).
  final Widget? entete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncEtat = ref.watch(etatCourseActiveProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.courseTitre)),
      body: SafeArea(
        child: Column(
          children: [
            if (entete != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MefaliTokens.screenMargin,
                  MefaliTokens.space3,
                  MefaliTokens.screenMargin,
                  0,
                ),
                child: entete,
              ),
            Expanded(
              child: asyncEtat.when(
                loading: () => const _ChargementCourse(),
                error: (_, _) => Center(child: Text(l10n.courseAucune)),
                data: (etat) => _CorpsCourse(etat: etat),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChargementCourse extends StatelessWidget {
  const _ChargementCourse();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(MefaliTokens.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Squelette(hauteur: 72),
          SizedBox(height: MefaliTokens.space3),
          Squelette(hauteur: 72),
        ],
      ),
    );
  }
}

class _CorpsCourse extends ConsumerWidget {
  const _CorpsCourse({required this.etat});

  final EtatCourse etat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (!etat.aUneCourse && etat.arrets.isEmpty) {
      return Center(
        child: Text(l10n.courseAucune, style: Theme.of(context).textTheme.bodyLarge),
      );
    }
    final enLigne = !etat.horsLigne;

    return Padding(
      padding: const EdgeInsets.all(MefaliTokens.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bandeau hors-ligne (FR-026, K3-1b) : « Actions enregistrées,
          // synchronisation auto ». Il dit ce qui CONTINUE de marcher, pas ce
          // qui est cassé — c'est la différence entre rassurer et inquiéter.
          if (etat.horsLigne) ...[
            BandeauHorsLigne(message: l10n.crsHorsLigneBandeau),
            const SizedBox(height: MefaliTokens.space2),
          ],
          if (etat.actionsEnAttente > 0) ...[
            _CompteurFile(etat: etat),
            const SizedBox(height: MefaliTokens.space2),
          ],
          Expanded(
            child: etat.toutCollecte
                ? BandeauLivraison(
                    etat: etat,
                    enLigne: enLigne,
                    onArriveChezClient: () => _transition(ref, etat, 'arrive'),
                  )
                : _Collecte(etat: etat, enLigne: enLigne),
          ),
        ],
      ),
    );
  }

  Future<void> _transition(WidgetRef ref, EtatCourse etat, String action) async {
    final livraison = etat.livraisonId;
    final arret = etat.arretCourant;
    if (livraison == null || arret == null) return;
    await ref.read(etatCourseActiveProvider.notifier).transitionArret(
          livraisonId: livraison,
          arretId: arret.arretId,
          action: action,
        );
  }
}

/// Le compteur d'actions en attente (FR-083) — nombre et poids des photos.
///
/// Yao doit pouvoir répondre à « est-ce que c'est parti ? » sans deviner. Le
/// poids compte autant que le nombre : trois photos de 2 Mo sur un réseau de
/// marché, ce n'est pas la même attente que trois transitions.
class _CompteurFile extends StatelessWidget {
  const _CompteurFile({required this.etat});

  final EtatCourse etat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ko = etat.octetsPhotosEnAttente ~/ 1024;
    final texte = ko > 0
        ? l10n.crsActionsEnAttentePhotos(etat.actionsEnAttente, ko)
        : l10n.crsActionsEnAttente(etat.actionsEnAttente);
    return Row(
      children: [
        const Icon(Symbols.cloud_upload_rounded,
            size: 18, color: MefaliTokens.textMuted),
        const SizedBox(width: MefaliTokens.space1),
        Text(
          texte,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: MefaliTokens.textMuted),
        ),
      ],
    );
  }
}

/// La phase de collecte : arrêt courant développé, arrêts résolus repliés.
class _Collecte extends ConsumerWidget {
  const _Collecte({required this.etat, required this.enLigne});

  final EtatCourse etat;
  final bool enLigne;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final courant = etat.arretCourant;
    if (courant == null) return const SizedBox.shrink();
    final rang = etat.rangArretCourant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              // Arrêts DÉJÀ résolus, repliés avec leur heure (K3-1b).
              for (var i = 0; i < etat.arrets.length; i++)
                if (etat.arrets[i].collecte ||
                    etat.arrets[i].statut == 'indisponible') ...[
                  CarteArretReplie(arret: etat.arrets[i], rang: i + 1),
                  const SizedBox(height: MefaliTokens.space2),
                ],
              // L'arrêt COURANT, seul développé.
              CarteArretCourant(
                arret: courant,
                rang: rang,
                total: etat.arrets.length,
                enLigne: enLigne,
              ),
              const SizedBox(height: MefaliTokens.space2),
              if (courant.lignes.isNotEmpty) ...[
                ChecklistArticles(
                  lignes: courant.lignes,
                  devise: etat.devise,
                  onCocher: (ligne, cochee) => ref
                      .read(etatCourseActiveProvider.notifier)
                      .cocherArticle(ligne.ligneId, cochee: cochee),
                  onIndisponible: (ligne) =>
                      _declarerIndisponible(context, ref, ligne),
                ),
                const SizedBox(height: MefaliTokens.space2),
              ],
              MontantAPayer(
                nomVendeur: courant.nom,
                montantUnites: courant.montantAPayerUnites,
                devise: etat.devise,
                articlesPris: courant.lignes.any((l) => !l.aPayer)
                    ? courant.articlesPris
                    : null,
              ),
              const SizedBox(height: MefaliTokens.space2),
              // Arrêts à venir, repliés eux aussi.
              for (var i = 0; i < etat.arrets.length; i++)
                if (!etat.arrets[i].collecte &&
                    etat.arrets[i].statut != 'indisponible' &&
                    etat.arrets[i].arretId != courant.arretId) ...[
                  CarteArretReplie(arret: etat.arrets[i], rang: i + 1),
                  const SizedBox(height: MefaliTokens.space2),
                ],
              TextButton.icon(
                onPressed: () => _arretImpossible(context, ref, courant),
                icon: const Icon(Symbols.block_rounded),
                label: Text(l10n.crsArretIndisponibleTitre),
              ),
            ],
          ),
        ),
        const SizedBox(height: MefaliTokens.space3),
        // Le scan reste VISIBLEMENT actif hors ligne : c'est l'action la plus
        // importante de l'écran, et elle n'a jamais eu besoin du réseau (R6).
        BoutonPrincipal(
          libelle: l10n.crsScannerQrVendeur,
          picto: Symbols.qr_code_scanner,
          onPresse: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => EcranScan(arret: courant)),
          ),
        ),
        if (!enLigne) ...[
          const SizedBox(height: MefaliTokens.space2),
          Text(
            l10n.crsHorsLigneScanEtCoches,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: MefaliTokens.textMuted),
          ),
        ],
      ],
    );
  }

  /// Déclare une ligne indisponible. La suite dépend de ce que le CLIENT a
  /// choisi : proposer un remplacement (photo + prix), l'appeler, ou retirer.
  Future<void> _declarerIndisponible(
    BuildContext context,
    WidgetRef ref,
    LigneChecklistVue ligne,
  ) async {
    final livraison = etat.livraisonId;
    if (livraison == null) return;
    final notifier = ref.read(etatCourseActiveProvider.notifier);

    if (ligne.preference == 'remplacer') {
      final proposition =
          await FeuilleRemplacement.ouvrir(context, ligne.libelle);
      if (proposition == null) return;
      await notifier.declarerLigneIndisponible(
        livraisonId: livraison,
        ligneId: ligne.ligneId,
        resolution: 'remplacer',
        prixProposeUnites: proposition.prixUnites,
        photo: proposition.photo,
      );
      return;
    }
    // `appeler` et `retirer` : le serveur applique la préférence du client. On
    // n'envoie PAS de résolution — le défaut sûr est le retrait, et on ne fait
    // jamais payer par défaut.
    await notifier.declarerLigneIndisponible(
      livraisonId: livraison,
      ligneId: ligne.ligneId,
    );
  }

  Future<void> _arretImpossible(
    BuildContext context,
    WidgetRef ref,
    ArretCourse arret,
  ) async {
    final livraison = etat.livraisonId;
    if (livraison == null) return;
    final motif = await FeuilleArretIndisponible.ouvrir(context, arret.nom);
    if (motif == null) return;
    await ref.read(etatCourseActiveProvider.notifier).declarerArretIndisponible(
          livraisonId: livraison,
          arretId: arret.arretId,
          motif: motif,
        );
  }
}
