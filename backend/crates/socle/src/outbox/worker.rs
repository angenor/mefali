//! Worker de publication de l'outbox : livraison at-least-once, consommateurs
//! idempotents. Contrat `contracts/outbox.md`, invariants data-model.md §1.

use std::sync::Arc;
use std::time::Duration;

use chrono::{DateTime, Utc};
use sqlx::postgres::PgPool;
use uuid::Uuid;

use super::write::OutboxError;

/// Événement publié, transmis aux consommateurs. Idempotence par `id`.
#[derive(Debug, Clone)]
pub struct EvenementPublie {
    /// Identifiant (UUIDv7) — clé de dédoublonnage côté consommateur.
    pub id: Uuid,
    /// Type de l'événement (taxonomie).
    pub type_evenement: String,
    /// Type de l'entité concernée.
    pub entite_type: String,
    /// Identifiant de l'entité.
    pub entite_id: Uuid,
    /// Contenu de l'événement.
    pub payload: serde_json::Value,
    /// Horodatage métier de la transition.
    pub survenu_le: DateTime<Utc>,
}

/// Erreur d'un consommateur (l'événement sera re-tenté au lot suivant).
#[derive(Debug, thiserror::Error)]
#[error("{0}")]
pub struct ConsommationError(pub String);

/// Un consommateur (notifications, métriques…) reçoit chaque événement AU MOINS
/// une fois. Il DOIT être idempotent (dédoublonnage par `id`).
#[async_trait::async_trait]
pub trait ConsommateurOutbox: Send + Sync {
    /// Nom du consommateur (journalisation).
    fn nom(&self) -> &'static str;

    /// Traite un événement. Une erreur laisse l'événement non publié (re-tenté).
    async fn consommer(&self, evenement: &EvenementPublie) -> Result<(), ConsommationError>;
}

/// Worker de publication. Lit par lots (`FOR UPDATE SKIP LOCKED`), distribue aux
/// consommateurs, marque `publie_le`, incrémente `tentatives` en cas d'échec.
pub struct WorkerOutbox {
    pool: PgPool,
    consommateurs: Vec<Arc<dyn ConsommateurOutbox>>,
    taille_lot: i64,
    intervalle: Duration,
}

impl WorkerOutbox {
    /// Crée un worker (lot de 100, intervalle 1 s par défaut).
    pub fn new(pool: PgPool, consommateurs: Vec<Arc<dyn ConsommateurOutbox>>) -> Self {
        Self {
            pool,
            consommateurs,
            taille_lot: 100,
            intervalle: Duration::from_secs(1),
        }
    }

    /// Règle l'intervalle entre deux lots.
    pub fn avec_intervalle(mut self, intervalle: Duration) -> Self {
        self.intervalle = intervalle;
        self
    }

    /// Règle la taille de lot.
    pub fn avec_taille_lot(mut self, taille_lot: i64) -> Self {
        self.taille_lot = taille_lot;
        self
    }

    /// Boucle infinie : traite un lot puis attend l'intervalle. À lancer comme
    /// tâche tokio depuis le binaire `api`.
    pub async fn run(self) {
        let mut ticker = tokio::time::interval(self.intervalle);
        loop {
            ticker.tick().await;
            match self.traiter_un_lot().await {
                Ok(n) if n > 0 => tracing::debug!(publies = n, "lot outbox traité"),
                Ok(_) => {}
                Err(e) => tracing::error!(erreur = %e, "échec du traitement d'un lot outbox"),
            }
        }
    }

    /// Traite un lot. Renvoie le nombre d'événements publiés avec succès.
    ///
    /// Le verrou `FOR UPDATE SKIP LOCKED` est tenu jusqu'au commit : plusieurs
    /// workers concurrents ne se marchent pas dessus.
    pub async fn traiter_un_lot(&self) -> Result<usize, OutboxError> {
        let mut tx = self.pool.begin().await?;

        let lignes = sqlx::query!(
            r#"
            SELECT id, type_evenement, entite_type, entite_id, payload, survenu_le
            FROM outbox.evenement
            WHERE publie_le IS NULL
            ORDER BY cree_le
            LIMIT $1
            FOR UPDATE SKIP LOCKED
            "#,
            self.taille_lot,
        )
        .fetch_all(&mut *tx)
        .await?;

        let mut publies = 0usize;
        for ligne in lignes {
            let evenement = EvenementPublie {
                id: ligne.id,
                type_evenement: ligne.type_evenement,
                entite_type: ligne.entite_type,
                entite_id: ligne.entite_id,
                payload: ligne.payload,
                survenu_le: ligne.survenu_le,
            };

            let mut echec: Option<String> = None;
            for consommateur in &self.consommateurs {
                if let Err(e) = consommateur.consommer(&evenement).await {
                    echec = Some(format!("{} : {}", consommateur.nom(), e));
                    break;
                }
            }

            match echec {
                None => {
                    sqlx::query!(
                        "UPDATE outbox.evenement SET publie_le = now() WHERE id = $1",
                        evenement.id,
                    )
                    .execute(&mut *tx)
                    .await?;
                    publies += 1;
                }
                Some(message) => {
                    sqlx::query!(
                        "UPDATE outbox.evenement
                         SET tentatives = tentatives + 1, derniere_erreur = $2
                         WHERE id = $1",
                        evenement.id,
                        message,
                    )
                    .execute(&mut *tx)
                    .await?;
                }
            }
        }

        tx.commit().await?;
        Ok(publies)
    }
}
