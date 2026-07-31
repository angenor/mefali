//! Mapping HTTP des refus du domaine commandes — `{ code, message_cle }`.
//!
//! **Un seul endroit** pour les trois surfaces du cycle (`commandes_http`
//! client, `course_http` coursier, `admin_commandes_http` admin) : un refus doit
//! rendre le même statut et la même clé, quelle que soit la porte par laquelle
//! on est entré. Dupliquer ce mapping par module le ferait diverger.
//!
//! Patron `qr_http` (cycle 006) : le domaine porte la clé courte
//! (`ErreurCommandes::message_cle`), la couche HTTP la préfixe de son espace de
//! noms i18n. Aucune chaîne utilisateur n'est écrite ici (constitution VII) —
//! seulement des clés que l'app résout dans son ARB fr.

use actix_web::http::StatusCode;
use actix_web::{HttpResponse, ResponseError};
use commandes::ErreurCommandes;
use serde_json::json;

use crate::auth_http::ErreurApi;

/// Erreur HTTP des surfaces commandes : auth/rôle (`ErreurApi`) ou refus du
/// domaine (`ErreurCommandes`).
#[derive(Debug)]
pub enum ErreurCommandesHttp {
    /// Erreur d'authentification / de rôle (réutilise le mapping comptes).
    Api(ErreurApi),
    /// Refus métier ou erreur d'infrastructure du domaine commandes.
    Domaine(ErreurCommandes),
}

impl From<ErreurApi> for ErreurCommandesHttp {
    fn from(e: ErreurApi) -> Self {
        ErreurCommandesHttp::Api(e)
    }
}

impl From<ErreurCommandes> for ErreurCommandesHttp {
    fn from(e: ErreurCommandes) -> Self {
        ErreurCommandesHttp::Domaine(e)
    }
}

impl std::fmt::Display for ErreurCommandesHttp {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ErreurCommandesHttp::Api(e) => write!(f, "{e}"),
            ErreurCommandesHttp::Domaine(e) => write!(f, "{e}"),
        }
    }
}

/// Statut HTTP d'un refus du domaine (contrat §1.2).
///
/// Les trois familles :
/// - **403** — l'appelant n'a pas le droit (compte bloqué, non-propriétaire,
///   téléphone non vérifié) : réessayer ne changera rien sans une action tierce ;
/// - **409** — l'état courant s'y oppose (transition illégale, vendeur fermé,
///   plafond cash, autre vendeur) : l'appelant peut agir sur l'état ;
/// - **422** — la demande elle-même est mal formée (repère manquant, panier
///   invalide).
///
/// `423 Locked` est réservé au code de remise épuisé : la ressource est
/// verrouillée jusqu'à intervention admin, ce qu'un 409 ne dirait pas.
pub fn statut(e: &ErreurCommandes) -> StatusCode {
    match e {
        ErreurCommandes::CommandeInconnue(_)
        | ErreurCommandes::LivraisonInconnue(_)
        | ErreurCommandes::SubstitutionInconnue(_)
        | ErreurCommandes::ArretInconnu(_) => StatusCode::NOT_FOUND,

        ErreurCommandes::CompteBloque
        | ErreurCommandes::NonProprietaire
        | ErreurCommandes::TelephoneNonVerifie => StatusCode::FORBIDDEN,

        ErreurCommandes::CategorieNonMixable
        // La grille de la zone ne couvre pas ce trajet : l'état s'y oppose, et
        // le client peut agir dessus en retirant un vendeur éloigné — même
        // famille qu'un vendeur fermé, pas une demande mal formée.
        | ErreurCommandes::TarifIndisponible
        | ErreurCommandes::VendeurIndisponible(_)
        | ErreurCommandes::ArticleIndisponible(_)
        | ErreurCommandes::CashIndisponible
        | ErreurCommandes::TransitionRefusee { .. }
        | ErreurCommandes::EtatIncompatible { .. }
        | ErreurCommandes::SubstitutionAutreVendeur
        | ErreurCommandes::SubstitutionEcartPrix
        | ErreurCommandes::SubstitutionExpiree
        | ErreurCommandes::RemiseIncorrecte
        // Lever un blocage qui n'existe pas : l'état s'y oppose, et il peut
        // changer (trois codes faux plus tard, la levée aura du sens).
        | ErreurCommandes::CodeNonBloque
        | ErreurCommandes::PreuvesIncompletes => StatusCode::CONFLICT,

        ErreurCommandes::CodeEpuise => StatusCode::LOCKED,

        ErreurCommandes::RepereManquant
        | ErreurCommandes::PanierInvalide(_)
        // Le contrat §2 range explicitement le dépôt non autorisé en 422 :
        // la DEMANDE est irrecevable (cette voie n'existe pas pour cette
        // commande), et aucune action du coursier sur l'état n'y changera rien —
        // c'est l'exploitation qui ouvre le drapeau.
        | ErreurCommandes::DepotNonAutorise
        | ErreurCommandes::MotifRequis => StatusCode::UNPROCESSABLE_ENTITY,

        // Infrastructure : Sql, StatutInconnu, ModeInconnu, Dependance.
        _ => StatusCode::INTERNAL_SERVER_ERROR,
    }
}

