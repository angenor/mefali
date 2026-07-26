/// Écran **adresse et paiement** (CMD-02 + CMD-03, US2 et US3).
///
/// Réf. `docs/design/png/C3-panier-multi-vendeurs.png` — cadres **3a′**
/// (adresse et paiement) et **3b** (montant au-dessus du plafond cash), puis la
/// confirmation qui remet immédiatement le **code et le QR**.
///
/// Widgets Material 3 thémés par `mefali_core` depuis `docs/design/tokens.md` ;
/// aucune chaîne utilisateur en dur (constitutions VII et XI) ; état en
/// Riverpod codegen (constitution XII).
///
/// Deux règles de la maquette que cet écran tient littéralement :
/// - le cash grisé montre **sa raison**, jamais un bouton mort — une option
///   désactivée sans explication fait croire à une panne ;
/// - l'appoint exact est écrit en toutes lettres : c'est ce qui évite la
///   scène du billet de 10 000 devant un coursier sans monnaie (§7.5-5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import 'bloc_scission.dart';
import 'etat_confirmation.dart';
import 'etat_panier.dart';

/// Écran de saisie d'adresse, choix du paiement, puis confirmation.
class EcranAdressePaiement extends ConsumerWidget {
  /// Crée l'écran.
  const EcranAdressePaiement({
    this.onPositionActuelle,
    this.onChangerAdresse,
    this.onConfirmer,
    this.onSuivre,
    this.libelleSuivre,
    this.capturerNote,
    super.key,
  });

  /// « Utiliser ma position actuelle » (GPS de l'appareil).
  final VoidCallback? onPositionActuelle;

  /// Ouvre le carnet d'adresses (CPT-05) pour réutiliser une adresse.
  final VoidCallback? onChangerAdresse;

  /// Confirme la commande (`POST /commandes` avec sa clé d'idempotence).
  final VoidCallback? onConfirmer;

  /// Passage au suivi d'UNE commande créée (C3 → C4). Absent, l'écran de
  /// confirmation s'en tient aux codes et aux QR : c'est déjà l'essentiel.
  ///
  /// Reçoit l'identifiant : une scission acceptée en crée N, et chacune a son
  /// propre suivi. Un rappel sans argument obligerait l'écran à en désigner une
  /// arbitrairement.
  final void Function(String commandeId)? onSuivre;

  /// Libellé de [onSuivre], résolu par l'appelant — le paquet cœur n'a pas de
  /// clé pour une navigation qui appartient à l'app (constitution VII).
  final String? libelleSuivre;

  /// Capture d'une note vocale — doublée par les tests.
  final CapturerNote? capturerNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final saisie = ref.watch(confirmationProvider);
    final panier = ref.watch(panierProvider);

    // Ce qui va être commandé : un devis, ou les N devis d'une scission
    // acceptée. Le second cas porte ses N frais de déplacement — le devis
    // d'ensemble n'en connaîtrait qu'un (C3-3d).
    final commandes = panier.scissionAcceptee
        ? [for (final t in panier.troncons) t.devis]
        : [if (panier.devis != null) panier.devis!];

