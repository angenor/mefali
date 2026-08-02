//! Surface d'**exploitation** du cycle PAY (T071, T072 — contrats §5).
//!
//! Cinq routes, un seul objet : répondre à « où est cet argent ? » sans avoir à
//! ouvrir la base. Le registre des transactions rapproche dans les deux sens
//! (FR-081), la file des dossiers montre les quatre familles d'anomalies
//! (FR-082), et les créances de coursiers se lisent et se règlent (FR-065,
//! FR-067, FR-083).
//!
//! ⚠ **Aucune page Nuxt** : ADM-01→06 sont des stories distinctes (FR-084).
//! Ce cycle livre les endpoints et le client TS régénéré — patron des cycles
//! 009 et 010, qui ont fait exactement la même chose.
//!
//! # Ce que ces routes ne font PAS
//!
//! Aucune ne rembourse (PAY-04, FR-041), aucune ne rouvre une transaction, et
//! le règlement d'une créance ne s'annule pas : une erreur se corrige par une
//! écriture **inverse** au livre (FR-064). Un registre qu'on peut rembobiner ne
//! prouve plus rien.

use actix_web::{get, post, web, HttpResponse};
use chrono::{DateTime, Utc};
use comptes::Role;
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToSchema};
use uuid::Uuid;

use crate::auth_http::{Auth, ErreurApiDto};
use crate::coursier_http::{CreanceDto, ErreurCoursierHttp};
use crate::erreurs_paiements::ErreurPaiementsHttp;

// ── Registre des transactions (T072, FR-080/FR-081) ───────────────────────

/// Filtres du registre.
#[derive(Debug, Deserialize, IntoParams)]
pub struct FiltreTransactionsDto {
    /// `ouverte` | `reglee` | `echouee` | `expiree` | `payee_hors_delai`.
    pub etat: Option<String>,
    /// Moyen employé (`wave`, `orange_money`, …).
    pub moyen: Option<String>,
    /// Rapprochement par commande — l'autre sens de FR-081.
    pub commande_id: Option<Uuid>,
    /// Borne basse d'ouverture (incluse).
    pub depuis: Option<DateTime<Utc>>,
    /// Borne haute d'ouverture (incluse).
    pub jusqu_a: Option<DateTime<Utc>>,
}

/// Une ligne du registre.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = LigneRegistre)]
pub struct LigneRegistreDto {
    /// Transaction.
    pub id: Uuid,
    /// Commande rapprochée — le rapprochement se lit sans jointure manuelle.
    pub commande_id: Uuid,
    /// Montant figé.
    pub montant_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// État de la transaction.
    pub etat: String,
    /// Moyen employé — `inconnu` tant que le fournisseur ne l'a pas dit.
    pub moyen: String,
    /// Fournisseur qui a encaissé.
    pub fournisseur: String,
    /// Référence côté fournisseur — le rapprochement dans l'AUTRE sens.
    pub reference_fournisseur: Option<String>,
    /// Ouverture.
    pub ouverte_le: DateTime<Utc>,
    /// Issue définitive.
    pub issue_le: Option<DateTime<Utc>>,
    /// De l'argent encaissé qu'aucune commande vivante n'attend (FR-082).
    pub orpheline: bool,
}

/// Le registre, avec son total.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = RegistreTransactions)]
pub struct RegistreTransactionsDto {
    /// Lignes, la plus récente d'abord.
    pub transactions: Vec<LigneRegistreDto>,
    /// Somme des montants **réglés** de la sélection — ce que le fournisseur
    /// doit avoir encaissé.
    pub total_regle_unites: i64,
}

