import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';

/// Ce que Yao propose au client quand un article manque et que celui-ci a
/// choisi « remplacer » (FR-017).
class PropositionRemplacement {
  /// Crée une proposition.
  const PropositionRemplacement({
    required this.prixUnites,
    required this.photo,
  });

  /// Prix demandé par le vendeur (unités mineures).
  final int prixUnites;

  /// Photo de l'article proposé — **obligatoire** (FR-045) : le client décide
  /// sur ce qu'il voit, pas sur une description.
  final List<int> photo;
}

/// Feuille de proposition de remplacement (K3-1a, préférence « remplacer »).
///
/// La photo n'est pas facultative et le prix non plus : sans les deux, le
/// client n'a aucune base pour accepter ou refuser, et son silence vaudrait
/// acceptation d'un article qu'il n'a jamais vu.
///
/// La photo voyage **avec** la demande (multipart), donc dans la file, donc
/// hors ligne — même patron que la collecte du cycle 006.
class FeuilleRemplacement extends StatefulWidget {
  /// Crée la feuille.
  const FeuilleRemplacement({super.key, required this.libelleArticle});

  /// Libellé de l'article manquant.
  final String libelleArticle;

  /// Ouvre la feuille et rend la proposition, ou `null` si Yao renonce.
  static Future<PropositionRemplacement?> ouvrir(
    BuildContext context,
    String libelleArticle,
  ) {
    return showModalBottomSheet<PropositionRemplacement>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FeuilleRemplacement(libelleArticle: libelleArticle),
    );
  }

  @override
  State<FeuilleRemplacement> createState() => _FeuilleRemplacementState();
}

class _FeuilleRemplacementState extends State<FeuilleRemplacement> {
  final _prix = TextEditingController();
  List<int>? _photo;

  @override
  void dispose() {
    _prix.dispose();
    super.dispose();
  }

  Future<void> _prendrePhoto() async {
    final fichier = await ImagePicker().pickImage(source: ImageSource.camera);
    if (fichier == null) return;
    final octets = await fichier.readAsBytes();
    if (mounted) setState(() => _photo = octets);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final prix = int.tryParse(_prix.text.trim());
    final complet = _photo != null && prix != null && prix > 0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: MefaliTokens.screenMargin,
          right: MefaliTokens.screenMargin,
          top: MefaliTokens.screenMargin,
          bottom: MediaQuery.viewInsetsOf(context).bottom + MefaliTokens.screenMargin,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.crsRemplacementTitre, style: textTheme.titleLarge),
            Text(
              widget.libelleArticle,
              style: textTheme.bodyMedium?.copyWith(color: MefaliTokens.textMuted),
            ),
            const SizedBox(height: MefaliTokens.space3),
            OutlinedButton.icon(
              onPressed: _prendrePhoto,
              icon: Icon(_photo == null
                  ? Symbols.photo_camera_rounded
                  : Symbols.check_circle_rounded),
              label: Text(l10n.crsRemplacementPhoto),
            ),
            const SizedBox(height: MefaliTokens.space3),
            TextField(
              controller: _prix,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.crsRemplacementPrix),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: MefaliTokens.space4),
            BoutonPrincipal(
              libelle: l10n.crsRemplacementEnvoyer,
              onPresse: complet
                  ? () => Navigator.of(context).pop(
                        PropositionRemplacement(
                          prixUnites: prix,
                          photo: _photo!,
                        ),
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// L'issue d'une proposition, telle que K3 l'affiche au retour du client.
///
/// La **fenêtre de décision restante** vient du serveur (`reste_s`), jamais
/// d'une constante d'app : c'est un paramètre de zone, et deux horloges qui
/// décomptent séparément finissent par ne plus dire la même chose.
class IssueRemplacement extends StatelessWidget {
  /// Crée le bandeau d'issue.
  const IssueRemplacement({super.key, required this.issue, this.resteS});

  /// `acceptee` | `refusee` | `expiree` | `en_attente`.
  final String issue;

  /// Secondes restantes (issue `en_attente` seulement).
  final int? resteS;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (fond, accent, libelle) = switch (issue) {
      'acceptee' => (
          MefaliTokens.successTint,
          MefaliTokens.success,
          l10n.crsRemplacementAcceptee,
        ),
      'refusee' => (
          MefaliTokens.dangerTint,
          MefaliTokens.danger,
          l10n.crsRemplacementRefusee,
        ),
      'expiree' => (
          MefaliTokens.dangerTint,
          MefaliTokens.danger,
          l10n.crsRemplacementExpiree,
        ),
      _ => (
          MefaliTokens.warningTint,
          MefaliTokens.warning,
          l10n.crsRemplacementAttente(resteS ?? 0),
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Text(
        libelle,
        style: TextStyle(color: accent, fontWeight: MefaliTokens.weightSemiBold),
      ),
    );
  }
}
