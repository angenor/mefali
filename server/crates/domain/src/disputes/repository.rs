use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{Dispute, DisputeType};

const DISPUTE_COLUMNS: &str =
    "id, order_id, reporter_id, dispute_type, status, description, resolution, resolved_by, created_at, updated_at";

/// Insert a new dispute record. Returns the created dispute.
pub async fn create_dispute(
    pool: &PgPool,
    order_id: Id,
    reporter_id: Id,
    dispute_type: &DisputeType,
    description: Option<&str>,
) -> Result<Dispute, AppError> {
    sqlx::query_as::<_, Dispute>(&format!(
        "INSERT INTO disputes (order_id, reporter_id, dispute_type, description)
         VALUES ($1, $2, $3, $4)
         RETURNING {DISPUTE_COLUMNS}"
    ))
    .bind(order_id)
    .bind(reporter_id)
    .bind(dispute_type)
    .bind(description)
    .fetch_one(pool)
    .await
    .map_err(|e| {
        if let sqlx::Error::Database(ref db_err) = e {
            if db_err.constraint() == Some("disputes_order_id_unique") {
                return AppError::Conflict(
                    "Un litige a deja ete signale pour cette commande".into(),
                );
            }
        }
        AppError::DatabaseError(format!("Failed to create dispute: {e}"))
    })
}

