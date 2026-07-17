import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import 'composants.dart';
import 'libelles_roles.dart';

/// Pièce d'identité choisie par le coursier.
@immutable
class PieceChoisie {
  /// Crée une pièce choisie.
  const PieceChoisie({required this.octets, required this.nom, required this.mime});

  /// Contenu du fichier.
  final Uint8List octets;

  /// Nom de fichier, transmis tel quel au serveur.
  final String nom;

  /// Type MIME — le serveur n'accepte que jpeg/png/webp/pdf.
  final String mime;
}

/// Choisit une pièce, ou `null` si l'utilisateur annule.
///
/// Injectable : `image_picker` passe par un canal de plateforme qu'un test
/// widget ne peut pas servir. On double la FONCTION, pas le canal — même
/// principe que `StockageJetonsMemoire` pour le stockage sécurisé.
typedef ChoisirPiece = Future<PieceChoisie?> Function(ImageSource source);

/// Implémentation réelle : l'appareil photo ou la galerie.
Future<PieceChoisie?> choisirPieceAppareil(ImageSource source) async {
  final fichier = await ImagePicker().pickImage(
    source: source,
    // La pièce doit rester LISIBLE par l'admin (FR-017) : on borne la taille
    // sans la rendre floue, plutôt que d'envoyer 12 Mo depuis un capteur récent.
    maxWidth: 2000,
    imageQuality: 85,
  );
  if (fichier == null) return null;
  return PieceChoisie(
    octets: await fichier.readAsBytes(),
    nom: fichier.name,
    mime: fichier.mimeType ?? 'image/jpeg',
  );
}

/// Constitution du dossier coursier depuis Mefali Pro (FR-015).
///
/// Les véhicules déclarables viennent de `transports_actifs` de la config de
/// zone (référentiel ZON-03) : jamais d'une liste en dur. Le serveur refuse de
/// toute façon tout ce qui n'y est pas — proposer un choix impossible ne ferait
/// que promettre un 422.
class FormulaireDossierCoursier extends ConsumerStatefulWidget {
  /// Crée le formulaire.
  const FormulaireDossierCoursier({
    super.key,
    required this.transportsActifs,
    this.choisirPiece = choisirPieceAppareil,
  });

  /// Slugs des types de transport actifs dans la zone.
  final List<String> transportsActifs;

  /// Sélecteur de pièce — doublé par les tests.
  final ChoisirPiece choisirPiece;

  @override
  ConsumerState<FormulaireDossierCoursier> createState() =>
      _FormulaireDossierCoursierState();
}

