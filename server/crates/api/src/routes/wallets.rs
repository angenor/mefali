use std::sync::Arc;

use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use common::types::Id;
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

    let (wallet, transactions) = service::get_wallet_with_transactions(&pool, auth.user_id).await?;

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

    // Best-effort push notification (fire-and-forget, non-blocking)
    {
        let pool = pool.clone();
        let fcm = fcm_client.clone();
        let user_id = auth.user_id;
        let amount = body.amount;
        let phone = body.phone_number.clone();
        actix_web::rt::spawn(async move {
            notify_withdrawal_completed(&pool, user_id, amount, &phone, fcm.as_ref().as_ref())
                .await;
        });
    }

    let response = ApiResponse::new(serde_json::json!({
        "transaction": tx,
    }));
    Ok(HttpResponse::Ok().json(response))
}

#[derive(Debug, Deserialize)]
pub struct AdminCreditBody {
    pub amount: i64,
    pub reason: String,
    pub order_id: Option<Id>,
}

#[derive(Debug, Deserialize)]
pub struct AdminCreditPath {
    pub user_id: Id,
}

/// POST /api/v1/admin/wallets/{user_id}/credit
///
/// Admin credits a user's wallet for dispute resolution.
pub async fn admin_credit_wallet(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<AdminCreditPath>,
    body: web::Json<AdminCreditBody>,
    fcm_client: web::Data<Option<FcmClient>>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;

    let (wallet, tx) = service::admin_credit_wallet(
        &pool,
        auth.user_id,
        path.user_id,
        body.amount,
        &body.reason,
        body.order_id,
    )
    .await?;

    // Best-effort push notification (fire-and-forget)
    {
        let pool = pool.clone();
        let fcm = fcm_client.clone();
        let target_user_id = path.user_id;
        let amount = body.amount;
        actix_web::rt::spawn(async move {
            notify_admin_credit(&pool, target_user_id, amount, fcm.as_ref().as_ref()).await;
        });
    }

    Ok(HttpResponse::Ok().json(ApiResponse::new(serde_json::json!({
        "wallet": wallet,
        "transaction": tx,
    }))))
}

/// Notify user that admin credited their wallet (best-effort).
async fn notify_admin_credit(
    pool: &PgPool,
    user_id: Id,
    amount: i64,
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
                title: "Reclamation traitee".into(),
                body: format!("+{amount_fcfa} FCFA credites sur votre wallet."),
                data: {
                    let mut map = serde_json::Map::new();
                    map.insert("event".into(), "wallet.admin_credit".into());
                    map.insert("amount".into(), amount.to_string().into());
                    Some(serde_json::Value::Object(map))
                },
            };
            if let Err(e) = fcm.send_push(&notification).await {
                warn!(user_id = %user_id, error = %e, "Failed to send admin credit notification");
            }
        }
    }
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
