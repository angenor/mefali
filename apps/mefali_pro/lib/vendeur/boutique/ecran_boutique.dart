import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import '../../roles/composants.dart';
import '../composants.dart';
import '../offre_livraison/etat_offre_livraison.dart';
import '../offre_livraison/feuille_offre_livraison.dart';
import '../pilotage.dart';
import 'etat_boutique.dart';
import 'feuille_horaires.dart';

/// Durées de pause proposées (maquette V1 : 30 min · 1 h · 2 h) et pas de
/// prolongation (+30) — constantes d'app MVP (spec, Assumptions).
const List<int> dureesPauseMinutes = [30, 60, 120];

/// Pas de prolongation d'une pause (maquette V1 : « + 30 min »).
const int pasProlongationMinutes = 30;

/// Écran V1 · Statut boutique (`docs/design/png/V1-statut-boutique.png`,
/// états 1a/1b/1c — FR-044). Ouvrir, fermer et mettre en pause en UN geste ;
/// la pause remplace l'interrupteur ; rappel non bloquant (FR-035).
class EcranBoutique extends ConsumerWidget {
  /// Crée l'écran.
  const EcranBoutique({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pilotage = ref.watch(pilotageProvider);

    return pilotage.when(
      loading: () => const SqueletteListe(),
      error: (_, _) => MessageEtat(
        texte: l10n.proBoutiqueErreur,
        picto: Symbols.wifi_off,
        action: () => ref.read(pilotageProvider.notifier).recharger(),
        libelleAction: l10n.proErreurAction,
      ),
      data: (pilote) {
        if (pilote == null) {
          return MessageEtat(
            texte: l10n.proArticlesSansPrestataire,
            picto: Symbols.storefront,
          );
        }
        return _Boutique(pilote: pilote);
      },
    );
  }
}

class _Boutique extends ConsumerWidget {
  const _Boutique({required this.pilote});

  final PrestatairePilotable pilote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final boutique = ref.watch(boutiqueProvider(pilote.id));

