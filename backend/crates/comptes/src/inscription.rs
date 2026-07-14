//! Flux UNIQUE inscription/connexion (CPT-01, FR-004..006).
//!
//! ## Pourquoi un seul flux
//!
//! Deux parcours séparés (« s'inscrire » / « se connecter ») trahiraient
//! l'existence d'un compte dès l'écran d'entrée. Ici, le même geste — numéro,
//! code — mène soit à une session (numéro connu), soit à une demande de
//! consentement (numéro inconnu). La divergence n'apparaît qu'APRÈS une
//! vérification RÉUSSIE, c'est-à-dire à quelqu'un qui possède déjà le
//! téléphone : ce n'est pas un oracle d'énumération. Tous les ÉCHECS, eux,
//! restent strictement indistinguables (SC-003, contrat 401 unique).

use chrono::Utc;
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::depot::PgComptes;
use crate::modele::{Appareil, AttributionRole, Compte, ErreurComptes, Role, Session};
use crate::ports::JetonInscription;
use crate::session::{
    emettre_acces, generer_jeton_inscription, generer_refresh, hacher_refresh, Jetons,
    OrigineSession, JETON_INSCRIPTION_TTL,
};

/// Issue d'une vérification OTP réussie (contrat `/auth/otp/verifier`).
#[derive(Debug)]
pub enum IssueVerification {
    /// Numéro connu — session ouverte sur le compte existant (aucun doublon).
    Session(SessionOuverte),
    /// Numéro inconnu — le consentement ARTCI est exigé avant toute création
    /// (FR-006). Le jeton porte le numéro vérifié, la zone et l'appareil.
    ConsentementRequis {
        /// Jeton d'inscription à usage unique, TTL 10 min (research R3).
        jeton_inscription: String,
    },
}

/// Session ouverte et son contexte (contrat `SessionOuverte`).
#[derive(Debug)]
pub struct SessionOuverte {
    /// Compte connecté.
    pub compte: Compte,
    /// Jetons remis à l'appareil.
    pub jetons: Jetons,
    /// Attributions de rôle du compte (tous statuts — FR-013).
    pub roles: Vec<AttributionRole>,
}

impl PgComptes {
    /// Demande d'un code (FR-001..003). Voir [`crate::otp::ServiceOtp::demander`]
    /// — l'appelant HTTP répond 202 neutre y compris sur `PlafondAtteint`.
    pub async fn demander_otp(
        &self,
        zone: Uuid,
        saisie_telephone: &str,
        ip: &str,
    ) -> Result<(), ErreurComptes> {
        self.otp().demander(zone, saisie_telephone, ip).await
    }

    /// Vérifie un code et ouvre une session, ou exige le consentement.
    pub async fn verifier_otp(
        &self,
        zone: Uuid,
        saisie_telephone: &str,
        code: &str,
        appareil: &Appareil,
    ) -> Result<IssueVerification, ErreurComptes> {
        let e164 = self.otp().verifier(zone, saisie_telephone, code).await?;

        let mut tx = self.pool.begin().await?;
        let Some(compte) = self.compte_par_telephone(&mut tx, &e164).await? else {
            // Numéro inconnu : rien à écrire en base. Le jeton porte l'appareil
            // capté ici, pour que `/auth/inscription` crée la session sans le
            // redemander (session.appareil_* est NOT NULL — analyze C1).
            drop(tx);
            let jeton = generer_jeton_inscription();
            self.ephemere
                .poser_jeton_inscription(
                    &jeton,
                    &JetonInscription {
                        telephone_e164: e164,
                        zone,
                        appareil: appareil.clone(),
                    },
                    JETON_INSCRIPTION_TTL,
                )
                .await?;
            return Ok(IssueVerification::ConsentementRequis {
                jeton_inscription: jeton,
            });
        };

        let maintenant = Utc::now();
        sqlx::query!(
            "UPDATE comptes.compte SET derniere_connexion_le = $2 WHERE id = $1",
            compte.id,
            maintenant,
        )
        .execute(&mut *tx)
        .await?;

        let (_, jetons) = self
            .creer_session(
                &mut tx,
                compte.id,
                compte.zone_id,
                appareil,
                OrigineSession::VerificationOtp,
            )
            .await?;
        tx.commit().await?;

        let roles = self.attributions(compte.id).await?;
        Ok(IssueVerification::Session(SessionOuverte {
            compte: Compte {
                derniere_connexion_le: Some(maintenant),
                ..compte
            },
            jetons,
            roles,
        }))
    }

