//! Composition racine du socle logistique et transition d'arrêt (data-model §4.1).
//!
//! ÉCRITURE = méthode inhérente `marquer_arret_collecte` sur `&mut PgTransaction`
//! (transition + événement dans la même transaction, constitution VI).
//! LECTURE = impl du port `ArretsDeCollecte`.

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use sqlx::PgPool;
use uuid::Uuid;

use crate::modele::{
    ArretACollecter, ErreurCommandes, ModeCollecte, ProgressionCollecte, StatutArret,
};
use crate::ports::ArretsDeCollecte;

/// Handle de dépôt du socle logistique. Clone bon marché (pool partagé).
#[derive(Clone)]
pub struct PgCommandes {
    pub(crate) pool: PgPool,
}

impl PgCommandes {
    /// Nouveau dépôt sur le pool applicatif.
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Accès au pool (racine de composition `qr`).
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    /// Bascule l'arrêt en COLLECTÉ dans `tx`, écrit `arret.collecte`, et si tous
    /// les arrêts de la livraison sont résolus, bascule la livraison EN_LIVRAISON
    /// + écrit `livraison.mise_en_livraison`. Idempotent par `uuid_client` : un
    /// rejeu du même uuid sur un arrêt déjà `collecte` renvoie la progression
    /// sans nouvelle écriture ni événement.
    #[allow(clippy::too_many_arguments)]
    pub async fn marquer_arret_collecte(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        arret_id: Uuid,
        uuid_client: Uuid,
        mode: ModeCollecte,
        photo_cle: Option<&str>,
        distance_m: i32,
        horodatage_serveur: DateTime<Utc>,
        acteur: Uuid,
    ) -> Result<ProgressionCollecte, ErreurCommandes> {
        // Contexte de l'arrêt + verrou de ligne (join segment→livraison→commande).
        let arret = sqlx::query!(
            r#"SELECT a.statut::text AS "statut!", a.collecte_uuid_client,
                      a.segment_id, s.livraison_id, l.commande_id,
                      a.prestataire_id, a.montant_avance, a.devise,
                      l.etat::text AS "etat_livraison!"
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               JOIN commandes.livraison l ON l.id = s.livraison_id
               WHERE a.id = $1
               FOR UPDATE OF a"#,
            arret_id,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurCommandes::ArretInconnu(arret_id))?;

        let statut: StatutArret = arret.statut.parse()?;

        // Idempotence & garde d'état (data-model §1.3).
        match statut {
            // Rejeu du MÊME uuid_client → succès sans nouvelle écriture ni événement.
            StatutArret::Collecte if arret.collecte_uuid_client == Some(uuid_client) => {
                return self.progression(tx, arret.livraison_id, false).await;
            }
            // Déjà collecté par un AUTRE uuid, arrêt indisponible, ou coursier
            // en route sans avoir déclaré son arrivée → refus. `en_route` est
            // absent de la table de transitions (data-model §3.3) : c'est
            // `arrive_le` qui fonde la prime d'attente (TRF-06), on ne peut pas
            // le sauter.
            StatutArret::Collecte | StatutArret::Indisponible | StatutArret::EnRoute => {
                return Err(ErreurCommandes::EtatIncompatible {
                    avant: statut.comme_str().to_owned(),
                    apres: StatutArret::Collecte.comme_str().to_owned(),
                });
            }
            // `a_collecter → collecte` DIRECT : chemin du cycle 006, conservé
            // tel quel (le coursier peut scanner sans avoir déclaré son trajet).
            // `arrive → collecte` : chemin nominal de la boucle CMD-04.
            StatutArret::ACollecter | StatutArret::Arrive => {}
        }

        // ── Partie A : bascule a_collecter → collecte ──────────────────────
        sqlx::query!(
            r#"UPDATE commandes.arret
               SET statut = 'collecte',
                   collecte_le = $2,
                   mode_collecte = $3::commandes.mode_collecte,
                   photo_cle = $4,
                   distance_scan_m = $5,
                   collecte_uuid_client = $6
               WHERE id = $1"#,
            arret_id,
            horodatage_serveur,
            mode.comme_str() as _,
            photo_cle,
            distance_m,
            uuid_client,
        )
        .execute(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "arret.collecte",
                entite_type: "arret",
                entite_id: arret_id,
                payload: json!({
                    "commande": arret.commande_id,
                    "livraison": arret.livraison_id,
                    "segment": arret.segment_id,
                    "prestataire": arret.prestataire_id,
                    "mode": mode.comme_str(),
                    "avec_photo": photo_cle.is_some(),
                    // ARTCI : jamais de lat/lng brut — présence GPS + distance arrondie.
                    "gps_ok": true,
                    "distance_m": distance_m,
                    "montant_avance": arret.montant_avance,
                    "devise": arret.devise,
                    "acteur": acteur,
                }),
                survenu_le: horodatage_serveur,
            },
        )
        .await?;

