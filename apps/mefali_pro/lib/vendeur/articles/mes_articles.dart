import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mes_articles.g.dart';

/// Le catalogue du prestataire piloté (écran V2 — FR-045). Famille par
/// prestataire, `@riverpod` nu (autoDispose) : liste d'écran, patron
/// `MesAdresses` du cycle 003.
@riverpod
class MesArticles extends _$MesArticles {
  @override
  Future<List<ArticleVendeur>> build(String prestataireId) => _charger();

  Future<List<ArticleVendeur>> _charger() async {
    final reponse = await ref
        .read(clientSessionProvider)
        .getVendeurApi()
        .mesArticles(id: prestataireId);
    return reponse.data?.toList() ?? const [];
  }

  /// Réaffiche le squelette puis recharge (patron R9 du cycle 004).
  Future<void> recharger() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_charger);
  }

  /// Ajoute un article (FR-020 — disponible par défaut).
  Future<void> creer({
    required String nom,
    required int prixUnites,
    int? prixBarreUnites,
    String? categorieInterne,
  }) async {
    await ref.read(clientSessionProvider).getVendeurApi().creerArticle(
          id: prestataireId,
          creerArticleDto: CreerArticleDto((b) => b
            ..nom = nom
            ..prixUnites = prixUnites
            ..prixBarreUnites = prixBarreUnites
            ..categorieInterne = categorieInterne),
        );
    await recharger();
  }

  /// Modifie prix / promo / nom — un prix barré qui deviendrait ≤ prix fait
  /// ÉCHOUER l'appel (422), la promotion n'est jamais retirée en silence
  /// (FR-023) : l'erreur remonte à l'écran.
  Future<void> modifier(
    String articleId, {
    String? nom,
    int? prixUnites,
    int? prixBarreUnites,
    bool retirerPrixBarre = false,
    String? categorieInterne,
  }) async {
    await ref.read(clientSessionProvider).getVendeurApi().modifierArticle(
          id: prestataireId,
          articleId: articleId,
          modifierArticleDto: ModifierArticleDto((b) {
            b
              ..nom = nom
              ..categorieInterne = categorieInterne;
            if (retirerPrixBarre) {
              // built_value omet les champs nuls : le drapeau dédié porte le
              // « null explicite » du contrat (retrait de promotion).
              b.retirerPrixBarre = true;
            } else if (prixBarreUnites != null) {
              b.prixBarreUnites = prixBarreUnites;
            }
            if (prixUnites != null) b.prixUnites = prixUnites;
          }),
        );
    await recharger();
  }

  /// Retire du catalogue — RÉVERSIBLE, la ligne subsiste (FR-055).
  Future<void> retirer(String articleId) async {
    await ref
        .read(clientSessionProvider)
        .getVendeurApi()
        .retirerArticle(id: prestataireId, articleId: articleId);
    await recharger();
  }

  /// Remet au catalogue sans ressaisie (FR-055).
  Future<void> remettre(String articleId) async {
    await ref
        .read(clientSessionProvider)
        .getVendeurApi()
        .remettreArticle(id: prestataireId, articleId: articleId);
    await recharger();
  }
}
