use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::Rating;

const RATING_COLUMNS: &str =
    "id, order_id, rater_id, rated_type, rated_id, score, comment, created_at";

/// Insert a single rating record. Returns the created rating.
pub async fn create_rating<'e>(
    executor: impl sqlx::PgExecutor<'e>,
    order_id: Id,
    rater_id: Id,
    rated_type: &str,
    rated_id: Id,
    score: i16,
    comment: Option<&str>,
) -> Result<Rating, AppError> {
    sqlx::query_as::<_, Rating>(&format!(
        "INSERT INTO ratings (order_id, rater_id, rated_type, rated_id, score, comment)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING {RATING_COLUMNS}"
    ))
    .bind(order_id)
    .bind(rater_id)
    .bind(rated_type)
    .bind(rated_id)
    .bind(score)
    .bind(comment)
    .fetch_one(executor)
    .await
    .map_err(|e| {
        if let sqlx::Error::Database(ref db_err) = e {
            if db_err.constraint() == Some("ratings_order_id_rated_type_key") {
                return AppError::Conflict(
                    "Une note a deja ete soumise pour cette commande".into(),
                );
            }
        }
        AppError::DatabaseError(format!("Failed to create rating: {e}"))
    })
}

/// Find ratings for a specific order (returns 0-2 ratings: merchant + driver).
pub async fn find_by_order(pool: &PgPool, order_id: Id) -> Result<Vec<Rating>, AppError> {
    sqlx::query_as::<_, Rating>(&format!(
        "SELECT {RATING_COLUMNS} FROM ratings WHERE order_id = $1 ORDER BY rated_type"
    ))
    .bind(order_id)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find ratings: {e}")))
}

/// Get average rating and count for a specific entity (merchant or driver).
pub async fn get_avg_rating(
    pool: &PgPool,
    rated_id: Id,
    rated_type: &str,
) -> Result<(f64, i64), AppError> {
    let row = sqlx::query_as::<_, (Option<f64>, i64)>(
        "SELECT AVG(score)::float8, COUNT(*)::bigint FROM ratings
         WHERE rated_id = $1 AND rated_type = $2",
    )
    .bind(rated_id)
    .bind(rated_type)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to get avg rating: {e}")))?;

    Ok((row.0.unwrap_or(0.0), row.1))
}
