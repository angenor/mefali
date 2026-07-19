//! Disponibilité des articles : bascules par TROIS sources et signalements
//! coursier à masquage automatique (VND-04, FR-037..043 — data-model §3.9,
//! §3.10, research R10).
//!
//! La fenêtre glissante s'ÉVALUE à l'écriture de chaque signalement accepté —
//! aucun compteur matérialisé, aucun cron : les signalements sortis de la
//! fenêtre ne comptent plus par construction de la requête, et ceux déjà
//! reçus RESTENT comptés après une remise en vente (re-masquage immédiat,
//! FR-041).

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::catalogue::Article;
use crate::depot::PgPrestataires;
use crate::modele::{ErreurPrestataires, SourceBascule};

/// Valeurs de repli des paramètres de zone du masquage (Récapitulatif :
/// 2 signalements de coursiers DISTINCTS en 7 jours).
const SEUIL_DEFAUT: i64 = 2;
const FENETRE_JOURS_DEFAUT: i64 = 7;

/// Issue d'un signalement coursier accepté ou rejoué.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SignalementRecu {
    /// Rejeu d'un identifiant déjà reçu — rien recompté, rien émis (FR-039).
    pub rejeu: bool,
    /// CE signalement a déclenché le masquage automatique (FR-040).
    pub masquage_automatique: bool,
    /// L'article était déjà en rupture — compté quand même (edge case spec).
    pub deja_en_rupture: bool,
}

impl PgPrestataires {
    /// Bascule vendeur/admin de la disponibilité (FR-037). Une rupture posée
    /// par l'Admin n'est levée QUE par l'Admin (FR-041) ; un rejeu sans
    /// changement d'état n'écrit ni n'émet rien. Émet `article.mis_en_rupture`
    /// ou `article.remis_en_vente`.
    pub async fn basculer_disponibilite(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        article: Uuid,
        disponible: bool,
        source: SourceBascule,
        acteur: Uuid,
    ) -> Result<Article, ErreurPrestataires> {
        let courant = self.article_dans_tx(tx, prestataire, article).await?;
        if courant.retire_le.is_some() {
            return Err(ErreurPrestataires::ArticleRetire(article));
        }
        if disponible && courant.rupture_admin() && source != SourceBascule::Admin {
            return Err(ErreurPrestataires::RuptureAdmin);
        }
        if courant.disponible == disponible {
            return Ok(courant);
        }

        sqlx::query!(
            "UPDATE prestataires.disponibilite_article d
             SET disponible = $3, source = $4::text::prestataires.source_bascule,
                 bascule_par = $5, bascule_le = now()
             FROM prestataires.site s
             WHERE d.article_id = $2 AND d.site_id = s.id AND s.prestataire_id = $1",
            prestataire,
            article,
            disponible,
            source.comme_str(),
            acteur,
        )
        .execute(&mut **tx)
        .await?;

        self.emettre_bascule(tx, prestataire, article, disponible, source, Some(acteur), false)
            .await?;
        self.article_dans_tx(tx, prestataire, article).await
    }