    return boutique.when(
      loading: () => const SqueletteListe(),
      error: (_, _) => MessageEtat(
        texte: l10n.proBoutiqueErreur,
        picto: Symbols.wifi_off,
        action: () =>
            ref.read(boutiqueProvider(pilote.id).notifier).recharger(),
        libelleAction: l10n.proErreurAction,
      ),
      data: (b) => _Contenu(pilote: pilote, boutique: b),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({required this.pilote, required this.boutique});

  final PrestatairePilotable pilote;
  final BoutiqueVendeur boutique;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final notifier = ref.read(boutiqueProvider(pilote.id).notifier);
    final enPause = boutique.statut == StatutBoutique.enPause;
    final effectifOuvert = boutique.etatEffectif.ouvert;

    final (etatTexte, etatTon) = enPause
        ? (l10n.proBoutiqueEnPause, TonPuce.avertissement)
        : effectifOuvert
            ? (l10n.proBoutiqueOuvert, TonPuce.succes)
            : (l10n.proBoutiqueFerme, TonPuce.danger);

    return ListView(
      children: [
        // En-tête : nom + puce d'état (maquette V1, commun aux trois états).
        CarteMefali(
          child: Row(
            children: [
              Expanded(
                child: Text(pilote.nom, style: textTheme.titleMedium),
              ),
              PuceStatut(texte: etatTexte, ton: etatTon),
            ],
          ),
        ),
        const SizedBox(height: MefaliTokens.space3),

        if (enPause)
          _CartePause(boutique: boutique, notifier: notifier)
        else ...[
          InterrupteurBoutique(
            ouvert: boutique.statut == StatutBoutique.ouvert,
            onOuvrir: () => notifier.geste(ActionBoutiqueDto.ouvrir),
            onFermer: () => notifier.geste(ActionBoutiqueDto.fermer),
          ),
          const SizedBox(height: MefaliTokens.space2),
          Row(
            children: [
              Icon(
                effectifOuvert ? Symbols.storefront : Symbols.visibility_off,
                size: 20,
                color:
                    effectifOuvert ? MefaliTokens.success : MefaliTokens.danger,
              ),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Text(
                  effectifOuvert
                      ? l10n.proBoutiqueAideOuverte
                      : l10n.proBoutiqueAideFermee,
                  style: textTheme.labelSmall?.copyWith(
                    color: effectifOuvert
                        ? MefaliTokens.success
                        : MefaliTokens.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space3),

          // FR-035 — rappel non bloquant (état 1c).
          if (boutique.rappelOuverture) ...[
            _CarteRappel(notifier: notifier),
            const SizedBox(height: MefaliTokens.space3),
          ],

          // Pause temporisée (état 1a) — proposée quand l'interrupteur est
          // sur ouvert.
          if (boutique.statut == StatutBoutique.ouvert) ...[
            CarteMefali(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Symbols.schedule, size: 20),
                      const SizedBox(width: MefaliTokens.space2),
                      Expanded(
                        child: Text(
                          l10n.proBoutiquePauseTitre,
                          style: textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MefaliTokens.space1),
                  Text(
                    l10n.proBoutiquePauseAide,
                    style: textTheme.labelSmall
                        ?.copyWith(color: MefaliTokens.textMuted),
                  ),
                  const SizedBox(height: MefaliTokens.space2),
                  Row(
                    children: [
                      for (final duree in dureesPauseMinutes) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => notifier.geste(
                              ActionBoutiqueDto.mettreEnPause,
                              dureeMinutes: duree,
                            ),
                            child: Text(l10n.proBoutiqueDuree(_duree(duree))),
                          ),
                        ),
                        if (duree != dureesPauseMinutes.last)
                          const SizedBox(width: MefaliTokens.space2),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: MefaliTokens.space3),
          ],
        ],
        if (enPause) const SizedBox(height: MefaliTokens.space3),

        _CarteHoraires(boutique: boutique, notifier: notifier),
        const SizedBox(height: MefaliTokens.space3),

        // VND-08 minimal (cycle PAY 011) — le vendeur décide s'il prend la
        // livraison à sa charge. Le réglage vit ici, à côté des horaires : ce
        // sont les deux décisions commerciales que le vendeur pilote seul.
        _CarteOffreLivraison(pilote: pilote),
        const SizedBox(height: MefaliTokens.space4),

        if (enPause)
          BoutonPrincipal(
            libelle: l10n.proBoutiqueReouvrir,
            picto: Symbols.check,
            onPresse: () => notifier.geste(ActionBoutiqueDto.ouvrir),
          ),
      ],
    );
  }
}

/// Le réglage d'offre de livraison (VND-08, FR-046) — état courant en clair,
/// et la feuille pour le changer.
///
/// Réf. `docs/design/png/V1-statut-boutique.png` (carte de réglage voisine des
/// horaires) ; ⚠ **écart assumé** : aucune planche VND-08 n'existe.
class _CarteOffreLivraison extends ConsumerWidget {
  const _CarteOffreLivraison({required this.pilote});

  final PrestatairePilotable pilote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final seuil = pilote.offreLivraisonSeuilUnites;

    final resume = switch (pilote.offreLivraison) {
      'toujours' => l10n.payOffreToujours,
      'au_dela' when seuil != null =>
        '${l10n.payOffreAuDela} (${formaterMontant(seuil, 'XOF')})',
      _ => l10n.payOffreJamais,
    };

    return CarteMefali(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.local_shipping, size: 20),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Text(
                  l10n.payOffreLivraisonTitre,
                  style: textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space2),
          Text(
            resume,
            style: textTheme.bodyLarge
                ?.copyWith(fontWeight: MefaliTokens.weightSemiBold),
          ),
          const SizedBox(height: MefaliTokens.space2),
          OutlinedButton.icon(
            onPressed: () => afficherFeuilleOffreLivraison(
              context,
              offre: pilote.offreLivraison,
              seuilUnites: seuil,
              devise: 'XOF',
              onEnregistrer: (offre, seuilUnites) => ref
                  .read(offreLivraisonProvider(pilote.id).notifier)
                  .declarer(offre, seuilUnites)
                  .then((code) => code == null
                      ? null
                      : (code == 'offre_seuil_manquant'
                          ? l10n.payOffreSeuilManquant
                          : l10n.proBoutiqueErreur)),
            ),
            icon: const Icon(Symbols.edit),
            label: Text(l10n.payOffreLivraisonModifier),
          ),
        ],
      ),
    );
  }
}

/// « 30 min », « 1 h », « 2 h » — libellés des durées de pause.
String _duree(int minutes) =>
    minutes < 60 ? '$minutes min' : '${minutes ~/ 60} h';

/// État 1b — la pause REMPLACE l'interrupteur : échéance en display,
/// prolonger, fermer pour la journée.
class _CartePause extends StatelessWidget {
  const _CartePause({required this.boutique, required this.notifier});

  final BoutiqueVendeur boutique;
  final Boutique notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final echeance = boutique.pauseFin?.toLocal();
    final minutes = echeance == null
        ? 0
        : echeance.difference(DateTime.now()).inMinutes.clamp(0, 720);

