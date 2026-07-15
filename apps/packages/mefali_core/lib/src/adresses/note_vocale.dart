import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:record/record.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../theme/tokens.dart';

/// Note vocale captée par [EnregistreurNoteVocale].
@immutable
class NoteVocaleCaptee {
  /// Crée une note captée.
  const NoteVocaleCaptee({required this.octets, required this.dureeS});

  /// Contenu du fichier (m4a/aac).
  final Uint8List octets;

  /// Durée en secondes — le serveur la borne par le paramètre de zone.
  final int dureeS;
}

/// Capture une note vocale, ou `null` si l'utilisateur renonce.
///
/// Injectable : `record` passe par un canal de plateforme qu'un test widget ne
/// sert pas. On double la FONCTION, pas le canal.
typedef CapturerNote = Future<NoteVocaleCaptee?> Function();

/// Joue une note vocale depuis une URL présignée.
typedef JouerNote = Future<void> Function(String url);

/// Implémentation réelle de la lecture (`just_audio`).
Future<void> jouerNoteReseau(String url) async {
  final lecteur = AudioPlayer();
  try {
    await lecteur.setUrl(url);
    await lecteur.play();
    // `play()` rend la main dès le démarrage : on attend la fin réelle pour que
    // l'appelant sache quand le bouton doit reprendre son état de repos.
    await lecteur.processingStateStream.firstWhere(
      (etat) => etat == ProcessingState.completed,
    );
  } finally {
    await lecteur.dispose();
  }
}

/// Bouton « Écouter le repère » (planche de style §4 — bouton audio).
///
/// Ce que le coursier utilisera pour trouver Awa (cadrage §8.2). Le mécanisme
/// est le même des deux côtés : une URL présignée, des octets intacts (SC-007).
class LecteurNoteVocale extends StatefulWidget {
  /// Crée le lecteur.
  const LecteurNoteVocale({
    super.key,
    required this.obtenirUrl,
    this.repereTexte,
    this.dureeS,
    this.jouer = jouerNoteReseau,
  });

  /// Obtient l'URL présignée de lecture (10 min) — appelée à chaque écoute :
  /// une URL périmée ne doit pas rendre le bouton inutile.
  final Future<String> Function() obtenirUrl;

  /// Repère écrit, affiché en aperçu sous le bouton.
  final String? repereTexte;

  /// Durée de la note, affichée telle quelle.
  final int? dureeS;

  /// Lecteur — doublé par les tests.
  final JouerNote jouer;

  @override
  State<LecteurNoteVocale> createState() => _LecteurNoteVocaleState();
}

class _LecteurNoteVocaleState extends State<LecteurNoteVocale> {
  bool _enLecture = false;
  bool _erreur = false;

