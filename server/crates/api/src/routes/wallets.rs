use std::sync::Arc;

use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use domain::users::model::UserRole;
use domain::wallets::service;
use payment_provider::provider::PaymentProvider;
use serde::Deserialize;
use sqlx::PgPool;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

/// GET /api/v1/wallets/me
///
/// Returns the authenticated user's wallet balance and recent transactions.
pub async fn get_wallet(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver, UserRole::Merchant])?;

    let (wallet, transactions) =
        service::get_wallet_with_transactions(&pool, auth.user_id).await?;

    let response = ApiResponse::new(serde_json::json!({
        "wallet": {
            "id": wallet.id,
            "balance": wallet.balance,
            "updated_at": wallet.updated_at,
        },
        "transactions": transactions,
    }));
    Ok(HttpResponse::Ok().json(response))
}

#[derive(Debug, Deserialize)]
pub struct WithdrawBody {
    pub amount: i64,
    pub phone_number: String,
}

/// POST /api/v1/wallets/withdraw
///
/// Driver requests a withdrawal from wallet to mobile money.
pub async fn withdraw(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    body: web::Json<WithdrawBody>,
    payment_provider: web::Data<Arc<dyn PaymentProvider>>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver])?;

    let tx = service::request_withdrawal(
        &pool,
        auth.user_id,
        body.amount,
        &body.phone_number,
        payment_provider.get_ref().as_ref(),
    )
    .await?;

    let response = ApiResponse::new(serde_json::json!({
        "transaction": tx,
    }));
    Ok(HttpResponse::Ok().json(response))
}
