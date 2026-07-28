//! Mapping HTTP des refus du domaine dispatch — `{ code, message_cle }`.
//!
//! **Un seul endroit** pour les deux surfaces du cycle (`dispatch_http`
//! coursier, `admin_dispatch_http` admin) : un refus doit rendre le même statut
//! et la même clé, quelle que soit la porte par laquelle on est entré.
//! Dupliquer ce mapping par module le ferait diverger.
//!
//! Patron `erreurs_commandes` (cycle 008) : le domaine porte la clé courte
//! (`ErreurDispatch::message_cle`), la couche HTTP la préfixe de son espace de
//! noms i18n. Aucune chaîne utilisateur n'est écrite ici (constitution VII) —
//! seulement des clés que l'app résout dans son ARB fr.

use actix_web::http::StatusCode;
use actix_web::{HttpResponse, ResponseError};
use dispatch::ErreurDispatch;
use serde_json::json;

use crate::auth_http::ErreurApi;

/// Erreur HTTP des surfaces dispatch : auth/rôle (`ErreurApi`) ou refus du
/// domaine (`ErreurDispatch`).
#[derive(Debug)]
pub enum ErreurDispatchHttp {
    /// Erreur d'authentification / de rôle (réutilise le mapping comptes).
    Api(ErreurApi),
    /// Refus métier ou erreur d'infrastructure du domaine dispatch.
    Domaine(ErreurDispatch),
}

impl From<ErreurApi> for ErreurDispatchHttp {
    fn from(e: ErreurApi) -> Self {
        ErreurDispatchHttp::Api(e)
    }
}

impl From<ErreurDispatch> for ErreurDispatchHttp {
    fn from(e: ErreurDispatch) -> Self {
        ErreurDispatchHttp::Domaine(e)
    }
}

impl std::fmt::Display for ErreurDispatchHttp {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ErreurDispatchHttp::Api(e) => write!(f, "{e}"),
            ErreurDispatchHttp::Domaine(e) => write!(f, "{e}"),
        }
    }
}

/// Statut HTTP d'un refus du domaine (contrat §1.4).
///
/// Trois familles, et la première est la plus importante du cycle :
///
/// - **404** — l'offre n'existe pas, **ou n'est pas la sienne**. La garde de
///   propriété rend le même statut que l'absence : révéler par un `403` qu'une
///   offre existe apprendrait à un coursier qu'une course circule sans lui ;
/// - **409** — l'état courant s'y oppose (déjà prise, échue, course active,
///   dossier invalide) : le coursier peut agir dessus, ou attendre la suivante ;
/// - **422** — la demande elle-même est mal formée (motif absent, reprise
///   manuelle sans objet).
pub fn statut(e: &ErreurDispatch) -> StatusCode {
    match e {
        ErreurDispatch::OffreInconnue(_) => StatusCode::NOT_FOUND,

        ErreurDispatch::DejaPrise
        | ErreurDispatch::OffreEchue
        | ErreurDispatch::CourseActive
        | ErreurDispatch::DossierCoursierInvalide => StatusCode::CONFLICT,

        ErreurDispatch::CapaciteNonDeclaree
        | ErreurDispatch::MotifRequis
        | ErreurDispatch::RepriseInutile => StatusCode::UNPROCESSABLE_ENTITY,

        // Infrastructure et configuration : ConfigurationInvalide,
        // ParametreAbsent, ValeurInconnue, Dependance, Sql. Une configuration
        // refusée est un défaut d'EXPLOITATION — le coursier n'y peut rien, et
        // lui montrer le détail ne l'aiderait pas.
        _ => StatusCode::INTERNAL_SERVER_ERROR,
    }
}

/// Corps `{ code, message_cle }` d'un refus du domaine.
///
/// Une erreur SANS clé i18n est une erreur TECHNIQUE : elle rend un code neutre
/// et n'expose rien de son détail — le détail vit dans les journaux.
pub fn corps(e: &ErreurDispatch) -> serde_json::Value {
    match e.message_cle() {
        Some(cle) => json!({ "code": cle, "message_cle": format!("dispatch.erreur.{cle}") }),
        None => json!({ "code": "erreur_interne", "message_cle": "dispatch.erreur.interne" }),
    }
}

