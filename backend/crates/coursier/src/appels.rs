//! Appels passés **via l'app** (FR-030 → FR-036).
//!
//! Trois choses que ce module tient, et une qu'il refuse :
//!
//! 1. **Aucun numéro n'entre ici.** Le serveur ne voit pas l'appel — il part du
//!    téléphone. Il en journalise l'intention, la direction, le motif et
//!    l'issue déclarée, jamais le numéro composé (R6).
//! 2. **Seul `client_absent` compte pour la preuve d'échec** (FR-035). Un appel
//!    de suivi ne prouve pas une absence, et c'est ce qui empêche un échec de se
//!    déclarer en passant trois appels de courtoisie.
//! 3. **L'issue est DÉCLARATIVE** (R19). Le serveur ne peut pas l'observer ;
//!    elle sert l'affichage de K4-1e et n'est jamais un critère. Un coursier qui
//!    déclarerait « sans réponse » à tort ne gagne rien — il informe seulement
//!    l'exploitation.
//!
//! Ce qu'il refuse : journaliser un appel sur une course qui n'est pas celle du
//! coursier. La garde de propriété vaut ici comme partout (FR-006).

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::NouvelEvenement;
use uuid::Uuid;

use crate::depot::PgCoursier;
use crate::modele::{AppelJournalise, CibleAppel, ErreurCoursier, IssueAppel, MotifAppel};

/// Ce que l'app déclare après avoir composé un numéro.
#[derive(Debug, Clone)]
pub struct DemandeAppel {
    /// Clé d'idempotence (UUIDv7 client, constitution V).
    pub uuid_client: Uuid,
    /// Vers le client ou vers un vendeur.
    pub vers: CibleAppel,
    /// Prestataire appelé (obligatoire si `vers = vendeur`).
    pub prestataire_id: Option<Uuid>,
    /// Motif de l'appel.
    pub motif: MotifAppel,
    /// Issue déclarée — facultative, `inconnue` par défaut.
    pub issue: Option<IssueAppel>,
    /// Horodatage de l'appareil. **Observation seulement** : le serveur écrit
    /// le sien, et c'est lui qui fonde l'espacement de la preuve.
    pub passe_le_local: DateTime<Utc>,
}

/// Ce que le serveur rend après avoir journalisé un appel.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppelEnregistre {
    /// Appel journalisé.
    pub appel_id: Uuid,
    /// Cet appel compte-t-il pour la preuve d'échec (FR-035) ?
    pub compte_pour_preuve: bool,
    /// Vrai si l'appel existait déjà (rejeu idempotent) — aucun événement n'a
    /// été ré-émis.
    pub rejeu: bool,
}

