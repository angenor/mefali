use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use domain::city_config::model::{
    CreateCityConfigRequest, ToggleActiveRequest, UpdateCityConfigRequest,
};
use domain::city_config::repository as city_repo;
use domain::disputes::model::{
    AdminDisputeDetail, DisputeResponse, DisputeStatus, DisputeType, ResolveAction,
    ResolveDisputeRequest,
};
use domain::disputes::{repository as dispute_repo, service as dispute_service};
use domain::users::model::{AdminUserListParams, UpdateUserStatusRequest, UserRole};
use domain::users::{repository as user_repo, service as user_service};
use notification::fcm::FcmClient;
use sqlx::PgPool;
use tracing::info;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;
use crate::routes::disputes::notify_reporter_dispute_resolved;

/// Raw count row from aggregation queries.
#[derive(Debug, sqlx::FromRow)]
struct CountRow {
    count: Option<i64>,
}

/// GET /api/v1/admin/dashboard/stats
///
/// Admin gets real-time operational KPIs: orders today, active merchants,
/// drivers online, pending disputes.
pub async fn dashboard_stats(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let (orders_today, active_merchants, drivers_online, pending_disputes) = tokio::try_join!(
        count_orders_today(&pool),
        count_active_merchants(&pool),
        count_drivers_online(&pool),
        count_pending_disputes(&pool),
    )?;

    let response = ApiResponse::new(serde_json::json!({
        "orders_today": orders_today,
        "active_merchants": active_merchants,
        "drivers_online": drivers_online,
        "pending_disputes": pending_disputes,
    }));

    Ok(HttpResponse::Ok().json(response))
}

async fn count_orders_today(pool: &PgPool) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COUNT(*)::BIGINT as count
         FROM orders
         WHERE created_at >= CURRENT_DATE",
    )
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

async fn count_active_merchants(pool: &PgPool) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COUNT(*)::BIGINT as count
         FROM merchants
         WHERE availability_status = 'open'",
    )
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

async fn count_drivers_online(pool: &PgPool) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COUNT(*)::BIGINT as count
         FROM users
         WHERE role = 'driver'
           AND is_available = true",
    )
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

async fn count_pending_disputes(pool: &PgPool) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COUNT(*)::BIGINT as count
         FROM disputes
         WHERE status IN ('open', 'in_progress')",
    )
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

/// Query params for admin dispute list.
#[derive(Debug, serde::Deserialize)]
pub struct AdminDisputeListParams {
    #[serde(default = "default_page")]
    pub page: i64,
    #[serde(default = "default_per_page")]
    pub per_page: i64,
    pub status: Option<String>,
    #[serde(rename = "type")]
    pub dispute_type: Option<String>,
}

fn default_page() -> i64 {
    1
}
fn default_per_page() -> i64 {
    20
}

impl AdminDisputeListParams {
    fn validated_page(&self) -> i64 {
        self.page.max(1)
    }
    fn validated_per_page(&self) -> i64 {
        self.per_page.clamp(1, 100)
    }
    fn offset(&self) -> i64 {
        (self.validated_page() - 1) * self.validated_per_page()
    }

    fn parse_status(&self) -> Option<DisputeStatus> {
        self.status.as_deref().and_then(|s| {
            serde_json::from_value(serde_json::Value::String(s.to_string())).ok()
        })
    }

    fn parse_type(&self) -> Option<DisputeType> {
        self.dispute_type.as_deref().and_then(|t| {
            serde_json::from_value(serde_json::Value::String(t.to_string())).ok()
        })
    }
}

/// GET /api/v1/admin/disputes
///
/// Admin lists disputes with optional status/type filters, paginated.
pub async fn list_disputes(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    query: web::Query<AdminDisputeListParams>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let status_filter = query.parse_status();
    let type_filter = query.parse_type();

    let per_page = query.validated_per_page();
    let page = query.validated_page();
    let offset = query.offset();

    let (items, total) = tokio::try_join!(
        dispute_repo::find_all_admin(
            &pool,
            status_filter.as_ref(),
            type_filter.as_ref(),
            per_page,
            offset,
        ),
        dispute_repo::count_all_admin(&pool, status_filter.as_ref(), type_filter.as_ref()),
    )?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_pagination(
        items,
        page,
        per_page,
        total,
    )))
}

/// GET /api/v1/admin/disputes/{dispute_id}
///
/// Admin gets dispute detail with order timeline and actor stats.
pub async fn get_dispute_detail(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let dispute_id = path.into_inner();
    let dispute = dispute_repo::find_by_id(&pool, dispute_id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Dispute {dispute_id} not found")))?;

    // Get the order to find merchant and driver
    let order = domain::orders::repository::find_by_id(&pool, dispute.order_id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Order {} not found", dispute.order_id)))?;

    // Parallel: timeline + merchant stats + driver stats
    let timeline_fut = dispute_repo::get_order_timeline(&pool, dispute.order_id);
    let merchant_stats_fut = dispute_repo::get_merchant_stats(&pool, order.merchant_id);

    let (timeline, merchant_stats) = tokio::try_join!(timeline_fut, merchant_stats_fut)?;

    let driver_stats = if let Some(driver_id) = order.driver_id {
        Some(dispute_repo::get_driver_stats(&pool, driver_id).await?)
    } else {
        None
    };

    let detail = AdminDisputeDetail {
        dispute: DisputeResponse::from(dispute),
        timeline,
        merchant_stats,
        driver_stats,
    };

    Ok(HttpResponse::Ok().json(ApiResponse::new(detail)))
}

/// POST /api/v1/admin/disputes/{dispute_id}/resolve
///
/// Admin resolves a dispute with credit/warn/dismiss action.
pub async fn resolve_dispute(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<ResolveDisputeRequest>,
    fcm_client: web::Data<Option<FcmClient>>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    body.validate().map_err(AppError::BadRequest)?;

    let dispute_id = path.into_inner();

    // Resolve the dispute
    let resolved = dispute_service::resolve_dispute(
        &pool,
        dispute_id,
        auth.user_id,
        &body.resolution,
    )
    .await?;

    // If action is credit, credit the reporter's wallet
    if body.action == ResolveAction::Credit {
        if let Some(amount) = body.credit_amount {
            let reason = format!("Credit litige: {}", body.resolution);
            domain::wallets::service::admin_credit_wallet(
                &pool,
                auth.user_id,
                resolved.reporter_id,
                amount,
                &reason,
                Some(resolved.order_id),
            )
            .await?;

            info!(
                dispute_id = %dispute_id,
                amount = amount,
                reporter_id = %resolved.reporter_id,
                "Dispute credit applied"
            );
        }
    }

    // Fire-and-forget: notify reporter (with error logging)
    {
        let pool_ref = pool.get_ref().clone();
        let fcm = fcm_client.into_inner();
        let reporter_id = resolved.reporter_id;
        tokio::spawn(async move {
            notify_reporter_dispute_resolved(&pool_ref, reporter_id, (*fcm).as_ref()).await;
            tracing::debug!(reporter_id = %reporter_id, "Dispute resolution notification sent");
        });
    }

    Ok(HttpResponse::Ok().json(ApiResponse::new(DisputeResponse::from(resolved))))
}

// ── City Config Endpoints ──────────────────────────────────────────

/// GET /api/v1/admin/cities
///
/// Admin lists all city configurations.
pub async fn list_cities(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;
    let cities = city_repo::list_all(&pool).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::new(cities)))
}