    return Container(
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.warningTint,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
        border: Border.all(color: MefaliTokens.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Symbols.pause_circle, size: 20),
              const SizedBox(width: MefaliTokens.space2),
              Text(l10n.proBoutiquePauseEnCours, style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: MefaliTokens.space1),
          Text(
            l10n.proBoutiqueAideFermee,
            style: textTheme.labelSmall?.copyWith(color: MefaliTokens.textMuted),
          ),
          const SizedBox(height: MefaliTokens.space3),
          Container(
            padding: const EdgeInsets.all(MefaliTokens.space3),
            decoration: BoxDecoration(
              color: MefaliTokens.surface,
              borderRadius: BorderRadius.circular(MefaliTokens.radiusButton),
            ),
            child: Column(
              children: [
                Text(
                  l10n.proBoutiqueReouvertureDans,
                  style: textTheme.labelSmall
                      ?.copyWith(color: MefaliTokens.textMuted),
                ),
                Text(
                  l10n.proBoutiqueMinutes(minutes),
                  style: textTheme.displayLarge?.copyWith(
                    color: MefaliTokens.primary,
                    fontSize: 32,
                  ),
                ),
                if (echeance != null)
                  Text(
                    l10n.proBoutiqueAHeure(DateFormat.Hm().format(echeance)),
                    style: textTheme.labelSmall
                        ?.copyWith(color: MefaliTokens.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(height: MefaliTokens.space3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => notifier.geste(
                    ActionBoutiqueDto.prolongerPause,
                    dureeMinutes: pasProlongationMinutes,
                  ),
                  child: Text(l10n.proBoutiqueProlonger),
                ),
              ),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      notifier.geste(ActionBoutiqueDto.fermerPourLaJournee),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MefaliTokens.danger,
                  ),
                  child: Text(l10n.proBoutiqueFermerJournee),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// État 1c — rappel doux : « Ouvrir maintenant » / « Je reste fermé ».
class _CarteRappel extends StatelessWidget {
  const _CarteRappel({required this.notifier});

  final Boutique notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.warningTint,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Symbols.warning, size: 20, color: MefaliTokens.warning),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Text(
                  l10n.proBoutiqueRappel(
                    DateFormat.Hm().format(DateTime.now()),
                  ),
                  style: textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space2),
          FilledButton.icon(
            onPressed: () => notifier.geste(ActionBoutiqueDto.ouvrir),
            style: FilledButton.styleFrom(
              backgroundColor: MefaliTokens.success,
            ),
            icon: const Icon(Symbols.check),
            label: Text(l10n.proBoutiqueOuvrirMaintenant),
          ),
          TextButton(
            onPressed: () =>
                notifier.geste(ActionBoutiqueDto.fermerPourLaJournee),
            child: Text(l10n.proBoutiqueResterFerme),
          ),
        ],
      ),
    );
  }
}

/// Carte des horaires habituels + accès à leur modification (FR-034).
class _CarteHoraires extends StatelessWidget {
  const _CarteHoraires({required this.boutique, required this.notifier});

  final BoutiqueVendeur boutique;
  final Boutique notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final plages = boutique.horairesDuJour;
    // `proBoutiqueAujourdhui` SUFFIXE déjà « aujourd'hui » à ce qu'on lui passe :
    // un jour sans plage prend donc sa propre clé, sinon on rendrait
    // « Fermé aujourd'hui aujourd'hui ».
    final duJour = plages.isEmpty
        ? l10n.proBoutiqueFermeAujourdhui
        : l10n.proBoutiqueAujourdhui(
            plages.map((p) => '${p.debut} — ${p.fin}').join(' · '),
          );

    return CarteMefali(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.schedule, size: 20),
              const SizedBox(width: MefaliTokens.space2),
              // `Expanded` : sur un écran de 360 dp — la largeur d'un téléphone
              // d'entrée de gamme, donc la cible — le titre débordait de 57 px.
              // Trouvé par le test de la carte d'offre de livraison, qui a
              // ramené la vue à une taille réaliste.
              Expanded(
                child: Text(
                  l10n.proBoutiqueHorairesTitre,
                  style: textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space2),
          Text(
            duJour,
            style: textTheme.bodyLarge
                ?.copyWith(fontWeight: MefaliTokens.weightSemiBold),
          ),
          const SizedBox(height: MefaliTokens.space2),
          OutlinedButton.icon(
            onPressed: () => afficherFeuilleHoraires(
              context,
              horaires: boutique.horaires,
              onEnregistrer: notifier.modifierHoraires,
            ),
            icon: const Icon(Symbols.edit),
            label: Text(l10n.proBoutiqueChangerHoraires),
          ),
        ],
      ),
    );
  }
}
