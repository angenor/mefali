/// Feuille **« Article manquant »** (CMD-06, US7) — maquette `C4-4c`.
///
/// Elle s'ouvre PAR-DESSUS le suivi : le client n'est pas sorti de sa commande,
/// on lui demande une décision au milieu. Trois choses doivent y être lisibles
/// en une seconde, parce qu'il en a soixante pour trancher :
///
/// 1. **l'écart de prix**, en toutes lettres (« 600 FCFA au lieu de 500 ») ;
/// 2. le **compte à rebours**, qui descend réellement — un chiffre figé serait
///    un mensonge sur le temps qui reste ;
/// 3. ce qui se passera **s'il ne répond pas** : on appelle, puis l'article est
///    retiré et rien n'est payé pour lui (FR-046). Un client qui sait ce que
///    coûte son silence n'a pas besoin de se presser.
///
/// À zéro, la feuille désarme ses deux boutons : la fenêtre est une promesse
/// faite au coursier autant qu'au client — passé le délai, il a déjà agi, et
/// l'API refuserait la décision de toute façon (`409 substitution_expiree`).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

import 'etat_suivi.dart';

/// Feuille de décision d'un remplacement proposé par le coursier.
class FeuilleSubstitution extends StatefulWidget {
  /// Crée la feuille.
  const FeuilleSubstitution({
    required this.substitution,
    required this.devise,
    this.onAccepter,
    this.onRefuser,
    super.key,
  });

  /// Proposition en attente de décision.
  final SubstitutionVue substitution;

  /// Devise ISO 4217 des montants affichés.
  final String devise;

  /// Acceptation (`POST …/decision` avec `accepte: true`).
  final VoidCallback? onAccepter;

  /// Refus — l'article est alors retiré, et non facturé.
  final VoidCallback? onRefuser;

  @override
  State<FeuilleSubstitution> createState() => _FeuilleSubstitutionState();
}

class _FeuilleSubstitutionState extends State<FeuilleSubstitution> {
  late int _resteS;
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    _resteS = widget.substitution.resteS;
    // ⚠ Le minuteur n'est QU'un affichage. L'échéance qui fait foi est
    // persistée côté serveur (research R10) : si l'app est tuée, mise en
    // veille ou en retard, la décision reste refusée après l'échéance. Un
    // compte à rebours local ne décide de rien — il informe.
    if (_resteS > 0) {
      _minuteur = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _resteS = _resteS > 0 ? _resteS - 1 : 0);
        if (_resteS == 0) _minuteur?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  /// Fenêtre encore ouverte : les boutons ne sont actifs que là.
  bool get _ouverte => _resteS > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sub = widget.substitution;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.substitutionTitre,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                // Le compte à rebours, visible en permanence (C4-4c).
                Chip(
                  label: Text(l10n.substitutionCompteARebours(_resteS)),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                ),
              ],
            ),
            const SizedBox(height: MefaliTokens.space3),
            Text(
              l10n.substitutionProposition(
                sub.articleNom,
                formaterMontant(sub.prixUnites, widget.devise),
                formaterMontant(sub.ancienPrixUnites, widget.devise),
              ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: MefaliTokens.space3),
            // Ce qui se passe SANS réponse — écrit d'avance, pas découvert
            // après coup (FR-046).
            Container(
              padding: const EdgeInsets.all(MefaliTokens.space3),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
              ),
              child: Text(
                l10n.substitutionIssueParDefaut,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: MefaliTokens.space4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _ouverte ? widget.onRefuser : null,
                    child: Text(l10n.substitutionRefuser),
                  ),
                ),
                const SizedBox(width: MefaliTokens.space3),
                Expanded(
                  child: FilledButton(
                    onPressed: _ouverte ? widget.onAccepter : null,
                    child: Text(l10n.substitutionAccepter),
                  ),
                ),
              ],
            ),
            if (!_ouverte) ...[
              const SizedBox(height: MefaliTokens.space2),
              Text(
                l10n.substitutionErreurExpiree,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
