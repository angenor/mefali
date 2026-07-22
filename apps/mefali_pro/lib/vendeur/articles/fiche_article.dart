import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import '../../roles/composants.dart';
import 'mes_articles.dart';

/// Pas des steppers de prix (maquette V2 1b : « Par pas de 100 FCFA ») —
/// constante d'app MVP, comme les durées de pause (spec, Assumptions).
const int pasDePrix = 100;

/// Fiche article — V2 vue 1b (`docs/design/png/V2-catalogue-stock.png`) :
/// prix en STEPPERS ± (pas de clavier obligatoire), toggle promo avec prix
/// normal barré et aperçu « Le client verra », enregistrer en bas (FR-045).
///
/// Le BROUILLON est un état strictement LOCAL (constitution XII — jamais
/// providerifié) ; seule la soumission passe par `MesArticles`.
class FicheArticle extends ConsumerStatefulWidget {
  /// Crée la fiche — `article` absent = création (FR-020).
  const FicheArticle({super.key, required this.prestataireId, this.article});

  /// Prestataire piloté.
  final String prestataireId;

  /// Article édité, ou `null` pour un ajout.
  final ArticleVendeur? article;

  @override
  ConsumerState<FicheArticle> createState() => _FicheArticleState();
}

class _FicheArticleState extends ConsumerState<FicheArticle> {
  late final TextEditingController _nom;
  late int _prix;
  late bool _promoActive;
  late int _prixBarre;
  late bool _disponible;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    final article = widget.article;
    _nom = TextEditingController(text: article?.nom ?? '');
    _prix = article?.prixUnites ?? 1000;
    _promoActive = article?.prixBarreUnites != null;
    _prixBarre = article?.prixBarreUnites ?? _prix + pasDePrix;
    _disponible = article?.disponible ?? true;
  }

  /// Bascule immédiate de la disponibilité (FR-045) — revert si le serveur
  /// refuse (rupture admin, réseau).
  Future<void> _basculer(bool valeur) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _disponible = valeur);
    try {
      await ref
          .read(mesArticlesProvider(widget.prestataireId).notifier)
          .basculerDisponibilite(widget.article!.id, valeur);
    } catch (_) {
      if (mounted) {
        setState(() => _disponible = !valeur);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.proArticleErreurEnregistrement)),
        );
      }
    }
  }

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  /// FR-023 côté écran : promo active ⇒ prix barré STRICTEMENT supérieur.
  bool get _promoInvalide => _promoActive && _prixBarre <= _prix;

  Future<void> _enregistrer() async {
    final l10n = AppLocalizations.of(context)!;
    final notifier =
        ref.read(mesArticlesProvider(widget.prestataireId).notifier);
    setState(() => _enCours = true);
    try {
      final article = widget.article;
      if (article == null) {
        await notifier.creer(
          nom: _nom.text.trim(),
          prixUnites: _prix,
          prixBarreUnites: _promoActive ? _prixBarre : null,
        );
      } else {
        await notifier.modifier(
          article.id,
          nom: _nom.text.trim(),
          prixUnites: _prix,
          prixBarreUnites: _promoActive ? _prixBarre : null,
          retirerPrixBarre: !_promoActive && article.prixBarreUnites != null,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _enCours = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.proArticleErreurEnregistrement)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final article = widget.article;
    final devise = article?.devise ?? 'XOF';

    return Scaffold(
      appBar: AppBar(
        title: Text(article?.nom ?? l10n.proArticleNouveauTitre),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          children: [
            TextField(
              controller: _nom,
              decoration: InputDecoration(labelText: l10n.proArticleNom),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: MefaliTokens.space3),
            CarteMefali(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.proArticlePrixNormal, style: textTheme.titleMedium),
                  const SizedBox(height: MefaliTokens.space2),
                  _Stepper(
                    texte: formaterMontant(_prix, devise),
                    barre: _promoActive,
                    onMoins: _prix >= pasDePrix
                        ? () => setState(() => _prix -= pasDePrix)
                        : null,
                    onPlus: () => setState(() => _prix += pasDePrix),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MefaliTokens.space3),
            CarteMefali(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.proArticlePrixPromo,
                          style: textTheme.titleMedium,
                        ),
                      ),
                      Switch.adaptive(
                        value: _promoActive,
                        onChanged: (valeur) =>
                            setState(() => _promoActive = valeur),
                      ),
                    ],
                  ),
                  if (_promoActive) ...[
                    const SizedBox(height: MefaliTokens.space2),
                    // Sur la maquette, le stepper promo édite le PRIX PROMO ;
                    // le prix normal devient le prix barré affiché au client.
                    _Stepper(
                      texte: formaterMontant(_prixBarre, devise),
                      accent: true,
                      onMoins: _prixBarre >= pasDePrix
                          ? () => setState(() => _prixBarre -= pasDePrix)
                          : null,
                      onPlus: () => setState(() => _prixBarre += pasDePrix),
                    ),
                    const SizedBox(height: MefaliTokens.space2),
                    if (_promoInvalide)
                      Text(
                        l10n.proArticlePromoInvalide,
                        style: textTheme.labelSmall
                            ?.copyWith(color: MefaliTokens.danger),
                      )
                    else
                      Text.rich(
                        TextSpan(
                          text: '${l10n.proArticleApercu} ',
                          style: textTheme.bodyLarge
                              ?.copyWith(color: MefaliTokens.textMuted),
                          children: [
                            TextSpan(
                              text: formaterMontant(_prix, devise),
                              style: textTheme.bodyLarge?.copyWith(
                                color: MefaliTokens.success,
                                fontWeight: MefaliTokens.weightSemiBold,
                              ),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: formaterMontant(_prixBarre, devise),
                              style: textTheme.bodyLarge?.copyWith(
                                color: MefaliTokens.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: MefaliTokens.space1),
                    Text(
                      l10n.proArticlePasDePrix,
                      style: textTheme.labelSmall
                          ?.copyWith(color: MefaliTokens.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (article != null && !article.retire) ...[
              const SizedBox(height: MefaliTokens.space3),
              // Carte « Disponible à la vente » (maquette V2 1b) — bascule
              // immédiate, indépendante du brouillon.
              CarteMefali(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.proArticleDisponibleVente,
                            style: textTheme.titleMedium,
                          ),
                          Text(
                            article.ruptureAdmin
                                ? l10n.proArticleRuptureAdmin
                                : l10n.proArticleDisponibleAide,
                            style: textTheme.labelSmall
                                ?.copyWith(color: MefaliTokens.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _disponible,
                      onChanged: article.ruptureAdmin ? null : _basculer,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: MefaliTokens.space4),
            BoutonPrincipal(
              libelle: l10n.proArticleEnregistrer,
              picto: Symbols.check,
              enCours: _enCours,
              actif: _nom.text.trim().isNotEmpty && !_promoInvalide,
              onPresse: _enregistrer,
            ),
          ],
        ),
      ),
    );
  }
}

/// Stepper ± de la maquette (édition sans clavier obligatoire).
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.texte,
    required this.onPlus,
    this.onMoins,
    this.barre = false,
    this.accent = false,
  });

  final String texte;
  final VoidCallback? onMoins;
  final VoidCallback onPlus;

  /// Rendu barré (le prix normal quand la promo est active).
  final bool barre;

  /// Rendu accentué (le prix promo — display success sur la maquette).
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        IconButton.outlined(
          onPressed: onMoins,
          icon: const Icon(Symbols.remove),
          tooltip: '-',
        ),
        Expanded(
          child: Text(
            texte,
            textAlign: TextAlign.center,
            style: (accent ? textTheme.displayLarge : textTheme.titleLarge)
                ?.copyWith(
              color: accent ? MefaliTokens.success : MefaliTokens.text,
              fontSize: accent ? 28 : null,
              decoration: barre ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        IconButton.outlined(
          onPressed: onPlus,
          icon: const Icon(Symbols.add),
          tooltip: '+',
        ),
      ],
    );
  }
}
