import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import 'etat_course.dart';

/// Traduit un refus **définitif** du serveur en une phrase que Yao comprend
/// (FR-084).
///
/// Le serveur rend un `code` court ; c'est **ici et seulement ici** qu'il
/// devient du texte. Un écran qui composerait sa propre phrase dériverait au
/// premier changement de règle, et deux écrans en composeraient deux
/// différentes pour le même refus.
///
/// Une clé inconnue rend le message générique plutôt que la clé elle-même : un
/// serveur plus récent que l'app est un cas normal (Shorebird patche le Dart,
/// pas le backend).
String messageReconciliation(AppLocalizations l10n, String cleOuCode) {
  final code = cleOuCode.split('.').last;
  return switch (code) {
    'non_proprietaire' => l10n.crsReconciliationCourseRetiree,
    'etat_incompatible' => l10n.crsReconciliationArretDejaCollecte,
    _ => l10n.crsReconciliationEtatIncompatible,
  };
}

/// **FR-086** — la trace consultable des actions refusées au rejeu.
///
/// Pourquoi cet écran existe : derrière une collecte refusée, il y a une avance
/// que Yao a **réellement engagée**. Sans trace, il n'aurait que sa parole face
/// à l'exploitation — et « le coursier ne perd jamais » deviendrait une formule.
/// L'écran ne propose donc rien à réessayer : il constate, horodate, et laisse
/// Yao effacer une fois qu'il en a parlé.
class JournalReconciliation extends ConsumerWidget {
  /// Crée le journal.
  const JournalReconciliation({super.key});

  /// Ouvre le journal en page pleine.
  static Future<void> ouvrir(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const JournalReconciliation()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final refus = ref.watch(
      etatCourseActiveProvider.select(
        (e) => e.value?.refus ?? const <RefusReconciliation>[],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.crsReconciliationJournalTitre),
        actions: [
          if (refus.isNotEmpty)
            IconButton(
              icon: const Icon(Symbols.delete_sweep_rounded),
              tooltip: l10n.crsReconciliationJournalEffacer,
              onPressed: () async {
                await ref.read(fileActionsProvider).effacerRefus();
                ref.invalidate(etatCourseActiveProvider);
              },
            ),
        ],
      ),
      body: refus.isEmpty
          ? Center(child: Text(l10n.crsReconciliationJournalVide))
          : ListView.separated(
              padding: const EdgeInsets.all(MefaliTokens.screenMargin),
              itemCount: refus.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: MefaliTokens.space2),
              itemBuilder: (_, i) => _LigneRefus(refus: refus[i]),
            ),
    );
  }
}

class _LigneRefus extends StatelessWidget {
  const _LigneRefus({required this.refus});

  final RefusReconciliation refus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: ListTile(
        leading: const Icon(Symbols.sync_problem_rounded,
            color: MefaliTokens.warning),
        title: Text(messageReconciliation(l10n, refus.motifCle)),
        subtitle: Text(
          // L'heure de l'ACTION, pas celle du refus : c'est le moment que Yao
          // se rappelle (« j'étais chez Adjoua à 14h32 »).
          l10n.crsReconciliationFaiteA(_heure(refus.creeLeLocal)),
          style: textTheme.bodySmall?.copyWith(color: MefaliTokens.textMuted),
        ),
      ),
    );
  }

  static String _heure(DateTime quand) {
    final local = quand.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
