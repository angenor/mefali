//! Dossier coursier (CPT-04, FR-015 → FR-018).
//!
//! ## Ce que le dossier est, et n'est pas
//!
//! Le dossier porte le CONTENU — pièce d'identité, référent local, véhicules ;
//! son STATUT est celui de l'attribution `coursier` (research R9). Il n'y a
//! donc pas de « valider le dossier » ici : valider un dossier, c'est valider
//! le rôle, et ça se passe dans `role.rs`. Ce module ne connaît qu'une
//! transition — la soumission, qui DEMANDE le rôle.
//!
//! ## Pourquoi la soumission porte la demande
//!
//! FR-015 exige qu'on ne puisse pas demander le rôle coursier sans dossier.
//! C'est pour ça que `demander_role_coursier` est `pub(crate)` : ce module est
//! son SEUL appelant hors tests. La règle n'est pas une convention de revue,
//! c'est la visibilité du langage qui la tient.

use chrono::Utc;
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use std::collections::HashMap;
use uuid::Uuid;
use zones::ConfigurationZones;

use crate::depot::PgComptes;
use crate::modele::{DossierCoursier, ErreurComptes, Role, StatutRole, VehiculeDeclare};
use crate::otp::normaliser_e164;
use crate::role::statut_role;

/// Taille maximale de la pièce d'identité.
///
/// CONSTANTE PRODUIT, pas un paramètre de zone : 10 Mo couvre largement une
/// photo de CNI prise au téléphone, et la borne protège le VPS — elle ne varie
/// pas d'une ville à l'autre (elle est absente du « Récapitulatif des
/// paramètres de zone » du cadrage).
pub const PIECE_TAILLE_MAX: usize = 10 * 1024 * 1024;

/// Types MIME acceptés pour la pièce d'identité (contrat `SoumissionDossier`).
pub const PIECE_MIMES: &[&str] = &["image/jpeg", "image/png", "image/webp", "application/pdf"];

/// Longueur maximale du nom du référent (contrat `SoumissionDossier`).
pub const REFERENT_NOM_MAX: usize = 120;

/// Pièce d'identité soumise (octets + type déclaré).
#[derive(Debug, Clone)]
pub struct PieceIdentite {
    /// Contenu du fichier.
    pub octets: Vec<u8>,
    /// Type MIME déclaré par le client, validé ici.
    pub mime: String,
}

/// Ce qu'un coursier soumet (FR-015).
#[derive(Debug, Clone)]
pub struct SoumissionDossier {
    /// Pièce d'identité.
    pub piece: PieceIdentite,
    /// Nom du référent local.
    pub referent_nom: String,
    /// Téléphone du référent — saisie BRUTE, normalisée ici comme celle du
    /// compte (même indicatif de zone, même CHECK en base).
    pub referent_telephone: String,
    /// Types de transport déclarés, par SLUG du référentiel ZON-03.
    ///
    /// Le client n'envoie jamais d'UUID : il coche des slugs venus de
    /// `transport.actifs` de la config de zone qu'il a déjà en main.
    pub vehicules: Vec<String>,
}

/// Issue d'une soumission (R14).
#[derive(Debug, Clone)]
pub enum IssueSoumission {
    /// Dossier créé (∅) ou re-soumis après refus : le rôle passe `en_attente`.
    Soumis {
        /// Le dossier tel qu'il est désormais.
        dossier: DossierCoursier,
        /// Clé de la pièce d'identité que cette soumission vient de REMPLACER
        /// (re-soumission après refus) — `None` à la première soumission.
        ///
        /// Plus aucune ligne ne la référence : c'est une donnée personnelle
        /// devenue orpheline dans le stockage objet, que l'appelant doit
        /// supprimer APRÈS son commit (constitution VIII — minimisation ARTCI).
        /// Le domaine ne la supprime pas lui-même : il ne possède pas la
        /// transaction, et un rollback ferait pointer le dossier vers du vide.
        piece_orpheline: Option<String>,
    },
    /// Un dossier est DÉJÀ en attente — rejeu réseau. Rien n'a changé, rien
    /// n'a été déposé, aucun événement n'a été émis : on rend l'état courant.
    DejaEnAttente(DossierCoursier),
}

