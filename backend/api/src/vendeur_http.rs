//! Surface VENDEUR — consommée par Mefali Pro (écrans V1/V2, cycle 005).
//!
//! Garde à TROIS refus distincts (FR-008/FR-011, research R11) :
//! 1. `role_vendeur_requis` — le compte ne porte pas le rôle vendeur VALIDE
//!    (extracteur `Auth`, machine à états du cycle 003) ;
//! 2. `prestataire_non_rattache` — le rôle seul n'autorise rien, c'est le
//!    rattachement qui délimite ;
//! 3. `prestataire_non_agree` — capacités DÉRIVÉES de l'état du prestataire :
//!    une suspension coupe tout SANS toucher au rôle (aucune cascade).

use actix_web::{get, web, HttpResponse};
use serde::Serialize;
use utoipa::ToSchema;
use uuid::Uuid;

use comptes::Role;
use prestataires::PgPrestataires;

use crate::auth_http::{Auth, ErreurApiDto};
use crate::prestataires_http::{EffectifBoutiqueDto, ErreurPresta, StatutPrestataireDto};

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
