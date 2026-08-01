//! Surface HTTP **FOURNISSEUR** — la seule route non authentifiée du produit.
//!
//! Un agrégateur ne porte pas de JWT : la notification vient d'un tiers, pas
//! d'un utilisateur. Sa garde est **cryptographique** (plan.md, Complexity
//! Tracking ligne 1) — signature HMAC vérifiée sur le corps brut avant toute
//! désérialisation.
//!
//! # Pourquoi `web::Bytes` et jamais `web::Json`
//!
//! `web::Json` désérialiserait le corps **avant** que le handler ne s'exécute,
//! donc avant toute vérification de signature : on ferait confiance à la
//! structure d'un inconnu, et la signature ne porterait plus sur les octets
//! réellement reçus mais sur une re-sérialisation. Un espace en plus, un ordre
//! de clés différent, et la vérification échoue sur une notification honnête —
//! ou pire, réussit sur une falsifiée (research R6).
//!
//! # Le segment `{fournisseur}`
//!
//! Il sélectionne l'implémentation à laquelle déléguer la vérification. C'est
//! **le point d'accroche du routage de phase 2+** (FR-043) : aujourd'hui il ne
//! porte aucune règle, et un fournisseur inconnu répond `404`. Le nommer dès
//! maintenant évite qu'ajouter un second fournisseur demande de changer l'URL
//! déclarée chez le premier — ce qui, chez un agrégateur, est une démarche
//! commerciale, pas un déploiement.

use actix_web::{post, web, HttpRequest, HttpResponse};
use paiements::{EntetesNotification, NotificationEntrante, PaymentProvider, PgPaiements};
use serde::Serialize;
use std::sync::Arc;
use utoipa::ToSchema;

use crate::erreurs_paiements::ErreurPaiementsHttp;

/// Ce que le webhook répond — **toujours `200`, sauf signature invalide**.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ReponseNotification)]
pub struct ReponseNotificationDto {
    /// Vrai si la notification a produit un effet.
    pub traite: bool,
    /// Pourquoi elle n'en a produit aucun : `rejeu`, `en_cours`, `orpheline`,
    /// `etat_incompatible`. Absent quand `traite` vaut `true`.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub motif: Option<String>,
}

/// Notification signée d'un fournisseur de paiement.
#[utoipa::path(
    post,
    path = "/paiements/notifications/{fournisseur}",
    tag = "paiements",
    params(("fournisseur" = String, Path,
            description = "Identifiant stable de l'implémentation destinataire. Point d'accroche \
                           du routage par moyen (phase 2+) — sans règle aujourd'hui.")),
    request_body(content = String, description = "Charge BRUTE du fournisseur, signée. Jamais \
                 désérialisée avant vérification de la signature.", content_type = "application/json"),
    responses(
        (status = 200, description = "Notification traitée, ou sans effet avec son motif. Un \
         rejeu répond 200 `{traite: false, motif: \"rejeu\"}` et NON une erreur : un fournisseur \
         qui reçoit une erreur retente en boucle (FR-022).", body = ReponseNotificationDto),
        (status = 401, description = "Signature absente, invalide ou périmée. Une ligne de \
         notification refusée est écrite ; rien d'autre (FR-020)."),
        (status = 404, description = "Segment `{fournisseur}` inconnu."),
        (status = 413, description = "Corps au-delà de la limite admise."),
    ),
)]
#[post("/paiements/notifications/{fournisseur}")]
pub async fn recevoir_notification(
    requete: HttpRequest,
    chemin: web::Path<String>,
    corps: web::Bytes,
    paiements: web::Data<PgPaiements>,
    commandes: web::Data<commandes::PgCommandes>,
    fournisseur: web::Data<Arc<dyn PaymentProvider>>,
) -> Result<HttpResponse, ErreurPaiementsHttp> {
    let segment = chemin.into_inner();
    let fournisseur = fournisseur.get_ref().as_ref();

    // Aucune règle métier ne lit ce nom (FR-003) : il ne sert qu'à choisir à
    // qui déléguer la vérification. Le comparer ici est un aiguillage, pas une
    // décision d'argent.
    if segment != fournisseur.nom() {
        return Err(paiements::ErreurPaiements::FournisseurInconnu(segment).into());
    }

    let entetes = EntetesNotification::depuis(
        requete
            .headers()
            .iter()
            .filter_map(|(nom, valeur)| valeur.to_str().ok().map(|v| (nom.as_str(), v))),
    );

    let resultat = paiements::traiter_notification(
        paiements.get_ref(),
        commandes.get_ref(),
        fournisseur,
        NotificationEntrante {
            corps_brut: &corps,
            entetes: &entetes,
            recue_le: paiements.maintenant(),
        },
    )
    .await?;

    Ok(HttpResponse::Ok().json(ReponseNotificationDto {
        traite: resultat.traite,
        motif: resultat.motif.map(str::to_owned),
    }))
}