/// Registre filtrable des transactions de paiement (FR-080, FR-081).
#[utoipa::path(
    get,
    path = "/admin/paiements/transactions",
    tag = "paiements-admin",
    params(FiltreTransactionsDto),
    responses(
        (status = 200, description = "Registre, la plus récente d'abord. Chaque ligne porte la \
         référence fournisseur ET la commande : le rapprochement se lit dans les deux sens sans \
         jointure manuelle (FR-081).", body = RegistreTransactionsDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/paiements/transactions")]
pub async fn registre_transactions(
    auth: Auth,
    filtre: web::Query<FiltreTransactionsDto>,
    paiements: web::Data<paiements::PgPaiements>,
) -> Result<HttpResponse, ErreurPaiementsHttp> {
    auth.exiger_role(Role::Admin)?;
    let lignes = paiements
        .registre_transactions(
            filtre.etat.as_deref(),
            filtre.moyen.as_deref(),
            filtre.commande_id,
            filtre.depuis,
            filtre.jusqu_a,
        )
        .await?;

    let total_regle_unites = lignes
        .iter()
        .filter(|l| l.etat == "reglee")
        .map(|l| l.montant_unites)
        .sum();

    Ok(HttpResponse::Ok().json(RegistreTransactionsDto {
        total_regle_unites,
        transactions: lignes
            .into_iter()
            .map(|l| LigneRegistreDto {
                id: l.id,
                commande_id: l.commande_id,
                montant_unites: l.montant_unites,
                devise: l.devise,
                etat: l.etat,
                moyen: l.moyen,
                fournisseur: l.fournisseur,
                reference_fournisseur: l.reference_fournisseur,
                ouverte_le: l.ouverte_le,
                issue_le: l.issue_le,
                orpheline: l.orpheline,
            })
            .collect(),
    }))
}

// ── File des dossiers d'anomalie (T072, FR-082) ───────────────────────────

/// Filtres de la file des dossiers.
#[derive(Debug, Deserialize, IntoParams)]
pub struct FiltreDossiersDto {
    /// `ouvert` | `clos`. Absent = tous.
    pub etat: Option<String>,
    /// Type de dossier (`montant_divergent`, `retenue_ecretee`, …).
    #[param(rename = "type")]
    #[serde(rename = "type")]
    pub type_dossier: Option<String>,
}

/// Un dossier d'anomalie.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = DossierPaiement)]
pub struct DossierDto {
    /// Dossier.
    pub id: Uuid,
    /// Famille d'anomalie.
    #[serde(rename = "type")]
    pub type_dossier: String,
    /// `ouvert` | `clos`.
    pub etat: String,
    /// Commande concernée.
    pub commande_id: Option<Uuid>,
    /// Transaction concernée.
    pub transaction_id: Option<Uuid>,
    /// Arrêt concerné (retenue écrêtée).
    pub arret_id: Option<Uuid>,
    /// Montant constaté.
    pub montant_constate: Option<i64>,
    /// Montant attendu.
    pub montant_attendu: Option<i64>,
    /// Devise ISO 4217.
    pub devise: Option<String>,
    /// Motif — **clé i18n**, jamais un texte libre.
    pub motif_cle: String,
    /// Ouverture.
    pub ouvert_le: DateTime<Utc>,
    /// Clôture.
    pub clos_le: Option<DateTime<Utc>>,
    /// Motif de clôture — clé i18n également.
    pub clos_motif_cle: Option<String>,
}

impl From<paiements::Dossier> for DossierDto {
    fn from(d: paiements::Dossier) -> Self {
        Self {
            id: d.id,
            type_dossier: d.type_dossier.comme_str().to_owned(),
            etat: d.etat.comme_str().to_owned(),
            commande_id: d.commande_id,
            transaction_id: d.transaction_id,
            arret_id: d.arret_id,
            montant_constate: d.montant_constate,
            montant_attendu: d.montant_attendu,
            devise: d.devise,
            motif_cle: d.motif_cle,
            ouvert_le: d.ouvert_le,
            clos_le: d.clos_le,
            clos_motif_cle: d.clos_motif_cle,
        }
    }
}

/// La file des anomalies d'argent.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = FileDossiers)]
pub struct FileDossiersDto {
    /// Dossiers, le plus récent d'abord.
    pub dossiers: Vec<DossierDto>,
}

/// File des anomalies d'argent (FR-082).
#[utoipa::path(
    get,
    path = "/admin/paiements/dossiers",
    tag = "paiements-admin",
    params(FiltreDossiersDto),
    responses(
        (status = 200, description = "Dossiers, le plus récent d'abord. Quatre familles y \
         apparaissent : divergence de montant ou de devise, paiement hors délai, transaction \
         orpheline, retenue écrêtée, remboursement dû.", body = FileDossiersDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/paiements/dossiers")]
pub async fn file_dossiers(
    auth: Auth,
    filtre: web::Query<FiltreDossiersDto>,
    paiements: web::Data<paiements::PgPaiements>,
) -> Result<HttpResponse, ErreurPaiementsHttp> {
    auth.exiger_role(Role::Admin)?;
    let dossiers = paiements
        .lister_dossiers(filtre.etat.as_deref(), filtre.type_dossier.as_deref())
        .await?;
    Ok(HttpResponse::Ok().json(FileDossiersDto {
        dossiers: dossiers.into_iter().map(DossierDto::from).collect(),
    }))
}

/// Corps de clôture — le motif est **obligatoire**.
#[derive(Debug, Deserialize, ToSchema)]
pub struct CloreDossierDto {
    /// Clé i18n du motif de clôture. Un dossier clos sans motif ne dit pas ce
    /// qui a été fait de l'argent — c'est-à-dire rien.
    pub motif_cle: String,
}

/// Clôt un dossier, avec motif (FR-082).
#[utoipa::path(
    post,
    path = "/admin/paiements/dossiers/{id}/clore",
    tag = "paiements-admin",
    params(("id" = Uuid, Path, description = "Dossier ouvert.")),
    request_body = CloreDossierDto,
    responses(
        (status = 200, description = "Clos — l'auteur et l'instant sont conservés.",
         body = DossierDto),
        (status = 409, description = "Dossier déjà clos. La clôture n'est pas une bascule : \
         rouvrir effacerait la trace de ce qui a été décidé.", body = ErreurApiDto),
        (status = 422, description = "Motif absent.", body = ErreurApiDto),
        (status = 404, description = "Dossier inconnu.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/paiements/dossiers/{id}/clore")]
pub async fn clore_dossier(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<CloreDossierDto>,
    paiements: web::Data<paiements::PgPaiements>,
) -> Result<HttpResponse, ErreurPaiementsHttp> {
    auth.exiger_role(Role::Admin)?;
    let dossier_id = chemin.into_inner();
    if corps.motif_cle.trim().is_empty() {
        return Err(paiements::ErreurPaiements::MotifRequis.into());
    }

    // L'existence se vérifie AVANT la clôture pour distinguer `404` de `409` :
    // un dossier inconnu et un dossier déjà clos ne demandent pas le même geste
    // à l'exploitation.
    paiements
        .dossier(dossier_id)
        .await?
        .ok_or(paiements::ErreurPaiements::DossierInconnu(dossier_id))?;

    let mut tx = paiements.pool().begin().await.map_err(|e| {
        ErreurPaiementsHttp::Domaine(paiements::ErreurPaiements::Sql(e))
    })?;
    let clos = paiements
        .clore_dossier(
            &mut tx,
            dossier_id,
            auth.compte_id,
            corps.motif_cle.trim(),
            paiements.maintenant(),
        )
        .await?;
    if !clos {
        return Err(paiements::ErreurPaiements::DossierDejaClos.into());
    }
    tx.commit().await.map_err(|e| {
        ErreurPaiementsHttp::Domaine(paiements::ErreurPaiements::Sql(e))
    })?;

    let dossier = paiements
        .dossier(dossier_id)
        .await?
        .ok_or(paiements::ErreurPaiements::DossierInconnu(dossier_id))?;
    Ok(HttpResponse::Ok().json(DossierDto::from(dossier)))
}

// ── Créances de coursiers (T071, FR-065/FR-067/FR-083) ────────────────────

/// Filtres de la file des créances.
#[derive(Debug, Deserialize, IntoParams)]
pub struct FiltreCreancesDto {
    /// `due` | `reglee`. Absent = toutes.
    pub etat: Option<String>,
    /// Créances d'un coursier donné.
    pub coursier_id: Option<Uuid>,
}

/// La file des créances, avec son total dû.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = FileCreances)]
pub struct FileCreancesDto {
    /// Créances, la plus récente d'abord.
    pub creances: Vec<CreanceDto>,
    /// Somme des créances **dues** de la sélection — l'exposition de Mefali
    /// envers ses coursiers (FR-065).
    pub total_du_unites: i64,
}

/// File des créances de coursiers (FR-083).
#[utoipa::path(
    get,
    path = "/admin/creances",
    tag = "paiements-admin",
    params(FiltreCreancesDto),
    responses(
        (status = 200, description = "Créances, la plus récente d'abord, avec le total dû. \
         Elles naissent SEULES à la livraison : l'exploitation les règle, elle ne les crée pas \
         (FR-063).", body = FileCreancesDto),
        (status = 422, description = "État de filtre inconnu.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/creances")]
pub async fn file_creances(
    auth: Auth,
    filtre: web::Query<FiltreCreancesDto>,
    coursier: web::Data<coursier::PgCoursier>,
) -> Result<HttpResponse, ErreurCoursierHttp> {
    auth.exiger_role(Role::Admin)?;
    let etat = match filtre.etat.as_deref() {
        None => None,
        Some("due") => Some(coursier::EtatCreance::Due),
        Some("reglee") => Some(coursier::EtatCreance::Reglee),
        // Un filtre mal orthographié est une demande invalide, pas une panne :
        // rendre 500 ferait lire « le serveur est cassé » à qui a simplement
        // mal écrit (défaut trouvé au cycle 010 sur la file des indemnisations).
        Some(autre) => {
            return Err(coursier::ErreurCoursier::ValeurInconnue(autre.to_owned()).into())
        }
    };

    let creances = coursier
        .lister_creances(filtre.coursier_id, etat)
        .await?;
    let total_du_unites = creances
        .iter()
        .filter(|c| c.etat == coursier::EtatCreance::Due)
        .map(|c| c.montant_unites)
        .sum();

    Ok(HttpResponse::Ok().json(FileCreancesDto {
        total_du_unites,
        creances: creances.into_iter().map(CreanceDto::from).collect(),
    }))
}

/// Corps du règlement — motif **obligatoire**.
#[derive(Debug, Deserialize, ToSchema)]
pub struct ReglerCreanceDto {
    /// Clé i18n du motif (`creance.reglement.virement_agence`, …). Sans lui,
    /// « réglée » ne dit pas COMMENT — et c'est la première question posée
    /// quand un coursier conteste.
    pub motif_cle: String,
}

/// Marque une créance réglée et écrit son mouvement de caisse (FR-067).
#[utoipa::path(
    post,
    path = "/admin/creances/{id}/regler",
    tag = "paiements-admin",
    params(("id" = Uuid, Path, description = "Créance due.")),
    request_body = ReglerCreanceDto,
    responses(
        (status = 200, description = "Réglée — la créance et son écriture de caisse `reglement` \
         sont écrites dans la MÊME transaction (research R12). Émet `caisse.creance_reglee`.",
         body = CreanceDto),
        (status = 409, description = "Créance déjà réglée. Le marquage n'est pas une bascule : \
         une erreur se corrige par une écriture INVERSE au livre (FR-064).", body = ErreurApiDto),
        (status = 422, description = "Motif absent.", body = ErreurApiDto),
        (status = 404, description = "Créance inconnue.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/creances/{id}/regler")]
pub async fn regler_creance(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<ReglerCreanceDto>,
    coursier: web::Data<coursier::PgCoursier>,
) -> Result<HttpResponse, ErreurCoursierHttp> {
    auth.exiger_role(Role::Admin)?;
    let creance = coursier
        .regler_creance(chemin.into_inner(), auth.compte_id, &corps.motif_cle)
        .await?;
    Ok(HttpResponse::Ok().json(CreanceDto::from(creance)))
}