    /// Signalement de rupture par un coursier SUR PLACE (FR-038..040).
    ///
    /// `signalement` est l'UUID GÉNÉRÉ CÔTÉ CLIENT (`Idempotency-Key`) : le
    /// rejeu rend la même issue sans double comptage (constitution V). La
    /// précondition de commande active passe par le port [`CommandesActives`] —
    /// un refus n'est compté NULLE PART.
    pub async fn signaler_rupture(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        signalement: Uuid,
        article: Uuid,
        coursier: Uuid,
        horodatage_local: DateTime<Utc>,
    ) -> Result<SignalementRecu, ErreurPrestataires> {
        // L'article, son vendeur, SON site et la ville (paramètres de zone).
        let ligne = sqlx::query!(
            r#"SELECT a.vendeur_id, a.retire_le, s.id AS site_id, p.ville_id,
                      COALESCE(d.disponible, true) AS "disponible!"
               FROM prestataires.article a
               JOIN prestataires.prestataire p ON p.id = a.vendeur_id
               JOIN prestataires.site s ON s.prestataire_id = a.vendeur_id
               LEFT JOIN prestataires.disponibilite_article d
                 ON d.article_id = a.id AND d.site_id = s.id
               WHERE a.id = $1"#,
            article,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurPrestataires::ArticleInconnu(article))?;
        if ligne.retire_le.is_some() {
            // Un article retiré n'est ni servi ni signalable (FR-055).
            return Err(ErreurPrestataires::ArticleRetire(article));
        }

        // Précondition de commande active (FR-038) — AVANT toute écriture.
        if !self.commandes.arret_actif(coursier, article).await? {
            return Err(ErreurPrestataires::SignalementInterdit);
        }

        // Idempotence par l'identifiant CLIENT (FR-039).
        let insere = sqlx::query!(
            "INSERT INTO prestataires.signalement_rupture
                 (id, article_id, site_id, coursier_compte_id, horodatage_local)
             VALUES ($1, $2, $3, $4, $5)
             ON CONFLICT (id) DO NOTHING",
            signalement,
            article,
            ligne.site_id,
            coursier,
            horodatage_local,
        )
        .execute(&mut **tx)
        .await?
        .rows_affected();
        let deja_en_rupture = !ligne.disponible;
        if insere == 0 {
            return Ok(SignalementRecu {
                rejeu: true,
                masquage_automatique: false,
                deja_en_rupture,
            });
        }

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "signalement_rupture.recu",
                entite_type: "signalement_rupture",
                entite_id: signalement,
                payload: json!({
                    "prestataire": ligne.vendeur_id,
                    "article": article,
                    "site": ligne.site_id,
                    "coursier": coursier,
                    "deja_en_rupture": deja_en_rupture,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;

        // Fenêtre glissante : coursiers DISTINCTS, paramètres de zone (FR-040).
        let (seuil, fenetre_jours) = self.parametres_masquage(ligne.ville_id).await?;
        let distincts = sqlx::query_scalar!(
            r#"SELECT count(DISTINCT coursier_compte_id) AS "n!"
               FROM prestataires.signalement_rupture
               WHERE article_id = $1 AND recu_le > now() - make_interval(days => $2::int)"#,
            article,
            fenetre_jours as i32,
        )
        .fetch_one(&mut **tx)
        .await?;

        let mut masquage_automatique = false;
        if distincts >= seuil && ligne.disponible {
            sqlx::query!(
                "UPDATE prestataires.disponibilite_article
                 SET disponible = false, source = 'coursier', bascule_par = NULL,
                     bascule_le = now()
                 WHERE article_id = $1 AND site_id = $2",
                article,
                ligne.site_id,
            )
            .execute(&mut **tx)
            .await?;
            self.emettre_bascule(
                tx,
                ligne.vendeur_id,
                article,
                false,
                SourceBascule::Coursier,
                None,
                true,
            )
            .await?;
            masquage_automatique = true;
        }

        Ok(SignalementRecu {
            rejeu: false,
            masquage_automatique,
            deja_en_rupture,
        })
    }

    /// Seuil et fenêtre du masquage automatique, résolus par héritage.
    async fn parametres_masquage(&self, ville: Uuid) -> Result<(i64, i64), ErreurPrestataires> {
        use zones::ConfigurationZones;
        let seuil = self
            .zones
            .parametre(ville, "rupture.masquage_seuil")
            .await?
            .and_then(|v| v.as_i64())
            .unwrap_or(SEUIL_DEFAUT);
        let fenetre = self
            .zones
            .parametre(ville, "rupture.masquage_fenetre_jours")
            .await?
            .and_then(|v| v.as_i64())
            .unwrap_or(FENETRE_JOURS_DEFAUT);
        Ok((seuil, fenetre))
    }

    /// Événement de bascule (FR-043) — ceux que VND-09 consommera (T4).
    #[allow(clippy::too_many_arguments)]
    async fn emettre_bascule(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        article: Uuid,
        disponible: bool,
        source: SourceBascule,
        acteur: Option<Uuid>,
        automatique: bool,
    ) -> Result<(), ErreurPrestataires> {
        let site: Option<Uuid> = sqlx::query_scalar!(
            "SELECT id FROM prestataires.site WHERE prestataire_id = $1",
            prestataire,
        )
        .fetch_optional(&mut **tx)
        .await?;
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: if disponible {
                    "article.remis_en_vente"
                } else {
                    "article.mis_en_rupture"
                },
                entite_type: "article",
                entite_id: article,
                payload: json!({
                    "prestataire": prestataire,
                    "site": site,
                    "source": source.comme_str(),
                    "automatique": automatique,
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        Ok(())
    }
}