    // Après confirmation, l'écran ne montre plus qu'une chose : les codes et
    // les QR. C'est ce que la cliente est venue chercher, et c'est ce qui doit
    // rester lisible même si le réseau tombe à la seconde suivante (R6).
    final creees = saisie.commandesCreees;
    if (creees.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.commandeConfirmee)),
        body: ListView(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          children: [
            // Échec partiel : ce qui manque se dit AVANT les codes de ce qui
            // est passé. Le panier ne contient déjà plus que le reste.
            if (panier.scissionAcceptee) ...[
              BlocRepriseScission(
                creees: creees.length,
                restants: panier.troncons.length,
                onReprendre: onConfirmer,
              ),
              const SizedBox(height: MefaliTokens.space4),
            ],
            for (var i = 0; i < creees.length; i++) ...[
              // Le rang n'apparaît que s'il y en a plusieurs : sur une commande
              // unique, « Commande 1 » n'apprend rien.
              if (creees.length > 1) ...[
                Text(
                  l10n.panierScissionCommandeNumero(i + 1),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MefaliTokens.space2),
              ],
              BlocRemise(
                jetonReception: creees[i].jetonReception,
                codeLivraison: creees[i].codeLivraison,
              ),
              const SizedBox(height: MefaliTokens.space3),
              Center(
                child: Text(
                  formaterMontant(creees[i].totalUnites, creees[i].devise),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (onSuivre != null && libelleSuivre != null) ...[
                const SizedBox(height: MefaliTokens.space4),
                FilledButton(
                  onPressed: () => onSuivre!(creees[i].id),
                  child: Text(libelleSuivre!),
                ),
              ],
              const SizedBox(height: MefaliTokens.space4),
            ],
          ],
        ),
      );
    }

    final totalUnites =
        commandes.fold(0, (total, d) => total + d.totalUnites);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commandeAdresseTitre)),
      body: ListView(
        padding: const EdgeInsets.all(MefaliTokens.screenMargin),
        children: [
          // Rappel de la scission acceptée : N commandes, N frais de
          // déplacement, dits une dernière fois AVANT le geste qui engage.
          if (panier.scissionAPresenter) ...[
            BlocScissionAcceptee(troncons: panier.troncons),
            const SizedBox(height: MefaliTokens.space3),
          ],
          _CarteAdresse(
            saisie: saisie,
            onPositionActuelle: onPositionActuelle,
            onChangerAdresse: onChangerAdresse,
          ),
          const SizedBox(height: MefaliTokens.space3),
          _CarteRepere(saisie: saisie, capturerNote: capturerNote),
          const SizedBox(height: MefaliTokens.space3),
          if (commandes.isNotEmpty)
            _CartePaiement(commandes: commandes, saisie: saisie),
          const SizedBox(height: MefaliTokens.space4),
          FilledButton(
            // Le bouton est désarmé tant que le repère manque : mieux vaut une
            // action visiblement indisponible qu'un `422` après coup.
            onPressed: saisie.pretAConfirmer ? onConfirmer : null,
            child: Text(
              commandes.isEmpty
                  ? l10n.panierCommander
                  : '${l10n.panierCommander} · '
                      '${formaterMontant(totalUnites, commandes.first.devise)}',
            ),
          ),
        ],
      ),
    );
  }
}

/// Le pin GPS et sa réutilisation depuis le carnet (C3-3a′).
class _CarteAdresse extends StatelessWidget {
  const _CarteAdresse({
    required this.saisie,
    this.onPositionActuelle,
    this.onChangerAdresse,
  });

  final EtatConfirmation saisie;
  final VoidCallback? onPositionActuelle;
  final VoidCallback? onChangerAdresse;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.home_rounded),
                const SizedBox(width: MefaliTokens.space2),
                Expanded(
                  child: Text(
                    saisie.lat == null
                        ? l10n.commandeAdresseTitre
                        : '${saisie.lat!.toStringAsFixed(5)}, '
                            '${saisie.lon!.toStringAsFixed(5)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (onChangerAdresse != null)
                  TextButton(
                    onPressed: onChangerAdresse,
                    child: Text(l10n.commandeAdresseChanger),
                  ),
              ],
            ),
            const SizedBox(height: MefaliTokens.space2),
            OutlinedButton.icon(
              onPressed: onPositionActuelle,
              icon: const Icon(Symbols.my_location_rounded),
              label: Text(l10n.commandeAdressePositionActuelle),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le repère, en TEXTE ou en VOCAL — l'un des deux suffit (FR-018).
class _CarteRepere extends ConsumerWidget {
  const _CarteRepere({required this.saisie, this.capturerNote});

  final EtatConfirmation saisie;
  final CapturerNote? capturerNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notifier = ref.read(confirmationProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.commandeAdresseRepereAide, style: theme.textTheme.bodySmall),
            const SizedBox(height: MefaliTokens.space2),
            SegmentedButton<ModeRepere>(
              segments: [
                ButtonSegment(
                  value: ModeRepere.texte,
                  label: Text(l10n.commandeAdresseRepereTexte),
                  icon: const Icon(Symbols.notes_rounded),
                ),
                ButtonSegment(
                  value: ModeRepere.vocal,
                  label: Text(l10n.commandeAdresseRepereVocal),
                  icon: const Icon(Symbols.mic_rounded),
                ),
              ],
              selected: {saisie.mode},
              onSelectionChanged: (s) => notifier.changerMode(s.first),
            ),
            const SizedBox(height: MefaliTokens.space3),
            if (saisie.mode == ModeRepere.texte)
              TextField(
                onChanged: notifier.saisirRepere,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.commandeAdresseRepereTexte,
                  // Le compteur rend la règle VISIBLE : le nombre vient de la
                  // configuration de zone, jamais d'une constante d'app.
                  counterText:
                      '${saisie.repereTexte.trim().length} / ${saisie.repereMinCaracteres}',
                ),
              )
            else
              EnregistreurNoteVocale(
                onCapturee: notifier.poserNoteVocale,
                dureeMaxS: 30,
                note: saisie.noteVocale,
                capturer: capturerNote,
              ),
          ],
        ),
      ),
    );
  }
}