/// POST /api/v1/admin/cities
///
/// Admin creates a new city configuration.
pub async fn create_city(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    body: web::Json<CreateCityConfigRequest>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    if body.city_name.trim().is_empty() {
        return Err(AppError::BadRequest("Le nom de la ville est requis".into()));
    }
    if let Some(m) = body.delivery_multiplier {
        if m <= 0.0 {
            return Err(AppError::BadRequest(
                "Le multiplicateur doit etre superieur a 0".into(),
            ));
        }
    }

    let city = city_repo::create(&pool, &body).await?;
    info!(city_id = %city.id, city_name = %city.city_name, "City config created");
    Ok(HttpResponse::Created().json(ApiResponse::new(city)))
}

/// PUT /api/v1/admin/cities/{city_id}
///
/// Admin updates an existing city configuration.
/// Accepts raw JSON to distinguish "zones_geojson absent" from "zones_geojson: null".
pub async fn update_city(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<serde_json::Value>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let city_id = path.into_inner();
    let raw = body.into_inner();

    // Detect whether zones_geojson key is present in the JSON payload
    let zones_geojson_provided = raw.as_object().map_or(false, |o| o.contains_key("zones_geojson"));

    let req: UpdateCityConfigRequest = serde_json::from_value(raw)
        .map_err(|e| AppError::BadRequest(format!("Invalid request body: {e}")))?;

    if let Some(ref name) = req.city_name {
        if name.trim().is_empty() {
            return Err(AppError::BadRequest("Le nom de la ville est requis".into()));
        }
    }
    if let Some(m) = req.delivery_multiplier {
        if m <= 0.0 {
            return Err(AppError::BadRequest(
                "Le multiplicateur doit etre superieur a 0".into(),
            ));
        }
    }

    let city = city_repo::update(&pool, city_id, &req, zones_geojson_provided).await?;
    info!(city_id = %city.id, "City config updated");
    Ok(HttpResponse::Ok().json(ApiResponse::new(city)))
}

/// PATCH /api/v1/admin/cities/{city_id}/active
///
/// Admin toggles city active status.
pub async fn toggle_city_active(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<ToggleActiveRequest>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let city_id = path.into_inner();
    let city = city_repo::toggle_active(&pool, city_id, body.is_active).await?;
    info!(city_id = %city.id, is_active = city.is_active, "City active status toggled");
    Ok(HttpResponse::Ok().json(ApiResponse::new(city)))
}

// --- Admin account management handlers ---

/// GET /api/v1/admin/users
///
/// Admin lists all users with pagination, optional role/status filters, and search.
pub async fn list_users(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    query: web::Query<AdminUserListParams>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let role_filter = query.role.as_deref();
    let status_filter = query.status.as_deref();
    let search = query.search.as_deref();

    let (users, total) = tokio::try_join!(
        user_repo::find_all_paginated(
            &pool,
            role_filter,
            status_filter,
            search,
            query.per_page,
            query.offset(),
        ),
        user_repo::count_all_filtered(&pool, role_filter, status_filter, search),
    )?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_pagination(
        users,
        query.page,
        query.per_page,
        total,
    )))
}

/// GET /api/v1/admin/users/{user_id}
///
/// Admin gets detailed user profile with aggregated stats.
pub async fn get_user_detail(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let user_id = path.into_inner();
    let detail = user_repo::find_detail_by_id(&pool, user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("User not found".into()))?;

    Ok(HttpResponse::Ok().json(ApiResponse::new(detail)))
}

/// PATCH /api/v1/admin/users/{user_id}/status
///
/// Admin suspends, deactivates, or reactivates a user account.
pub async fn update_user_status_admin(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateUserStatusRequest>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let target_user_id = path.into_inner();
    let updated = user_service::admin_update_user_status(
        &pool,
        auth.user_id,
        target_user_id,
        body.new_status.clone(),
        body.reason.as_deref(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::new(updated)))
}

// ── Admin Merchant List & History Endpoints ──────────────────────────

/// Query params for admin merchant list.
#[derive(Debug, serde::Deserialize)]
pub struct AdminMerchantListParams {
    #[serde(default = "default_page")]
    pub page: i64,
    #[serde(default = "default_per_page")]
    pub per_page: i64,
    pub status: Option<String>,
    pub city_id: Option<uuid::Uuid>,
    pub search: Option<String>,
}

impl AdminMerchantListParams {
    fn validated_page(&self) -> i64 {
        self.page.max(1)
    }
    fn validated_per_page(&self) -> i64 {
        self.per_page.clamp(1, 100)
    }
    fn offset(&self) -> i64 {
        (self.validated_page() - 1) * self.validated_per_page()
    }
}

/// Merchant list item for admin view.
#[derive(Debug, serde::Serialize, sqlx::FromRow)]
pub struct AdminMerchantListItem {
    pub id: uuid::Uuid,
    pub name: String,
    #[sqlx(rename = "availability_status")]
    pub status: domain::merchants::model::MerchantStatus,
    pub city_name: Option<String>,
    pub category: Option<String>,
    pub orders_count: i64,
    pub avg_rating: f64,
    pub disputes_count: i64,
    pub created_at: common::types::Timestamp,
}

/// GET /api/v1/admin/merchants
///
/// Admin lists merchants with pagination, optional status/city/search filters.
pub async fn list_merchants_admin(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    query: web::Query<AdminMerchantListParams>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let status_filter = query.status.as_deref();
    let city_filter = query.city_id;
    let search = query.search.as_deref();

    let per_page = query.validated_per_page();
    let page = query.validated_page();
    let offset = query.offset();
    let search_escaped = search.map(|s| s.replace('\\', "\\\\").replace('%', "\\%").replace('_', "\\_"));
    let search_ref = search_escaped.as_deref();

    let (items, total) = tokio::try_join!(
        find_merchants_admin(&pool, status_filter, city_filter, search_ref, per_page, offset),
        count_merchants_admin(&pool, status_filter, city_filter, search_ref),
    )?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_pagination(
        items,
        page,
        per_page,
        total,
    )))
}

