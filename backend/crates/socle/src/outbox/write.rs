//! Écriture d'un événement dans la MÊME transaction que la transition d'état
//! (constitution VI). Contrat `contracts/outbox.md`.

use chrono::{DateTime, Utc};
use uuid::Uuid;

/// Erreurs de l'outbox (écriture et worker).
#[derive(Debug, thiserror::Error)]
pub enum OutboxError {
    /// Erreur de la base de données.
    #[error("erreur base de données outbox : {0}")]
    Db(#[from] sqlx::Error),
}

/// Événement à écrire. Emprunte ses chaînes à l'appelant (aucune allocation superflue).
pub struct NouvelEvenement<'a> {
    /// Clé de la taxonomie (`docs/taxonomie-evenements.md`).
    pub type_evenement: &'a str,
    /// Type de l'entité concernée (ex. `"commande"`).
    pub entite_type: &'a str,
    /// Identifiant de l'entité.
    pub entite_id: Uuid,
    /// Contenu de l'événement (propriétés standard incluses quand elles existent).
    pub payload: serde_json::Value,
    /// Horodatage MÉTIER de la transition.
    pub survenu_le: DateTime<Utc>,
}

/// Écrit un événement dans la transaction ouverte. Renvoie l'`id` (UUIDv7) créé.
///
/// Prend obligatoirement une transaction — jamais un pool — pour rendre
/// l'atomicité impossible à contourner (constitution VI). L'événement n'existe
/// que si la transaction de la transition commite.
pub async fn ecrire_evenement(
    tx: &mut sqlx::PgTransaction<'_>,
    evenement: NouvelEvenement<'_>,
) -> Result<Uuid, OutboxError> {
    let id = Uuid::now_v7();
    sqlx::query!(
        r#"
        INSERT INTO outbox.evenement
            (id, type_evenement, entite_type, entite_id, payload, survenu_le)
        VALUES ($1, $2, $3, $4, $5, $6)
        "#,
        id,
        evenement.type_evenement,
        evenement.entite_type,
        evenement.entite_id,
        evenement.payload,
        evenement.survenu_le,
    )
    .execute(&mut **tx)
    .await?;
    Ok(id)
}