class _FormulaireDossierCoursierState
    extends ConsumerState<FormulaireDossierCoursier> {
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _telephone = TextEditingController();
  final Set<String> _vehicules = {};
  PieceChoisie? _piece;
  String? _erreur;
  bool _envoi = false;

  /// Clé d'idempotence de CETTE tentative (R14).
  ///
  /// Générée une fois et CONSERVÉE entre les essais : c'est tout l'intérêt —
  /// si le réseau coupe après que le serveur a reçu le dossier, le renvoi rejoue
  /// la même clé et rend l'état courant au lieu d'un doublon.
  final String _cleIdempotence = const Uuid().v7();

  @override
  void dispose() {
    _nom.dispose();
    _telephone.dispose();
    super.dispose();
  }

  /// FR-015 scénario 1 — dossier incomplet = non soumis. La règle est aussi
  /// côté serveur ; ici elle évite un aller-retour et dit ce qui manque.
  bool get _complet =>
      _piece != null &&
      _nom.text.trim().isNotEmpty &&
      _telephone.text.trim().isNotEmpty &&
      _vehicules.isNotEmpty;

  Future<void> _prendrePiece(ImageSource source) async {
    final piece = await widget.choisirPiece(source);
    if (piece == null || !mounted) return;
    setState(() {
      _piece = piece;
      _erreur = null;
    });
  }

  Future<void> _soumettre() async {
    final l10n = AppLocalizations.of(context)!;
    final piece = _piece;
    if (piece == null || !_complet) {
      setState(() => _erreur = l10n.proDossierIncomplet);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      await ref.read(clientSessionProvider).getMoiApi().soumettreDossierCoursier(
            idempotencyKey: _cleIdempotence,
            piece: MultipartFile.fromBytes(
              piece.octets,
              filename: piece.nom,
              contentType: DioMediaType.parse(piece.mime),
            ),
            referentNom: _nom.text.trim(),
            referentTelephone: _telephone.text.trim(),
            vehicules: BuiltList<String>(_vehicules),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        // 422 : le serveur a la vraie règle (véhicule hors zone, pièce refusée,
        // référent non normalisable). On rend SA clé i18n plutôt que d'en
        // inventer une seconde version, forcément divergente.
        _erreur = switch (e.response?.statusCode) {
          422 => l10n.proDossierRefuseParServeur,
          409 => l10n.proDossierDejaTraite,
          _ => l10n.proErreurAide,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final erreur = _erreur;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.proDossierTitre)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.proDossierAide, style: textTheme.bodyLarge),
                      const SizedBox(height: MefaliTokens.space4),
                      _Section(titre: l10n.proDossierPiece),
                      _ChoixPiece(
                        piece: _piece,
                        onPrendre: _prendrePiece,
                        enCours: _envoi,
                      ),
                      const SizedBox(height: MefaliTokens.space4),
                      _Section(titre: l10n.proDossierVehicules),
                      _ChoixVehicules(
                        actifs: widget.transportsActifs,
                        selection: _vehicules,
                        onBascule: (slug, choisi) => setState(() {
                          if (choisi) {
                            _vehicules.add(slug);
                          } else {
                            _vehicules.remove(slug);
                          }
                        }),
                      ),
                      const SizedBox(height: MefaliTokens.space4),
                      _Section(titre: l10n.proDossierReferent),
                      Text(
                        l10n.proDossierReferentAide,
                        style: textTheme.bodyLarge?.copyWith(color: MefaliTokens.textMuted),
                      ),
                      const SizedBox(height: MefaliTokens.space3),
                      TextField(
                        controller: _nom,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: MefaliTokens.bodySize,
                          height: MefaliTokens.bodyHeight,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.proDossierReferentNom,
                          prefixIcon: const Icon(Symbols.person),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: MefaliTokens.space3),
                      TextField(
                        controller: _telephone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                          LengthLimitingTextInputFormatter(20),
                        ],
                        style: const TextStyle(
                          fontSize: MefaliTokens.bodySize,
                          height: MefaliTokens.bodyHeight,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.proDossierReferentTelephone,
                          prefixIcon: const Icon(Symbols.call),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (erreur != null) ...[
                        const SizedBox(height: MefaliTokens.space3),
                        _Bandeau(texte: erreur),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MefaliTokens.space3),
              // Action principale en bas d'écran (règle d'or 3).
              BoutonPrincipal(
                libelle: l10n.proDossierEnvoyer,
                picto: Symbols.send,
                enCours: _envoi,
                actif: _complet,
                onPresse: _soumettre,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.titre});

  final String titre;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MefaliTokens.space2),
      child: Text(titre, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ChoixPiece extends StatelessWidget {
  const _ChoixPiece({required this.piece, required this.onPrendre, required this.enCours});

  final PieceChoisie? piece;
  final void Function(ImageSource source) onPrendre;
  final bool enCours;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final choisie = piece;

    return CarteMefali(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (choisie != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(MefaliTokens.radiusButton),
              child: Image.memory(
                choisie.octets,
                height: 160,
                fit: BoxFit.cover,
                // Un PDF n'a pas d'aperçu : on le dit plutôt que d'afficher
                // l'icône d'image cassée de Flutter.
                errorBuilder: (context, _, _) => _Message(texte: choisie.nom),
              ),
            ),
            const SizedBox(height: MefaliTokens.space3),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: MefaliTokens.tapMin,
                  child: OutlinedButton.icon(
                    onPressed: enCours ? null : () => onPrendre(ImageSource.camera),
                    icon: const Icon(Symbols.photo_camera),
                    label: Text(l10n.proDossierPhotographier),
                  ),
                ),
              ),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: SizedBox(
                  height: MefaliTokens.tapMin,
                  child: OutlinedButton.icon(
                    onPressed: enCours ? null : () => onPrendre(ImageSource.gallery),
                    icon: const Icon(Symbols.image),
                    label: Text(l10n.proDossierChoisirFichier),
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

class _ChoixVehicules extends StatelessWidget {
  const _ChoixVehicules({
    required this.actifs,
    required this.selection,
    required this.onBascule,
  });

  final List<String> actifs;
  final Set<String> selection;
  final void Function(String slug, bool choisi) onBascule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Config jamais chargée : le dire. Un formulaire sans aucun choix de
    // véhicule serait un cul-de-sac silencieux (règle d'or 5).
    if (actifs.isEmpty) return _Message(texte: l10n.proDossierVehiculesIndisponibles);

    return Wrap(
      spacing: MefaliTokens.space2,
      runSpacing: MefaliTokens.space2,
      children: [
        for (final slug in actifs)
          SizedBox(
            height: MefaliTokens.tapMin,
            child: FilterChip(
              label: Text(l10n.transport(slug)),
              selected: selection.contains(slug),
              onSelected: (choisi) => onBascule(slug, choisi),
            ),
          ),
      ],
    );
  }
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.dangerTint,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Text(
        texte,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: MefaliTokens.text),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Text(
      texte,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: MefaliTokens.textMuted),
    );
  }
}