/// Find dispute for a specific order (at most one per order).
pub async fn find_by_order(pool: &PgPool, order_id: Id) -> Result<Option<Dispute>, AppError> {
    sqlx::query_as::<_, Dispute>(&format!(
        "SELECT {DISPUTE_COLUMNS} FROM disputes WHERE order_id = $1"
    ))
    .bind(order_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find dispute by order: {e}")))
}

/// Find dispute by ID.
pub async fn find_by_id(pool: &PgPool, dispute_id: Id) -> Result<Option<Dispute>, AppError> {
    sqlx::query_as::<_, Dispute>(&format!(
        "SELECT {DISPUTE_COLUMNS} FROM disputes WHERE id = $1"
    ))
    .bind(dispute_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find dispute: {e}")))
}

/// Find disputes filed by a specific user, paginated, newest first.
pub async fn find_by_reporter(
    pool: &PgPool,
    reporter_id: Id,
    limit: i64,
    offset: i64,
) -> Result<Vec<Dispute>, AppError> {
    sqlx::query_as::<_, Dispute>(&format!(
        "SELECT {DISPUTE_COLUMNS} FROM disputes
         WHERE reporter_id = $1
         ORDER BY created_at DESC
         LIMIT $2 OFFSET $3"
    ))
    .bind(reporter_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find disputes by reporter: {e}")))
}

/// Update a dispute to resolved status.
pub async fn resolve(
    pool: &PgPool,
    dispute_id: Id,
    admin_id: Id,
    resolution: &str,
) -> Result<Dispute, AppError> {
    sqlx::query_as::<_, Dispute>(&format!(
        "UPDATE disputes SET status = $1, resolution = $2, resolved_by = $3
         WHERE id = $4
         RETURNING {DISPUTE_COLUMNS}"
    ))
    .bind(super::model::DisputeStatus::Resolved)
    .bind(resolution)
    .bind(admin_id)
    .bind(dispute_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to resolve dispute: {e}")))
}

/// Count total disputes filed by a specific user.
pub async fn count_by_reporter(pool: &PgPool, reporter_id: Id) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, (i64,)>(
        "SELECT COUNT(*)::bigint FROM disputes WHERE reporter_id = $1",
    )
    .bind(reporter_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to count disputes: {e}")))?;

    Ok(row.0)
}

/// List disputes for admin with order/reporter summary, filtered and paginated.
pub async fn find_all_admin(
    pool: &PgPool,
    status_filter: Option<&super::model::DisputeStatus>,
    type_filter: Option<&DisputeType>,
    limit: i64,
    offset: i64,
) -> Result<Vec<super::model::AdminDisputeListItem>, AppError> {
    let mut query = String::from(
        "SELECT d.id, d.order_id, d.reporter_id, d.dispute_type, d.status,
                d.description, d.created_at,
                u.name as reporter_name, u.phone as reporter_phone,
                m.name as merchant_name, o.total as order_total
         FROM disputes d
         JOIN users u ON u.id = d.reporter_id
         JOIN orders o ON o.id = d.order_id
         JOIN merchants m ON m.id = o.merchant_id
         WHERE 1=1",
    );

    let mut param_idx = 1;
    if status_filter.is_some() {
        query.push_str(&format!(" AND d.status = ${param_idx}"));
        param_idx += 1;
    }
    if type_filter.is_some() {
        query.push_str(&format!(" AND d.dispute_type = ${param_idx}"));
        param_idx += 1;
    }

    query.push_str(&format!(
        " ORDER BY d.created_at DESC LIMIT ${param_idx} OFFSET ${}",
        param_idx + 1
    ));

    let mut q = sqlx::query_as::<_, super::model::AdminDisputeListItem>(&query);

    if let Some(s) = status_filter {
        q = q.bind(s);
    }
    if let Some(t) = type_filter {
        q = q.bind(t);
    }
    q = q.bind(limit).bind(offset);

    q.fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to list admin disputes: {e}")))
}

/// Count disputes for admin with optional filters.
pub async fn count_all_admin(
    pool: &PgPool,
    status_filter: Option<&super::model::DisputeStatus>,
    type_filter: Option<&DisputeType>,
) -> Result<i64, AppError> {
    let mut query = String::from("SELECT COUNT(*)::bigint FROM disputes d WHERE 1=1");

    if status_filter.is_some() {
        query.push_str(" AND d.status = $1");
        if type_filter.is_some() {
            query.push_str(" AND d.dispute_type = $2");
        }
    } else if type_filter.is_some() {
        query.push_str(" AND d.dispute_type = $1");
    }

    let mut q = sqlx::query_as::<_, (i64,)>(&query);

    if let Some(s) = status_filter {
        q = q.bind(s);
    }
    if let Some(t) = type_filter {
        q = q.bind(t);
    }

    let row = q
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to count admin disputes: {e}")))?;

    Ok(row.0)
}

/// Insert a dispute event into the timeline.
pub async fn insert_dispute_event(
    pool: &PgPool,
    dispute_id: Id,
    event_type: &str,
    label: &str,
    metadata: Option<serde_json::Value>,
) -> Result<(), AppError> {
    sqlx::query(
        "INSERT INTO dispute_events (dispute_id, event_type, label, metadata) \
         VALUES ($1, $2, $3, $4)",
    )
    .bind(dispute_id)
    .bind(event_type)
    .bind(label)
    .bind(metadata)
    .execute(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to insert dispute event: {e}")))?;
    Ok(())
}

/// Get order timeline events (key timestamps) in a single query.
/// Includes dispute_events (e.g. sponsor_contacted) via UNION.
pub async fn get_order_timeline(
    pool: &PgPool,
    order_id: Id,
) -> Result<Vec<super::model::OrderTimelineEvent>, AppError> {
    let rows = sqlx::query_as::<_, (String, Option<common::types::Timestamp>)>(
        "SELECT label, ts FROM (
            SELECT 'Commande placee' AS label, o.created_at AS ts, 1 AS sort_order
            FROM orders o WHERE o.id = $1
          UNION ALL
            SELECT 'Collectee par livreur', dl.picked_up_at, 2
            FROM deliveries dl WHERE dl.order_id = $1
          UNION ALL
            SELECT 'Livree au client', dl.delivered_at, 3
            FROM deliveries dl WHERE dl.order_id = $1
          UNION ALL
            SELECT 'Litige signale', d.created_at, 4
            FROM disputes d WHERE d.order_id = $1
          UNION ALL
            SELECT de.label, de.created_at, 5
            FROM dispute_events de
            JOIN disputes d ON d.id = de.dispute_id
            WHERE d.order_id = $1
        ) timeline
        ORDER BY sort_order, ts",
    )
    .bind(order_id)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to get order timeline: {e}")))?;

    Ok(rows
        .into_iter()
        .map(|(label, timestamp)| super::model::OrderTimelineEvent { label, timestamp })
        .collect())
}

/// Count distinct disputes involving drivers sponsored by a given sponsor.
/// Counts disputes where the order's driver is an active sponsored driver of the sponsor.
pub async fn count_disputes_for_sponsored_drivers(
    pool: &PgPool,
    sponsor_id: Id,
) -> Result<i64, AppError> {
    let row: (i64,) = sqlx::query_as(
        "SELECT COUNT(DISTINCT d.id)::bigint \
         FROM disputes d \
         JOIN orders o ON d.order_id = o.id \
         JOIN sponsorships s ON o.driver_id = s.sponsored_id \
         WHERE s.sponsor_id = $1 \
           AND s.status = 'active' \
           AND d.status IN ('open', 'in_progress', 'resolved')",
    )
    .bind(sponsor_id)
    .fetch_one(pool)
    .await
    .map_err(|e| {
        AppError::DatabaseError(format!("Failed to count disputes for sponsored drivers: {e}"))
    })?;
    Ok(row.0)
}

/// Get merchant stats for dispute context.
pub async fn get_merchant_stats(
    pool: &PgPool,
    merchant_id: Id,
) -> Result<super::model::ActorStats, AppError> {
    let row = sqlx::query_as::<_, (Option<String>, i64, i64)>(
        "SELECT m.name,
                (SELECT COUNT(*)::bigint FROM orders WHERE merchant_id = $1) as total_orders,
                (SELECT COUNT(*)::bigint FROM disputes d
                 JOIN orders o ON o.id = d.order_id
                 WHERE o.merchant_id = $1) as total_disputes
         FROM merchants m WHERE m.id = $1",
    )
    .bind(merchant_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to get merchant stats: {e}")))?;

    Ok(super::model::ActorStats {
        name: row.0,
        total_orders: row.1,
        total_disputes: row.2,
    })
}

/// Get driver stats for dispute context.
pub async fn get_driver_stats(
    pool: &PgPool,
    driver_id: Id,
) -> Result<super::model::ActorStats, AppError> {
    let row = sqlx::query_as::<_, (Option<String>, i64, i64)>(
        "SELECT u.name,
                (SELECT COUNT(*)::bigint FROM deliveries WHERE driver_id = $1) as total_deliveries,
                (SELECT COUNT(*)::bigint FROM disputes d
                 JOIN orders o ON o.id = d.order_id
                 WHERE o.driver_id = $1) as total_disputes
         FROM users u WHERE u.id = $1",
    )
    .bind(driver_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to get driver stats: {e}")))?;

    Ok(super::model::ActorStats {
        name: row.0,
        total_orders: row.1,
        total_disputes: row.2,
    })
}
