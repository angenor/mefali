/// Accueil de l'app cliente (cycle CMD 008, T067).
///
/// Remplace `AccueilProvisoire` : c'est d'ici que partent les deux seuls
/// chemins que le cycle CMD produit — **suivre une commande** (`GET
/// /moi/commandes` → C4) et **en composer une** (fiche vendeur → C3).
///
/// La découverte des vendeurs (recherche, tri par distance et fiabilité)
/// appartient au module VND et n'est pas construite ici : on ouvre une fiche
/// par son lien, comme la plaque du vendeur et sa page publique y mènent.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../l10n/app_localizations.dart';
import '../panier/etat_panier.dart';
import 'actions_commande.dart';
import 'ecran_vendeur.dart';
import 'pages_commande.dart';

part 'accueil.g.dart';

/// Les commandes du compte. `@riverpod` nu (autoDispose) : liste d'accueil,
/// rechargée à chaque venue — une commande avance pendant qu'on ne la regarde
/// pas. `retry: pasDeRetry` : hors ligne, `ActionsCommande` rend déjà celles du
/// cache ; réessayer en boucle ne ferait que vider la batterie.
@Riverpod(retry: pasDeRetry)
Future<List<CommandeResumeeVue>> mesCommandes(Ref ref) =>
    ref.read(actionsCommandeProvider).mesCommandes();

/// Accueil : mes commandes, l'accès au panier, l'ouverture d'un vendeur.
class AccueilClient extends ConsumerWidget {
  /// Crée l'accueil.
  const AccueilClient({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = AppLocalizations.of(context)!;
    final commandes = ref.watch(mesCommandesProvider);
    final panier = ref.watch(panierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(app.appTitle),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(mesCommandesProvider),
            icon: const Icon(Symbols.refresh_rounded),
            tooltip: app.accueilCommandesTitre,
          ),
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () async => ref.invalidate(mesCommandesProvider),
        child: ListView(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          children: [
            _OuvrirVendeur(),
            const SizedBox(height: MefaliTokens.space4),
            Text(
              app.accueilCommandesTitre,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: MefaliTokens.space2),
            ...commandes.when(
              loading: () => [
                const Center(child: CircularProgressIndicator.adaptive()),
              ],
              error: (_, _) => [Text(app.accueilCommandesErreur)],
              data: (liste) => liste.isEmpty
                  ? [Text(app.accueilAucuneCommande)]
                  : [for (final c in liste) _CarteCommande(commande: c)],
            ),
          ],
        ),
      ),
      bottomNavigationBar: panier.estVide
          ? null
          : Padding(
              padding: const EdgeInsets.all(MefaliTokens.space4),
              child: FilledButton.icon(
                onPressed: () => ouvrirPanier(context),
                icon: const Icon(Symbols.shopping_basket_rounded),
                label: Text(app.accueilVoirPanier(panier.nbArticles)),
              ),
            ),
    );
  }
}

/// Le champ qui ouvre une fiche vendeur depuis son lien ou son identifiant.
class _OuvrirVendeur extends ConsumerStatefulWidget {
  @override
  ConsumerState<_OuvrirVendeur> createState() => _OuvrirVendeurState();
}

class _OuvrirVendeurState extends ConsumerState<_OuvrirVendeur> {
  // État strictement LOCAL (constitution XII) : un champ de saisie n'a aucune
  // raison de vivre dans un provider.
  final TextEditingController _saisie = TextEditingController();

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _saisie,
              decoration: InputDecoration(
                labelText: app.accueilVendeurIdentifiant,
                helperText: app.accueilVendeurAide,
                helperMaxLines: 2,
              ),
              onSubmitted: (_) => _ouvrir(),
            ),
            const SizedBox(height: MefaliTokens.space3),
            FilledButton.tonalIcon(
              onPressed: _ouvrir,
              icon: const Icon(Symbols.storefront_rounded),
              label: Text(app.accueilOuvrirVendeur),
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrir() {
    final id = identifiantVendeur(_saisie.text);
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EcranVendeur(
          prestataireId: id,
          onVoirPanier: () => ouvrirPanier(context),
        ),
      ),
    );
  }
}

/// Extrait l'identifiant d'un vendeur d'un lien de plaque ou d'une saisie
/// directe. `null` si rien d'exploitable — on n'ouvre pas une fiche au hasard.
///
/// Accepte `mefali.com/v/{id}`, `.../prestataires/{id}` ou l'UUID seul : les
/// trois formes circulent (page publique, plaque, support), et exiger la bonne
/// serait un piège de plus pour la cliente.
String? identifiantVendeur(String saisie) {
  final texte = saisie.trim();
  if (texte.isEmpty) return null;
  final uuid = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  ).firstMatch(texte);
  return uuid?.group(0)?.toLowerCase();
}

class _CarteCommande extends StatelessWidget {
  const _CarteCommande({required this.commande});

  final CommandeResumeeVue commande;

  @override
  Widget build(BuildContext context) {
    final core = MefaliCoreLocalizations.of(context)!;
    final app = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        leading: Icon(
          commande.enCours
              ? Symbols.local_shipping_rounded
              : Symbols.check_circle_rounded,
        ),
        title: Text(formaterMontant(commande.totalUnites, commande.devise)),
        // L'état vient du serveur en CLÉ i18n : c'est ici qu'il devient une
        // phrase, jamais côté serveur (constitution VII).
        subtitle: Text(libelleEtatSuivi(core, app, commande.etatCle)),
        trailing: const Icon(Symbols.chevron_right_rounded),
        onTap: () => ouvrirSuivi(context, commande.id),
      ),
    );
  }
}