        // ── Partie B : gating EN_LIVRAISON (livraison déjà lue en_collecte) ──
        let bascule = arret.etat_livraison == "en_collecte";
        self.gating_livraison(
            tx,
            arret.livraison_id,
            arret.commande_id,
            acteur,
            horodatage_serveur,
            bascule,
        )
        .await
    }

    /// Bascule la livraison EN_LIVRAISON si toutes ses COLLECTES sont résolues
    /// (et qu'elle est encore `en_collecte`). Renvoie la progression.
    ///
    /// ⚠ **Ne compte que les arrêts de type `collecte`** (cycle CMD 008, P1 /
    /// research R4). Le cycle 006 comptait `count(*)` sur TOUS les arrêts du
    /// segment ; depuis que la remise est elle aussi un arrêt (cadrage §7.2),
    /// `resolus = total` ne serait JAMAIS vrai — l'arrêt de remise n'est jamais
    /// `collecte`, et la livraison resterait bloquée en collecte pour toujours.
    /// Régression silencieuse : aucun test du cycle 006 ne la signalait, faute
    /// d'arrêt de remise dans ses fixtures.
    async fn gating_livraison(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        livraison_id: Uuid,
        commande_id: Uuid,
        acteur: Uuid,
        horodatage_serveur: DateTime<Utc>,
        livraison_en_collecte: bool,
    ) -> Result<ProgressionCollecte, ErreurCommandes> {
        let comptes = sqlx::query!(
            r#"SELECT count(*) AS "total!",
                      count(*) FILTER (WHERE a.statut = 'collecte') AS "collectes!",
                      count(*) FILTER (WHERE a.statut IN ('collecte','indisponible')) AS "resolus!"
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               WHERE s.livraison_id = $1
                 AND a.type_arret = 'collecte'"#,
            livraison_id,
        )
        .fetch_one(&mut **tx)
        .await?;

        let nb_arrets = comptes.total as i16;
        let nb_collectes = comptes.collectes as i16;
        let tous_resolus = comptes.total > 0 && comptes.resolus == comptes.total;

        let en_livraison = if tous_resolus && livraison_en_collecte {
            sqlx::query!(
                r#"UPDATE commandes.livraison
                   SET etat = 'en_livraison', etat_le = $2
                   WHERE id = $1 AND etat = 'en_collecte'"#,
                livraison_id,
                horodatage_serveur,
            )
            .execute(&mut **tx)
            .await?;

            ecrire_evenement(
                tx,
                NouvelEvenement {
                    type_evenement: "livraison.mise_en_livraison",
                    entite_type: "livraison",
                    entite_id: livraison_id,
                    payload: json!({
                        "commande": commande_id,
                        "nb_arrets": nb_arrets,
                        "acteur": acteur,
                    }),
                    survenu_le: horodatage_serveur,
                },
            )
            .await?;
            true
        } else {
            false
        };

        Ok(ProgressionCollecte {
            nb_collectes,
            nb_arrets,
            en_livraison,
        })
    }

    /// Tous les arrêts `à_collecter` de la course active du coursier (livraison
    /// `en_collecte` assignée), ordonnés. Vide si aucune course assignée
    /// (R10 — exact en prod avant DSP). Sert le pré-provisionnement (QRC-02).
    pub async fn arrets_course_active(
        &self,
        coursier: Uuid,
    ) -> Result<Vec<ArretACollecter>, ErreurCommandes> {
        let lignes = sqlx::query!(
            r#"SELECT a.id AS arret_id, l.id AS livraison_id, s.id AS segment_id,
                      l.commande_id, a.prestataire_id AS "prestataire_id!", a.site_lat, a.site_lon,
                      a.montant_avance, a.devise
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               JOIN commandes.livraison l ON l.id = s.livraison_id
               WHERE l.coursier_id = $1
                 AND l.etat = 'en_collecte'
                 AND a.statut = 'a_collecter'
                 AND a.type_arret = 'collecte'
               ORDER BY s.ordre, a.ordre"#,
            coursier,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(lignes
            .into_iter()
            .map(|l| ArretACollecter {
                arret_id: l.arret_id,
                livraison_id: l.livraison_id,
                segment_id: l.segment_id,
                commande_id: l.commande_id,
                prestataire_id: l.prestataire_id,
                site_lat: l.site_lat,
                site_lon: l.site_lon,
                montant_avance: l.montant_avance,
                devise: l.devise,
            })
            .collect())
    }

    /// Arrêt d'une course active du coursier par son id, QUEL QUE SOIT son
    /// statut (pour la vérification puis la garde d'état de `marquer_arret_collecte`).
    /// `None` si l'arrêt n'appartient pas à une course `en_collecte` du coursier
    /// (précondition FR-012 → `arret_hors_course`).
    pub async fn arret_de_coursier(
        &self,
        coursier: Uuid,
        arret_id: Uuid,
    ) -> Result<Option<ArretACollecter>, ErreurCommandes> {
        let ligne = sqlx::query!(
            r#"SELECT a.id AS arret_id, l.id AS livraison_id, s.id AS segment_id,
                      l.commande_id, a.prestataire_id AS "prestataire_id!", a.site_lat, a.site_lon,
                      a.montant_avance, a.devise
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               JOIN commandes.livraison l ON l.id = s.livraison_id
               WHERE a.id = $1 AND l.coursier_id = $2 AND l.etat = 'en_collecte'
                 AND a.type_arret = 'collecte'"#,
            arret_id,
            coursier,
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(ligne.map(|l| ArretACollecter {
            arret_id: l.arret_id,
            livraison_id: l.livraison_id,
            segment_id: l.segment_id,
            commande_id: l.commande_id,
            prestataire_id: l.prestataire_id,
            site_lat: l.site_lat,
            site_lon: l.site_lon,
            montant_avance: l.montant_avance,
            devise: l.devise,
        }))
    }

    /// Progression courante d'une livraison (chemin idempotent — aucune écriture).
    ///
    /// ⚠ Compte les seules COLLECTES (P1 / research R4) : l'arrêt de remise
    /// n'est pas une collecte, une livraison à 2 collectes + 1 remise annonce
    /// « 2 sur 2 », jamais « 2 sur 3 ».
    async fn progression(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        livraison_id: Uuid,
        en_livraison: bool,
    ) -> Result<ProgressionCollecte, ErreurCommandes> {
        let comptes = sqlx::query!(
            r#"SELECT count(*) AS "total!",
                      count(*) FILTER (WHERE a.statut = 'collecte') AS "collectes!"
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               WHERE s.livraison_id = $1
                 AND a.type_arret = 'collecte'"#,
            livraison_id,
        )
        .fetch_one(&mut **tx)
        .await?;
        Ok(ProgressionCollecte {
            nb_collectes: comptes.collectes as i16,
            nb_arrets: comptes.total as i16,
            en_livraison,
        })
    }
}

#[async_trait]
impl ArretsDeCollecte for PgCommandes {
    async fn arret_a_collecter(
        &self,
        coursier: Uuid,
        prestataire: Uuid,
    ) -> Result<Option<ArretACollecter>, ErreurCommandes> {
        // Arrêt `à_collecter` d'ordre le plus bas de la course active du coursier
        // visant ce prestataire (livraison en_collecte assignée au coursier).
        let ligne = sqlx::query!(
            r#"SELECT a.id AS arret_id, l.id AS livraison_id, s.id AS segment_id,
                      l.commande_id, a.prestataire_id AS "prestataire_id!", a.site_lat, a.site_lon,
                      a.montant_avance, a.devise
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               JOIN commandes.livraison l ON l.id = s.livraison_id
               WHERE l.coursier_id = $1
                 AND l.etat = 'en_collecte'
                 AND a.prestataire_id = $2
                 AND a.statut = 'a_collecter'
                 AND a.type_arret = 'collecte'
               ORDER BY s.ordre, a.ordre
               LIMIT 1"#,
            coursier,
            prestataire,
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(ligne.map(|l| ArretACollecter {
            arret_id: l.arret_id,
            livraison_id: l.livraison_id,
            segment_id: l.segment_id,
            commande_id: l.commande_id,
            prestataire_id: l.prestataire_id,
            site_lat: l.site_lat,
            site_lon: l.site_lon,
            montant_avance: l.montant_avance,
            devise: l.devise,
        }))
    }
}
