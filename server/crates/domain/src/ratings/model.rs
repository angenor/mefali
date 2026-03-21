use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

/// Rating entity matching the `ratings` table schema.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Rating {
    pub id: Id,
    pub order_id: Id,
    pub rater_id: Id,
    pub rated_type: RatedType,
    pub rated_id: Id,
    pub score: i16,
    pub comment: Option<String>,
    pub created_at: Timestamp,
}

/// Input for creating a single rating record.
#[derive(Debug, Clone)]
pub struct CreateRatingInput {
    pub order_id: Id,
    pub rater_id: Id,
    pub rated_type: RatedType,
    pub rated_id: Id,
    pub score: i16,
    pub comment: Option<String>,
}

/// Pair of ratings (merchant + driver) returned after submission.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RatingPair {
    pub merchant_rating: Rating,
    pub driver_rating: Rating,
}

/// Type of entity being rated.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RatedType {
    Merchant,
    Driver,
}

impl RatedType {
    pub fn as_str(&self) -> &'static str {
        match self {
            RatedType::Merchant => "merchant",
            RatedType::Driver => "driver",
        }
    }
}

impl std::fmt::Display for RatedType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.as_str())
    }
}

// sqlx decode from TEXT column — avoids needing a PostgreSQL ENUM type.
impl sqlx::Type<sqlx::Postgres> for RatedType {
    fn type_info() -> sqlx::postgres::PgTypeInfo {
        <String as sqlx::Type<sqlx::Postgres>>::type_info()
    }
}

impl<'r> sqlx::Decode<'r, sqlx::Postgres> for RatedType {
    fn decode(
        value: sqlx::postgres::PgValueRef<'r>,
    ) -> Result<Self, Box<dyn std::error::Error + Send + Sync>> {
        let s = <String as sqlx::Decode<sqlx::Postgres>>::decode(value)?;
        match s.as_str() {
            "merchant" => Ok(RatedType::Merchant),
            "driver" => Ok(RatedType::Driver),
            other => Err(format!("Unknown rated_type: {other}").into()),
        }
    }
}

impl<'q> sqlx::Encode<'q, sqlx::Postgres> for RatedType {
    fn encode_by_ref(
        &self,
        buf: &mut sqlx::postgres::PgArgumentBuffer,
    ) -> Result<sqlx::encode::IsNull, Box<dyn std::error::Error + Send + Sync>> {
        <&str as sqlx::Encode<sqlx::Postgres>>::encode_by_ref(&self.as_str(), buf)
    }
}

/// Request payload for the double-rating API endpoint.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubmitRatingRequest {
    pub merchant_score: i16,
    pub driver_score: i16,
    pub merchant_comment: Option<String>,
    pub driver_comment: Option<String>,
}

impl SubmitRatingRequest {
    const MAX_COMMENT_LENGTH: usize = 500;

    pub fn validate(&self) -> Result<(), String> {
        if !(1..=5).contains(&self.merchant_score) {
            return Err("merchant_score must be between 1 and 5".into());
        }
        if !(1..=5).contains(&self.driver_score) {
            return Err("driver_score must be between 1 and 5".into());
        }
        if let Some(ref c) = self.merchant_comment {
            if c.len() > Self::MAX_COMMENT_LENGTH {
                return Err(format!("merchant_comment must be at most {} characters", Self::MAX_COMMENT_LENGTH));
            }
        }
        if let Some(ref c) = self.driver_comment {
            if c.len() > Self::MAX_COMMENT_LENGTH {
                return Err(format!("driver_comment must be at most {} characters", Self::MAX_COMMENT_LENGTH));
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rated_type_serde_roundtrip() {
        let types = vec![
            (RatedType::Merchant, "\"merchant\""),
            (RatedType::Driver, "\"driver\""),
        ];
        for (variant, expected_json) in types {
            let json = serde_json::to_string(&variant).unwrap();
            assert_eq!(json, expected_json);
            let parsed: RatedType = serde_json::from_str(&json).unwrap();
            assert_eq!(parsed, variant);
        }
    }

    #[test]
    fn test_rated_type_display() {
        assert_eq!(RatedType::Merchant.to_string(), "merchant");
        assert_eq!(RatedType::Driver.to_string(), "driver");
    }

    #[test]
    fn test_submit_rating_request_valid() {
        let req = SubmitRatingRequest {
            merchant_score: 5,
            driver_score: 4,
            merchant_comment: Some("Tres bon garba !".into()),
            driver_comment: None,
        };
        assert!(req.validate().is_ok());
    }

    #[test]
    fn test_submit_rating_request_invalid_merchant_score() {
        let req = SubmitRatingRequest {
            merchant_score: 0,
            driver_score: 4,
            merchant_comment: None,
            driver_comment: None,
        };
        assert!(req.validate().is_err());
        assert!(req.validate().unwrap_err().contains("merchant_score"));
    }

    #[test]
    fn test_submit_rating_request_invalid_driver_score() {
        let req = SubmitRatingRequest {
            merchant_score: 3,
            driver_score: 6,
            merchant_comment: None,
            driver_comment: None,
        };
        assert!(req.validate().is_err());
        assert!(req.validate().unwrap_err().contains("driver_score"));
    }

    #[test]
    fn test_submit_rating_request_serde() {
        let req = SubmitRatingRequest {
            merchant_score: 5,
            driver_score: 4,
            merchant_comment: Some("Super".into()),
            driver_comment: None,
        };
        let json = serde_json::to_value(&req).unwrap();
        assert_eq!(json["merchant_score"], 5);
        assert_eq!(json["driver_score"], 4);
        assert_eq!(json["merchant_comment"], "Super");
        assert!(json["driver_comment"].is_null());
    }
}
