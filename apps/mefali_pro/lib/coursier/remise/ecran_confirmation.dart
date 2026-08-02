import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import '../course/appels_course.dart';
import '../course/etat_course.dart';
import '../preuves/ecran_preuves.dart';
import 'etat_remise.dart';
import 'pave_code.dart';
import '../course/montant_a_encaisser.dart';

/// **K4-1a / K4-1c** — l'écran de confirmation de livraison (T039, T042).
///
/// Réf. `docs/design/png/K4-confirmation-livraison.png` états 1a (arrivé chez le
/// client) et 1c (hors-ligne) ; valeurs de `docs/design/tokens.md`.
///
/// La hiérarchie de la maquette est une décision produit, pas une mise en page :
/// **QR en action principale** (aléa long, inattaquable), **code en secondaire**
/// (4 chiffres, plafonné), **dépôt en lien discret** — et le dépôt n'apparaît
/// que si l'exploitation l'a ouvert sur cette commande (FR-039). Inverser cet
/// ordre reviendrait à pousser vers la voie la plus faible.
///
/// **Écart de maquette assumé** : le bouton « Générer un lien de paiement mobile
/// money » de 1a n'est **pas construit** — c'est PAY-03, tranche T3 (FR-050).
/// L'app rappelle l'absence de paiement partiel et renvoie au chemin de secours.
class EcranConfirmation extends ConsumerStatefulWidget {
  /// Crée l'écran de confirmation.
  const EcranConfirmation({
    super.key,
    required this.etat,
    required this.enLigne,
    this.onScannerQr,
    this.prendrePhoto,
    this.obtenirPosition,
  });

  /// La course, arrivée chez le client.
  final EtatCourse etat;

  /// Réseau disponible ? Décide du grisage des seules actions qui en ont besoin.
  final bool enLigne;

  /// Ouvre le scanner du QR client — la voie principale.
  final VoidCallback? onScannerQr;

  /// Capture de la photo de dépôt. Injectable : `image_picker` passe par un
  /// canal de plateforme qu'un test widget ne sert pas (patron `CapturerNote`).
  final Future<List<int>?> Function()? prendrePhoto;

  /// Position du coursier au dépôt. Injectable pour la même raison.
  final Future<Position?> Function()? obtenirPosition;

  @override
  ConsumerState<EcranConfirmation> createState() => _EcranConfirmationState();
}

class _EcranConfirmationState extends ConsumerState<EcranConfirmation> {
  bool _depotEnCours = false;