async fn find_merchants_admin(
    pool: &PgPool,
    status: Option<&str>,
    city_id: Option<uuid::Uuid>,
    search: Option<&str>,
    limit: i64,
    offset: i64,
) -> Result<Vec<AdminMerchantListItem>, AppError> {
    sqlx::query_as::<_, AdminMerchantListItem>(
        "SELECT m.id, m.name, m.availability_status, cc.city_name,
                m.category,
                COALESCE(o_agg.cnt, 0) AS orders_count,
                COALESCE(r_agg.avg_score, 0.0) AS avg_rating,
                COALESCE(d_agg.cnt, 0) AS disputes_count,
                m.created_at
         FROM merchants m
         LEFT JOIN city_config cc ON cc.id = m.city_id
         LEFT JOIN (SELECT merchant_id, COUNT(*)::bigint AS cnt FROM orders GROUP BY merchant_id) o_agg ON o_agg.merchant_id = m.id
         LEFT JOIN (SELECT rated_id, AVG(score)::float8 AS avg_score FROM ratings WHERE rated_type = 'merchant' GROUP BY rated_id) r_agg ON r_agg.rated_id = m.user_id
         LEFT JOIN (SELECT o2.merchant_id, COUNT(*)::bigint AS cnt FROM disputes d JOIN orders o2 ON o2.id = d.order_id GROUP BY o2.merchant_id) d_agg ON d_agg.merchant_id = m.id
         WHERE m.onboarding_step = 5
           AND ($1::text IS NULL OR m.availability_status::text = $1)
           AND ($2::uuid IS NULL OR m.city_id = $2)
           AND ($3::text IS NULL OR m.name ILIKE '%' || $3 || '%' ESCAPE '\\')
         ORDER BY m.created_at DESC
         LIMIT $4 OFFSET $5",
    )
    .bind(status)
    .bind(city_id)
    .bind(search)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

async fn count_merchants_admin(
    pool: &PgPool,
    status: Option<&str>,
    city_id: Option<uuid::Uuid>,
    search: Option<&str>,
) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COUNT(*)::bigint AS count
         FROM merchants m
         WHERE m.onboarding_step = 5
           AND ($1::text IS NULL OR m.availability_status::text = $1)
           AND ($2::uuid IS NULL OR m.city_id = $2)
           AND ($3::text IS NULL OR m.name ILIKE '%' || $3 || '%' ESCAPE '\\')",
    )
    .bind(status)
    .bind(city_id)
    .bind(search)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

/// Merchant profile info for history view.
#[derive(Debug, serde::Serialize, sqlx::FromRow)]
pub struct MerchantProfileInfo {
    pub id: uuid::Uuid,
    pub name: String,
    pub address: Option<String>,
    #[sqlx(rename = "availability_status")]
    pub status: domain::merchants::model::MerchantStatus,
    pub category: Option<String>,
    pub kyc_status: Option<String>,
    pub created_at: common::types::Timestamp,
}

/// Aggregated merchant stats.
#[derive(Debug, serde::Serialize)]
pub struct MerchantHistoryStats {
    pub total_orders: i64,
    pub completed_orders: i64,
    pub completion_rate: f64,
    pub avg_rating: f64,
    pub total_disputes: i64,
    pub resolved_disputes: i64,
}

/// Recent order item for merchant history.
#[derive(Debug, serde::Serialize, sqlx::FromRow)]
pub struct MerchantRecentOrder {
    pub id: uuid::Uuid,
    pub status: domain::orders::model::OrderStatus,
    pub total: i64,
    pub customer_name: Option<String>,
    pub created_at: common::types::Timestamp,
}

/// Full merchant history response.
#[derive(Debug, serde::Serialize)]
pub struct MerchantHistoryResponse {
    pub merchant: MerchantProfileInfo,
    pub stats: MerchantHistoryStats,
    pub recent_orders: PaginatedItems<MerchantRecentOrder>,
}

/// Generic paginated items wrapper.
#[derive(Debug, serde::Serialize)]
pub struct PaginatedItems<T: serde::Serialize> {
    pub items: Vec<T>,
    pub page: i64,
    pub per_page: i64,
    pub total: i64,
}

/// Query params for merchant/driver history (pagination for recent items).
#[derive(Debug, serde::Deserialize)]
pub struct HistoryParams {
    #[serde(default = "default_page")]
    pub page: i64,
    #[serde(default = "default_history_per_page")]
    pub per_page: i64,
}

fn default_history_per_page() -> i64 {
    10
}

impl HistoryParams {
    fn validated_page(&self) -> i64 {
        self.page.max(1)
    }
    fn validated_per_page(&self) -> i64 {
        self.per_page.clamp(1, 100)
    }
    fn offset(&self) -> i64 {
        (self.validated_page() - 1) * self.validated_per_page()
    }
}

