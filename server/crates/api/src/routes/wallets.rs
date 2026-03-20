use std::sync::Arc;

use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use domain::users::model::UserRole;
use domain::wallets::service;
use notification::fcm::{FcmClient, PushNotification};
use payment_provider::provider::PaymentProvider;
use serde::Deserialize;
use sqlx::PgPool;
use tracing::warn;

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
/// Driver or Merchant requests a withdrawal from wallet to mobile money.
pub async fn withdraw(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    body: web::Json<WithdrawBody>,
    payment_provider: web::Data<Arc<dyn PaymentProvider>>,
    fcm_client: web::Data<Option<FcmClient>>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver, UserRole::Merchant])?;

    let tx = service::request_withdrawal(
        &pool,
        auth.user_id,
        body.amount,
        &body.phone_number,
        payment_provider.get_ref().as_ref(),
    )
    .await?;

    // Best-effort push notification
    notify_withdrawal_completed(
        &pool,
        auth.user_id,
        body.amount,
        &body.phone_number,
        fcm_client.as_ref().as_ref(),
    )
    .await;

    let response = ApiResponse::new(serde_json::json!({
        "transaction": tx,
    }));
    Ok(HttpResponse::Ok().json(response))
}

/// Notify user that withdrawal was processed (best-effort).
async fn notify_withdrawal_completed(
    pool: &PgPool,
    user_id: common::types::Id,
    amount: i64,
    phone_number: &str,
    fcm_client: Option<&FcmClient>,
) {
    let fcm = match fcm_client {
        Some(c) => c,
        None => return,
    };

    let user = match domain::users::repository::find_by_id(pool, user_id).await {
        Ok(Some(u)) => u,
        _ => return,
    };

    if let Some(ref token) = user.fcm_token {
        if !token.is_empty() {
            let amount_fcfa = amount / 100;
            let notification = PushNotification {
                device_token: token.clone(),
                title: "Retrait effectue".into(),
                body: format!("-{amount_fcfa} FCFA vers {phone_number}"),
                data: {
                    let mut map = serde_json::Map::new();
                    map.insert("event".into(), "wallet.withdrawal".into());
                    map.insert("amount".into(), amount.to_string().into());
                    Some(serde_json::Value::Object(map))
                },
            };
            if let Err(e) = fcm.send_push(&notification).await {
                warn!(user_id = %user_id, error = %e, "Failed to send withdrawal notification");
            }
        }
    }
}