impl ResponseError for ErreurDispatchHttp {
    fn status_code(&self) -> StatusCode {
        match self {
            ErreurDispatchHttp::Api(e) => e.status_code(),
            ErreurDispatchHttp::Domaine(e) => statut(e),
        }
    }

    fn error_response(&self) -> HttpResponse {
        match self {
            ErreurDispatchHttp::Api(e) => e.error_response(),
            ErreurDispatchHttp::Domaine(e) => {
                if statut(e) == StatusCode::INTERNAL_SERVER_ERROR {
                    tracing::error!(erreur = %e, "erreur interne du domaine dispatch");
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
            ErreurDispatch::OffreInconnue(Uuid::now_v7()),
            ErreurDispatch::DejaPrise,
            ErreurDispatch::OffreEchue,
            ErreurDispatch::CourseActive,
            ErreurDispatch::DossierCoursierInvalide,
            ErreurDispatch::CapaciteNonDeclaree,
            ErreurDispatch::MotifRequis,
            ErreurDispatch::RepriseInutile,
        ] {
            let corps = corps(&erreur);
            assert_ne!(
                corps["code"], "erreur_interne",
                "« {erreur} » est un refus MÉTIER : il doit porter sa clé i18n",
            );
            let cle = corps["message_cle"].as_str().unwrap();
            assert!(cle.starts_with("dispatch.erreur."), "clé mal préfixée : {cle}");
        }
    }

    /// L'offre d'un autre coursier rend `404`, pas `403` : un `403` apprendrait
    /// à ce coursier qu'une course circule sans lui.
    #[test]
    fn l_offre_d_un_autre_n_existe_pas() {
        let e = ErreurDispatch::OffreInconnue(Uuid::now_v7());
        assert_eq!(statut(&e), StatusCode::NOT_FOUND);
        assert_eq!(corps(&e)["message_cle"], "dispatch.erreur.offre_inconnue");
    }

    /// « Déjà prise » est un `409` — et l'app l'affiche comme l'état K2-1b, ton
    /// neutre, **sans pénalité** (FR-049). Ce n'est pas un échec technique.
    #[test]
    fn deja_prise_est_un_conflit_lisible_pas_une_panne() {
        assert_eq!(statut(&ErreurDispatch::DejaPrise), StatusCode::CONFLICT);
        assert_eq!(
            corps(&ErreurDispatch::DejaPrise)["code"],
            "deja_prise",
            "l'app doit pouvoir distinguer ce cas de tous les autres conflits",
        );
        assert_eq!(statut(&ErreurDispatch::OffreEchue), StatusCode::CONFLICT);
    }

    /// Une configuration refusée est un défaut d'exploitation : elle ne dit rien
    /// au coursier, et son détail reste dans les journaux.
    #[test]
    fn une_erreur_technique_n_expose_rien() {
        for e in [
            ErreurDispatch::ConfigurationInvalide("verrou ≤ timer".to_owned()),
            ErreurDispatch::ParametreAbsent("dispatch.rayon_m".to_owned()),
            ErreurDispatch::Dependance("détail interne à ne pas fuiter".to_owned()),
        ] {
            assert_eq!(statut(&e), StatusCode::INTERNAL_SERVER_ERROR);
            let corps = corps(&e);
            assert_eq!(corps["code"], "erreur_interne");
            assert!(
                !corps.to_string().contains("détail interne")
                    && !corps.to_string().contains("verrou"),
                "le détail technique reste dans les journaux",
            );
        }
    }

    #[test]
    fn les_trois_familles_de_statut() {
        assert_eq!(
            statut(&ErreurDispatch::OffreInconnue(Uuid::now_v7())),
            StatusCode::NOT_FOUND,
        );
        assert_eq!(statut(&ErreurDispatch::CourseActive), StatusCode::CONFLICT);
        assert_eq!(
            statut(&ErreurDispatch::MotifRequis),
            StatusCode::UNPROCESSABLE_ENTITY,
        );
    }
}