  Future<void> _ecouter() async {
    setState(() {
      _enLecture = true;
      _erreur = false;
    });
    try {
      await widget.jouer(await widget.obtenirUrl());
    } catch (_) {
      if (mounted) setState(() => _erreur = true);
    } finally {
      if (mounted) setState(() => _enLecture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final texte = widget.repereTexte;

    return InkWell(
      onTap: _enLecture ? null : _ecouter,
      borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(MefaliTokens.space3),
        constraints: const BoxConstraints(minHeight: MefaliTokens.tapMin),
        decoration: BoxDecoration(
          color: MefaliTokens.surface,
          borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
          border: Border.all(color: MefaliTokens.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: MefaliTokens.primary,
                shape: BoxShape.circle,
              ),
              child: _enLecture
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(MefaliTokens.surface),
                      ),
                    )
                  : const Icon(Symbols.play_arrow, fill: 1, color: MefaliTokens.surface),
            ),
            const SizedBox(width: MefaliTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _erreur ? l10n.adresseRepereErreur : l10n.adresseRepereEcouter,
                    style: textTheme.titleMedium,
                  ),
                  if (texte != null && texte.isNotEmpty)
                    Text(
                      texte,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(color: MefaliTokens.textMuted),
                    ),
                ],
              ),
            ),
            if (widget.dureeS != null) ...[
              const SizedBox(width: MefaliTokens.space2),
              Text(
                l10n.adresseRepereDuree(widget.dureeS!),
                style: textTheme.bodyLarge?.copyWith(color: MefaliTokens.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bouton d'enregistrement de la note vocale de repère (FR-019).
///
/// La durée maximale vient de la configuration de ZONE, jamais d'une constante
/// (FR-024) : si elle n'est pas connue, on n'invente pas de borne — le serveur
/// tranchera. Sans borne locale, l'utilisateur peut dépasser et se faire
/// refuser ; c'est préférable à une limite fausse imposée en silence.
class EnregistreurNoteVocale extends StatefulWidget {
  /// Crée l'enregistreur.
  const EnregistreurNoteVocale({
    super.key,
    required this.onCapturee,
    required this.dureeMaxS,
    this.note,
    this.capturer,
  });

  /// Appelé quand une note est captée.
  final ValueChanged<NoteVocaleCaptee> onCapturee;

  /// Durée maximale servie par la config de zone — `null` = inconnue.
  final int? dureeMaxS;

  /// Note déjà captée, s'il y en a une.
  final NoteVocaleCaptee? note;

  /// Capture — doublée par les tests ; l'implémentation réelle sinon.
  final CapturerNote? capturer;

  @override
  State<EnregistreurNoteVocale> createState() => _EnregistreurNoteVocaleState();
}

class _EnregistreurNoteVocaleState extends State<EnregistreurNoteVocale> {
  final AudioRecorder _micro = AudioRecorder();
  bool _enCours = false;
  int _secondes = 0;
  Timer? _minuteur;

  @override
  void dispose() {
    _minuteur?.cancel();
    unawaited(_micro.dispose());
    super.dispose();
  }

  Future<void> _basculer() async {
    if (_enCours) {
      await _arreter();
      return;
    }
    final capturer = widget.capturer;
    if (capturer != null) {
      final note = await capturer();
      if (note != null && mounted) widget.onCapturee(note);
      return;
    }
    await _demarrer();
  }

  Future<void> _demarrer() async {
    if (!await _micro.hasPermission()) return;
    // `m4a` = AAC dans un conteneur MP4 : ce que le serveur accepte, et ce que
    // les deux plateformes savent produire nativement.
    await _micro.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: '',
    );
    if (!mounted) return;
    setState(() {
      _enCours = true;
      _secondes = 0;
    });
    _minuteur = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondes++);
      final max = widget.dureeMaxS;
      // Borne de la ZONE : on arrête tout seul plutôt que de laisser
      // l'utilisateur parler pour rien puis se faire refuser (FR-019).
      if (max != null && _secondes >= max) unawaited(_arreter());
    });
  }

  Future<void> _arreter() async {
    _minuteur?.cancel();
    final chemin = await _micro.stop();
    if (!mounted) return;
    setState(() => _enCours = false);
    if (chemin == null) return;
    // `record` rend un chemin de fichier ; les octets partent en multipart.
    final octets = await _lireFichier(chemin);
    if (octets == null || !mounted) return;
    widget.onCapturee(NoteVocaleCaptee(octets: octets, dureeS: _secondes));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final note = widget.note;
    final max = widget.dureeMaxS;

    final libelle = switch ((_enCours, note)) {
      (true, _) => l10n.adresseRepereArreter(_secondes),
      (false, final n?) => l10n.adresseRepereRefaire(n.dureeS),
      (false, null) => l10n.adresseRepereEnregistrer,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: MefaliTokens.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: _basculer,
            icon: Icon(_enCours ? Symbols.stop_circle : Symbols.mic, fill: _enCours ? 1 : 0),
            label: Text(libelle),
          ),
        ),
        if (max != null) ...[
          const SizedBox(height: MefaliTokens.space1),
          Text(
            l10n.adresseRepereMax(max),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: MefaliTokens.textMuted),
          ),
        ],
      ],
    );
  }
}

/// Lit les octets du fichier produit par `record` (Android/iOS — pas de web au
/// MVP). Un fichier illisible rend `null` : on ne remonte pas une note vide.
Future<Uint8List?> _lireFichier(String chemin) async {
  try {
    return await File(chemin).readAsBytes();
  } catch (_) {
    return null;
  }
}
