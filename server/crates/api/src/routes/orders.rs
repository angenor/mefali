use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use domain::orders::model::{CreateOrderPayload, OrderStatus, RejectOrderPayload};
use domain::orders::service;
use domain::users::model::UserRole;
use sqlx::PgPool;
use uuid::Uuid;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

/// POST /api/v1/orders
///
/// Client creates a new order.
pub async fn create_order(
    auth: AuthenticatedUser,
    body: web::Json<CreateOrderPayload>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Client])?;

    let order = service::create_order(&pool, auth.user_id, &body).await?;

    let response = ApiResponse::new(serde_json::json!({ "order": order }));
    Ok(HttpResponse::Created().json(response))
}

/// Query parameters for merchant orders list.
#[derive(Debug, serde::Deserialize)]
pub struct MerchantOrdersQuery {
    pub status: Option<String>,
}

/// GET /api/v1/merchants/me/orders?status=pending,confirmed,ready
///
/// Merchant gets their active orders filtered by status.
pub async fn get_merchant_orders(
    auth: AuthenticatedUser,
    query: web::Query<MerchantOrdersQuery>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let statuses = parse_status_filter(&query.status)?;
    let orders = service::get_merchant_orders(&pool, auth.user_id, &statuses).await?;

    let response = ApiResponse::new(serde_json::json!({ "orders": orders }));
    Ok(HttpResponse::Ok().json(response))
}

/// PUT /api/v1/orders/{id}/accept
///
/// Merchant accepts a pending order.
pub async fn accept_order(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let order = service::accept_order(&pool, auth.user_id, path.into_inner()).await?;

    let response = ApiResponse::new(serde_json::json!({ "order": order }));
    Ok(HttpResponse::Ok().json(response))
}

/// PUT /api/v1/orders/{id}/reject
///
/// Merchant rejects a pending order with a reason.
pub async fn reject_order(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    body: web::Json<RejectOrderPayload>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    body.validate()?;
    let order =
        service::reject_order(&pool, auth.user_id, path.into_inner(), &body.reason).await?;

    let response = ApiResponse::new(serde_json::json!({ "order": order }));
    Ok(HttpResponse::Ok().json(response))
}

/// PUT /api/v1/orders/{id}/ready
///
/// Merchant marks a confirmed order as ready for pickup.
pub async fn mark_ready(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let order = service::mark_ready(&pool, auth.user_id, path.into_inner()).await?;

    let response = ApiResponse::new(serde_json::json!({ "order": order }));
    Ok(HttpResponse::Ok().json(response))
}

/// GET /api/v1/merchants/me/stats/weekly
///
/// Merchant gets their weekly sales dashboard stats.
pub async fn get_weekly_stats(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let stats = service::get_merchant_weekly_stats(&pool, auth.user_id).await?;

    let response = ApiResponse::new(serde_json::json!(stats));
    Ok(HttpResponse::Ok().json(response))
}

/// Parse comma-separated status filter into Vec<OrderStatus>.
/// Defaults to active statuses if no filter provided.
fn parse_status_filter(status_param: &Option<String>) -> Result<Vec<OrderStatus>, AppError> {
    match status_param {
        None => Ok(vec![
            OrderStatus::Pending,
            OrderStatus::Confirmed,
            OrderStatus::Ready,
        ]),
        Some(s) if s.trim().is_empty() => Ok(vec![
            OrderStatus::Pending,
            OrderStatus::Confirmed,
            OrderStatus::Ready,
        ]),
        Some(s) => {
            let mut statuses = Vec::new();
            for part in s.split(',') {
                let status = match part.trim() {
                    "pending" => OrderStatus::Pending,
                    "confirmed" => OrderStatus::Confirmed,
                    "preparing" => OrderStatus::Preparing,
                    "ready" => OrderStatus::Ready,
                    "collected" => OrderStatus::Collected,
                    "in_transit" => OrderStatus::InTransit,
                    "delivered" => OrderStatus::Delivered,
                    "cancelled" => OrderStatus::Cancelled,
                    other => {
                        return Err(AppError::BadRequest(format!(
                            "Invalid order status: '{other}'"
                        )));
                    }
                };
                statuses.push(status);
            }
            Ok(statuses)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_status_filter_none() {
        let result = parse_status_filter(&None).unwrap();
        assert_eq!(result.len(), 3);
        assert!(result.contains(&OrderStatus::Pending));
        assert!(result.contains(&OrderStatus::Confirmed));
        assert!(result.contains(&OrderStatus::Ready));
    }

    #[test]
    fn test_parse_status_filter_single() {
        let result = parse_status_filter(&Some("pending".into())).unwrap();
        assert_eq!(result.len(), 1);
        assert_eq!(result[0], OrderStatus::Pending);
    }

    #[test]
    fn test_parse_status_filter_multiple() {
        let result = parse_status_filter(&Some("pending,confirmed,ready".into())).unwrap();
        assert_eq!(result.len(), 3);
    }

    #[test]
    fn test_parse_status_filter_invalid() {
        let result = parse_status_filter(&Some("invalid_status".into()));
        assert!(result.is_err());
    }

    #[test]
    fn test_parse_status_filter_empty() {
        let result = parse_status_filter(&Some("".into())).unwrap();
        assert_eq!(result.len(), 3); // defaults
    }
}

#[cfg(test)]
mod integration_tests {
    use actix_web::test;
    use domain::test_fixtures::*;
    use domain::users::model::UserRole;
    use sqlx::PgPool;

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_weekly_stats_200_ok(pool: PgPool) {
        let user_m = create_test_user_with_role(&pool, UserRole::Merchant)
            .await
            .unwrap();
        let merchant = create_test_merchant(&pool, user_m.id).await.unwrap();
        let customer = create_test_user(&pool).await.unwrap();
        let p = create_test_product_with_price(&pool, merchant.id, "Garba", 250000)
            .await
            .unwrap();
        create_test_delivered_order(&pool, customer.id, merchant.id, &[(p.id, 2, 250000)])
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(user_m.id, "merchant");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/merchants/me/stats/weekly")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        // 1 order: 2x Garba @ 250000 = 500000 total
        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(
            body["data"]["current_week"]["total_sales"]
                .as_i64()
                .unwrap(),
            500000
        );
        assert_eq!(
            body["data"]["current_week"]["order_count"]
                .as_i64()
                .unwrap(),
            1
        );
        assert!(
            !body["data"]["product_breakdown"]
                .as_array()
                .unwrap()
                .is_empty()
        );
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_weekly_stats_401_no_token(pool: PgPool) {
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/merchants/me/stats/weekly")
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 401);
    }

    /// Verifies role check happens before DB lookup (handler ordering).
    /// Uses a non-existent user_id — if handler order changes to DB-first, this will get 404.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_weekly_stats_403_wrong_role(pool: PgPool) {
        let token = crate::test_helpers::create_test_jwt(uuid::Uuid::new_v4(), "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/merchants/me/stats/weekly")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 403);
    }
}