/// GET /api/v1/admin/merchants/{merchant_id}/history
///
/// Admin views detailed merchant history with stats and recent orders.
pub async fn get_merchant_history(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    query: web::Query<HistoryParams>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let merchant_id = path.into_inner();

    // Get merchant profile
    let merchant = sqlx::query_as::<_, MerchantProfileInfo>(
        "SELECT m.id, m.name, m.address, m.availability_status, m.category,
                (SELECT kd.status::text FROM kyc_documents kd WHERE kd.user_id = m.user_id
                 ORDER BY kd.created_at DESC LIMIT 1) AS kyc_status,
                m.created_at
         FROM merchants m WHERE m.id = $1 AND m.onboarding_step = 5",
    )
    .bind(merchant_id)
    .fetch_optional(&**pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?
    .ok_or_else(|| AppError::NotFound(format!("Merchant {merchant_id} not found")))?;

    let per_page = query.validated_per_page();
    let page = query.validated_page();
    let offset = query.offset();

    // Parallel: stats + recent orders + order count
    let stats_fut = get_merchant_stats_full(&pool, merchant_id);
    let orders_fut = find_merchant_recent_orders(&pool, merchant_id, per_page, offset);
    let count_fut = count_merchant_orders(&pool, merchant_id);

    let (stats, recent_items, total_recent) = tokio::try_join!(stats_fut, orders_fut, count_fut)?;

    let response = MerchantHistoryResponse {
        merchant,
        stats,
        recent_orders: PaginatedItems {
            items: recent_items,
            page,
            per_page,
            total: total_recent,
        },
    };

    Ok(HttpResponse::Ok().json(ApiResponse::new(response)))
}

async fn get_merchant_stats_full(
    pool: &PgPool,
    merchant_id: uuid::Uuid,
) -> Result<MerchantHistoryStats, AppError> {
    // Fetch merchant user_id for ratings lookup
    let user_id: uuid::Uuid = sqlx::query_scalar("SELECT user_id FROM merchants WHERE id = $1")
        .bind(merchant_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    let row = sqlx::query_as::<_, (i64, i64, f64, i64, i64)>(
        "SELECT
            COALESCE((SELECT COUNT(*)::bigint FROM orders WHERE merchant_id = $1), 0),
            COALESCE((SELECT COUNT(*)::bigint FROM orders WHERE merchant_id = $1 AND status = 'delivered'), 0),
            COALESCE((SELECT AVG(r.score)::float8 FROM ratings r WHERE r.rated_id = $2 AND r.rated_type = 'merchant'), 0.0),
            COALESCE((SELECT COUNT(*)::bigint FROM disputes d JOIN orders o ON o.id = d.order_id WHERE o.merchant_id = $1), 0),
            COALESCE((SELECT COUNT(*)::bigint FROM disputes d JOIN orders o ON o.id = d.order_id WHERE o.merchant_id = $1 AND d.status IN ('resolved', 'closed')), 0)",
    )
    .bind(merchant_id)
    .bind(user_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    let total = row.0;
    let completed = row.1;
    let rate = if total > 0 {
        (completed as f64 / total as f64) * 100.0
    } else {
        0.0
    };

    Ok(MerchantHistoryStats {
        total_orders: total,
        completed_orders: completed,
        completion_rate: (rate * 10.0).round() / 10.0,
        avg_rating: (row.2 * 10.0).round() / 10.0,
        total_disputes: row.3,
        resolved_disputes: row.4,
    })
}

async fn find_merchant_recent_orders(
    pool: &PgPool,
    merchant_id: uuid::Uuid,
    limit: i64,
    offset: i64,
) -> Result<Vec<MerchantRecentOrder>, AppError> {
    sqlx::query_as::<_, MerchantRecentOrder>(
        "SELECT o.id, o.status, o.total,
                (SELECT u.name FROM users u WHERE u.id = o.customer_id) AS customer_name,
                o.created_at
         FROM orders o
         WHERE o.merchant_id = $1
         ORDER BY o.created_at DESC
         LIMIT $2 OFFSET $3",
    )
    .bind(merchant_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

async fn count_merchant_orders(pool: &PgPool, merchant_id: uuid::Uuid) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COUNT(*)::bigint AS count FROM orders WHERE merchant_id = $1",
    )
    .bind(merchant_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

// ── Admin Driver List & History Endpoints ────────────────────────────

/// Query params for admin driver list.
#[derive(Debug, serde::Deserialize)]
pub struct AdminDriverListParams {
    #[serde(default = "default_page")]
    pub page: i64,
    #[serde(default = "default_per_page")]
    pub per_page: i64,
    pub status: Option<String>,
    pub city_id: Option<uuid::Uuid>,
    pub search: Option<String>,
    pub available: Option<bool>,
}

impl AdminDriverListParams {
    fn validated_page(&self) -> i64 {
        self.page.max(1)
    }
    fn validated_per_page(&self) -> i64 {
        self.per_page.clamp(1, 100)
    }
    fn offset(&self) -> i64 {
        (self.validated_page() - 1) * self.validated_per_page()
    }
}

/// Driver list item for admin view.
#[derive(Debug, serde::Serialize, sqlx::FromRow)]
pub struct AdminDriverListItem {
    pub id: uuid::Uuid,
    pub name: Option<String>,
    pub status: domain::users::model::UserStatus,
    pub city_name: Option<String>,
    pub deliveries_count: i64,
    pub avg_rating: f64,
    pub disputes_count: i64,
    pub available: bool,
    pub created_at: common::types::Timestamp,
}

/// GET /api/v1/admin/drivers
///
/// Admin lists drivers with pagination, optional status/city/search/available filters.
pub async fn list_drivers_admin(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    query: web::Query<AdminDriverListParams>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let status_filter = query.status.as_deref();
    let city_filter = query.city_id;
    let search = query.search.as_deref();
    let available_filter = query.available;
    let per_page = query.validated_per_page();
    let page = query.validated_page();
    let offset = query.offset();
    let search_escaped = search.map(|s| s.replace('\\', "\\\\").replace('%', "\\%").replace('_', "\\_"));
    let search_ref = search_escaped.as_deref();

    let (items, total) = tokio::try_join!(
        find_drivers_admin(&pool, status_filter, city_filter, search_ref, available_filter, per_page, offset),
        count_drivers_admin(&pool, status_filter, city_filter, search_ref, available_filter),
    )?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_pagination(
        items,
        page,
        per_page,
        total,
    )))
}

async fn find_drivers_admin(
    pool: &PgPool,
    status: Option<&str>,
    city_id: Option<uuid::Uuid>,
    search: Option<&str>,
    available: Option<bool>,
    limit: i64,
    offset: i64,
) -> Result<Vec<AdminDriverListItem>, AppError> {
    sqlx::query_as::<_, AdminDriverListItem>(
        "SELECT u.id, u.name, u.status, cc.city_name,
                COALESCE(dl_agg.cnt, 0) AS deliveries_count,
                COALESCE(r_agg.avg_score, 0.0) AS avg_rating,
                COALESCE(d_agg.cnt, 0) AS disputes_count,
                u.is_available AS available,
                u.created_at
         FROM users u
         LEFT JOIN city_config cc ON cc.id = u.city_id
         LEFT JOIN (SELECT driver_id, COUNT(*)::bigint AS cnt FROM deliveries GROUP BY driver_id) dl_agg ON dl_agg.driver_id = u.id
         LEFT JOIN (SELECT rated_id, AVG(score)::float8 AS avg_score FROM ratings WHERE rated_type = 'driver' GROUP BY rated_id) r_agg ON r_agg.rated_id = u.id
         LEFT JOIN (SELECT o.driver_id, COUNT(*)::bigint AS cnt FROM disputes d JOIN orders o ON o.id = d.order_id GROUP BY o.driver_id) d_agg ON d_agg.driver_id = u.id
         WHERE u.role = 'driver'
           AND ($1::text IS NULL OR u.status::text = $1)
           AND ($2::uuid IS NULL OR u.city_id = $2)
           AND ($3::text IS NULL OR u.name ILIKE '%' || $3 || '%' ESCAPE '\\')
           AND ($4::bool IS NULL OR u.is_available = $4)
         ORDER BY u.created_at DESC
         LIMIT $5 OFFSET $6",
    )
    .bind(status)
    .bind(city_id)
    .bind(search)
    .bind(available)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

async fn count_drivers_admin(
    pool: &PgPool,
    status: Option<&str>,
    city_id: Option<uuid::Uuid>,
    search: Option<&str>,
    available: Option<bool>,
) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COUNT(*)::bigint AS count
         FROM users u
         WHERE u.role = 'driver'
           AND ($1::text IS NULL OR u.status::text = $1)
           AND ($2::uuid IS NULL OR u.city_id = $2)
           AND ($3::text IS NULL OR u.name ILIKE '%' || $3 || '%' ESCAPE '\\')
           AND ($4::bool IS NULL OR u.is_available = $4)",
    )
    .bind(status)
    .bind(city_id)
    .bind(search)
    .bind(available)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

/// Driver profile info for history view.
#[derive(Debug, serde::Serialize, sqlx::FromRow)]
pub struct DriverProfileInfo {
    pub id: uuid::Uuid,
    pub name: Option<String>,
    pub phone: String,
    pub status: domain::users::model::UserStatus,
    pub kyc_status: Option<String>,
    pub sponsor_name: Option<String>,
    pub available: bool,
    pub created_at: common::types::Timestamp,
}

/// Aggregated driver stats.
#[derive(Debug, serde::Serialize)]
pub struct DriverHistoryStats {
    pub total_deliveries: i64,
    pub completed_deliveries: i64,
    pub completion_rate: f64,
    pub avg_rating: f64,
    pub total_disputes: i64,
    pub resolved_disputes: i64,
}

/// Recent delivery item for driver history.
#[derive(Debug, serde::Serialize, sqlx::FromRow)]
pub struct DriverRecentDelivery {
    pub id: uuid::Uuid,
    pub order_id: uuid::Uuid,
    pub status: domain::deliveries::model::DeliveryStatus,
    pub merchant_name: Option<String>,
    pub delivered_at: Option<common::types::Timestamp>,
}

/// Full driver history response.
#[derive(Debug, serde::Serialize)]
pub struct DriverHistoryResponse {
    pub driver: DriverProfileInfo,
    pub stats: DriverHistoryStats,
    pub recent_deliveries: PaginatedItems<DriverRecentDelivery>,
}

/// GET /api/v1/admin/drivers/{driver_id}/history
///
/// Admin views detailed driver history with stats and recent deliveries.
pub async fn get_driver_history(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    query: web::Query<HistoryParams>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let driver_id = path.into_inner();

    // Get driver profile
    let driver = sqlx::query_as::<_, DriverProfileInfo>(
        "SELECT u.id, u.name, u.phone, u.status,
                (SELECT kd.status::text FROM kyc_documents kd WHERE kd.user_id = u.id
                 ORDER BY kd.created_at DESC LIMIT 1) AS kyc_status,
                (SELECT sp_u.name FROM sponsorships s JOIN users sp_u ON sp_u.id = s.sponsor_id
                 WHERE s.sponsored_id = u.id LIMIT 1) AS sponsor_name,
                u.is_available AS available,
                u.created_at
         FROM users u WHERE u.id = $1 AND u.role = 'driver'",
    )
    .bind(driver_id)
    .fetch_optional(&**pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?
    .ok_or_else(|| AppError::NotFound(format!("Driver {driver_id} not found")))?;

    let per_page = query.validated_per_page();
    let page = query.validated_page();
    let offset = query.offset();

    // Parallel: stats + recent deliveries + delivery count
    let stats_fut = get_driver_stats_full(&pool, driver_id);
    let deliveries_fut =
        find_driver_recent_deliveries(&pool, driver_id, per_page, offset);
    let count_fut = count_driver_deliveries(&pool, driver_id);

    let (stats, recent_items, total_recent) =
        tokio::try_join!(stats_fut, deliveries_fut, count_fut)?;

    let response = DriverHistoryResponse {
        driver,
        stats,
        recent_deliveries: PaginatedItems {
            items: recent_items,
            page,
            per_page,
            total: total_recent,
        },
    };

    Ok(HttpResponse::Ok().json(ApiResponse::new(response)))
}

async fn get_driver_stats_full(
    pool: &PgPool,
    driver_id: uuid::Uuid,
) -> Result<DriverHistoryStats, AppError> {
    let row = sqlx::query_as::<_, (i64, i64, f64, i64, i64)>(
        "SELECT
            COALESCE((SELECT COUNT(*)::bigint FROM deliveries WHERE driver_id = $1), 0),
            COALESCE((SELECT COUNT(*)::bigint FROM deliveries WHERE driver_id = $1 AND status = 'delivered'), 0),
            COALESCE((SELECT AVG(r.score)::float8 FROM ratings r WHERE r.rated_id = $1 AND r.rated_type = 'driver'), 0.0),
            COALESCE((SELECT COUNT(*)::bigint FROM disputes d JOIN orders o ON o.id = d.order_id WHERE o.driver_id = $1), 0),
            COALESCE((SELECT COUNT(*)::bigint FROM disputes d JOIN orders o ON o.id = d.order_id WHERE o.driver_id = $1 AND d.status IN ('resolved', 'closed')), 0)",
    )
    .bind(driver_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    let total = row.0;
    let completed = row.1;
    let rate = if total > 0 {
        (completed as f64 / total as f64) * 100.0
    } else {
        0.0
    };

    Ok(DriverHistoryStats {
        total_deliveries: total,
        completed_deliveries: completed,
        completion_rate: (rate * 10.0).round() / 10.0,
        avg_rating: (row.2 * 10.0).round() / 10.0,
        total_disputes: row.3,
        resolved_disputes: row.4,
    })
}

async fn find_driver_recent_deliveries(
    pool: &PgPool,
    driver_id: uuid::Uuid,
    limit: i64,
    offset: i64,
) -> Result<Vec<DriverRecentDelivery>, AppError> {
    sqlx::query_as::<_, DriverRecentDelivery>(
        "SELECT dl.id, dl.order_id, dl.status,
                (SELECT m.name FROM merchants m JOIN orders o ON o.merchant_id = m.id WHERE o.id = dl.order_id) AS merchant_name,
                dl.delivered_at
         FROM deliveries dl
         WHERE dl.driver_id = $1
         ORDER BY dl.created_at DESC
         LIMIT $2 OFFSET $3",
    )
    .bind(driver_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

async fn count_driver_deliveries(pool: &PgPool, driver_id: uuid::Uuid) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COUNT(*)::bigint AS count FROM deliveries WHERE driver_id = $1",
    )
    .bind(driver_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

#[cfg(test)]
mod integration_tests {
    use actix_web::test;
    use domain::test_fixtures::*;
    use domain::users::model::UserRole;
    use sqlx::PgPool;

    /// Admin gets 200 with zero counts when DB is empty.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_dashboard_stats_200_empty(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/dashboard/stats")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["orders_today"], 0);
        assert_eq!(body["data"]["active_merchants"], 0);
        assert_eq!(body["data"]["drivers_online"], 0);
        assert_eq!(body["data"]["pending_disputes"], 0);
    }

    /// Admin gets correct counts with real data.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_dashboard_stats_200_with_data(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let agent = create_test_user_with_role(&pool, UserRole::Agent)
            .await
            .unwrap();

        // Create an open merchant (availability_status = 'open')
        let merchant = create_test_merchant_for_agent(&pool, agent.id)
            .await
            .unwrap();
        sqlx::query("UPDATE merchants SET availability_status = 'open' WHERE id = $1")
            .bind(merchant.id)
            .execute(&pool)
            .await
            .unwrap();

        // Create an order today
        let customer = create_test_user(&pool).await.unwrap();
        let product = create_test_product(&pool, merchant.id).await.unwrap();
        create_test_delivered_order(&pool, customer.id, merchant.id, &[(product.id, 1, 100000)])
            .await
            .unwrap();

        // Create a driver who is available
        let driver = create_test_user_with_role(&pool, UserRole::Driver)
            .await
            .unwrap();
        sqlx::query("UPDATE users SET is_available = true WHERE id = $1")
            .bind(driver.id)
            .execute(&pool)
            .await
            .unwrap();

        // Create an open dispute
        sqlx::query(
            "INSERT INTO disputes (id, order_id, reporter_id, dispute_type, status, created_at, updated_at)
             SELECT gen_random_uuid(), o.id, $1, 'quality', 'open', NOW(), NOW()
             FROM orders o LIMIT 1",
        )
        .bind(customer.id)
        .execute(&pool)
        .await
        .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/dashboard/stats")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["orders_today"], 1);
        assert_eq!(body["data"]["active_merchants"], 1);
        assert_eq!(body["data"]["drivers_online"], 1);
        assert_eq!(body["data"]["pending_disputes"], 1);
    }

    /// Non-admin role gets 403 Forbidden.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_dashboard_stats_403_wrong_role(pool: PgPool) {
        let token = crate::test_helpers::create_test_jwt(uuid::Uuid::new_v4(), "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/dashboard/stats")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 403);
    }

    /// No auth token returns 401.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_dashboard_stats_401_no_token(pool: PgPool) {
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/dashboard/stats")
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 401);
    }

    // ── Admin Disputes Tests ──────────────────────────────────────────

    /// Helper: create test data with a dispute for admin tests.
    async fn setup_dispute_data(pool: &PgPool) -> (uuid::Uuid, uuid::Uuid, uuid::Uuid) {
        let admin = create_test_user_with_role(pool, UserRole::Admin)
            .await
            .unwrap();
        let agent = create_test_user_with_role(pool, UserRole::Agent)
            .await
            .unwrap();
        let merchant = create_test_merchant_for_agent(pool, agent.id)
            .await
            .unwrap();
        let customer = create_test_user(pool).await.unwrap();
        let product = create_test_product(pool, merchant.id).await.unwrap();
        let order =
            create_test_delivered_order(pool, customer.id, merchant.id, &[(product.id, 1, 100000)])
                .await
                .unwrap();

        // Create an open dispute
        let dispute_id: (uuid::Uuid,) = sqlx::query_as(
            "INSERT INTO disputes (id, order_id, reporter_id, dispute_type, status, description, created_at, updated_at)
             VALUES (gen_random_uuid(), $1, $2, 'quality', 'open', 'Nourriture froide', NOW(), NOW())
             RETURNING id",
        )
        .bind(order.id)
        .bind(customer.id)
        .fetch_one(pool)
        .await
        .unwrap();

        (admin.id, dispute_id.0, customer.id)
    }

    /// Admin lists disputes — returns paginated list.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_disputes_200(pool: PgPool) {
        let (admin_id, _dispute_id, _customer_id) = setup_dispute_data(&pool).await;

        let token = crate::test_helpers::create_test_jwt(admin_id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/disputes")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["meta"]["total"], 1);
        let items = body["data"].as_array().unwrap();
        assert_eq!(items.len(), 1);
        assert_eq!(items[0]["dispute_type"], "quality");
        assert_eq!(items[0]["status"], "open");
        assert!(items[0]["merchant_name"].is_string());
    }

    /// Admin lists disputes with status filter.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_disputes_with_status_filter(pool: PgPool) {
        let (admin_id, _dispute_id, _customer_id) = setup_dispute_data(&pool).await;

        let token = crate::test_helpers::create_test_jwt(admin_id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        // Filter by resolved → should be empty
        let req = test::TestRequest::get()
            .uri("/api/v1/admin/disputes?status=resolved")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["meta"]["total"], 0);
    }

    /// Admin gets dispute detail with timeline and stats.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_get_dispute_detail_200(pool: PgPool) {
        let (admin_id, dispute_id, _customer_id) = setup_dispute_data(&pool).await;

        let token = crate::test_helpers::create_test_jwt(admin_id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri(&format!("/api/v1/admin/disputes/{}", dispute_id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["dispute"]["id"], dispute_id.to_string());
        assert_eq!(body["data"]["dispute"]["status"], "open");
        assert!(body["data"]["timeline"].is_array());
        assert!(body["data"]["merchant_stats"]["total_orders"].is_number());
    }

    /// Admin resolves dispute with dismiss action.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_resolve_dispute_dismiss(pool: PgPool) {
        let (admin_id, dispute_id, _customer_id) = setup_dispute_data(&pool).await;

        let token = crate::test_helpers::create_test_jwt(admin_id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::post()
            .uri(&format!("/api/v1/admin/disputes/{}/resolve", dispute_id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(serde_json::json!({
                "action": "dismiss",
                "resolution": "Litige non fonde apres verification"
            }))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["status"], "resolved");
        assert_eq!(
            body["data"]["resolution"],
            "Litige non fonde apres verification"
        );
    }

    /// Admin resolves dispute with credit action.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_resolve_dispute_credit(pool: PgPool) {
        let (admin_id, dispute_id, customer_id) = setup_dispute_data(&pool).await;

        // Ensure customer has a wallet
        sqlx::query(
            "INSERT INTO wallets (id, user_id, balance, updated_at) VALUES (gen_random_uuid(), $1, 0, NOW())
             ON CONFLICT (user_id) DO NOTHING",
        )
        .bind(customer_id)
        .execute(&pool)
        .await
        .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin_id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::post()
            .uri(&format!("/api/v1/admin/disputes/{}/resolve", dispute_id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(serde_json::json!({
                "action": "credit",
                "resolution": "Client credite 500 FCFA",
                "credit_amount": 500
            }))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["status"], "resolved");
    }

    /// Non-admin gets 403 on admin disputes endpoints.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_disputes_403_wrong_role(pool: PgPool) {
        let token = crate::test_helpers::create_test_jwt(uuid::Uuid::new_v4(), "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/disputes")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 403);
    }

    // ── Admin City Config Tests ──────────────────────────────────────────

    /// Admin lists cities — returns empty list initially.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_cities_200_empty(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/cities")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        let cities = body["data"].as_array().unwrap();
        assert!(cities.is_empty());
    }

    /// Admin creates a city successfully.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_create_city_201(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::post()
            .uri("/api/v1/admin/cities")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(serde_json::json!({
                "city_name": "Bouake",
                "delivery_multiplier": 1.50,
                "is_active": true
            }))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 201);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["city_name"], "Bouake");
        assert_eq!(body["data"]["delivery_multiplier"], 1.5);
        assert_eq!(body["data"]["is_active"], true);
        assert!(body["data"]["id"].is_string());
    }

    /// Creating a city with duplicate name returns 409 Conflict.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_create_city_duplicate_409(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();

        // Insert city directly
        sqlx::query("INSERT INTO city_config (city_name) VALUES ('Bouake')")
            .execute(&pool)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::post()
            .uri("/api/v1/admin/cities")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(serde_json::json!({
                "city_name": "Bouake"
            }))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 409);
    }

    /// Updating a city to a name that already exists returns 409.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_update_city_duplicate_name_409(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();

        // Insert two cities
        sqlx::query("INSERT INTO city_config (city_name) VALUES ('Bouake'), ('Abidjan')")
            .execute(&pool)
            .await
            .unwrap();

        let city_id: (uuid::Uuid,) = sqlx::query_as(
            "SELECT id FROM city_config WHERE city_name = 'Abidjan'",
        )
        .fetch_one(&pool)
        .await
        .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        // Try to rename Abidjan to Bouake
        let req = test::TestRequest::put()
            .uri(&format!("/api/v1/admin/cities/{}", city_id.0))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(serde_json::json!({ "city_name": "Bouake" }))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 409);
    }

    /// Admin updates an existing city.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_update_city_200(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();

        // Insert city
        let city_id: (uuid::Uuid,) = sqlx::query_as(
            "INSERT INTO city_config (city_name, delivery_multiplier) VALUES ('Bouake', 1.00) RETURNING id",
        )
        .fetch_one(&pool)
        .await
        .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::put()
            .uri(&format!("/api/v1/admin/cities/{}", city_id.0))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(serde_json::json!({
                "delivery_multiplier": 2.00,
                "zones_geojson": {"type": "FeatureCollection", "features": []}
            }))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["delivery_multiplier"], 2.0);
        assert_eq!(body["data"]["zones_geojson"]["type"], "FeatureCollection");
    }

    /// Admin toggles city active status.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_toggle_city_active_200(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();

        let city_id: (uuid::Uuid,) = sqlx::query_as(
            "INSERT INTO city_config (city_name, is_active) VALUES ('Bouake', true) RETURNING id",
        )
        .fetch_one(&pool)
        .await
        .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::patch()
            .uri(&format!("/api/v1/admin/cities/{}/active", city_id.0))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(serde_json::json!({ "is_active": false }))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["is_active"], false);
    }

    /// Non-admin gets 403 on admin cities endpoints.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_cities_403_wrong_role(pool: PgPool) {
        let token = crate::test_helpers::create_test_jwt(uuid::Uuid::new_v4(), "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/cities")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 403);
    }

    // ===== Admin Users tests =====

    /// Admin lists users and gets paginated results with data.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_users_200_with_data(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let _client = create_test_user(&pool).await.unwrap();
        let _driver = create_test_user_with_role(&pool, UserRole::Driver)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/users?page=1&per_page=20")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert!(body["data"].as_array().unwrap().len() >= 3);
        assert!(body["meta"]["total"].as_i64().unwrap() >= 3);
        assert_eq!(body["meta"]["page"], 1);
    }

    /// Admin lists users with empty DB (only admin).
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_users_200_empty(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/users")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        // At least the admin user itself
        assert!(body["data"].as_array().unwrap().len() >= 1);
    }

    /// Admin lists users filtered by role.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_users_with_role_filter(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let _client = create_test_user(&pool).await.unwrap();
        let _driver = create_test_user_with_role(&pool, UserRole::Driver)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/users?role=driver")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        let users = body["data"].as_array().unwrap();
        assert_eq!(users.len(), 1);
        assert_eq!(users[0]["role"], "driver");
    }

    /// Admin lists users with search query.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_users_with_search(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let _client = create_test_user(&pool).await.unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        // Search by name (all test users have "Test User" name)
        let req = test::TestRequest::get()
            .uri("/api/v1/admin/users?search=Test")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert!(body["data"].as_array().unwrap().len() >= 2);
    }

    /// Admin gets user detail with stats.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_get_user_detail_200(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let client = create_test_user(&pool).await.unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri(&format!("/api/v1/admin/users/{}", client.id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["id"], client.id.to_string());
        assert_eq!(body["data"]["role"], "client");
        assert_eq!(body["data"]["status"], "active");
        assert_eq!(body["data"]["total_orders"], 0);
        assert_eq!(body["data"]["disputes_filed"], 0);
    }

    /// Admin gets 404 for non-existent user.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_get_user_detail_404(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri(&format!(
                "/api/v1/admin/users/{}",
                uuid::Uuid::new_v4()
            ))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 404);
    }

    /// Admin suspends a user account.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_update_user_status_suspend_200(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let client = create_test_user(&pool).await.unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let pool2 = pool.clone();
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::patch()
            .uri(&format!("/api/v1/admin/users/{}/status", client.id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(serde_json::json!({
                "new_status": "suspended",
                "reason": "Violation des conditions"
            }))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["status"], "suspended");

        // Verify audit log was created
        let audit: (i64,) = sqlx::query_as(
            "SELECT COUNT(*)::BIGINT FROM admin_audit_logs WHERE target_user_id = $1",
        )
        .bind(client.id)
        .fetch_one(&pool2)
        .await
        .unwrap();
        assert_eq!(audit.0, 1);
    }

    /// Admin deactivates a user account.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_update_user_status_deactivate_200(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let client = create_test_user(&pool).await.unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::patch()
            .uri(&format!("/api/v1/admin/users/{}/status", client.id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(serde_json::json!({ "new_status": "deactivated" }))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["status"], "deactivated");
    }

    /// Admin reactivates a suspended user.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_update_user_status_reactivate_200(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let client = create_test_user(&pool).await.unwrap();

        // First suspend
        domain::users::repository::update_status(
            &pool,
            client.id,
            domain::users::model::UserStatus::Suspended,
        )
        .await
        .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::patch()
            .uri(&format!("/api/v1/admin/users/{}/status", client.id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(serde_json::json!({
                "new_status": "active",
                "reason": "Rehabilite"
            }))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["status"], "active");
    }

    /// Admin cannot modify another admin account (403).
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_update_user_status_admin_on_admin_403(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let other_admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::patch()
            .uri(&format!("/api/v1/admin/users/{}/status", other_admin.id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(serde_json::json!({ "new_status": "suspended" }))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 403);
    }

    /// Non-admin gets 403 on admin users endpoints.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_users_403_wrong_role(pool: PgPool) {
        let token = crate::test_helpers::create_test_jwt(uuid::Uuid::new_v4(), "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/users")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 403);
    }

    /// No token gets 401 on admin users endpoints.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_users_401_no_token(pool: PgPool) {
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/users")
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 401);
    }

    // ── Admin Merchant List Tests ──────────────────────────────────────

    /// Admin gets 200 with empty merchant list.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_merchants_admin_200_empty(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/merchants")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"].as_array().unwrap().len(), 0);
        assert_eq!(body["meta"]["total"], 0);
    }

    /// Admin gets 200 with merchant data.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_merchants_admin_200_with_data(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let agent = create_test_user_with_role(&pool, UserRole::Agent)
            .await
            .unwrap();
        let _merchant = create_test_merchant_for_agent(&pool, agent.id)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/merchants")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"].as_array().unwrap().len(), 1);
        assert_eq!(body["meta"]["total"], 1);
        assert!(body["data"][0]["name"].as_str().is_some());
        assert!(body["data"][0]["orders_count"].as_i64().is_some());
    }

    /// Admin can search merchants by name.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_merchants_admin_200_with_search(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let agent = create_test_user_with_role(&pool, UserRole::Agent)
            .await
            .unwrap();
        let _merchant = create_test_merchant_for_agent(&pool, agent.id)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        // Search with matching name
        let req = test::TestRequest::get()
            .uri("/api/v1/admin/merchants?search=Agent")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);
        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"].as_array().unwrap().len(), 1);

        // Search with no match
        let req2 = test::TestRequest::get()
            .uri("/api/v1/admin/merchants?search=nonexistent")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp2 = test::call_service(&app, req2).await;
        assert_eq!(resp2.status(), 200);
        let body2: serde_json::Value = test::read_body_json(resp2).await;
        assert_eq!(body2["data"].as_array().unwrap().len(), 0);
    }

    /// Non-admin role gets 403 on admin merchants endpoint.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_merchants_admin_403_wrong_role(pool: PgPool) {
        let token = crate::test_helpers::create_test_jwt(uuid::Uuid::new_v4(), "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/merchants")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 403);
    }

    /// No token gets 401 on admin merchants endpoint.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_merchants_admin_401_no_token(pool: PgPool) {
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/merchants")
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 401);
    }

    // ── Admin Merchant History Tests ──────────────────────────────────

    /// Admin gets 200 merchant history with stats.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_merchant_history_200(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let agent = create_test_user_with_role(&pool, UserRole::Agent)
            .await
            .unwrap();
        let merchant = create_test_merchant_for_agent(&pool, agent.id)
            .await
            .unwrap();

        // Create an order for stats
        let customer = create_test_user(&pool).await.unwrap();
        let product = create_test_product(&pool, merchant.id).await.unwrap();
        create_test_delivered_order(&pool, customer.id, merchant.id, &[(product.id, 1, 100000)])
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri(&format!("/api/v1/admin/merchants/{}/history", merchant.id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert!(body["data"]["merchant"]["name"].as_str().is_some());
        assert_eq!(body["data"]["stats"]["total_orders"], 1);
        assert_eq!(body["data"]["stats"]["completed_orders"], 1);
        assert!(body["data"]["recent_orders"]["items"].as_array().unwrap().len() >= 1);
    }

    /// Admin gets 404 for nonexistent merchant.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_merchant_history_404(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri(&format!(
                "/api/v1/admin/merchants/{}/history",
                uuid::Uuid::new_v4()
            ))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 404);
    }

    /// Non-admin gets 403 on merchant history.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_merchant_history_403(pool: PgPool) {
        let token = crate::test_helpers::create_test_jwt(uuid::Uuid::new_v4(), "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri(&format!(
                "/api/v1/admin/merchants/{}/history",
                uuid::Uuid::new_v4()
            ))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 403);
    }

    // ── Admin Driver List Tests ──────────────────────────────────────

    /// Admin gets 200 with empty driver list.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_drivers_admin_200_empty(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/drivers")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        // admin user exists with role Admin, not Driver
        assert_eq!(body["meta"]["total"], 0);
    }

    /// Admin gets 200 with driver data.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_drivers_admin_200_with_data(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let _driver = create_test_user_with_role(&pool, UserRole::Driver)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/drivers")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"].as_array().unwrap().len(), 1);
        assert_eq!(body["meta"]["total"], 1);
        assert!(body["data"][0]["deliveries_count"].as_i64().is_some());
    }

    /// Non-admin role gets 403 on admin drivers endpoint.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_drivers_admin_403_wrong_role(pool: PgPool) {
        let token = crate::test_helpers::create_test_jwt(uuid::Uuid::new_v4(), "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/drivers")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 403);
    }

    /// No token gets 401 on admin drivers endpoint.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_drivers_admin_401_no_token(pool: PgPool) {
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/admin/drivers")
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 401);
    }

    // ── Admin Driver History Tests ──────────────────────────────────

    /// Admin gets 200 driver history with stats.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_driver_history_200(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let driver = create_test_user_with_role(&pool, UserRole::Driver)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri(&format!("/api/v1/admin/drivers/{}/history", driver.id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert!(body["data"]["driver"]["name"].is_string() || body["data"]["driver"]["name"].is_null());
        assert_eq!(body["data"]["stats"]["total_deliveries"], 0);
        assert_eq!(body["data"]["recent_deliveries"]["items"].as_array().unwrap().len(), 0);
    }

    /// Admin gets 404 for nonexistent driver.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_driver_history_404(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();
        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri(&format!(
                "/api/v1/admin/drivers/{}/history",
                uuid::Uuid::new_v4()
            ))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 404);
    }

    /// Non-admin gets 403 on driver history.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_driver_history_403(pool: PgPool) {
        let token = crate::test_helpers::create_test_jwt(uuid::Uuid::new_v4(), "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri(&format!(
                "/api/v1/admin/drivers/{}/history",
                uuid::Uuid::new_v4()
            ))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 403);
    }
}
