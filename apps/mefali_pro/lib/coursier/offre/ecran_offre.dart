/// Écran **K2 — offre de course** (DSP-04).
///
/// Cible : `docs/design/png/K2-offre-course.png`, valeurs exactes de
/// `docs/design/tokens.md`. Plein écran, décision **à une main** en bas.
///
/// Ce que l'écran doit rendre évident en 40 secondes :
///
/// - le **compte à rebours**, sur bandeau sombre (contraste plein soleil) ;
/// - les **arrêts numérotés** avec leurs distances inter-arrêts ;
/// - la **destination approximative**, avec la mention « adresse exacte après
///   acceptation » : avant d'accepter, Yao ne voit aucune coordonnée du client ;
/// - le **gain** en display `--success` et l'**avance** en display `--danger`
///   sur fond teinté — les deux montants dominent l'écran, parce que ce sont
///   eux qui décident.
///
/// ⚠ Le **compte à rebours est un état LOCAL du widget** (constitution XII, qui
/// le nomme explicitement). Son autorité reste `echeance_le`, rendu par le
/// serveur : le widget compte, le serveur tranche. Reconstruire l'écran avec une
/// échéance dépassée affiche K2-1b **sans aucun appel réseau**.
///
/// **Écart assumé avec la maquette**, à porter au produit : K2 affiche
/// « quartier Sokoura ». Aucun quartier n'existe en donnée —
/// `TypeZone::Quartier` est une PROVISION (constitution IX). L'écran affiche
/// donc le nom de la ville.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import 'etat_offre.dart';

/// Plafond de non-réponses franches affiché dans K2-1b (« n sur 3 »).
///
/// Miroir d'affichage de `dispatch.timeouts_francs_par_jour` : le serveur seul
/// décide de la franchise, l'écran ne fait que la dire.
const int francsParJourAffiches = 3;

/// L'écran K2.
class EcranOffre extends ConsumerStatefulWidget {
  /// Construit l'écran.
  const EcranOffre({super.key});

  @override
  ConsumerState<EcranOffre> createState() => _EcranOffreState();
}

class _EcranOffreState extends ConsumerState<EcranOffre> {
  /// Tic du compte à rebours — **local**, jamais providerifié.
  Timer? _tic;

  /// Instant courant, rafraîchi chaque seconde. C'est le seul état que le
  /// compte à rebours a besoin de porter : le reste vient de `echeance_le`.
  DateTime _maintenant = DateTime.now().toUtc();

  /// Code du dernier refus (`deja_prise`, `offre_echue`), ou `null`.
  String? _refus;

  /// Secondes écoulées depuis le dernier rechargement de l'offre.
  int _depuisRechargement = 0;

  @override
  void initState() {
    super.initState();
    // UNE horloge pour deux besoins : le compte à rebours (chaque seconde) et
    // l'interrogation de l'offre (toutes les `periodeInterrogation`). Deux
    // minuteurs, ou un minuteur côté provider, seraient deux choses de plus à
    // annuler — et c'est exactement ce qu'on oublie.
    _tic = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _maintenant = DateTime.now().toUtc();
        _depuisRechargement += 1;
      });
      if (_depuisRechargement >= periodeInterrogation.inSeconds) {
        _depuisRechargement = 0;
        ref.invalidate(offreEnCoursProvider);
      }
    });
  }

  @override
  void dispose() {
    _tic?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final offre = ref.watch(offreEnCoursProvider);

    return Scaffold(
      backgroundColor: MefaliTokens.background,
      body: SafeArea(
        child: offre.when(
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (_, _) => _Expiree(
            titre: t.offreTempsEcoule,
            corps: t.offreDejaPriseTexte,
            francs: 1,
          ),
          data: (offre) {
            // K2-1b sans aucun appel réseau : l'échéance suffit à trancher.
            if (offre == null || offre.estEchue(_maintenant) || _refus != null) {
              return _Expiree(
                titre: _refus == 'deja_prise'
                    ? t.offreDejaPriseTitre
                    : t.offreTempsEcoule,
                corps: t.offreDejaPriseTexte,
                francs: 1,
              );
            }
            return _Offre(
              offre: offre,
              restantS: offre.restantS(_maintenant),
              onAccepter: () async {
                final decision =
                    await ref.read(offreEnCoursProvider.notifier).accepter();
                if (!decision.acceptee && mounted) {
                  setState(() => _refus = decision.codeErreur ?? 'deja_prise');
                }
              },
              onRefuser: () => ref.read(offreEnCoursProvider.notifier).refuser(),
            );
          },
        ),
      ),
    );
  }
}