    /// Crée le compte après consentement, puis ouvre sa session (FR-005/006).
    ///
    /// Le consentement est validé AVANT de consommer le jeton : un refus ne
    /// doit pas brûler le jeton et renvoyer l'utilisateur à un nouveau SMS.
    pub async fn inscrire(
        &self,
        jeton_inscription: &str,
        consentement_version: &str,
    ) -> Result<SessionOuverte, ErreurComptes> {
        if consentement_version.trim().is_empty() {
            return Err(ErreurComptes::ConsentementRequis);
        }
        let contenu = self
            .ephemere
            .consommer_jeton_inscription(jeton_inscription)
            .await?
            .ok_or(ErreurComptes::JetonInscriptionInvalide)?;

        let mut tx = self.pool.begin().await?;
        // Le numéro a pu être inscrit entre la vérification et ici (autre
        // appareil) : on ouvre alors une session sur le compte existant plutôt
        // que d'échouer — « sans doublon possible » (FR-005).
        let compte = match self
            .compte_par_telephone(&mut tx, &contenu.telephone_e164)
            .await?
        {
            Some(existant) => existant,
            None => {
                self.creer_compte(
                    &mut tx,
                    &contenu.telephone_e164,
                    contenu.zone,
                    consentement_version,
                )
                .await?
            }
        };

        let (_, jetons) = self
            .creer_session(
                &mut tx,
                compte.id,
                compte.zone_id,
                &contenu.appareil,
                OrigineSession::Inscription,
            )
            .await?;
        tx.commit().await?;

        let roles = self.attributions(compte.id).await?;
        Ok(SessionOuverte {
            compte,
            jetons,
            roles,
        })
    }

    /// Crée un compte RÉDUIT au numéro vérifié + zone + consentement, avec son
    /// attribution `client` valide, et émet `compte.cree` — le tout dans LA
    /// transaction de l'appelant (constitution VI).
    ///
    /// Aucune donnée de profil : ni nom, ni e-mail (clarification « numéro
    /// seul »). L'unicité du numéro est portée par le schéma (UNIQUE) : deux
    /// inscriptions vraiment simultanées font échouer la perdante, dont le
    /// rejeu se résout naturellement en connexion.
    pub async fn creer_compte(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        telephone_e164: &str,
        zone: Uuid,
        consentement_version: &str,
    ) -> Result<Compte, ErreurComptes> {
        if consentement_version.trim().is_empty() {
            return Err(ErreurComptes::ConsentementRequis);
        }
        let id = Uuid::now_v7();
        let maintenant = Utc::now();

        let ligne = sqlx::query!(
            r#"INSERT INTO comptes.compte
                 (id, telephone_e164, zone_id, consentement_version, consentement_le)
               VALUES ($1, $2, $3, $4, $5)
               RETURNING cree_le"#,
            id,
            telephone_e164,
            zone,
            consentement_version,
            maintenant,
        )
        .fetch_one(&mut **tx)
        .await?;

        // Le rôle client naît valide et le reste (CHECK du schéma — R9).
        sqlx::query!(
            r#"INSERT INTO comptes.attribution_role (compte_id, role, statut)
               VALUES ($1, 'client'::comptes.role, 'valide'::comptes.statut_role)"#,
            id,
        )
        .execute(&mut **tx)
        .await?;

        // L'attribution `client` automatique est INCLUSE dans compte.cree
        // (data-model §4) — pas de role.attribue pour elle.
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "compte.cree",
                entite_type: "compte",
                entite_id: id,
                payload: json!({
                    "zone": zone,
                    "role": Role::Client.comme_str(),
                    "consentement_version": consentement_version,
                    "consentement_le": maintenant,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;

        Ok(Compte {
            id,
            telephone_e164: telephone_e164.to_owned(),
            zone_id: zone,
            consentement_version: consentement_version.to_owned(),
            consentement_le: maintenant,
            cree_le: ligne.cree_le,
            derniere_connexion_le: None,
        })
    }

    /// Ouvre une session d'appareil et émet `session.creee` dans la transaction
    /// de l'appelant. Renvoie la session et les jetons — le refresh EN CLAIR
    /// n'existe qu'ici et dans la réponse HTTP : la base n'en voit que le hash.
    pub async fn creer_session(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
        zone: Uuid,
        appareil: &Appareil,
        origine: OrigineSession,
    ) -> Result<(Session, Jetons), ErreurComptes> {
        let id = Uuid::now_v7();
        let rafraichissement = generer_refresh();
        let maintenant = Utc::now();

        let ligne = sqlx::query!(
            r#"INSERT INTO comptes.session
                 (id, compte_id, refresh_hash, appareil_nom, appareil_plateforme)
               VALUES ($1, $2, $3, $4, $5)
               RETURNING cree_le, derniere_activite_le"#,
            id,
            compte,
            hacher_refresh(&rafraichissement),
            appareil.nom,
            appareil.plateforme.comme_str(),
        )
        .fetch_one(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "session.creee",
                entite_type: "session",
                entite_id: id,
                payload: json!({
                    "zone": zone,
                    "compte": compte,
                    "appareil_plateforme": appareil.plateforme.comme_str(),
                    "origine": origine.comme_str(),
                }),
                survenu_le: maintenant,
            },
        )
        .await?;

        let acces = emettre_acces(&self.secret, compte, id)?;
        Ok((
            Session {
                id,
                compte_id: compte,
                appareil: appareil.clone(),
                cree_le: ligne.cree_le,
                derniere_activite_le: ligne.derniere_activite_le,
                revoquee_le: None,
            },
            Jetons {
                acces,
                rafraichissement,
            },
        ))
    }
}