/// Dossier + identité du compte, pour la revue admin (contrat
/// `DossierCoursierAdmin`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DossierCoursierAdmin {
    /// Le dossier lui-même.
    pub dossier: DossierCoursier,
    /// Numéro du coursier — l'admin doit pouvoir le rappeler (FR-017).
    pub telephone_e164: String,
}

impl PgComptes {
    /// Soumet (ou re-soumet après refus) le dossier coursier et DEMANDE le rôle.
    ///
    /// Tout est dans LA transaction de l'appelant : le dossier, les véhicules,
    /// la transition de rôle et les deux événements (`role.demande` +
    /// `dossier_coursier.soumis`) tombent ou tiennent ensemble (constitution VI).
    ///
    /// Seul le dépôt de la pièce dans le stockage objet échappe à la
    /// transaction — aucun stockage objet n'est transactionnel. L'ordre est
    /// choisi pour que le pire cas soit inoffensif : on dépose APRÈS avoir
    /// validé la transition, donc un rollback laisse au pire un objet orphelin
    /// dans le bucket, jamais une ligne qui pointe vers un objet absent.
    ///
    /// Une re-soumission écrit une clé NEUVE et n'écrase donc jamais la pièce
    /// précédente : celle-ci est rendue en [`IssueSoumission::Soumis::piece_orpheline`],
    /// à charge de l'appelant de la supprimer après commit.
    pub async fn soumettre_dossier_coursier(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
        soumission: &SoumissionDossier,
    ) -> Result<IssueSoumission, ErreurComptes> {
        let zone = self.zone_du_compte(tx, compte).await?;
        let avant = statut_role(tx, compte, Role::Coursier).await?;

        // R14 — rejeu pendant `en_attente` : le dossier est déjà là. On le rend
        // tel quel, sans rien déposer ni émettre. Le 409 reste réservé aux
        // transitions réellement invalides (depuis `valide` ou `suspendu`).
        if avant == Some(StatutRole::EnAttente) {
            let dossier = self.dossier_dans_tx(tx, compte, zone).await?;
            return Ok(IssueSoumission::DejaEnAttente(dossier));
        }

        // Validations AVANT tout effet : un dossier incomplet n'est pas soumis
        // (FR-015, scénario 1).
        let referent_nom = soumission.referent_nom.trim();
        if referent_nom.is_empty() || referent_nom.chars().count() > REFERENT_NOM_MAX {
            return Err(ErreurComptes::DossierIncomplet);
        }
        if soumission.piece.octets.is_empty() || soumission.vehicules.is_empty() {
            return Err(ErreurComptes::DossierIncomplet);
        }
        if soumission.piece.octets.len() > PIECE_TAILLE_MAX {
            return Err(ErreurComptes::ObjetTropVolumineux);
        }
        if !PIECE_MIMES.contains(&soumission.piece.mime.as_str()) {
            return Err(ErreurComptes::MediaInvalide(soumission.piece.mime.clone()));
        }

        let referent_e164 =
            normaliser_e164(&self.zones, zone, &soumission.referent_telephone).await?;
        let types = self.resoudre_vehicules(zone, &soumission.vehicules).await?;

        // La MACHINE décide : ∅|refuse → en_attente, tout le reste →
        // TransitionInvalide. Appelée avant le dépôt de la pièce — un 409 ne
        // doit pas laisser d'octets derrière lui.
        self.demander_role_coursier(tx, compte).await?;

        // La pièce que le UPSERT ci-dessous va déréférencer. Lue AVANT lui, et
        // dans la transaction : après, la clé est perdue et la donnée
        // personnelle resterait dans le bucket sans que rien ne la désigne.
        let piece_orpheline = sqlx::query_scalar!(
            "SELECT piece_cle_objet FROM comptes.dossier_coursier WHERE compte_id = $1",
            compte,
        )
        .fetch_optional(&mut **tx)
        .await?;

        let cle_piece = format!("comptes/pieces/{compte}/{}", Uuid::now_v7());
        self.objets
            .deposer(
                &cle_piece,
                soumission.piece.octets.clone(),
                &soumission.piece.mime,
            )
            .await?;

        let maintenant = Utc::now();
        sqlx::query!(
            r#"INSERT INTO comptes.dossier_coursier
                 (compte_id, piece_cle_objet, piece_mime, referent_nom,
                  referent_telephone_e164, soumis_le)
               VALUES ($1, $2, $3, $4, $5, $6)
               ON CONFLICT (compte_id) DO UPDATE SET
                 piece_cle_objet = EXCLUDED.piece_cle_objet,
                 piece_mime = EXCLUDED.piece_mime,
                 referent_nom = EXCLUDED.referent_nom,
                 referent_telephone_e164 = EXCLUDED.referent_telephone_e164,
                 soumis_le = EXCLUDED.soumis_le"#,
            compte,
            cle_piece,
            soumission.piece.mime,
            referent_nom,
            referent_e164,
            maintenant,
        )
        .execute(&mut **tx)
        .await?;

        // La flotte re-soumise REMPLACE la précédente : le coursier refusé qui
        // renvoie son dossier redéclare ses véhicules, il ne les cumule pas.
        sqlx::query!(
            "DELETE FROM comptes.vehicule_declare WHERE compte_id = $1",
            compte,
        )
        .execute(&mut **tx)
        .await?;

        let ids: Vec<Uuid> = types.iter().map(|_| Uuid::now_v7()).collect();
        let types_ids: Vec<Uuid> = types.iter().map(|t| t.type_transport_id).collect();
        sqlx::query!(
            r#"INSERT INTO comptes.vehicule_declare (id, compte_id, type_transport_id)
               SELECT v.id, $2, v.type_transport
               FROM unnest($1::uuid[], $3::uuid[]) AS v(id, type_transport)"#,
            &ids,
            compte,
            &types_ids,
        )
        .execute(&mut **tx)
        .await?;

        let re_soumission = avant == Some(StatutRole::Refuse);
        let slugs: Vec<&str> = types.iter().map(|t| t.slug.as_str()).collect();
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "dossier_coursier.soumis",
                // PK = compte_id : aucun id de substitution (taxonomie T004).
                entite_type: "dossier_coursier",
                entite_id: compte,
                // Minimisation ARTCI : ni la pièce, ni le référent, ni aucune
                // donnée nominative ne sortent en événement (taxonomie T004).
                payload: json!({
                    "zone": zone,
                    "compte": compte,
                    "role": Role::Coursier.comme_str(),
                    "vehicules": slugs,
                    "re_soumission": re_soumission,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;

        Ok(IssueSoumission::Soumis {
            dossier: DossierCoursier {
                compte_id: compte,
                piece_cle_objet: cle_piece,
                piece_mime: soumission.piece.mime.clone(),
                referent_nom: referent_nom.to_owned(),
                referent_telephone_e164: referent_e164,
                soumis_le: maintenant,
                vehicules: types,
                statut: StatutRole::EnAttente,
                motif: None,
            },
            piece_orpheline,
        })
    }

    /// Dossier d'un compte (`GET /moi/dossier-coursier`).
    pub async fn dossier_coursier(&self, compte: Uuid) -> Result<DossierCoursier, ErreurComptes> {
        let mut tx = self.pool.begin().await?;
        let zone = self.zone_du_compte(&mut tx, compte).await?;
        let dossier = self.dossier_dans_tx(&mut tx, compte, zone).await?;
        tx.rollback().await?;
        Ok(dossier)
    }

    /// Dossiers pour la revue admin, filtrables par statut (FR-017).
    pub async fn dossiers_coursier(
        &self,
        statut: Option<StatutRole>,
    ) -> Result<Vec<DossierCoursierAdmin>, ErreurComptes> {
        let lignes = sqlx::query!(
            r#"SELECT d.compte_id, c.telephone_e164, c.zone_id,
                      d.piece_cle_objet, d.piece_mime, d.referent_nom,
                      d.referent_telephone_e164, d.soumis_le,
                      a.statut::text AS "statut!", a.motif
               FROM comptes.dossier_coursier d
               JOIN comptes.compte c ON c.id = d.compte_id
               -- Le statut du dossier EST celui de l'attribution (R9) : le
               -- filtre porte donc sur `attribution_role`, via son index
               -- (role, statut).
               JOIN comptes.attribution_role a
                 ON a.compte_id = d.compte_id AND a.role = 'coursier'::comptes.role
               WHERE $1::text IS NULL OR a.statut = $1::text::comptes.statut_role
               ORDER BY d.soumis_le DESC"#,
            statut.map(StatutRole::comme_str),
        )
        .fetch_all(&self.pool)
        .await?;

        let comptes: Vec<Uuid> = lignes.iter().map(|l| l.compte_id).collect();
        let mut vehicules = self.vehicules_par_compte(&comptes).await?;

        // Une zone par compte, mais une seule lecture de `transport.actifs` par
        // zone : la liste admin d'une ville ne doit pas la relire N fois.
        let mut actifs_par_zone: HashMap<Uuid, Vec<String>> = HashMap::new();
        let mut dossiers = Vec::with_capacity(lignes.len());
        for ligne in lignes {
            let actifs = match actifs_par_zone.get(&ligne.zone_id) {
                Some(actifs) => actifs,
                None => {
                    let actifs = self.zones.transports_actifs(ligne.zone_id).await?;
                    actifs_par_zone.entry(ligne.zone_id).or_insert(actifs)
                }
            };
            let declares = vehicules
                .remove(&ligne.compte_id)
                .unwrap_or_default()
                .into_iter()
                .map(|(id, slug)| VehiculeDeclare {
                    type_transport_id: id,
                    actif_zone: actifs.iter().any(|a| a == &slug),
                    slug,
                })
                .collect();

            dossiers.push(DossierCoursierAdmin {
                dossier: DossierCoursier {
                    compte_id: ligne.compte_id,
                    piece_cle_objet: ligne.piece_cle_objet,
                    piece_mime: ligne.piece_mime,
                    referent_nom: ligne.referent_nom,
                    referent_telephone_e164: ligne.referent_telephone_e164,
                    soumis_le: ligne.soumis_le,
                    vehicules: declares,
                    statut: ligne.statut.parse().map_err(ErreurComptes::Jeton)?,
                    motif: ligne.motif,
                },
                telephone_e164: ligne.telephone_e164,
            });
        }
        Ok(dossiers)
    }

    /// Dossier complet d'un compte pour l'admin (`GET /admin/comptes/{id}/…`).
    pub async fn dossier_coursier_admin(
        &self,
        compte: Uuid,
    ) -> Result<DossierCoursierAdmin, ErreurComptes> {
        let telephone = sqlx::query_scalar!(
            "SELECT telephone_e164 FROM comptes.compte WHERE id = $1",
            compte,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurComptes::CompteInconnu(compte))?;

        Ok(DossierCoursierAdmin {
            dossier: self.dossier_coursier(compte).await?,
            telephone_e164: telephone,
        })
    }

    /// Zone de rattachement, dans la transaction en cours.
    async fn zone_du_compte(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
    ) -> Result<Uuid, ErreurComptes> {
        sqlx::query_scalar!("SELECT zone_id FROM comptes.compte WHERE id = $1", compte)
            .fetch_optional(&mut **tx)
            .await?
            .ok_or(ErreurComptes::CompteInconnu(compte))
    }

    /// Lecture du dossier + de son statut, dans la transaction en cours.
    async fn dossier_dans_tx(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
        zone: Uuid,
    ) -> Result<DossierCoursier, ErreurComptes> {
        let ligne = sqlx::query!(
            r#"SELECT d.piece_cle_objet, d.piece_mime, d.referent_nom,
                      d.referent_telephone_e164, d.soumis_le,
                      a.statut::text AS "statut!", a.motif
               FROM comptes.dossier_coursier d
               JOIN comptes.attribution_role a
                 ON a.compte_id = d.compte_id AND a.role = 'coursier'::comptes.role
               WHERE d.compte_id = $1"#,
            compte,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurComptes::DossierInconnu(compte))?;

        let lignes = sqlx::query!(
            r#"SELECT t.id, t.slug
               FROM comptes.vehicule_declare v
               JOIN zones.type_transport t ON t.id = v.type_transport_id
               WHERE v.compte_id = $1
               ORDER BY t.ordre"#,
            compte,
        )
        .fetch_all(&mut **tx)
        .await?;

        // Edge case spec : un type DÉSACTIVÉ dans la zone après déclaration
        // reste déclaré — il est signalé (`actif_zone = false`), pas effacé.
        let actifs = self.zones.transports_actifs(zone).await?;
        let vehicules = lignes
            .into_iter()
            .map(|l| VehiculeDeclare {
                type_transport_id: l.id,
                actif_zone: actifs.iter().any(|a| a == &l.slug),
                slug: l.slug,
            })
            .collect();

        Ok(DossierCoursier {
            compte_id: compte,
            piece_cle_objet: ligne.piece_cle_objet,
            piece_mime: ligne.piece_mime,
            referent_nom: ligne.referent_nom,
            referent_telephone_e164: ligne.referent_telephone_e164,
            soumis_le: ligne.soumis_le,
            vehicules,
            statut: ligne.statut.parse().map_err(ErreurComptes::Jeton)?,
            motif: ligne.motif,
        })
    }

    /// Véhicules de plusieurs comptes en UNE requête (liste admin).
    async fn vehicules_par_compte(
        &self,
        comptes: &[Uuid],
    ) -> Result<HashMap<Uuid, Vec<(Uuid, String)>>, ErreurComptes> {
        let lignes = sqlx::query!(
            r#"SELECT v.compte_id, t.id, t.slug
               FROM comptes.vehicule_declare v
               JOIN zones.type_transport t ON t.id = v.type_transport_id
               WHERE v.compte_id = ANY($1)
               ORDER BY v.compte_id, t.ordre"#,
            comptes,
        )
        .fetch_all(&self.pool)
        .await?;

        let mut par_compte: HashMap<Uuid, Vec<(Uuid, String)>> = HashMap::new();
        for ligne in lignes {
            par_compte
                .entry(ligne.compte_id)
                .or_default()
                .push((ligne.id, ligne.slug));
        }
        Ok(par_compte)
    }

    /// Résout des slugs en types de transport ACTIFS de la zone (FR-015).
    ///
    /// L'appartenance aux actifs est vérifiée AVANT le référentiel : un slug
    /// inconnu (« licorne ») et un slug connu mais inactif à Tiassalé
    /// (« camion ») sont le même refus côté client — `VehiculeHorsZone`, 422.
    /// Le contrat ne prévoit pas d'autre code, et distinguer les deux
    /// renseignerait un client sur le référentiel sans utilité.
    async fn resoudre_vehicules(
        &self,
        zone: Uuid,
        slugs: &[String],
    ) -> Result<Vec<VehiculeDeclare>, ErreurComptes> {
        let actifs = self.zones.transports_actifs(zone).await?;

        // Dédoublonnage : « moto, moto » est une maladresse de saisie, pas une
        // erreur — et la contrainte UNIQUE (compte_id, type_transport_id) la
        // refuserait en SQL brut.
        let mut demandes: Vec<&str> = Vec::new();
        for slug in slugs {
            let slug = slug.trim();
            if !actifs.iter().any(|a| a == slug) {
                return Err(ErreurComptes::VehiculeHorsZone(slug.to_owned()));
            }
            if !demandes.contains(&slug) {
                demandes.push(slug);
            }
        }

        let demandes_owned: Vec<String> = demandes.iter().map(|s| (*s).to_owned()).collect();
        let lignes = sqlx::query!(
            r#"SELECT id, slug FROM zones.type_transport
               WHERE slug = ANY($1) ORDER BY ordre"#,
            &demandes_owned,
        )
        .fetch_all(&self.pool)
        .await?;

        if lignes.len() != demandes.len() {
            // Un slug déclaré ACTIF dans la zone mais absent du référentiel :
            // la configuration de zone est en faute, pas le coursier (500).
            return Err(ErreurComptes::ConfigurationZoneInvalide {
                cle: "transport.actifs",
                raison: "slug actif absent du référentiel zones.type_transport".to_owned(),
            });
        }

        Ok(lignes
            .into_iter()
            .map(|l| VehiculeDeclare {
                type_transport_id: l.id,
                slug: l.slug,
                // Ils viennent d'être validés contre les actifs de la zone.
                actif_zone: true,
            })
            .collect())
    }
}
