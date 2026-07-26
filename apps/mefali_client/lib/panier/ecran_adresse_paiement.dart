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

import 'etat_confirmation.dart';
import 'etat_panier.dart';

/// Écran de saisie d'adresse, choix du paiement, puis confirmation.
class EcranAdressePaiement extends ConsumerWidget {
  /// Crée l'écran.
  const EcranAdressePaiement({
    this.onPositionActuelle,
    this.onChangerAdresse,
    this.onConfirmer,
    this.capturerNote,
    super.key,
  });

  /// « Utiliser ma position actuelle » (GPS de l'appareil).
  final VoidCallback? onPositionActuelle;

  /// Ouvre le carnet d'adresses (CPT-05) pour réutiliser une adresse.
  final VoidCallback? onChangerAdresse;

  /// Confirme la commande (`POST /commandes` avec sa clé d'idempotence).
  final VoidCallback? onConfirmer;

  /// Capture d'une note vocale — doublée par les tests.
  final CapturerNote? capturerNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final saisie = ref.watch(confirmationProvider);
    final devis = ref.watch(panierProvider).devis;

    // Après confirmation, l'écran ne montre plus qu'une chose : le code et le
    // QR. C'est ce que la cliente est venue chercher, et c'est ce qui doit
    // rester lisible même si le réseau tombe à la seconde suivante (R6).
    final creee = saisie.commandeCreee;
    if (creee != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.commandeConfirmee)),
        body: ListView(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          children: [
            BlocRemise(
              jetonReception: creee.jetonReception,
              codeLivraison: creee.codeLivraison,
            ),
            const SizedBox(height: MefaliTokens.space3),
            Center(
              child: Text(
                formaterMontant(creee.totalUnites, creee.devise),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commandeAdresseTitre)),
      body: ListView(
        padding: const EdgeInsets.all(MefaliTokens.screenMargin),
        children: [
          _CarteAdresse(
            saisie: saisie,
            onPositionActuelle: onPositionActuelle,
            onChangerAdresse: onChangerAdresse,
          ),
          const SizedBox(height: MefaliTokens.space3),
          _CarteRepere(saisie: saisie, capturerNote: capturerNote),
          const SizedBox(height: MefaliTokens.space3),
          if (devis != null) _CartePaiement(devis: devis, saisie: saisie),
          const SizedBox(height: MefaliTokens.space4),
          FilledButton(
            // Le bouton est désarmé tant que le repère manque : mieux vaut une
            // action visiblement indisponible qu'un `422` après coup.
            onPressed: saisie.pretAConfirmer ? onConfirmer : null,
            child: Text(
              devis == null
                  ? l10n.panierCommander
                  : '${l10n.panierCommander} · '
                      '${formaterMontant(devis.totalUnites, devis.devise)}',
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
                    child: Text(l10n.panierScissionAction),
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
  const _CartePaiement({required this.devis, required this.saisie});

  final DevisPanierVue devis;
  final EtatConfirmation saisie;

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
            Text(l10n.commandePaiementTitre, style: theme.textTheme.titleMedium),
            const SizedBox(height: MefaliTokens.space2),

            // C3-3b — le cash grisé montre SA RAISON. Un bouton désactivé sans
            // explication fait croire à une panne de l'app.
            if (!devis.cashAutorise) ...[
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
                    enabled: devis.cashAutorise,
                    title: Text(l10n.commandePaiementCash),
                    // L'APPOINT EXACT, en toutes lettres : c'est lui qui évite
                    // la scène du gros billet devant un coursier sans monnaie
                    // (§7.5-5).
                    subtitle: devis.cashAutorise
                        ? Text(l10n.commandePaiementAppoint(
                            formaterMontant(devis.totalUnites, devis.devise),
                          ))
                        : null,
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
