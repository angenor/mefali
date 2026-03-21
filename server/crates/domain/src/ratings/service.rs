use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;
use tracing::info;

use super::model::{RatedType, RatingPair, SubmitRatingRequest};
use super::repository;
use crate::merchants;
use crate::orders;

/// Submit a double rating (merchant + driver) for a delivered order.
/// Validates ownership, delivery status, and duplicate prevention.
/// Both ratings are inserted atomically in a single transaction.
pub async fn submit_double_rating(
    pool: &PgPool,
    order_id: Id,
    rater_id: Id,
    request: &SubmitRatingRequest,
) -> Result<RatingPair, AppError> {
    request.validate().map_err(AppError::BadRequest)?;

    // Fetch the order and validate
    let order = orders::repository::find_by_id(pool, order_id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Order {order_id} not found")))?;

    // Verify ownership
    if order.customer_id != rater_id {
        return Err(AppError::Forbidden(
            "You can only rate your own orders".into(),
        ));
    }

    // Verify delivered status
    if order.status != orders::model::OrderStatus::Delivered {
        return Err(AppError::BadRequest(
            "Only delivered orders can be rated".into(),
        ));
    }

    // Get driver_id (must exist for delivered orders)
    let driver_id = order
        .driver_id
        .ok_or_else(|| AppError::InternalError("Delivered order has no driver assigned".into()))?;

    // Get merchant's user_id (ratings.rated_id references users.id, not merchants.id)
    let merchant = merchants::repository::find_by_id(pool, order.merchant_id)
        .await?
        .ok_or_else(|| {
            AppError::InternalError(format!("Merchant {} not found", order.merchant_id))
        })?;

    // Atomic transaction for both ratings
    let mut tx = pool
        .begin()
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to begin transaction: {e}")))?;

    let merchant_rating = repository::create_rating(
        &mut *tx,
        order_id,
        rater_id,
        RatedType::Merchant.as_str(),
        merchant.user_id,
        request.merchant_score,
        request.merchant_comment.as_deref(),
    )
    .await?;

    let driver_rating = repository::create_rating(
        &mut *tx,
        order_id,
        rater_id,
        RatedType::Driver.as_str(),
        driver_id,
        request.driver_score,
        request.driver_comment.as_deref(),
    )
    .await?;

    tx.commit()
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to commit transaction: {e}")))?;

    info!(
        order_id = %order_id,
        merchant_score = request.merchant_score,
        driver_score = request.driver_score,
        "Double rating submitted"
    );

    Ok(RatingPair {
        merchant_rating,
        driver_rating,
    })
}

/// Get existing ratings for an order (if any).
pub async fn get_order_ratings(
    pool: &PgPool,
    order_id: Id,
    requester_id: Id,
) -> Result<Option<RatingPair>, AppError> {
    // Verify order ownership
    let order = orders::repository::find_by_id(pool, order_id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Order {order_id} not found")))?;

    if order.customer_id != requester_id {
        return Err(AppError::Forbidden(
            "You can only view ratings for your own orders".into(),
        ));
    }

    let ratings = repository::find_by_order(pool, order_id).await?;

    if ratings.is_empty() {
        return Ok(None);
    }

    // Build pair from found ratings
    let merchant_rating = ratings.iter().find(|r| r.rated_type == RatedType::Merchant);
    let driver_rating = ratings.iter().find(|r| r.rated_type == RatedType::Driver);

    match (merchant_rating, driver_rating) {
        (Some(m), Some(d)) => Ok(Some(RatingPair {
            merchant_rating: m.clone(),
            driver_rating: d.clone(),
        })),
        _ => {
            tracing::warn!(
                order_id = %order_id,
                count = ratings.len(),
                "Partial rating found (expected 0 or 2, got incomplete pair)"
            );
            Err(AppError::InternalError(
                "Partial rating data detected — contact support".into(),
            ))
        }
    }
}
