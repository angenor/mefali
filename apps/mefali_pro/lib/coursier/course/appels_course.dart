import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'etat_course.dart';

/// Compose un numéro. Injectable : `url_launcher` passe par un canal de
/// plateforme qu'un test widget ne sert pas. On double la FONCTION, pas le
/// canal (patron `CapturerNote` de `mefali_core`).
typedef ComposerNumero = Future<bool> Function(String numero);

/// Implémentation réelle : ouvre le composeur du téléphone.
///
/// ⚠ Le numéro est passé au système, **jamais affiché** (FR-034) : Yao appelle
/// sans jamais lire le numéro du client, et ne peut donc pas le noter.
Future<bool> composerNumeroReel(String numero) {
  return launchUrl(Uri(scheme: 'tel', path: numero));
}

/// Ce qui se passe autour d'un appel : composer, puis déclarer l'issue.
///
/// L'issue est demandée **au retour**, pas avant : Yao ne sait pas encore si le
/// client va décrocher au moment où il tape sur le bouton. C'est ce qui rend la
/// déclaration honnête plutôt que machinale (R19).
class ActionsAppel {
  /// Crée le service d'appel.
  const ActionsAppel({
    required this.ref,
    this.composer = composerNumeroReel,
  });

  /// Portée Riverpod — les actions passent par le notifier de course.
  final WidgetRef ref;

  /// Composeur injecté.
  final ComposerNumero composer;

  /// Appelle le CLIENT et journalise l'intention (FR-030).
  ///
  /// L'ordre compte : on journalise **avant** de composer. Un appel passé dont
  /// la journalisation échouerait ne compterait pas pour la preuve, et Yao
  /// aurait dépensé son crédit pour rien.
  Future<void> appelerClient(
    BuildContext context, {
    required EtatCourse etat,
    required String motif,
  }) async {
    final numero = etat.client.telephone;
    final livraison = etat.livraisonId;
    if (numero == null || livraison == null) return;
    await _appeler(context, livraison: livraison, numero: numero, motif: motif);
  }

  /// Appelle le VENDEUR d'un arrêt (FR-032).
  Future<void> appelerVendeur(
    BuildContext context, {
    required EtatCourse etat,
    required ArretCourse arret,
    String motif = 'substitution',
  }) async {
    final numero = arret.telephoneVendeur;
    final livraison = etat.livraisonId;
    if (numero == null || livraison == null) return;
    await _appeler(
      context,
      livraison: livraison,
      numero: numero,
      motif: motif,
      vers: 'vendeur',
      prestataireId: arret.prestataireId,
    );
  }

  Future<void> _appeler(
    BuildContext context, {
    required String livraison,
    required String numero,
    required String motif,
    String vers = 'client',
    String? prestataireId,
  }) async {
    final notifier = ref.read(etatCourseActiveProvider.notifier);
    final uuidClient = await notifier.journaliserAppel(
      livraisonId: livraison,
      vers: vers,
      motif: motif,
      prestataireId: prestataireId,
    );
    await composer(numero);
    if (!context.mounted) return;
    // Au RETOUR d'appel seulement : Yao sait maintenant ce qui s'est passé.
    final issue = await FeuilleIssueAppel.ouvrir(context);
    if (issue == null) return;
    await notifier.declarerIssueAppel(
      livraisonId: livraison,
      uuidClient: uuidClient,
      issue: issue,
    );
  }
}

/// Demande l'issue au retour d'un appel (K4-1e affiche « sans réponse »).
class FeuilleIssueAppel extends StatelessWidget {
  /// Crée la feuille.
  const FeuilleIssueAppel({super.key});

  /// Ouvre la feuille et rend l'issue déclarée, ou `null` si Yao l'ignore.
  static Future<String?> ouvrir(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => const FeuilleIssueAppel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.crsAppelIssueQuestion,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: MefaliTokens.space3),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop('repondu'),
              child: Text(l10n.crsAppelIssueRepondu),
            ),
            const SizedBox(height: MefaliTokens.space2),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop('sans_reponse'),
              child: Text(l10n.crsAppelIssueSansReponse),
            ),
            const SizedBox(height: MefaliTokens.space3),
            // La mention qui évite le pire malentendu : appeler depuis le
            // répertoire ne compte pas, et Yao doit l'apprendre AVANT l'échec.
            Text(
              l10n.crsAppelsSeulsViaAppComptent,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: MefaliTokens.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