/// Corps `{ code, message_cle }` d'un refus du domaine.
///
/// Une erreur SANS clé i18n est une erreur TECHNIQUE : elle rend un code neutre
/// et n'expose rien de son détail — le détail vit dans les journaux.
pub fn corps(e: &ErreurCommandes) -> serde_json::Value {
    match e.message_cle() {
        Some(cle) => json!({ "code": cle, "message_cle": format!("commande.erreur.{cle}") }),
        None => json!({ "code": "erreur_interne", "message_cle": "commande.erreur.interne" }),
    }
}

impl ResponseError for ErreurCommandesHttp {
    fn status_code(&self) -> StatusCode {
        match self {
            ErreurCommandesHttp::Api(e) => e.status_code(),
            ErreurCommandesHttp::Domaine(e) => statut(e),
        }
    }

    fn error_response(&self) -> HttpResponse {
        match self {
            ErreurCommandesHttp::Api(e) => e.error_response(),
            ErreurCommandesHttp::Domaine(e) => {
                if statut(e) == StatusCode::INTERNAL_SERVER_ERROR {
                    tracing::error!(erreur = %e, "erreur interne du domaine commandes");
                }
                HttpResponse::build(statut(e)).json(corps(e))
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    #[test]
    fn chaque_refus_metier_porte_sa_cle_i18n() {
        for erreur in [
            ErreurCommandes::CompteBloque,
            ErreurCommandes::CategorieNonMixable,
            ErreurCommandes::RepereManquant,
            ErreurCommandes::TelephoneNonVerifie,
            ErreurCommandes::VendeurIndisponible(Uuid::now_v7()),
            ErreurCommandes::ArticleIndisponible(Uuid::now_v7()),
            ErreurCommandes::CashIndisponible,
            ErreurCommandes::SubstitutionAutreVendeur,
            ErreurCommandes::SubstitutionEcartPrix,
            ErreurCommandes::SubstitutionExpiree,
            ErreurCommandes::CodeEpuise,
            ErreurCommandes::RemiseIncorrecte,
            ErreurCommandes::DepotNonAutorise,
            ErreurCommandes::CodeNonBloque,
            ErreurCommandes::PreuvesIncompletes,
            ErreurCommandes::MotifRequis,
            ErreurCommandes::NonProprietaire,
            ErreurCommandes::TarifIndisponible,
        ] {
            let corps = corps(&erreur);
            assert_ne!(
                corps["code"], "erreur_interne",
                "« {erreur} » est un refus MÉTIER : il doit porter sa clé i18n",
            );
            let cle = corps["message_cle"].as_str().unwrap();
            assert!(
                cle.starts_with("commande.erreur."),
                "clé i18n mal préfixée : {cle}",
            );
        }
    }

    /// `AucuneRegle` de TRF est un REFUS, pas une panne : il traverse la
    /// conversion en gardant sa clé, et rend 409 — pas 500.
    ///
    /// Sans ce chemin, un panier trop dispersé pour la grille de la zone (le
    /// véhicule demandé plafonne à 800 m) répondait « une erreur est survenue »,
    /// qui n'apprend rien à personne. Constaté sur émulateur.
    #[test]
    fn aucune_regle_tarifaire_est_un_refus_lisible_pas_un_500() {
        let e = ErreurCommandes::from(tarification::ErreurTarif::AucuneRegle);
        assert!(matches!(e, ErreurCommandes::TarifIndisponible));
        assert_eq!(statut(&e), StatusCode::CONFLICT);
        let corps = corps(&e);
        assert_eq!(corps["code"], "tarif_indisponible");
        assert_eq!(corps["message_cle"], "commande.erreur.tarif_indisponible");
    }

    /// Les AUTRES erreurs de TRF restent techniques : seule `AucuneRegle` est
    /// une situation que le client peut lever.
    #[test]
    fn les_autres_erreurs_tarifaires_restent_techniques() {
        let e = ErreurCommandes::from(tarification::ErreurTarif::SimulationRequise);
        assert_eq!(statut(&e), StatusCode::INTERNAL_SERVER_ERROR);
        assert_eq!(corps(&e)["code"], "erreur_interne");
    }

    #[test]
    fn une_erreur_technique_n_expose_rien() {
        let e = ErreurCommandes::Dependance("détail interne à ne pas fuiter".to_owned());
        assert_eq!(statut(&e), StatusCode::INTERNAL_SERVER_ERROR);
        let corps = corps(&e);
        assert_eq!(corps["code"], "erreur_interne");
        assert!(
            !corps.to_string().contains("détail interne"),
            "le détail technique reste dans les journaux",
        );
    }

    #[test]
    fn les_trois_familles_de_statut() {
        assert_eq!(statut(&ErreurCommandes::CompteBloque), StatusCode::FORBIDDEN);
        assert_eq!(
            statut(&ErreurCommandes::CategorieNonMixable),
            StatusCode::CONFLICT,
        );
        assert_eq!(
            statut(&ErreurCommandes::RepereManquant),
            StatusCode::UNPROCESSABLE_ENTITY,
        );
        assert_eq!(
            statut(&ErreurCommandes::CodeEpuise),
            StatusCode::LOCKED,
            "verrouillé jusqu'à intervention admin — un 409 ne le dirait pas",
        );
    }
}
