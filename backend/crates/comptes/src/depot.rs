//! Accès Postgres au domaine comptes (patron du cycle 002).
//!
//! [`PgComptes`] porte le pool, les ports et le secret, et regroupe deux
//! surfaces :
//! - LECTURES : le trait [`Comptes`], consommé par les modules suivants — la
//!   porte de mise en ligne (CRS) et le filtre de transport (DSP) ;
//! - ÉCRITURES : méthodes inhérentes prenant `&mut sqlx::PgTransaction`, pour
//!   que l'atomicité « transition + événement outbox » soit impossible à
//!   contourner (constitution VI). Réparties dans `inscription.rs`, `role.rs`,
//!   `dossier.rs`, `adresse.rs`.
//!
//! Les énums Postgres sont écrites par cast `$n::text::comptes.<type>` et
//! relues en `<colonne>::text` — patron établi par `zones::Forcage`.

use std::sync::Arc;

use async_trait::async_trait;
use sqlx::PgPool;
use uuid::Uuid;
use zones::PgZones;

use crate::modele::{AttributionRole, Compte, ErreurComptes, Role, TypeTransport};
use crate::otp::ServiceOtp;
use crate::ports::{DepotEphemere, DepotObjets, EnvoiSms};

/// Lectures du domaine comptes — interface stable offerte aux autres crates
/// (data-model §5). Volontairement étroite : les modules suivants ont besoin de
/// savoir CE QU'UN COMPTE PEUT FAIRE, pas de lire la table.
#[async_trait]
pub trait Comptes: Send + Sync {
    /// Rôles au statut `valide` UNIQUEMENT — un rôle en attente, refusé ou
    /// suspendu n'ouvre rien (FR-011).
    async fn roles_valides(&self, compte: Uuid) -> Result<Vec<Role>, ErreurComptes>;

    /// Porte de mise en ligne du coursier (cycle CRS).
    ///
    /// INVARIANT SC-005 : `true` si et seulement si l'attribution `coursier`
    /// existe au statut `valide`. Aucun autre chemin, aucune exception.
    async fn coursier_autorise_en_ligne(&self, compte: Uuid) -> Result<bool, ErreurComptes>;

    /// Capacités de transport déclarées, pour que le dispatch (cycle DSP) ne
    /// propose que des commandes compatibles (FR-018).
    async fn capacites_transport(&self, compte: Uuid) -> Result<Vec<TypeTransport>, ErreurComptes>;
}

/// Handle de dépôt du domaine comptes. Le clone est bon marché (pool et ports
/// partagés).
#[derive(Clone)]
pub struct PgComptes {
    pub(crate) pool: PgPool,
    pub(crate) zones: PgZones,
    pub(crate) ephemere: Arc<dyn DepotEphemere>,
    pub(crate) sms: Arc<dyn EnvoiSms>,
    pub(crate) objets: Arc<dyn DepotObjets>,
    pub(crate) secret: Arc<[u8]>,
}

impl PgComptes {
    /// Construit le dépôt à partir du pool, des ports et du secret
    /// (`JWT_SECRET`). `PgZones` est dérivé du pool : la résolution des
    /// paramètres hérités se fait dans la MÊME base.
    pub fn new(
        pool: PgPool,
        ephemere: Arc<dyn DepotEphemere>,
        sms: Arc<dyn EnvoiSms>,
        objets: Arc<dyn DepotObjets>,
        secret: Arc<[u8]>,
    ) -> Self {
        Self {
            zones: PgZones::new(pool.clone()),
            pool,
            ephemere,
            sms,
            objets,
            secret,
        }
    }

    /// Pool sous-jacent — l'appelant ouvre ses transactions.
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    /// Secret de signature (consommé par l'extracteur `Auth` de la couche api).
    pub fn secret(&self) -> &[u8] {
        &self.secret
    }

    /// Stockage objet — pièces d'identité (`dossier.rs`) et repères vocaux
    /// (`adresse.rs`). Exposé pour que la couche `api` présigne sans
    /// reconstruire un client.
    pub fn objets(&self) -> &dyn DepotObjets {
        &*self.objets
    }