  @override
  void initState() {
    super.initState();
    final livraison = widget.etat.livraisonId;
    if (livraison != null) {
      // Après le premier rendu : `charger` écrit dans un provider, et le faire
      // pendant la construction de l'arbre est le piège relevé au cycle 004.
      Future.microtask(
        () => ref.read(etatRemiseProvider.notifier).charger(livraison),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final etat = widget.etat;
    final remise = ref.watch(etatRemiseProvider);
    final client = etat.client;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Entête : NOM D'USAGE, repère et HEURE D'ARRIVÉE (FR-052). Le nom
        // d'usage n'existe pas encore côté produit (aucune colonne nominative,
        // cycle CPT 003) : le repère prend sa place — et c'est de toute façon
        // lui qui fait trouver la porte.
        Card(
          child: ListTile(
            leading: const Icon(Symbols.location_on_rounded,
                color: MefaliTokens.success),
            title: Text(
              l10n.crsRemiseTitre(client.nomUsage ?? client.repereTexte ?? ''),
              style: textTheme.titleMedium,
            ),
            subtitle: Text(
              switch (_heureArrivee(etat)) {
                // L'heure d'arrivée vient du SERVEUR ; hors ligne elle n'existe
                // pas encore, et le « arrivé — » qu'affichait ce sous-titre ne
                // disait rien à personne (T087).
                null => client.repereTexte ?? '',
                final heure =>
                  l10n.crsRemiseRepereArrivee(client.repereTexte ?? '', heure),
              },
            ),
            trailing: Text('${etat.arrets.length} / ${etat.arrets.length}'),
          ),
        ),
        if (!widget.enLigne) ...[
          const SizedBox(height: MefaliTokens.space2),
          // FR-041 — le bandeau ne prétend JAMAIS que la course est close côté
          // serveur. « Validation locale », pas « livraison confirmée ».
          BandeauHorsLigne(message: l10n.crsRemiseValidationLocale),
        ],
        const SizedBox(height: MefaliTokens.space3),
        Expanded(
          child: ListView(
            children: [
              BlocMontantAEncaisser(
                montantUnites: etat.montantAEncaisserUnites,
                devise: etat.devise,
                modePaiement: etat.modePaiement,
              ),
              // Seulement s'il reste quelque chose à encaisser. Sur une
              // commande PRÉPAYÉE, ce bloc parlait d'un choix « cash ou mobile
              // money » qui n'existe plus, et proposait même un lien de
              // paiement juste sous « Rien à encaisser » — l'ambiguïté exacte
              // que SC-012 existe pour supprimer (T088).
              if (etat.modePaiement == 'cash') ...[
                const SizedBox(height: MefaliTokens.space3),
                _JamaisPartiel(enLigne: widget.enLigne),
              ],
              if (!widget.enLigne) ...[
                const SizedBox(height: MefaliTokens.space3),
                _Rassurance(message: l10n.crsRemiseScanEtCodeSansReseau),
              ],
            ],
          ),
        ),
        if (remise.erreurCle != null) ...[
          _Refus(message: messageErreurRemise(l10n, remise.erreurCle!)),
          const SizedBox(height: MefaliTokens.space2),
        ],
        // ── Les trois voies, dans l'ordre de la maquette ──────────────────
        FilledButton.icon(
          // Le scan ne demande RIEN au réseau (FR-040) : il reste actif hors
          // ligne, et c'est tout l'intérêt du pré-provisionnement.
          onPressed: widget.onScannerQr,
          icon: const Icon(Symbols.qr_code_scanner_rounded),
          label: Text(l10n.crsRemiseScannerQrClient),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(64),
          ),
        ),
        const SizedBox(height: MefaliTokens.space2),
        OutlinedButton.icon(
          onPressed: remise.codeBloque ? null : _ouvrirPaveCode,
          icon: const Icon(Symbols.dialpad_rounded),
          label: Text(l10n.crsRemiseSaisirCode),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(MefaliTokens.buttonHeight),
          ),
        ),
        // Lien discret, et SEULEMENT si l'exploitation a ouvert la voie
        // (FR-039). L'afficher grisé apprendrait au coursier qu'une porte
        // existe et l'inviterait à demander qu'on l'ouvre.
        if (client.depotAutorise) ...[
          const SizedBox(height: MefaliTokens.space2),
          TextButton.icon(
            onPressed: _depotEnCours ? null : _confirmerDepot,
            icon: const Icon(Symbols.home_rounded, size: 16),
            label: Text(l10n.crsRemiseDepot, textAlign: TextAlign.center),
          ),
        ],
        // ── La sortie de secours : le client ne répond pas (K4-1e) ─────────
        //
        // Volontairement la DERNIÈRE et la moins appuyée des options : un
        // échec coûte de l'argent à quelqu'un, et les trois voies de remise
        // doivent avoir été essayées avant. Elle n'est pas cachée pour autant
        // — un coursier planté devant une porte close doit savoir où aller.
        const SizedBox(height: MefaliTokens.space3),
        TextButton.icon(
          key: const Key('remise-vers-preuves'),
          onPressed: etat.livraisonId == null ? null : _ouvrirPreuves,
          icon: const Icon(Symbols.gpp_maybe, size: 16),
          label: Text(l10n.crsPreuvesTitre),
        ),
      ],
    );
  }

  /// Ouvre K4-1e — les trois preuves à réunir avant de déclarer l'échec.
  Future<void> _ouvrirPreuves() async {
    final livraison = widget.etat.livraisonId;
    if (livraison == null) return;
    // L'appel passe par le chemin UNIQUE de journalisation (`ActionsAppel`) :
    // il enfile l'intention, compose sans afficher le numéro, puis demande
    // l'issue au retour. Le motif est `client_absent` — le seul qui compte
    // pour la preuve (FR-035).
    final appels = ActionsAppel(ref: ref);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (contexte) => EcranPreuves(
          livraisonId: livraison,
          onAppeler: () => appels.appelerClient(
            contexte,
            etat: widget.etat,
            motif: 'client_absent',
          ),
          prendrePhoto: widget.prendrePhoto,
        ),
      ),
    );
  }

  /// Heure d'arrivée chez le client — l'horodatage SERVEUR de l'arrêt de
  /// REMISE, et `null` tant qu'il n'est pas connu.
  ///
  /// Il se lisait sur le dernier arrêt de COLLECTE, qui n'est pas la même
  /// chose et n'est de toute façon jamais horodaté localement : le sous-titre
  /// affichait donc « arrivé — » en toutes circonstances (T087).
  String? _heureArrivee(EtatCourse etat) {
    final quand = etat.remise.arriveChezClientLe;
    if (quand == null) return null;
    final local = quand.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _ouvrirPaveCode() async {
    final etat = widget.etat;
    final livraison = etat.livraisonId;
    final commande = etat.commandeId;
    if (livraison == null || commande == null) return;
    ref.read(etatRemiseProvider.notifier).choisirVoie(VoieRemise.code);
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaveCode(
          livraisonId: livraison,
          commandeId: commande,
          onReessayerScan: () {
            Navigator.of(context).pop();
            widget.onScannerQr?.call();
          },
        ),
      ),
    );
  }

  /// **Voie dépôt** (T042) — photo et position capturées puis **enfilées avec la
  /// demande**, jamais déposées au préalable (R18, FR-048b).
  ///
  /// C'est ce qui rend cette troisième voie utilisable hors ligne : un upload
  /// préalable supposerait le réseau au moment précis où il manque.
  Future<void> _confirmerDepot() async {
    final etat = widget.etat;
    final livraison = etat.livraisonId;
    final commande = etat.commandeId;
    if (livraison == null || commande == null) return;

    setState(() => _depotEnCours = true);
    try {
      final notifier = ref.read(etatRemiseProvider.notifier)
        ..choisirVoie(VoieRemise.depot);
      final photo = await (widget.prendrePhoto ?? _photoReelle)();
      if (photo == null) return;
      final position = await (widget.obtenirPosition ?? _positionReelle)();
      if (!mounted) return;
      if (position == null) {
        _signaler(AppLocalizations.of(context)!.crsRemiseDepotPositionManquante);
        return;
      }
      final ok = await notifier.confirmer(
        livraisonId: livraison,
        commandeId: commande,
        photo: photo,
        depotLat: position.latitude,
        depotLon: position.longitude,
      );
      if (!mounted || !ok) return;
      _signaler(AppLocalizations.of(context)!.crsRemiseConfirmee);
    } finally {
      if (mounted) setState(() => _depotEnCours = false);
    }
  }

  void _signaler(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<List<int>?> _photoReelle() async {
    final prise = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    return prise?.readAsBytes();
  }

  static Future<Position?> _positionReelle() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition();
  }
}

