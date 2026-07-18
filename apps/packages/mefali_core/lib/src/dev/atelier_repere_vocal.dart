/// Atelier de DÉVELOPPEMENT du repère vocal (FR-019, FR-020).
///
/// # Pourquoi il existe
///
/// [FeuilleEnregistrerAdresse] n'a AUCUN point d'entrée dans l'app : son vrai
/// déclencheur (la proposition post-livraison) appartient au cycle CMD, pas
/// encore construit. Or `record` (micro + permission) et `just_audio`
/// (réécoute) sont des canaux de plateforme qu'aucun test widget ne sert : ils
/// ne s'éprouvent qu'en les EXÉCUTANT sur un appareil. Cet atelier ouvre la
/// feuille sur un pin GPS bouchon pour exercer, avant CMD, la chaîne complète :
/// permission → enregistrement → réécoute LOCALE → envoi réel → réécoute
/// SERVEUR (URL présignée, SC-007).
///
/// # Invisible en build normal
///
/// [modeDevAdresse] est une constante de compilation à `false` par défaut :
/// sans `--dart-define=MEFALI_DEV_ADRESSE=true`, le seul appelant ([AccueilProvisoire])
/// n'instancie jamais cet écran, et le compilateur Dart élimine tout l'arbre —
/// exactement comme le bandeau du code dev de l'OTP (`otp_dev.dart`). Le flux
/// de production n'est pas touché.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../adresses/feuille_enregistrer_adresse.dart';
import '../adresses/note_vocale.dart';
import '../auth/cadre_auth.dart';
import '../auth/clients.dart';
import '../config/service_config.dart';
import '../theme/tokens.dart';

/// Vrai quand le build a été fait avec `--dart-define=MEFALI_DEV_ADRESSE=true`.
///
/// `const` et non une variable : c'est ce qui permet au compilateur de couper
/// la branche morte en release (voir [modeDevOtp] pour le même mécanisme).
const bool modeDevAdresse = bool.fromEnvironment('MEFALI_DEV_ADRESSE');

/// Pin GPS BOUCHON — centre de Tiassalé, la zone d'amorçage (mêmes valeurs que
/// les fixtures de test du contrat `Adresse`). Le vrai déclencheur (cycle CMD)
/// fournira le pin réel de la livraison ; ici il n'a qu'à être plausible.
const double _latBouchon = 5.898;
const double _lngBouchon = -4.823;

/// Joue une note vocale depuis un FICHIER LOCAL — pendant de [jouerNoteReseau]
/// pour la réécoute AVANT envoi (les octets fraîchement captés, jamais montés
/// sur le réseau). Exerce le chemin `just_audio`/ExoPlayer sur un fichier local,
/// distinct de la lecture d'une URL présignée.
Future<void> jouerNoteFichier(String chemin) async {
  final lecteur = AudioPlayer();
  try {
    await lecteur.setFilePath(chemin);
    await lecteur.play();
    await lecteur.processingStateStream.firstWhere(
      (etat) => etat == ProcessingState.completed,
    );
  } finally {
    await lecteur.dispose();
  }
}

/// Atelier DEV : ouvre la feuille d'enregistrement d'adresse et déroule
/// l'aller-retour réel du repère vocal.
///
/// `record`, `just_audio` et l'upload multipart sont INJECTABLES (patron de
/// [FeuilleEnregistrerAdresse.capturerNote] et [ListeAdresses.jouerNote]) : le
/// vrai micro par défaut sur appareil, des doubles en test widget.
class AtelierRepereVocal extends ConsumerStatefulWidget {
  /// Crée l'atelier.
  const AtelierRepereVocal({
    super.key,
    this.capturerNote,
    this.jouerLocal = jouerNoteFichier,
    this.jouerReseau = jouerNoteReseau,
  });

  /// Capture de note — `null` = vrai micro (le but de l'atelier). Doublée par
  /// les tests, comme dans la feuille de production.
  final CapturerNote? capturerNote;

  /// Réécoute LOCALE des octets captés — doublée par les tests.
  final JouerNote jouerLocal;

  /// Réécoute SERVEUR depuis l'URL présignée — doublée par les tests.
  final JouerNote jouerReseau;

  @override
  ConsumerState<AtelierRepereVocal> createState() => _AtelierRepereVocalState();
}

class _AtelierRepereVocalState extends ConsumerState<AtelierRepereVocal> {
  /// Borne de durée de la ZONE (FR-024) — `null` tant qu'elle n'est pas connue :
  /// on n'invente pas de borne locale, le serveur tranchera.
  int? _dureeMax;

