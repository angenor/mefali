import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';

/// Feuille de réglage de l'**offre de livraison** du vendeur (VND-08 minimal,
/// FR-046).
///
/// Trois choix, un seuil quand il en faut un, et un rappel que le vendeur doit
/// lire AVANT de valider : les commandes déjà passées ne changent pas de prix
/// (FR-048). Le découvrir après un appel client serait le pire moment.
///
/// Réf. `docs/design/png/V1-statut-boutique.png` — motifs de réglage (carte,
/// titre, aide, bouton pleine largeur). ⚠ **Écart assumé** : aucune planche de
/// paiement ni de VND-08 n'existe (plan.md, Complexity Tracking) ; le badge
/// « livraison gratuite » côté client relève du reste de VND-08 (FR-049,
/// FR-114) et n'est pas construit ici.
Future<void> afficherFeuilleOffreLivraison(
  BuildContext context, {
  required String offre,
  required int? seuilUnites,
  required String devise,
  required Future<String?> Function(String offre, int? seuilUnites)
      onEnregistrer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FeuilleOffreLivraison(
      offre: offre,
      seuilUnites: seuilUnites,
      devise: devise,
      onEnregistrer: onEnregistrer,
    ),
  );
}

class _FeuilleOffreLivraison extends StatefulWidget {
  const _FeuilleOffreLivraison({
    required this.offre,
    required this.seuilUnites,
    required this.devise,
    required this.onEnregistrer,
  });

  final String offre;
  final int? seuilUnites;
  final String devise;
  final Future<String?> Function(String offre, int? seuilUnites) onEnregistrer;

  @override
  State<_FeuilleOffreLivraison> createState() => _FeuilleOffreLivraisonState();
}

class _FeuilleOffreLivraisonState extends State<_FeuilleOffreLivraison> {
  /// Brouillon LOCAL (constitution XII) : rien n'est engagé tant que le vendeur
  /// n'a pas validé.
  late String _offre;
  late final TextEditingController _seuil;
  bool _enCours = false;
  String? _erreurCle;

  @override
  void initState() {
    super.initState();
    _offre = widget.offre;
    _seuil = TextEditingController(
      text: widget.seuilUnites?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _seuil.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final l10n = AppLocalizations.of(context)!;
    final seuil = int.tryParse(_seuil.text.trim());
    // Contrôle LOCAL avant l'aller-retour : le serveur refuse de toute façon
    // (`400 offre_seuil_manquant`), mais faire voyager une saisie qu'on sait
    // invalide ferait attendre le vendeur pour rien.
    if (_offre == 'au_dela' && (seuil == null || seuil <= 0)) {
      setState(() => _erreurCle = l10n.payOffreSeuilManquant);
      return;
    }
    setState(() {
      _enCours = true;
      _erreurCle = null;
    });
    final refus = await widget.onEnregistrer(
      _offre,
      _offre == 'au_dela' ? seuil : null,
    );
    if (!mounted) return;
    if (refus != null) {
      setState(() {
        _enCours = false;
        _erreurCle = refus;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: MefaliTokens.space3,
        right: MefaliTokens.space3,
        top: MefaliTokens.space3,
        bottom: MediaQuery.of(context).viewInsets.bottom + MefaliTokens.space3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.payOffreLivraisonTitre, style: textTheme.titleLarge),
          const SizedBox(height: MefaliTokens.space3),
          for (final (valeur, libelle) in [
            ('jamais', l10n.payOffreJamais),
            ('toujours', l10n.payOffreToujours),
            ('au_dela', l10n.payOffreAuDela),
          ])
            // `RadioGroup` n'existe pas dans la version de Flutter figée par le
            // lockfile — les versions ne bougent pas au milieu d'un cycle
            // (constitution X).
            RadioListTile<String>(
              value: valeur,
              // ignore: deprecated_member_use
              groupValue: _offre,
              // ignore: deprecated_member_use
              onChanged: _enCours
                  ? null
                  : (v) => setState(() {
                        _offre = v ?? 'jamais';
                        _erreurCle = null;
                      }),
              title: Text(libelle),
              contentPadding: EdgeInsets.zero,
            ),
          if (_offre == 'au_dela') ...[
            const SizedBox(height: MefaliTokens.space2),
            TextField(
              controller: _seuil,
              enabled: !_enCours,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.payOffreSeuilLibelle,
                suffixText: libelleDevise(widget.devise),
              ),
            ),
          ],
          const SizedBox(height: MefaliTokens.space3),
          // FR-048, dit AVANT la validation — pas après.
          Row(
            children: [
              const Icon(Symbols.info, size: 20, color: MefaliTokens.textMuted),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Text(
                  l10n.payOffreRappelCommandesEnCours,
                  style: textTheme.labelSmall
                      ?.copyWith(color: MefaliTokens.textMuted),
                ),
              ),
            ],
          ),
          if (_erreurCle != null) ...[
            const SizedBox(height: MefaliTokens.space2),
            Text(
              _erreurCle!,
              style: textTheme.bodySmall?.copyWith(color: MefaliTokens.danger),
            ),
          ],
          const SizedBox(height: MefaliTokens.space3),
          FilledButton(
            onPressed: _enCours ? null : _enregistrer,
            child: Text(l10n.proArticleEnregistrer),
          ),
        ],
      ),
    );
  }
}
