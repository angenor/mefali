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
              l10n.crsRemiseRepereArrivee(
                client.repereTexte ?? '',
                _heureArrivee(etat),
              ),
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
              _MontantAEncaisser(
                montantUnites: etat.montantAEncaisserUnites,
                devise: etat.devise,
              ),
              const SizedBox(height: MefaliTokens.space3),
              _JamaisPartiel(enLigne: widget.enLigne),
              if (!widget.enLigne) ...[
                const SizedBox(height: MefaliTokens.space3),
                _Rassurance(message: l10n.crsRemiseScanEtCodeSansReseau),
              ],
            ],
          ),
        ),
        if (remise.erreurCle != null) ...[
          _Refus(message: _messageErreur(l10n, remise.erreurCle!)),
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

  /// Heure d'arrivée chez le client — l'horodatage SERVEUR de l'arrêt de remise.
  String _heureArrivee(EtatCourse etat) {
    final quand = etat.arrets.isEmpty ? null : etat.arrets.last.collecteLe;
    if (quand == null) return '—';
    final local = quand.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _messageErreur(AppLocalizations l10n, String cle) => switch (cle) {
        'depot_non_autorise' => l10n.crsErreurDepotNonAutorise,
        'code_epuise' => l10n.crsErreurCodeEpuise,
        'depot_preuve_incomplete' => l10n.crsRemiseDepotSansPhoto,
        _ => l10n.crsErreurCodeIncorrect,
      };

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
class _MontantAEncaisser extends StatelessWidget {
  const _MontantAEncaisser({required this.montantUnites, required this.devise});

  final int montantUnites;
  final String devise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.successTint,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.crsRemiseEncaissez, style: textTheme.bodyMedium),
          const SizedBox(height: MefaliTokens.space1),
          Text(
            formaterMontant(montantUnites, devise),
            style: textTheme.displayMedium?.copyWith(
              color: MefaliTokens.success,
              fontWeight: MefaliTokens.weightBold,
            ),
          ),
        ],
      ),
    );
  }
}

/// **FR-049 / FR-050** — l'absence totale de paiement partiel, rappelée à
/// l'écran, et le renvoi au chemin de secours quand le client n'a pas l'appoint.
///
/// Aucun lien de paiement n'est généré : c'est PAY-03 (tranche T3). Dire
/// « indisponible » plutôt que rien est une décision — un bouton absent laisse
/// croire à un oubli, un bouton grisé dit qu'on y a pensé.
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