/// L'offre elle-même (K2-1a).
class _Offre extends StatelessWidget {
  const _Offre({
    required this.offre,
    required this.restantS,
    required this.onAccepter,
    required this.onRefuser,
  });

  final OffreCourante offre;
  final int restantS;
  final Future<void> Function() onAccepter;
  final Future<void> Function() onRefuser;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        _Bandeau(restantS: restantS, nbArrets: offre.arrets.length),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(MefaliTokens.screenMargin),
            children: [
              _CarteArrets(offre: offre),
              const SizedBox(height: MefaliTokens.space3),
              _CarteGain(offre: offre),
              const SizedBox(height: MefaliTokens.space3),
              _CarteAvance(offre: offre),
              if (offre.degraded) ...[
                const SizedBox(height: MefaliTokens.space2),
                Text(
                  t.offreDistancesEstimees,
                  key: const Key('offre-degrade'),
                  style: const TextStyle(
                    fontSize: MefaliTokens.captionSize,
                    color: MefaliTokens.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Décision à une main, en BAS : c'est là que le pouce arrive.
        Padding(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: MefaliTokens.buttonHeight,
                child: FilledButton.icon(
                  key: const Key('offre-accepter'),
                  onPressed: onAccepter,
                  icon: const Icon(Symbols.check_rounded),
                  label: Text(
                    t.offreAccepter(
                      formaterMontant(offre.gainTotalUnites, offre.devise),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: MefaliTokens.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: MefaliTokens.space2),
              SizedBox(
                width: double.infinity,
                height: MefaliTokens.buttonHeight,
                child: OutlinedButton.icon(
                  key: const Key('offre-refuser'),
                  onPressed: onRefuser,
                  icon: const Icon(Symbols.close_rounded),
                  label: Text(t.offreRefuser),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bandeau sombre avec le compte à rebours (contraste plein soleil).
class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.restantS, required this.nbArrets});

  final int restantS;
  final int nbArrets;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      color: MefaliTokens.text,
      padding: const EdgeInsets.all(MefaliTokens.space3),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MefaliTokens.primary, width: 3),
            ),
            child: Text(
              '$restantS',
              key: const Key('offre-compte-a-rebours'),
              style: const TextStyle(
                fontSize: MefaliTokens.titleSize,
                fontWeight: MefaliTokens.weightBold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: MefaliTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.offreTitre,
                  style: const TextStyle(
                    fontSize: MefaliTokens.headingSize,
                    fontWeight: MefaliTokens.weightSemiBold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  t.offreSousTitre(nbArrets),
                  style: const TextStyle(
                    fontSize: MefaliTokens.captionSize,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Les arrêts numérotés et la destination approximative.
class _CarteArrets extends StatelessWidget {
  const _CarteArrets({required this.offre});

  final OffreCourante offre;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _Carte(
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final arret in offre.arrets)
            Padding(
              padding: const EdgeInsets.only(bottom: MefaliTokens.space2),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: MefaliTokens.primary,
                    child: Text(
                      '${arret.ordre}',
                      style: const TextStyle(
                        fontSize: MefaliTokens.captionSize,
                        fontWeight: MefaliTokens.weightBold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: MefaliTokens.space2),
                  Expanded(
                    child: Text(
                      arret.nom,
                      style: const TextStyle(
                        fontSize: MefaliTokens.bodySize,
                        fontWeight: MefaliTokens.weightSemiBold,
                      ),
                    ),
                  ),
                  Text(
                    arret.ordre == 1
                        ? t.offreDistanceDepart(_distance(arret.distanceM))
                        : t.offreDistanceSuivante(_distance(arret.distanceM)),
                    style: const TextStyle(
                      fontSize: MefaliTokens.captionSize,
                      color: MefaliTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          Row(
            children: [
              const Icon(Symbols.location_on_rounded, color: MefaliTokens.success),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.offreDestination(offre.zoneNom),
                      key: const Key('offre-destination'),
                      style: const TextStyle(
                        fontSize: MefaliTokens.bodySize,
                        fontWeight: MefaliTokens.weightSemiBold,
                      ),
                    ),
                    // La mention qui rend le manque d'adresse compréhensible :
                    // ce n'est pas une donnée absente, c'est une donnée qui
                    // arrive après (ARTCI).
                    Text(
                      t.offreAdresseApresAcceptation,
                      style: const TextStyle(
                        fontSize: MefaliTokens.captionSize,
                        color: MefaliTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _distance(offre.destinationDistanceM),
                style: const TextStyle(
                  fontSize: MefaliTokens.captionSize,
                  color: MefaliTokens.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Le gain, en display `--success`.
class _CarteGain extends StatelessWidget {
  const _CarteGain({required this.offre});

  final OffreCourante offre;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _Carte(
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.offreGainTotal,
            style: const TextStyle(
              fontSize: MefaliTokens.bodySize,
              color: MefaliTokens.textMuted,
            ),
          ),
          Text(
            formaterMontant(offre.gainTotalUnites, offre.devise),
            key: const Key('offre-gain'),
            style: const TextStyle(
              fontSize: MefaliTokens.displaySize,
              fontWeight: MefaliTokens.weightBold,
              color: MefaliTokens.success,
            ),
          ),
          Text(
            t.offreGainDetail(
              formaterMontant(offre.gainDeplacementUnites, offre.devise),
              formaterMontant(offre.gainArretsUnites, offre.devise),
              formaterMontant(offre.gainEffortUnites, offre.devise),
            ),
            style: const TextStyle(
              fontSize: MefaliTokens.captionSize,
              color: MefaliTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// L'avance, en display `--danger` sur fond teinté : c'est l'argent de Yao.
class _CarteAvance extends StatelessWidget {
  const _CarteAvance({required this.offre});

  final OffreCourante offre;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.dangerTint,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
        border: Border.all(color: MefaliTokens.danger),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.warning_rounded, color: MefaliTokens.danger, size: 20),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Text(
                  t.offreAvanceTitre,
                  style: const TextStyle(
                    fontSize: MefaliTokens.bodySize,
                    fontWeight: MefaliTokens.weightSemiBold,
                    color: MefaliTokens.danger,
                  ),
                ),
              ),
            ],
          ),
          Text(
            formaterMontant(offre.avanceUnites, offre.devise),
            key: const Key('offre-avance'),
            style: const TextStyle(
              fontSize: MefaliTokens.displaySize,
              fontWeight: MefaliTokens.weightBold,
              color: MefaliTokens.danger,
            ),
          ),
          Text(
            t.offreAvanceRembourse(
              formaterMontant(offre.plafondRetenuUnites, offre.devise),
            ),
            key: const Key('offre-plafond'),
            style: const TextStyle(
              fontSize: MefaliTokens.captionSize,
              color: MefaliTokens.danger,
            ),
          ),
        ],
      ),
    );
  }
}

/// **K2-1b** — temps écoulé ou course déjà prise. Ton NEUTRE, aucun blâme.
class _Expiree extends StatelessWidget {
  const _Expiree({required this.titre, required this.corps, required this.francs});

  final String titre;
  final String corps;
  final int francs;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: MefaliTokens.text,
          padding: const EdgeInsets.all(MefaliTokens.space3),
          child: Text(
            titre,
            key: const Key('offre-expiree-titre'),
            style: const TextStyle(
              fontSize: MefaliTokens.headingSize,
              fontWeight: MefaliTokens.weightSemiBold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(MefaliTokens.space4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Symbols.timer_rounded,
                    size: 48,
                    color: MefaliTokens.warning,
                  ),
                  const SizedBox(height: MefaliTokens.space3),
                  Text(
                    t.offreDejaPriseTitre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: MefaliTokens.titleSize,
                      fontWeight: MefaliTokens.weightSemiBold,
                    ),
                  ),
                  const SizedBox(height: MefaliTokens.space2),
                  Text(
                    corps,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: MefaliTokens.bodySize,
                      color: MefaliTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: MefaliTokens.space3),
                  // « Sans pénalité — n sur 3 aujourd'hui ». Le dire est ce qui
                  // évite qu'un coursier croie avoir été puni.
                  Chip(
                    key: const Key('offre-sans-penalite'),
                    avatar: const Icon(Symbols.check_rounded, size: 16),
                    label: Text(t.offreSansPenalite(francs, francsParJourAffiches)),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: SizedBox(
            width: double.infinity,
            height: MefaliTokens.buttonHeight,
            child: FilledButton.icon(
              key: const Key('offre-retour'),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Symbols.dashboard_rounded),
              label: Text(t.offreRetourTableau),
            ),
          ),
        ),
      ],
    );
  }
}

/// Carte blanche à bordure — la brique visuelle de K2.
class _Carte extends StatelessWidget {
  const _Carte({required this.enfant});

  final Widget enfant;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.surface,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
        border: Border.all(color: MefaliTokens.border),
      ),
      child: enfant,
    );
  }
}

/// Distance lisible : « 800 m » ou « 1,8 km ».
String _distance(int metres) {
  if (metres < 1000) return '$metres m';
  final km = (metres / 100).round() / 10;
  return '${km.toString().replaceAll('.', ',')} km';
}
