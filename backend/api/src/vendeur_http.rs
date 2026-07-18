//! Surface VENDEUR — consommée par Mefali Pro (écrans V1/V2, cycle 005).
//!
//! Garde à TROIS refus distincts (FR-008/FR-011, research R11) :
//! 1. `role_vendeur_requis` — le compte ne porte pas le rôle vendeur VALIDE
//!    (extracteur `Auth`, machine à états du cycle 003) ;
//! 2. `prestataire_non_rattache` — le rôle seul n'autorise rien, c'est le
//!    rattachement qui délimite ;
//! 3. `prestataire_non_agree` — capacités DÉRIVÉES de l'état du prestataire :
//!    une suspension coupe tout SANS toucher au rôle (aucune cascade).

use actix_multipart::form::MultipartForm;
use actix_web::{get, post, put, web, HttpResponse};
use serde::Serialize;
use utoipa::ToSchema;
use uuid::Uuid;

use comptes::Role;
use prestataires::{ModificationArticle, NouvelArticle, PgPrestataires, SourceBascule};

use crate::admin_prestataires_http::{DepotPhotoDto, PhotoForm};
use crate::auth_http::{Auth, ErreurApiDto};
use crate::prestataires_http::{
    article_vendeur_dto, sql, ArticleVendeurDto, CreerArticleDto, EffectifBoutiqueDto,
    ErreurPresta, ModifierArticleDto, StatutPrestataireDto,
};

/// Garde commune des endpoints `/vendeur/prestataires/{id}/…`.
pub(crate) async fn exiger_pilotage(
    auth: &Auth,
    depot: &PgPrestataires,
    prestataire: Uuid,
) -> Result<(), ErreurPresta> {
    if !auth.a_role(Role::Vendeur) {
        return Err(ErreurPresta::RoleVendeurRequis);
    }
    depot
        .exiger_pilotage(auth.compte_id, prestataire)
        .await
        .map_err(ErreurPresta::from)
}

/// Prestataire pilotable par le compte (résumé — l'app prend le premier).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PrestatairePilotable)]
pub struct PrestatairePilotableDto {
    /// Identifiant.
    pub id: Uuid,
    /// Nom public.
    pub nom: String,
    /// Cycle de vie — `suspendu` : l'app affiche le refus, le rôle est intact.
    pub statut: StatutPrestataireDto,
    /// État effectif de la boutique.
    pub boutique: EffectifBoutiqueDto,
}

/// Prestataires que ce compte pilote (rattachements du cycle VND).
#[utoipa::path(
    get,
    path = "/vendeur/prestataires",
    tag = "vendeur",
    responses(
        (status = 200, description = "Prestataires rattachés, plus ancien rattachement \
         d'abord — l'app pilote le premier au MVP (aucune sélection de site n'existe, \
         FR-019).", body = [PrestatairePilotableDto]),
        (status = 403, description = "Rôle vendeur requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/vendeur/prestataires")]
pub async fn mes_prestataires(
    auth: Auth,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    if !auth.a_role(Role::Vendeur) {
        return Err(ErreurPresta::RoleVendeurRequis);
    }
    let ids = depot.pilotables(auth.compte_id).await?;
    let mut sortie = Vec::with_capacity(ids.len());
    for id in ids {
        let p = depot.prestataire(id).await?;
        let boutique = depot
            .boutique(id)
            .await?
            .map(|(_, _, effectif)| effectif)
            .unwrap_or(prestataires::modele::EffectifBoutique {
                ouvert: false,
                reouverture_estimee: None,
            });
        sortie.push(PrestatairePilotableDto {
            id: p.id,
            nom: p.nom,
            statut: p.statut.into(),
            boutique: boutique.into(),
        });
    }
    Ok(HttpResponse::Ok().json(sortie))
}

// ── Catalogue (écran V2 — FR-045, FR-020..023, FR-055) ─────────────────────