    /// Service OTP monté sur les ports de ce dépôt.
    pub(crate) fn otp(&self) -> ServiceOtp<'_> {
        ServiceOtp::new(&*self.ephemere, &*self.sms, &self.zones, &self.secret)
    }

    /// Compte par numéro E.164, dans la transaction en cours.
    pub(crate) async fn compte_par_telephone(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        e164: &str,
    ) -> Result<Option<Compte>, ErreurComptes> {
        let ligne = sqlx::query!(
            r#"SELECT id, telephone_e164, zone_id, consentement_version, consentement_le,
                      cree_le, derniere_connexion_le
               FROM comptes.compte WHERE telephone_e164 = $1"#,
            e164,
        )
        .fetch_optional(&mut **tx)
        .await?;

        Ok(ligne.map(|l| Compte {
            id: l.id,
            telephone_e164: l.telephone_e164,
            zone_id: l.zone_id,
            consentement_version: l.consentement_version,
            consentement_le: l.consentement_le,
            cree_le: l.cree_le,
            derniere_connexion_le: l.derniere_connexion_le,
        }))
    }

    /// Compte par identifiant (lecture sur pool).
    pub async fn compte(&self, compte: Uuid) -> Result<Compte, ErreurComptes> {
        let ligne = sqlx::query!(
            r#"SELECT id, telephone_e164, zone_id, consentement_version, consentement_le,
                      cree_le, derniere_connexion_le
               FROM comptes.compte WHERE id = $1"#,
            compte,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurComptes::CompteInconnu(compte))?;

        Ok(Compte {
            id: ligne.id,
            telephone_e164: ligne.telephone_e164,
            zone_id: ligne.zone_id,
            consentement_version: ligne.consentement_version,
            consentement_le: ligne.consentement_le,
            cree_le: ligne.cree_le,
            derniere_connexion_le: ligne.derniere_connexion_le,
        })
    }

    /// Toutes les attributions d'un compte, quel que soit leur statut (l'API
    /// `/moi` les expose telles quelles — FR-013).
    pub async fn attributions(&self, compte: Uuid) -> Result<Vec<AttributionRole>, ErreurComptes> {
        // ⚠ `ORDER BY attribution_role.role` (qualifié) et NON `ORDER BY role` :
        // non qualifié, Postgres trierait sur la colonne de SORTIE `role::text`,
        // donc par ordre alphabétique (admin, client, coursier, vendeur).
        // Qualifiée, la colonne d'ENTRÉE trie selon la déclaration de l'énum —
        // client, coursier, vendeur, admin — l'ordre métier attendu par l'UI.
        let lignes = sqlx::query!(
            r#"SELECT role::text AS "role!", statut::text AS "statut!", motif,
                      decide_par, decide_le, demande_le
               FROM comptes.attribution_role WHERE compte_id = $1
               ORDER BY attribution_role.role"#,
            compte,
        )
        .fetch_all(&self.pool)
        .await?;

        lignes
            .into_iter()
            .map(|l| {
                Ok(AttributionRole {
                    role: l.role.parse().map_err(ErreurComptes::Jeton)?,
                    statut: l.statut.parse().map_err(ErreurComptes::Jeton)?,
                    motif: l.motif,
                    decide_par: l.decide_par,
                    decide_le: l.decide_le,
                    demande_le: l.demande_le,
                })
            })
            .collect()
    }
}

#[async_trait]
impl Comptes for PgComptes {
    async fn roles_valides(&self, compte: Uuid) -> Result<Vec<Role>, ErreurComptes> {
        // Colonne QUALIFIÉE : tri par l'énum (ordre métier), pas par le texte.
        let lignes = sqlx::query!(
            r#"SELECT role::text AS "role!" FROM comptes.attribution_role
               WHERE compte_id = $1 AND statut = 'valide'::comptes.statut_role
               ORDER BY attribution_role.role"#,
            compte,
        )
        .fetch_all(&self.pool)
        .await?;

        lignes
            .into_iter()
            .map(|l| l.role.parse().map_err(ErreurComptes::Jeton))
            .collect()
    }

    async fn coursier_autorise_en_ligne(&self, compte: Uuid) -> Result<bool, ErreurComptes> {
        // Une SEULE définition de la porte, exprimée en SQL : « l'attribution
        // coursier est valide ». Toute autre lecture serait un contournement.
        let autorise = sqlx::query_scalar!(
            r#"SELECT EXISTS(
                 SELECT 1 FROM comptes.attribution_role
                 WHERE compte_id = $1
                   AND role = 'coursier'::comptes.role
                   AND statut = 'valide'::comptes.statut_role
               )"#,
            compte,
        )
        .fetch_one(&self.pool)
        .await?;
        Ok(autorise.unwrap_or(false))
    }

    async fn capacites_transport(&self, compte: Uuid) -> Result<Vec<TypeTransport>, ErreurComptes> {
        let lignes = sqlx::query!(
            r#"SELECT t.id, t.slug
               FROM comptes.vehicule_declare v
               JOIN zones.type_transport t ON t.id = v.type_transport_id
               WHERE v.compte_id = $1
               ORDER BY t.ordre"#,
            compte,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(lignes
            .into_iter()
            .map(|l| TypeTransport {
                id: l.id,
                slug: l.slug,
            })
            .collect())
    }
}
