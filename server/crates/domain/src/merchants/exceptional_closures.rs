use common::error::AppError;
use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

/// Exceptional closure for a specific date (holiday, vacation, etc.).
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct ExceptionalClosure {
    pub id: Id,
    pub merchant_id: Id,
    pub closure_date: chrono::NaiveDate,
    pub reason: Option<String>,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

/// Payload for creating an exceptional closure.
#[derive(Debug, Deserialize)]
pub struct CreateClosurePayload {
    pub closure_date: chrono::NaiveDate,
    pub reason: Option<String>,
}

impl CreateClosurePayload {
    pub fn validate(&self) -> Result<(), AppError> {
        let today = chrono::Utc::now().date_naive();
        if self.closure_date < today {
            return Err(AppError::BadRequest(
                "La date de fermeture doit être aujourd'hui ou dans le futur".into(),
            ));
        }
        if let Some(ref reason) = self.reason {
            if reason.len() > 200 {
                return Err(AppError::BadRequest(
                    "Le motif ne peut pas dépasser 200 caractères".into(),
                ));
            }
        }
        Ok(())
    }
}

// -- Repository functions --

/// Create an exceptional closure for a merchant.
pub async fn create(
    pool: &sqlx::PgPool,
    merchant_id: Id,
    payload: &CreateClosurePayload,
) -> Result<ExceptionalClosure, AppError> {
    payload.validate()?;

    sqlx::query_as::<_, ExceptionalClosure>(
        "INSERT INTO exceptional_closures (merchant_id, closure_date, reason)
         VALUES ($1, $2, $3)
         RETURNING id, merchant_id, closure_date, reason, created_at, updated_at",
    )
    .bind(merchant_id)
    .bind(payload.closure_date)
    .bind(&payload.reason)
    .fetch_one(pool)
    .await
    .map_err(|e| match e {
        sqlx::Error::Database(ref db_err) if db_err.is_unique_violation() => {
            AppError::Conflict("Une fermeture existe déjà pour cette date".into())
        }
        _ => AppError::DatabaseError(e.to_string()),
    })
}

/// Find all upcoming closures for a merchant (date >= today), ordered by date.
pub async fn find_upcoming(
    pool: &sqlx::PgPool,
    merchant_id: Id,
) -> Result<Vec<ExceptionalClosure>, AppError> {
    let today = chrono::Utc::now().date_naive();
    sqlx::query_as::<_, ExceptionalClosure>(
        "SELECT id, merchant_id, closure_date, reason, created_at, updated_at
         FROM exceptional_closures
         WHERE merchant_id = $1 AND closure_date >= $2
         ORDER BY closure_date",
    )
    .bind(merchant_id)
    .bind(today)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Delete an exceptional closure (ownership check via merchant_id).
pub async fn delete(
    pool: &sqlx::PgPool,
    closure_id: Id,
    merchant_id: Id,
) -> Result<(), AppError> {
    let result = sqlx::query(
        "DELETE FROM exceptional_closures WHERE id = $1 AND merchant_id = $2",
    )
    .bind(closure_id)
    .bind(merchant_id)
    .execute(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound("Fermeture exceptionnelle non trouvée".into()));
    }
    Ok(())
}

/// Check if a merchant has an exceptional closure on a given date.
pub async fn is_closed_on(
    pool: &sqlx::PgPool,
    merchant_id: Id,
    date: chrono::NaiveDate,
) -> Result<bool, AppError> {
    let exists: bool = sqlx::query_scalar(
        "SELECT EXISTS(SELECT 1 FROM exceptional_closures WHERE merchant_id = $1 AND closure_date = $2)",
    )
    .bind(merchant_id)
    .bind(date)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(exists)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_closure_payload_future_date() {
        let payload = CreateClosurePayload {
            closure_date: chrono::Utc::now().date_naive() + chrono::Duration::days(1),
            reason: Some("Jour férié".into()),
        };
        assert!(payload.validate().is_ok());
    }

    #[test]
    fn test_create_closure_payload_today() {
        let payload = CreateClosurePayload {
            closure_date: chrono::Utc::now().date_naive(),
            reason: None,
        };
        assert!(payload.validate().is_ok());
    }

    #[test]
    fn test_create_closure_payload_past_date() {
        let payload = CreateClosurePayload {
            closure_date: chrono::Utc::now().date_naive() - chrono::Duration::days(1),
            reason: None,
        };
        assert!(payload.validate().is_err());
    }

    #[test]
    fn test_create_closure_payload_reason_too_long() {
        let payload = CreateClosurePayload {
            closure_date: chrono::Utc::now().date_naive() + chrono::Duration::days(1),
            reason: Some("x".repeat(201)),
        };
        assert!(payload.validate().is_err());
    }

    #[test]
    fn test_exceptional_closure_serde() {
        let ec = ExceptionalClosure {
            id: uuid::Uuid::new_v4(),
            merchant_id: uuid::Uuid::new_v4(),
            closure_date: chrono::NaiveDate::from_ymd_opt(2026, 3, 25).unwrap(),
            reason: Some("Tabaski".into()),
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        };
        let json = serde_json::to_string(&ec).unwrap();
        assert!(json.contains("closure_date"));
        assert!(json.contains("Tabaski"));
        let back: ExceptionalClosure = serde_json::from_str(&json).unwrap();
        assert_eq!(back.reason, Some("Tabaski".into()));
    }
}