/// Le choix du paiement (C3-3a′ et C3-3b).
class _CartePaiement extends ConsumerWidget {
  const _CartePaiement({required this.commandes, required this.saisie});

  /// Les devis des commandes à payer : un seul, ou les N d'une scission
  /// acceptée. Le mode de paiement, lui, est commun aux N.
  final List<DevisPanierVue> commandes;

  final EtatConfirmation saisie;

  /// Le cash n'est proposé que s'il l'est pour CHAQUE commande : un mode refusé
  /// sur l'une bloquerait la série entière au moment de créer.
  bool get _cashAutorise => commandes.every((d) => d.cashAutorise);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notifier = ref.read(confirmationProvider.notifier);
    final devis = commandes.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.commandePaiementTitre, style: theme.textTheme.titleMedium),
            const SizedBox(height: MefaliTokens.space2),

            // C3-3b — le cash grisé montre SA RAISON. Un bouton désactivé sans
            // explication fait croire à une panne de l'app.
            if (!_cashAutorise) ...[
              Container(
                padding: const EdgeInsets.all(MefaliTokens.space3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
                ),
                child: Row(
                  children: [
                    Icon(Symbols.warning_rounded,
                        color: theme.colorScheme.onSecondaryContainer),
                    const SizedBox(width: MefaliTokens.space2),
                    Expanded(
                      child: Text(
                        l10n.commandePaiementCashIndisponible(
                          formaterMontant(devis.plafondUnites, devis.devise),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MefaliTokens.space2),
            ],

            RadioGroup<String>(
              groupValue: saisie.modePaiement,
              onChanged: (v) {
                if (v != null) notifier.choisirPaiement(v);
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'cash',
                    // Cash au-dessus du plafond : l'option reste VISIBLE mais
                    // inerte, avec sa raison juste au-dessus. La faire
                    // disparaître laisserait la cliente chercher une option
                    // qu'elle a déjà utilisée hier.
                    enabled: _cashAutorise,
                    title: Text(l10n.commandePaiementCash),
                    // L'APPOINT EXACT, en toutes lettres : c'est lui qui évite
                    // la scène du gros billet devant un coursier sans monnaie
                    // (§7.5-5). UN appoint par commande : deux livraisons sont
                    // deux paiements, pas un règlement groupé.
                    subtitle: !_cashAutorise
                        ? null
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < commandes.length; i++)
                                Text(
                                  commandes.length == 1
                                      ? l10n.commandePaiementAppoint(
                                          formaterMontant(
                                            commandes[i].totalUnites,
                                            commandes[i].devise,
                                          ),
                                        )
                                      : '${l10n.panierScissionCommandeNumero(i + 1)}'
                                          ' · '
                                          '${l10n.commandePaiementAppoint(formaterMontant(commandes[i].totalUnites, commandes[i].devise))}',
                                ),
                            ],
                          ),
                  ),
                  RadioListTile<String>(
                    value: 'mobile_money',
                    title: Text(l10n.commandePaiementMobileMoney),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
