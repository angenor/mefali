//! Signalement de rupture par le COURSIER SUR PLACE (VND-04, FR-037..040).
//!
//! Ce cycle livre la capacité, sa précondition et sa protection ; l'ÉCRAN
//! coursier appartient au cycle CRS. Conçu pour la file hors-ligne
//! (constitution V) : UUID client en `Idempotency-Key`, horodatage local,
//! rejeu idempotent — un même identifiant ne compte jamais deux fois.

use actix_web::{post, web, HttpRequest, HttpResponse};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

use comptes::Role;
use prestataires::PgPrestataires;

use crate::auth_http::{Auth, ErreurApiDto};
use crate::prestataires_http::{sql, ErreurPresta};

/// Corps du signalement.
#[derive(Debug, Deserialize, ToSchema)]
pub struct SignalerRuptureDto {
    /// Article introuvable sur place.
    pub article_id: Uuid,
    /// Horodatage LOCAL de l'appareil (file hors-ligne — FR-039).
    pub horodatage_local: DateTime<Utc>,
}

/// Issue du signalement.
#[derive(Debug, Serialize, ToSchema)]
pub struct SignalementRecuDto {
    /// Reçu (vrai aussi pour un rejeu — même réponse, rien recompté).
    pub recu: bool,
    /// CE signalement a déclenché le masquage automatique (FR-040).
    pub masquage_automatique: bool,
}

/// Lit l'en-tête `Idempotency-Key` (REQUIS — patron du cycle 003).
fn idempotency_key(requete: &HttpRequest) -> Result<Uuid, ErreurPresta> {
    requete
        .headers()
        .get("idempotency-key")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.parse::<Uuid>().ok())
        .ok_or(ErreurPresta::CorpsInvalide)
}

/// Signale un article introuvable — REFUSÉ (et compté nulle part) sans
/// commande active comportant un arrêt chez ce prestataire (FR-038).
#[utoipa::path(
    post,
    path = "/coursier/signalements-rupture",
    tag = "coursier",
    params(
        ("Idempotency-Key" = Uuid, Header,
         description = "UUID généré CÔTÉ CLIENT — devient l'identifiant du signalement, \
          rejeu réseau idempotent (FR-039)."),
    ),
    request_body = SignalerRuptureDto,
    responses(
        (status = 200, description = "Accepté (ou rejeu — même réponse). Deux coursiers \
         DISTINCTS dans la fenêtre masquent l'article automatiquement (FR-040) ; les \
         signalements reçus restent comptés après une remise en vente (FR-041).",
         body = SignalementRecuDto),
        (status = 403, description = "Aucune commande active éligible (port CommandesActives) \
         — refusé, compté NULLE PART.", body = ErreurApiDto),
        (status = 404, description = "Article inconnu ou retiré du catalogue.", body = ErreurApiDto),
        (status = 422, description = "En-tête d'idempotence absent ou corps invalide.",
         body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/coursier/signalements-rupture")]
pub async fn signaler_rupture(
    auth: Auth,
    requete: HttpRequest,
    corps: web::Json<SignalerRuptureDto>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    if !auth.a_role(Role::Coursier) {
        return Err(ErreurPresta::RoleRequis);
    }
    let signalement = idempotency_key(&requete)?;

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let issue = depot
        .signaler_rupture(
            &mut tx,
            signalement,
            corps.article_id,
            auth.compte_id,
            corps.horodatage_local,
        )
        .await?;
    tx.commit().await.map_err(sql)?;

    Ok(HttpResponse::Ok().json(SignalementRecuDto {
        recu: true,
        masquage_automatique: issue.masquage_automatique,
    }))
}