  /// Capture courante remontée par la feuille.
  AdresseASoumettre? _captee;

  /// Clé d'idempotence de la capture courante (R14) — générée à la capture et
  /// CONSERVÉE entre les essais d'envoi : un rejeu rend l'adresse existante.
  String? _cle;

  /// Adresse effectivement enregistrée par le serveur.
  Adresse? _envoyee;

  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    // Instantané pris à l'entrée, comme la version de consentement de
    // `RacineAuth` : lu par `ref.read`, jamais observé.
    _lireDureeMax();
  }

  Future<void> _lireDureeMax() async {
    try {
      final service = await ref.read(serviceConfigProvider);
      if (mounted) {
        setState(() => _dureeMax = service.courante?.noteVocaleDureeMaxS);
      }
    } catch (_) {
      // Config injoignable : la feuille se passera de borne, le serveur bornera.
    }
  }

  Future<void> _ouvrirFeuille() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (contexteFeuille) => Padding(
        // Laisse la place au clavier (deux champs texte dans la feuille).
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(contexteFeuille).bottom,
        ),
        child: SingleChildScrollView(
          child: FeuilleEnregistrerAdresse(
            lat: _latBouchon,
            lng: _lngBouchon,
            dureeMaxS: _dureeMax,
            capturerNote: widget.capturerNote,
            onEnregistrer: (adresse) {
              setState(() {
                _captee = adresse;
                _cle = const Uuid().v7();
                _envoyee = null;
                _erreur = null;
              });
              Navigator.of(contexteFeuille).pop();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _envoyer() async {
    final captee = _captee;
    final cle = _cle;
    if (captee == null || cle == null) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    final note = captee.note;
    try {
      final reponse = await ref
          .read(clientSessionProvider)
          .getMoiApi()
          .enregistrerAdresse(
            idempotencyKey: cle,
            lat: captee.lat,
            lng: captee.lng,
            libelle: captee.libelle,
            repereTexte: captee.repereTexte,
            // Le serveur dérive le mime de l'en-tête de la partie : `audio/mp4`
            // (m4a/aac), un des types que la note vocale accepte.
            noteVocale: note == null
                ? null
                : MultipartFile.fromBytes(
                    note.octets,
                    filename: 'repere.m4a',
                    contentType: DioMediaType.parse('audio/mp4'),
                  ),
            dureeS: note?.dureeS,
          );
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _envoyee = reponse.data;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final statut = e.response?.statusCode;
      setState(() {
        _envoi = false;
        _erreur = 'HTTP ${statut ?? '—'} · ${e.message ?? e.type.name}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = e.toString();
      });
    }
  }

  Future<void> _supprimer() async {
    final envoyee = _envoyee;
    if (envoyee == null) return;
    try {
      await ref
          .read(clientSessionProvider)
          .getMoiApi()
          .supprimerAdresse(adresseId: envoyee.id);
      if (!mounted) return;
      setState(() {
        _envoyee = null;
        _captee = null;
        _cle = null;
      });
    } catch (e) {
      if (mounted) setState(() => _erreur = e.toString());
    }
  }

  /// Écrit les octets captés dans un fichier temporaire pour la réécoute locale.
  /// `record` rend un chemin puis on jette les octets ; on les réécrit ici.
  Future<String> _fichierTemp(NoteVocaleCaptee note) async {
    final fichier = File('${Directory.systemTemp.path}/mefali_repere_dev.m4a');
    await fichier.writeAsBytes(note.octets, flush: true);
    return fichier.path;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.atelierRepereTitre)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.atelierRepereAide, style: textTheme.bodyLarge),
              const SizedBox(height: MefaliTokens.space4),
              BoutonPrincipal(
                libelle: l10n.atelierRepereOuvrir,
                picto: Symbols.add_location_alt,
                onPresse: _ouvrirFeuille,
              ),
              if (_captee != null) ...[
                const SizedBox(height: MefaliTokens.space4),
                _CarteCapture(
                  captee: _captee!,
                  fichierTemp: _fichierTemp,
                  jouerLocal: widget.jouerLocal,
                  envoi: _envoi,
                  onEnvoyer: _envoyer,
                ),
              ],
              if (_erreur != null) ...[
                const SizedBox(height: MefaliTokens.space3),
                Text(
                  l10n.atelierRepereErreur(_erreur!),
                  style: textTheme.bodyLarge?.copyWith(
                    color: MefaliTokens.danger,
                  ),
                ),
              ],
              if (_envoyee != null) ...[
                const SizedBox(height: MefaliTokens.space4),
                _CarteEnvoyee(
                  envoyee: _envoyee!,
                  urlRepere: () async =>
                      (await ref
                              .read(clientSessionProvider)
                              .getMoiApi()
                              .ecouterRepereVocal(adresseId: _envoyee!.id))
                          .data!
                          .url,
                  jouerReseau: widget.jouerReseau,
                  onSupprimer: _supprimer,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ce que la feuille a rendu : réécoute LOCALE (avant envoi) puis envoi réel.
class _CarteCapture extends StatelessWidget {
  const _CarteCapture({
    required this.captee,
    required this.fichierTemp,
    required this.jouerLocal,
    required this.envoi,
    required this.onEnvoyer,
  });

  final AdresseASoumettre captee;
  final Future<String> Function(NoteVocaleCaptee note) fichierTemp;
  final JouerNote jouerLocal;
  final bool envoi;
  final VoidCallback onEnvoyer;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final note = captee.note;

    return _Carte(
      children: [
        Text(l10n.atelierRepereCaptee, style: textTheme.titleMedium),
        const SizedBox(height: MefaliTokens.space2),
        Row(
          children: [
            const Icon(Symbols.location_on, color: MefaliTokens.textMuted),
            const SizedBox(width: MefaliTokens.space2),
            Expanded(
              child: Text(
                '${captee.libelle} · ${captee.lat}, ${captee.lng}',
                style: textTheme.bodyLarge,
              ),
            ),
          ],
        ),
        if (captee.repereTexte != null) ...[
          const SizedBox(height: MefaliTokens.space1),
          Text(
            captee.repereTexte!,
            style: textTheme.bodyLarge?.copyWith(color: MefaliTokens.textMuted),
          ),
        ],
        const SizedBox(height: MefaliTokens.space3),
        if (note != null) ...[
          Text(
            l10n.atelierRepereOctets(note.octets.length),
            style: textTheme.bodyLarge?.copyWith(color: MefaliTokens.textMuted),
          ),
          const SizedBox(height: MefaliTokens.space2),
          LecteurNoteVocale(
            obtenirUrl: () => fichierTemp(note),
            dureeS: note.dureeS,
            jouer: jouerLocal,
          ),
        ] else
          Text(
            l10n.atelierRepereSansNote,
            style: textTheme.bodyLarge?.copyWith(color: MefaliTokens.textMuted),
          ),
        const SizedBox(height: MefaliTokens.space4),
        SizedBox(
          height: MefaliTokens.buttonHeight,
          child: FilledButton.icon(
            onPressed: envoi ? null : onEnvoyer,
            icon: envoi
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : const Icon(Symbols.cloud_upload),
            label: Text(
              envoi ? l10n.atelierRepereEnvoi : l10n.atelierRepereEnvoyer,
            ),
          ),
        ),
      ],
    );
  }
}

/// L'adresse effectivement enregistrée : réécoute SERVEUR (SC-007) et nettoyage.
class _CarteEnvoyee extends StatelessWidget {
  const _CarteEnvoyee({
    required this.envoyee,
    required this.urlRepere,
    required this.jouerReseau,
    required this.onSupprimer,
  });

  final Adresse envoyee;
  final Future<String> Function() urlRepere;
  final JouerNote jouerReseau;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return _Carte(
      children: [
        Row(
          children: [
            const Icon(
              Symbols.check_circle,
              fill: 1,
              color: MefaliTokens.success,
            ),
            const SizedBox(width: MefaliTokens.space2),
            Expanded(
              child: Text(
                l10n.atelierRepereEnvoyee(envoyee.id),
                style: textTheme.titleMedium,
              ),
            ),
          ],
        ),
        if (envoyee.aRepereVocal) ...[
          const SizedBox(height: MefaliTokens.space3),
          LecteurNoteVocale(
            obtenirUrl: urlRepere,
            dureeS: envoyee.repereVocalDureeS,
            jouer: jouerReseau,
          ),
        ],
        const SizedBox(height: MefaliTokens.space3),
        SizedBox(
          height: MefaliTokens.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: onSupprimer,
            icon: const Icon(Symbols.delete),
            label: Text(l10n.atelierRepereSupprimer),
          ),
        ),
      ],
    );
  }
}

/// Cadre commun des deux cartes de l'atelier (mêmes tokens que `ListeAdresses`).
class _Carte extends StatelessWidget {
  const _Carte({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.surface,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
        border: Border.all(color: MefaliTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
