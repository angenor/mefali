import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import 'ecran_scan.dart';
import 'etat_course.dart';

/// Écran K3 — course active du coursier : liste d'arrêts, arrêt courant, gros
/// bouton de scan. Réf. `docs/design/png/K3-course-active.png`. Widgets M3
/// thémés `mefali_core` (constitution XI), constructeurs `.adaptive`.
class EcranCourseActive extends ConsumerWidget {
  /// Crée l'écran de course active. [entete] (optionnel) est rendu en tête du
  /// corps, DANS l'unique Scaffold — la bascule de rôle du coursier bi-rôle y
  /// passe sans imbriquer un second Scaffold (FR-046).
  const EcranCourseActive({super.key, this.entete});

  /// Widget d'entête optionnel (ex. bascule de rôle).
  final Widget? entete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncEtat = ref.watch(etatCourseActiveProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.courseTitre)),
      body: SafeArea(
        child: Column(
          children: [
            if (entete != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MefaliTokens.screenMargin,
                  MefaliTokens.space3,
                  MefaliTokens.screenMargin,
                  0,
                ),
                child: entete,
              ),
            Expanded(
              child: asyncEtat.when(
                loading: () => const _ChargementCourse(),
                error: (_, _) => Center(child: Text(l10n.courseAucune)),
                data: (etat) => _CorpsCourse(etat: etat),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChargementCourse extends StatelessWidget {
  const _ChargementCourse();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(MefaliTokens.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Squelette(hauteur: 72),
          SizedBox(height: MefaliTokens.space3),
          Squelette(hauteur: 72),
        ],
      ),
    );
  }
}

class _CorpsCourse extends ConsumerWidget {
  const _CorpsCourse({required this.etat});

  final EtatCourse etat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (etat.arrets.isEmpty) {
      return Center(
        child: Text(l10n.courseAucune, style: Theme.of(context).textTheme.bodyLarge),
      );
    }
    final courant = etat.arretCourant;

    return Padding(
      padding: const EdgeInsets.all(MefaliTokens.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (etat.horsLigne) ...[
            BandeauHorsLigne(message: l10n.courseHorsLigne),
            const SizedBox(height: MefaliTokens.space3),
          ],
          if (etat.toutCollecte) ...[
            BandeauSucces(message: l10n.courseSuccesEnLivraison),
            const SizedBox(height: MefaliTokens.space3),
          ],
          Expanded(
            child: ListView.separated(
              itemCount: etat.arrets.length,
              separatorBuilder: (_, _) => const SizedBox(height: MefaliTokens.space2),
              itemBuilder: (_, i) => _CarteArret(
                arret: etat.arrets[i],
                courant: courant?.arretId == etat.arrets[i].arretId,
              ),
            ),
          ),
          if (courant != null) ...[
            const SizedBox(height: MefaliTokens.space3),
            BoutonPrincipal(
              libelle: l10n.courseScannerQr,
              picto: Symbols.qr_code_scanner,
              onPresse: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EcranScan(arret: courant),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteArret extends StatelessWidget {
  const _CarteArret({required this.arret, required this.courant});

  final ArretCourse arret;
  final bool courant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
        side: courant
            ? const BorderSide(color: MefaliTokens.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space3),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(arret.nom, style: textTheme.titleMedium),
                  const SizedBox(height: MefaliTokens.space1),
                  Text(
                    formaterMontant(arret.montantAvance, arret.devise),
                    style: textTheme.bodyMedium?.copyWith(color: MefaliTokens.textMuted),
                  ),
                ],
              ),
            ),
            _PuceStatut(collecte: arret.collecte),
          ],
        ),
      ),
    );
  }
}

class _PuceStatut extends StatelessWidget {
  const _PuceStatut({required this.collecte});

  final bool collecte;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (fond, accent, libelle, icone) = collecte
        ? (
            MefaliTokens.successTint,
            MefaliTokens.success,
            l10n.courseArretCollecte,
            Symbols.check_circle_rounded,
          )
        : (
            MefaliTokens.warningTint,
            MefaliTokens.warning,
            l10n.courseArretACollecter,
            Symbols.pending_rounded,
          );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MefaliTokens.space2,
        vertical: MefaliTokens.space1,
      ),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: accent),
          const SizedBox(width: MefaliTokens.space1),
          Text(libelle, style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
