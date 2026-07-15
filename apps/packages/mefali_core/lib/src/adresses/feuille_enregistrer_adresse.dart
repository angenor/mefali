import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../auth/cadre_auth.dart';
import '../theme/tokens.dart';
import 'note_vocale.dart';

/// Adresse à enregistrer, telle que la feuille la restitue.
@immutable
class AdresseASoumettre {
  /// Crée l'adresse à soumettre.
  const AdresseASoumettre({
    required this.libelle,
    required this.lat,
    required this.lng,
    this.repereTexte,
    this.note,
  });

  /// « Maison », « Bureau » ou libre.
  final String libelle;

  /// Latitude du pin GPS de la livraison.
  final double lat;

  /// Longitude du pin GPS de la livraison.
  final double lng;

  /// Repère écrit.
  final String? repereTexte;

  /// Repère parlé.
  final NoteVocaleCaptee? note;
}

/// Proposition d'enregistrer l'adresse d'une livraison réussie (FR-019).
///
/// La proposition est REFUSABLE sans friction : l'enregistrement n'est jamais
/// obligatoire, et cette feuille se ferme d'un geste. Elle est présentée par le
/// module commandes (cycle CMD) après une livraison ; ce cycle en fournit le
/// déclencheur simulé pour les tests.
class FeuilleEnregistrerAdresse extends StatefulWidget {
  /// Crée la feuille.
  const FeuilleEnregistrerAdresse({
    super.key,
    required this.lat,
    required this.lng,
    required this.onEnregistrer,
    this.dureeMaxS,
    this.repereTexteInitial,
    this.capturerNote,
  });

  /// Latitude de l'adresse livrée.
  final double lat;

  /// Longitude de l'adresse livrée.
  final double lng;

  /// Appelé quand l'utilisateur accepte la proposition.
  final ValueChanged<AdresseASoumettre> onEnregistrer;

  /// Durée max de note vocale servie par la config de zone (FR-019).
  final int? dureeMaxS;

  /// Repère déjà saisi à la commande, repris tel quel.
  final String? repereTexteInitial;

  /// Capture de note — doublée par les tests.
  final CapturerNote? capturerNote;

  @override
  State<FeuilleEnregistrerAdresse> createState() => _FeuilleEnregistrerAdresseState();
}

class _FeuilleEnregistrerAdresseState extends State<FeuilleEnregistrerAdresse> {
  late final TextEditingController _libelle = TextEditingController();
  late final TextEditingController _repere =
      TextEditingController(text: widget.repereTexteInitial ?? '');
  NoteVocaleCaptee? _note;

  /// Libellé choisi par une puce, ou `null` si l'utilisateur écrit le sien.
  String? _puce;

  @override
  void dispose() {
    _libelle.dispose();
    _repere.dispose();
    super.dispose();
  }

  String get _libelleFinal => _puce ?? _libelle.text.trim();

  void _enregistrer() {
    final libelle = _libelleFinal;
    if (libelle.isEmpty) return;
    final repere = _repere.text.trim();
    widget.onEnregistrer(
      AdresseASoumettre(
        libelle: libelle,
        lat: widget.lat,
        lng: widget.lng,
        repereTexte: repere.isEmpty ? null : repere,
        note: _note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    // Deux libellés proposés, plus le champ libre : ce sont les deux adresses
    // que 90 % des gens enregistrent, et le reste s'écrit.
    final puces = [l10n.adresseLibelleMaison, l10n.adresseLibelleBureau];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.adresseProposerTitre, style: textTheme.titleLarge),
            const SizedBox(height: MefaliTokens.space2),
            Text(
              l10n.adresseProposerAide,
              style: textTheme.bodyLarge?.copyWith(color: MefaliTokens.textMuted),
            ),
            const SizedBox(height: MefaliTokens.space4),
            Wrap(
              spacing: MefaliTokens.space2,
              children: [
                for (final puce in puces)
                  SizedBox(
                    height: MefaliTokens.tapMin,
                    child: ChoiceChip(
                      label: Text(puce),
                      selected: _puce == puce,
                      onSelected: (choisi) => setState(() {
                        _puce = choisi ? puce : null;
                        if (choisi) _libelle.clear();
                      }),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MefaliTokens.space3),
            TextField(
              controller: _libelle,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 60,
              style: const TextStyle(
                fontSize: MefaliTokens.bodySize,
                height: MefaliTokens.bodyHeight,
              ),
              decoration: InputDecoration(
                labelText: l10n.adresseLibelleLibre,
                prefixIcon: const Icon(Symbols.label),
                counterText: '',
              ),
              // Écrire son propre libellé désélectionne la puce : les deux se
              // contrediraient sinon.
              onChanged: (_) => setState(() => _puce = null),
            ),
            const SizedBox(height: MefaliTokens.space3),
            TextField(
              controller: _repere,
              maxLines: 2,
              maxLength: 500,
              style: const TextStyle(
                fontSize: MefaliTokens.bodySize,
                height: MefaliTokens.bodyHeight,
              ),
              decoration: InputDecoration(
                labelText: l10n.adresseRepereTexte,
                hintText: l10n.adresseRepereExemple,
                prefixIcon: const Icon(Symbols.signpost),
                counterText: '',
              ),
            ),
            const SizedBox(height: MefaliTokens.space3),
            EnregistreurNoteVocale(
              dureeMaxS: widget.dureeMaxS,
              note: _note,
              capturer: widget.capturerNote,
              onCapturee: (note) => setState(() => _note = note),
            ),
            const SizedBox(height: MefaliTokens.space4),
            BoutonPrincipal(
              libelle: l10n.adresseProposerAction,
              picto: Symbols.bookmark,
              actif: _libelleFinal.isNotEmpty,
              onPresse: _enregistrer,
            ),
            const SizedBox(height: MefaliTokens.space2),
            // Refuser doit être aussi facile qu'accepter (FR-019).
            SizedBox(
              height: MefaliTokens.tapMin,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.adresseProposerRefuser),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