/// Le montant, en display success (K4-1a) — c'est le chiffre que Yao doit lire
/// d'un coup d'œil, sac dans une main, téléphone dans l'autre.

/// **FR-049 / FR-050** — l'absence totale de paiement partiel, rappelée à
/// l'écran, et le renvoi au chemin de secours quand le client n'a pas l'appoint.
///
/// Aucun lien de paiement n'est généré : c'est PAY-03 (tranche T3). Dire
/// « indisponible » plutôt que rien est une décision — un bouton absent laisse
/// croire à un oubli, un bouton grisé dit qu'on y a pensé.
/// Traduit une clé de refus de remise en phrase pour le coursier.
///
/// ⚠ Le cas par défaut n'est PAS « code incorrect », et c'est tout l'objet de
/// cette fonction. Une panne serveur (5xx, clé `erreur_interne`) tombait
/// auparavant sur ce message et accusait le client à tort : le coursier
/// redemandait le code, échouait encore, et brûlait ses trois essais jusqu'au
/// blocage de la remise — sur une commande dont le code était parfaitement bon
/// (constaté sur émulateur, T088). Seul un refus qui parle VRAIMENT du code le
/// dit ; tout le reste est une panne, et se présente comme telle.
///
/// Fonction de premier niveau, donc directement testable : le mapping est la
/// partie qui portait le défaut, pas le widget qui l'affiche.
String messageErreurRemise(AppLocalizations l10n, String cle) => switch (cle) {
      'depot_non_autorise' => l10n.crsErreurDepotNonAutorise,
      'code_epuise' => l10n.crsErreurCodeEpuise,
      'depot_preuve_incomplete' => l10n.crsRemiseDepotSansPhoto,
      'remise_incorrecte' => l10n.crsErreurCodeIncorrect,
      _ => l10n.crsErreurRemiseTechnique,
    };

class _JamaisPartiel extends StatelessWidget {
  const _JamaisPartiel({required this.enLigne});

  final bool enLigne;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.surface,
        border: Border.all(color: MefaliTokens.border),
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Symbols.info_rounded,
                  size: 16, color: MefaliTokens.textMuted),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Text(
                  enLigne
                      ? l10n.crsRemiseJamaisPartiel
                      : l10n.crsRemiseJamaisPartielHorsLigne,
                  style: textTheme.bodySmall
                      ?.copyWith(color: MefaliTokens.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space2),
          OutlinedButton.icon(
            // Toujours inactif : PAY-03 n'existe pas (FR-050). Hors ligne, le
            // libellé le dit explicitement ; en ligne aussi, faute de service.
            onPressed: null,
            icon: const Icon(Symbols.link_rounded, size: 16),
            label: Text(l10n.crsRemiseLienMobileMoneyIndisponible),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(MefaliTokens.tapMin),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un refus, en clair. La clé i18n vient du serveur ; l'écran ne compose jamais
/// sa propre phrase (constitution VII).
class _Refus extends StatelessWidget {
  const _Refus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.dangerTint,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusButton),
      ),
      child: Row(
        children: [
          const Icon(Symbols.error_rounded, color: MefaliTokens.danger),
          const SizedBox(width: MefaliTokens.space2),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: MefaliTokens.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le bloc vert de K4-1c : ce qui marche encore sans réseau. Dire ce qui
/// FONCTIONNE vaut mieux que d'énumérer ce qui manque.
class _Rassurance extends StatelessWidget {
  const _Rassurance({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.surface,
        border: Border.all(color: MefaliTokens.success),
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Row(
        children: [
          const Icon(Symbols.check_rounded, color: MefaliTokens.success),
          const SizedBox(width: MefaliTokens.space2),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
