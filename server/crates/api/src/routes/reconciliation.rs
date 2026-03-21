use std::sync::Arc;

use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use common::types::PaginationParams;
use domain::reconciliation::{repository, service};
use domain::users::model::UserRole;
use payment_provider::provider::PaymentProvider;
use serde::Deserialize;
use sqlx::PgPool;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

#[derive(Debug, Deserialize)]
pub struct RunReconciliationBody {
    pub date: Option<String>,
    #[serde(default)]
    pub force: bool,
}

/// POST /api/v1/admin/reconciliation/run
///
/// Manually trigger reconciliation for a date (defaults to yesterday).
/// Set `force: true` to re-run even if a report already exists (e.g., after CinetPay outage).
pub async fn run_reconciliation(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    body: web::Json<RunReconciliationBody>,
    payment_provider: web::Data<Arc<dyn PaymentProvider>>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let date = match &body.date {
        Some(d) => chrono::NaiveDate::parse_from_str(d, "%Y-%m-%d")
            .map_err(|_| AppError::BadRequest("Invalid date format, expected YYYY-MM-DD".into()))?,
        None => chrono::Utc::now().date_naive() - chrono::Duration::days(1),
    };

    let report =
        service::run_daily_reconciliation(&pool, payment_provider.get_ref().as_ref(), date, body.force).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::new(&report)))
}

/// GET /api/v1/admin/reconciliation/reports
///
/// List reconciliation reports with pagination.
pub async fn list_reports(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    query: web::Query<PaginationParams>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let (reports, total) = repository::list_reports(&pool, query.per_page, query.offset()).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_pagination(
        reports,
        query.page,
        query.per_page,
        total,
    )))
}

#[derive(Debug, Deserialize)]
pub struct ReportDatePath {
    pub date: String,
}

/// GET /api/v1/admin/reconciliation/reports/{date}
///
/// Get a specific reconciliation report with its discrepancies.
pub async fn get_report(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<ReportDatePath>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let date = chrono::NaiveDate::parse_from_str(&path.date, "%Y-%m-%d")
        .map_err(|_| AppError::BadRequest("Invalid date format, expected YYYY-MM-DD".into()))?;

    let report = repository::find_report_by_date(&pool, date)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("No reconciliation report for {date}")))?;

    let discrepancies = repository::get_discrepancies(&pool, report.id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::new(serde_json::json!({
        "report": report,
        "discrepancies": discrepancies,
    }))))
}
