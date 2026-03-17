use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

/// Business hours entry for a merchant (one per day of week).
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BusinessHours {
    pub id: Id,
    pub merchant_id: Id,
    pub day_of_week: i16,
    pub open_time: chrono::NaiveTime,
    pub close_time: chrono::NaiveTime,
    pub is_closed: bool,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

/// Payload for setting business hours for a single day.
#[derive(Debug, Deserialize)]
pub struct SetBusinessHoursEntry {
    pub day_of_week: i16,
    pub open_time: String,
    pub close_time: String,
    pub is_closed: bool,
}

/// Wrapper payload for setting all business hours at once.
#[derive(Debug, Deserialize)]
pub struct SetBusinessHoursPayload {
    pub hours: Vec<SetBusinessHoursEntry>,
}

impl SetBusinessHoursEntry {
    pub fn validate(&self) -> Result<(), common::error::AppError> {
        if self.day_of_week < 0 || self.day_of_week > 6 {
            return Err(common::error::AppError::BadRequest(
                "day_of_week must be between 0 (Monday) and 6 (Sunday)".into(),
            ));
        }
        Self::parse_time(&self.open_time)?;
        Self::parse_time(&self.close_time)?;
        Ok(())
    }

    pub fn parse_time(time_str: &str) -> Result<chrono::NaiveTime, common::error::AppError> {
        chrono::NaiveTime::parse_from_str(time_str, "%H:%M").map_err(|_| {
            common::error::AppError::BadRequest(format!(
                "Invalid time format '{}'. Expected HH:MM",
                time_str
            ))
        })
    }
}

// -- Repository functions --

/// Delete all existing hours for a merchant, then insert new ones (transactional).
pub async fn set_hours(
    pool: &sqlx::PgPool,
    merchant_id: Id,
    entries: &[SetBusinessHoursEntry],
) -> Result<Vec<BusinessHours>, common::error::AppError> {
    for entry in entries {
        entry.validate()?;
    }

    let mut tx = pool
        .begin()
        .await
        .map_err(|e| common::error::AppError::DatabaseError(e.to_string()))?;

    sqlx::query("DELETE FROM business_hours WHERE merchant_id = $1")
        .bind(merchant_id)
        .execute(&mut *tx)
        .await
        .map_err(|e| common::error::AppError::DatabaseError(e.to_string()))?;

    let mut results = Vec::with_capacity(entries.len());
    for entry in entries {
        let open = SetBusinessHoursEntry::parse_time(&entry.open_time)?;
        let close = SetBusinessHoursEntry::parse_time(&entry.close_time)?;

        let row = sqlx::query_as::<_, BusinessHours>(
            "INSERT INTO business_hours (merchant_id, day_of_week, open_time, close_time, is_closed)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING id, merchant_id, day_of_week, open_time, close_time, is_closed, created_at, updated_at",
        )
        .bind(merchant_id)
        .bind(entry.day_of_week)
        .bind(open)
        .bind(close)
        .bind(entry.is_closed)
        .fetch_one(&mut *tx)
        .await
        .map_err(|e| common::error::AppError::DatabaseError(e.to_string()))?;

        results.push(row);
    }

    tx.commit()
        .await
        .map_err(|e| common::error::AppError::DatabaseError(e.to_string()))?;

    Ok(results)
}

/// Find all business hours for a merchant.
pub async fn find_by_merchant(
    pool: &sqlx::PgPool,
    merchant_id: Id,
) -> Result<Vec<BusinessHours>, common::error::AppError> {
    sqlx::query_as::<_, BusinessHours>(
        "SELECT id, merchant_id, day_of_week, open_time, close_time, is_closed, created_at, updated_at
         FROM business_hours WHERE merchant_id = $1 ORDER BY day_of_week",
    )
    .bind(merchant_id)
    .fetch_all(pool)
    .await
    .map_err(|e| common::error::AppError::DatabaseError(e.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_day_of_week_valid() {
        for day in 0..=6 {
            let entry = SetBusinessHoursEntry {
                day_of_week: day,
                open_time: "08:00".into(),
                close_time: "20:00".into(),
                is_closed: false,
            };
            assert!(entry.validate().is_ok());
        }
    }

    #[test]
    fn test_validate_day_of_week_invalid() {
        let entry = SetBusinessHoursEntry {
            day_of_week: 7,
            open_time: "08:00".into(),
            close_time: "20:00".into(),
            is_closed: false,
        };
        assert!(entry.validate().is_err());
    }

    #[test]
    fn test_validate_time_format_valid() {
        assert!(SetBusinessHoursEntry::parse_time("08:00").is_ok());
        assert!(SetBusinessHoursEntry::parse_time("23:59").is_ok());
        assert!(SetBusinessHoursEntry::parse_time("00:00").is_ok());
    }

    #[test]
    fn test_validate_time_format_invalid() {
        assert!(SetBusinessHoursEntry::parse_time("25:00").is_err());
        assert!(SetBusinessHoursEntry::parse_time("noon").is_err());
        assert!(SetBusinessHoursEntry::parse_time("").is_err());
    }

    #[test]
    fn test_business_hours_serde() {
        let bh = BusinessHours {
            id: uuid::Uuid::new_v4(),
            merchant_id: uuid::Uuid::new_v4(),
            day_of_week: 0,
            open_time: chrono::NaiveTime::from_hms_opt(8, 0, 0).unwrap(),
            close_time: chrono::NaiveTime::from_hms_opt(20, 0, 0).unwrap(),
            is_closed: false,
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        };
        let json = serde_json::to_string(&bh).unwrap();
        assert!(json.contains("day_of_week"));
    }
}
