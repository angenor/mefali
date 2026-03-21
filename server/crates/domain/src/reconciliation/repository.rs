use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{
    DiscrepancyType, PendingDiscrepancy, ReconciliationDiscrepancy, ReconciliationReport,
    ReconciliationStatus,
};
use crate::wallets::model::WalletTransaction;

const REPORT_COLUMNS: &str = "id, reconciliation_date, total_credits_count, total_credits_amount, \
     total_withdrawals_count, total_withdrawals_amount, matched_count, \
     discrepancy_count, status, created_at";

const DISCREPANCY_COLUMNS: &str = "id, report_id, discrepancy_type, wallet_transaction_id, \
     internal_amount, external_amount, reference, details, created_at";

/// Fetch all wallet transactions for a given date (UTC day boundaries).
pub async fn get_transactions_for_date(
    pool: &PgPool,
    date: chrono::NaiveDate,
) -> Result<Vec<WalletTransaction>, AppError> {
    let start = date.and_hms_opt(0, 0, 0).unwrap().and_utc();
    let end = (date + chrono::Duration::days(1))
        .and_hms_opt(0, 0, 0)
        .unwrap()
        .and_utc();

    sqlx::query_as::<_, WalletTransaction>(
        "SELECT id, wallet_id, amount, transaction_type, reference, description, created_at
         FROM wallet_transactions
         WHERE created_at >= $1 AND created_at < $2
         ORDER BY created_at",
    )
    .bind(start)
    .bind(end)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to fetch transactions for date: {e}")))
}

/// Check if a reconciliation report already exists for a date.
pub async fn find_report_by_date(
    pool: &PgPool,
    date: chrono::NaiveDate,
) -> Result<Option<ReconciliationReport>, AppError> {
    sqlx::query_as::<_, ReconciliationReport>(&format!(
        "SELECT {REPORT_COLUMNS} FROM reconciliation_reports WHERE reconciliation_date = $1"
    ))
    .bind(date)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find reconciliation report: {e}")))
}

/// Parameters for creating a reconciliation report.
pub struct CreateReportParams {
    pub date: chrono::NaiveDate,
    pub total_credits_count: i32,
    pub total_credits_amount: i64,
    pub total_withdrawals_count: i32,
    pub total_withdrawals_amount: i64,
    pub matched_count: i32,
}

/// Create a reconciliation report and its discrepancies in a single transaction.
pub async fn create_report(
    pool: &PgPool,
    params: &CreateReportParams,
    discrepancies: &[PendingDiscrepancy],
) -> Result<ReconciliationReport, AppError> {
    let discrepancy_count = discrepancies.len() as i32;
    let status = determine_status(discrepancies);

    let mut tx = pool
        .begin()
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to begin transaction: {e}")))?;

    let report = sqlx::query_as::<_, ReconciliationReport>(&format!(
        "INSERT INTO reconciliation_reports
         (reconciliation_date, total_credits_count, total_credits_amount,
          total_withdrawals_count, total_withdrawals_amount, matched_count,
          discrepancy_count, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING {REPORT_COLUMNS}"
    ))
    .bind(params.date)
    .bind(params.total_credits_count)
    .bind(params.total_credits_amount)
    .bind(params.total_withdrawals_count)
    .bind(params.total_withdrawals_amount)
    .bind(params.matched_count)
    .bind(discrepancy_count)
    .bind(&status)
    .fetch_one(&mut *tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to create reconciliation report: {e}")))?;

    for d in discrepancies {
        sqlx::query(
            "INSERT INTO reconciliation_discrepancies
             (report_id, discrepancy_type, wallet_transaction_id, internal_amount,
              external_amount, reference, details)
             VALUES ($1, $2, $3, $4, $5, $6, $7)",
        )
        .bind(report.id)
        .bind(&d.discrepancy_type)
        .bind(d.wallet_transaction_id)
        .bind(d.internal_amount)
        .bind(d.external_amount)
        .bind(&d.reference)
        .bind(&d.details)
        .execute(&mut *tx)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to create discrepancy: {e}")))?;
    }

    tx.commit()
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to commit reconciliation: {e}")))?;

    Ok(report)
}

/// Delete a reconciliation report and its discrepancies (CASCADE).
/// Used to allow re-running reconciliation for a date (e.g., after CinetPay outage).
pub async fn delete_report_by_date(
    pool: &PgPool,
    date: chrono::NaiveDate,
) -> Result<bool, AppError> {
    let result = sqlx::query("DELETE FROM reconciliation_reports WHERE reconciliation_date = $1")
        .bind(date)
        .execute(pool)
        .await
        .map_err(|e| {
            AppError::DatabaseError(format!("Failed to delete reconciliation report: {e}"))
        })?;
    Ok(result.rows_affected() > 0)
}

/// List reconciliation reports with pagination.
pub async fn list_reports(
    pool: &PgPool,
    limit: i64,
    offset: i64,
) -> Result<(Vec<ReconciliationReport>, i64), AppError> {
    let total = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM reconciliation_reports")
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to count reports: {e}")))?;

    let reports = sqlx::query_as::<_, ReconciliationReport>(&format!(
        "SELECT {REPORT_COLUMNS} FROM reconciliation_reports
         ORDER BY reconciliation_date DESC
         LIMIT $1 OFFSET $2"
    ))
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to list reports: {e}")))?;

    Ok((reports, total))
}

/// Get discrepancies for a report.
pub async fn get_discrepancies(
    pool: &PgPool,
    report_id: Id,
) -> Result<Vec<ReconciliationDiscrepancy>, AppError> {
    sqlx::query_as::<_, ReconciliationDiscrepancy>(&format!(
        "SELECT {DISCREPANCY_COLUMNS} FROM reconciliation_discrepancies
         WHERE report_id = $1
         ORDER BY created_at"
    ))
    .bind(report_id)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to get discrepancies: {e}")))
}

/// Determine reconciliation status from discrepancies.
fn determine_status(discrepancies: &[PendingDiscrepancy]) -> ReconciliationStatus {
    if discrepancies.is_empty() {
        return ReconciliationStatus::Ok;
    }
    let has_critical = discrepancies.iter().any(|d| {
        matches!(
            d.discrepancy_type,
            DiscrepancyType::OrphanCredit | DiscrepancyType::UnconfirmedAggregator
        )
    });
    if has_critical {
        ReconciliationStatus::Critical
    } else {
        ReconciliationStatus::Warnings
    }
}