/// Catalogue COMPLET du prestataire piloté (ruptures, retirés, verrou admin).
#[utoipa::path(
    get,
    path = "/vendeur/prestataires/{id}/articles",
    tag = "vendeur",
    params(("id" = Uuid, Path, description = "Prestataire piloté.")),
    responses(
        (status = 200, description = "Catalogue de pilotage — les retirés en tête de leur \
         groupe, remise possible sans ressaisie (FR-055).", body = [ArticleVendeurDto]),
        (status = 403, description = "Rôle vendeur absent, non rattaché, ou prestataire non \
         agréé (trois codes distincts — R11).", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/vendeur/prestataires/{id}/articles")]
pub async fn mes_articles(
    auth: Auth,
    chemin: web::Path<Uuid>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    let prestataire = chemin.into_inner();
    exiger_pilotage(&auth, &depot, prestataire).await?;
    let articles = depot.articles_du_vendeur(prestataire).await?;
    let mut sortie = Vec::with_capacity(articles.len());
    for article in articles {
        sortie.push(article_vendeur_dto(&depot, article).await?);
    }
    Ok(HttpResponse::Ok().json(sortie))
}

/// Ajoute un article au catalogue (V2 — « + Ajouter un article »).
#[utoipa::path(
    post,
    path = "/vendeur/prestataires/{id}/articles",
    tag = "vendeur",
    params(("id" = Uuid, Path, description = "Prestataire piloté.")),
    request_body = CreerArticleDto,
    responses(
        (status = 201, description = "Article créé, disponible par défaut (FR-020). Émet \
         `article.cree`.", body = ArticleVendeurDto),
        (status = 422, description = "Prix barré ≤ prix (FR-023), montant négatif, nom vide.",
         body = ErreurApiDto),
        (status = 403, description = "Refus de pilotage (trois codes distincts).", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/vendeur/prestataires/{id}/articles")]
pub async fn creer_article(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<CreerArticleDto>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    let prestataire = chemin.into_inner();
    exiger_pilotage(&auth, &depot, prestataire).await?;
    let corps = corps.into_inner();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let article = depot
        .creer_article(
            &mut tx,
            prestataire,
            &NouvelArticle {
                nom: corps.nom,
                prix_unites: corps.prix_unites,
                prix_barre_unites: corps.prix_barre_unites,
                categorie_interne: corps.categorie_interne,
            },
            SourceBascule::Vendeur,
            auth.compte_id,
        )
        .await?;
    tx.commit().await.map_err(sql)?;
    Ok(HttpResponse::Created().json(article_vendeur_dto(&depot, article).await?))
}

/// Modifie nom / prix / prix barré / étiquette (fiche article V2).
#[utoipa::path(
    put,
    path = "/vendeur/prestataires/{id}/articles/{article_id}",
    tag = "vendeur",
    params(
        ("id" = Uuid, Path, description = "Prestataire piloté."),
        ("article_id" = Uuid, Path, description = "Article."),
    ),
    request_body = ModifierArticleDto,
    responses(
        (status = 200, description = "Modifié — `prix_barre_unites: null` retire la promotion \
         EXPLICITEMENT. Un montant déjà FIGÉ ne bouge jamais (SC-005). Émet `article.modifie`.",
         body = ArticleVendeurDto),
        (status = 422, description = "Prix barré qui deviendrait ≤ prix : l'opération ÉCHOUE, \
         la promotion n'est pas retirée en silence (FR-023).", body = ErreurApiDto),
        (status = 404, description = "Article inconnu ou retiré du catalogue.", body = ErreurApiDto),
        (status = 403, description = "Refus de pilotage.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[put("/vendeur/prestataires/{id}/articles/{article_id}")]
pub async fn modifier_article(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    corps: web::Json<ModifierArticleDto>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    let (prestataire, article) = chemin.into_inner();
    exiger_pilotage(&auth, &depot, prestataire).await?;
    let corps = corps.into_inner();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let article = depot
        .modifier_article(
            &mut tx,
            prestataire,
            article,
            &ModificationArticle {
                nom: corps.nom,
                prix_unites: corps.prix_unites,
                // `retirer_prix_barre` ≡ `prix_barre_unites: null` (clients
                // générés — built_value ne sérialise pas un null explicite).
                prix_barre_unites: if corps.retirer_prix_barre.unwrap_or(false) {
                    Some(None)
                } else {
                    corps.prix_barre_unites
                },
                categorie_interne: corps.categorie_interne,
            },
            SourceBascule::Vendeur,
            auth.compte_id,
        )
        .await?;
    tx.commit().await.map_err(sql)?;
    Ok(HttpResponse::Ok().json(article_vendeur_dto(&depot, article).await?))
}

/// Dépose/remplace la photo de l'article (multipart, ≤ 5 Mo).
#[utoipa::path(
    post,
    path = "/vendeur/prestataires/{id}/articles/{article_id}/photo",
    tag = "vendeur",
    params(
        ("id" = Uuid, Path, description = "Prestataire piloté."),
        ("article_id" = Uuid, Path, description = "Article."),
    ),
    request_body(content = DepotPhotoDto, content_type = "multipart/form-data"),
    responses(
        (status = 200, description = "Photo remplacée (clé neuve, l'ancienne purgée après \
         commit).", body = ArticleVendeurDto),
        (status = 422, description = "Type refusé ou fichier trop volumineux.", body = ErreurApiDto),
        (status = 404, description = "Article inconnu ou retiré.", body = ErreurApiDto),
        (status = 403, description = "Refus de pilotage.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/vendeur/prestataires/{id}/articles/{article_id}/photo")]
pub async fn photo_article(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    MultipartForm(form): MultipartForm<PhotoForm>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    let (prestataire, article) = chemin.into_inner();
    exiger_pilotage(&auth, &depot, prestataire).await?;
    let (octets, mime) = form.contenu();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let (article, orpheline) = depot
        .photo_article(
            &mut tx,
            prestataire,
            article,
            octets,
            &mime,
            SourceBascule::Vendeur,
            auth.compte_id,
        )
        .await?;
    tx.commit().await.map_err(sql)?;
    if let Some(cle) = orpheline {
        if let Err(e) = depot.objets().supprimer(&cle).await {
            tracing::warn!(cle = %cle, erreur = %e, "photo d'article remplacée non purgée");
        }
    }
    Ok(HttpResponse::Ok().json(article_vendeur_dto(&depot, article).await?))
}

/// Retire l'article du catalogue — RÉVERSIBLE (FR-055).
#[utoipa::path(
    post,
    path = "/vendeur/prestataires/{id}/articles/{article_id}/retrait",
    tag = "vendeur",
    params(
        ("id" = Uuid, Path, description = "Prestataire piloté."),
        ("article_id" = Uuid, Path, description = "Article."),
    ),
    responses(
        (status = 200, description = "Retiré : plus servi, plus commandable, plus signalable — \
         la ligne subsiste. Émet `article.retire_du_catalogue`.", body = ArticleVendeurDto),
        (status = 404, description = "Article inconnu.", body = ErreurApiDto),
        (status = 403, description = "Refus de pilotage.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/vendeur/prestataires/{id}/articles/{article_id}/retrait")]
pub async fn retirer_article(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    let (prestataire, article) = chemin.into_inner();
    exiger_pilotage(&auth, &depot, prestataire).await?;
    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let article = depot
        .retirer_article(&mut tx, prestataire, article, SourceBascule::Vendeur, auth.compte_id)
        .await?;
    tx.commit().await.map_err(sql)?;
    Ok(HttpResponse::Ok().json(article_vendeur_dto(&depot, article).await?))
}

/// Remet un article retiré au catalogue, sans ressaisie (FR-055).
#[utoipa::path(
    post,
    path = "/vendeur/prestataires/{id}/articles/{article_id}/remise",
    tag = "vendeur",
    params(
        ("id" = Uuid, Path, description = "Prestataire piloté."),
        ("article_id" = Uuid, Path, description = "Article."),
    ),
    responses(
        (status = 200, description = "Remis : il revient avec son historique et sa \
         disponibilité telle qu'elle était. Émet `article.remis_au_catalogue`.",
         body = ArticleVendeurDto),
        (status = 404, description = "Article inconnu.", body = ErreurApiDto),
        (status = 403, description = "Refus de pilotage.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/vendeur/prestataires/{id}/articles/{article_id}/remise")]
pub async fn remettre_article(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    let (prestataire, article) = chemin.into_inner();
    exiger_pilotage(&auth, &depot, prestataire).await?;
    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let article = depot
        .remettre_article(&mut tx, prestataire, article, SourceBascule::Vendeur, auth.compte_id)
        .await?;
    tx.commit().await.map_err(sql)?;
    Ok(HttpResponse::Ok().json(article_vendeur_dto(&depot, article).await?))
}