impl PgCoursier {
    /// Journalise un appel passé via l'app. Idempotent par `uuid_client`.
    pub async fn journaliser_appel(
        &self,
        coursier: Uuid,
        livraison: Uuid,
        demande: DemandeAppel,
    ) -> Result<AppelEnregistre, ErreurCoursier> {
        self.exiger_proprietaire(livraison, coursier).await?;
        if demande.vers == CibleAppel::Vendeur && demande.prestataire_id.is_none() {
            return Err(ErreurCoursier::DemandeInvalide(
                "un appel vendeur doit dire lequel",
            ));
        }

        // Rejeu : le MÊME corps, sans seconde ligne ni second événement (V).
        if let Some(existant) = self.appel_par_uuid(demande.uuid_client).await? {
            return Ok(AppelEnregistre {
                appel_id: existant.0,
                compte_pour_preuve: existant.1.compte_pour_preuve(),
                rejeu: true,
            });
        }

        let appel_id = Uuid::now_v7();
        let issue = demande.issue.unwrap_or_default();
        let mut tx = self.pool.begin().await?;
        sqlx::query!(
            r#"INSERT INTO coursier.appel_coursier
                   (id, livraison_id, coursier_id, vers, prestataire_id, motif, issue,
                    uuid_client, passe_le_local)
               VALUES ($1, $2, $3, $4, $5, $6::text::coursier.motif_appel,
                       $7::text::coursier.issue_appel, $8, $9)"#,
            appel_id,
            livraison,
            coursier,
            demande.vers.comme_str(),
            demande.prestataire_id,
            demande.motif.comme_str(),
            issue.comme_str(),
            demande.uuid_client,
            demande.passe_le_local,
        )
        .execute(&mut *tx)
        .await?;

        // `appel.intention` existe depuis le cycle 008 et prévoyait déjà
        // `de: coursier` : ce cycle est le premier à l'émettre avec cette
        // valeur. Sa forme ne bouge pas — et surtout, AUCUN numéro n'y entre.
        let commande = self.commande_de_livraison(&mut tx, livraison).await?;
        socle::ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "appel.intention",
                entite_type: "commande",
                entite_id: commande,
                payload: json!({
                    "de": "coursier",
                    "vers": demande.vers.comme_str(),
                    "motif": demande.motif.comme_str(),
                    "livraison": livraison,
                    "acteur": coursier,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        tx.commit().await?;

        Ok(AppelEnregistre {
            appel_id,
            compte_pour_preuve: demande.motif.compte_pour_preuve(),
            rejeu: false,
        })
    }

    /// Met à jour la seule ISSUE d'un appel déjà journalisé (R19).
    ///
    /// Modifiable jusqu'à la déclaration d'échec : Yao répond « sans réponse »
    /// puis le client rappelle. Aucun événement — l'issue n'est pas une
    /// transition d'état, et elle n'est jamais un critère de preuve.
    pub async fn declarer_issue_appel(
        &self,
        coursier: Uuid,
        livraison: Uuid,
        uuid_client: Uuid,
        issue: IssueAppel,
    ) -> Result<AppelEnregistre, ErreurCoursier> {
        self.exiger_proprietaire(livraison, coursier).await?;
        let ligne = sqlx::query!(
            r#"UPDATE coursier.appel_coursier
                  SET issue = $3::text::coursier.issue_appel
                WHERE uuid_client = $1 AND livraison_id = $2
            RETURNING id, motif::text AS "motif!""#,
            uuid_client,
            livraison,
            issue.comme_str(),
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurCoursier::DemandeInvalide("appel inconnu"))?;

        Ok(AppelEnregistre {
            appel_id: ligne.id,
            compte_pour_preuve: ligne.motif.parse::<MotifAppel>()?.compte_pour_preuve(),
            rejeu: false,
        })
    }

    /// Appels journalisés d'une livraison, du plus ancien au plus récent.
    ///
    /// C'est la lecture de la preuve (nombre + espacement) et celle de
    /// l'exploitation (FR-063). **Aucun numéro** n'en sort — il n'y en a pas.
    pub async fn appels_de_livraison(
        &self,
        livraison: Uuid,
    ) -> Result<Vec<AppelJournalise>, ErreurCoursier> {
        let lignes = sqlx::query!(
            r#"SELECT id, vers, prestataire_id, motif::text AS "motif!",
                      issue::text AS "issue!", passe_le, passe_le_local
               FROM coursier.appel_coursier
               WHERE livraison_id = $1
               ORDER BY passe_le"#,
            livraison,
        )
        .fetch_all(&self.pool)
        .await?;

        lignes
            .into_iter()
            .map(|l| {
                Ok(AppelJournalise {
                    id: l.id,
                    vers: l.vers.parse()?,
                    prestataire_id: l.prestataire_id,
                    motif: l.motif.parse()?,
                    issue: l.issue.parse()?,
                    passe_le: l.passe_le,
                    passe_le_local: l.passe_le_local,
                })
            })
            .collect()
    }

    /// Appel déjà enregistré pour ce `uuid_client` (rejeu idempotent).
    async fn appel_par_uuid(
        &self,
        uuid_client: Uuid,
    ) -> Result<Option<(Uuid, MotifAppel)>, ErreurCoursier> {
        let ligne = sqlx::query!(
            r#"SELECT id, motif::text AS "motif!" FROM coursier.appel_coursier
               WHERE uuid_client = $1"#,
            uuid_client,
        )
        .fetch_optional(&self.pool)
        .await?;
        match ligne {
            Some(l) => Ok(Some((l.id, l.motif.parse()?))),
            None => Ok(None),
        }
    }

    /// Commande porteuse d'une livraison — `entite_id` des événements.
    pub(crate) async fn commande_de_livraison(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        livraison: Uuid,
    ) -> Result<Uuid, ErreurCoursier> {
        sqlx::query_scalar!(
            "SELECT commande_id FROM commandes.livraison WHERE id = $1",
            livraison,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurCoursier::CourseNonProprietaire)
    }
}
