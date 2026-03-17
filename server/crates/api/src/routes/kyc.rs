use actix_multipart::Multipart;
use actix_web::{web, HttpResponse};
use aws_sdk_s3::Client;
use common::error::AppError;
use common::response::ApiResponse;
use domain::kyc::model::KycDocumentType;
use domain::kyc::service;
use domain::users::model::UserRole;
use futures_util::StreamExt;
use sqlx::PgPool;
use uuid::Uuid;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

/// GET /api/v1/kyc/pending
///
/// List all drivers pending KYC verification.
pub async fn pending_drivers(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Agent, UserRole::Admin])?;

    let users = service::list_pending_kyc_users(&pool).await?;

    let response = ApiResponse::new(serde_json::json!({ "users": users }));
    Ok(HttpResponse::Ok().json(response))
}

/// GET /api/v1/kyc/{user_id}
///
/// Get KYC summary for a user (info + documents + sponsor).
pub async fn kyc_summary(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Agent, UserRole::Admin])?;

    let user_id = path.into_inner();
    let summary = service::get_kyc_summary(&pool, user_id).await?;

    let response = ApiResponse::new(summary);
    Ok(HttpResponse::Ok().json(response))
}

/// POST /api/v1/kyc/{user_id}/documents
///
/// Upload a KYC document (multipart: document_type + file).
pub async fn upload_document(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    mut payload: Multipart,
    pool: web::Data<PgPool>,
    config: web::Data<common::config::AppConfig>,
    s3_client: web::Data<Client>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Agent, UserRole::Admin])?;

    let user_id = path.into_inner();

    // Parse multipart fields
    let mut document_type: Option<String> = None;
    let mut file_bytes: Vec<u8> = Vec::new();
    let mut content_type: Option<String> = None;

    while let Some(item) = payload.next().await {
        let mut field = item.map_err(|e| AppError::BadRequest(e.to_string()))?;
        let field_name = field.name().unwrap_or("").to_string();

        match field_name.as_str() {
            "document_type" => {
                let mut data = Vec::new();
                while let Some(chunk) = field.next().await {
                    data.extend_from_slice(
                        &chunk.map_err(|e| AppError::BadRequest(e.to_string()))?,
                    );
                }
                document_type = Some(
                    String::from_utf8(data)
                        .map_err(|_| AppError::BadRequest("Invalid UTF-8".into()))?,
                );
            }
            "file" => {
                content_type = field.content_type().map(|ct| ct.to_string());
                while let Some(chunk) = field.next().await {
                    file_bytes.extend_from_slice(
                        &chunk.map_err(|e| AppError::BadRequest(e.to_string()))?,
                    );
                }
            }
            _ => {}
        }
    }

    let doc_type_str = document_type
        .ok_or_else(|| AppError::BadRequest("Missing document_type field".into()))?;
    let doc_type: KycDocumentType =
        serde_json::from_str(&format!("\"{}\"", doc_type_str)).map_err(|_| {
            AppError::BadRequest(format!(
                "Invalid document_type: '{}'. Allowed: cni, permis",
                doc_type_str
            ))
        })?;
    let ct = content_type
        .ok_or_else(|| AppError::BadRequest("Missing file field".into()))?;

    if file_bytes.is_empty() {
        return Err(AppError::BadRequest("File is empty".into()));
    }

    let document = service::upload_kyc_document(
        &pool,
        s3_client.get_ref(),
        &config,
        user_id,
        doc_type,
        file_bytes,
        &ct,
    )
    .await?;

    let response = ApiResponse::new(serde_json::json!({ "document": document }));
    Ok(HttpResponse::Created().json(response))
}

/// POST /api/v1/kyc/{user_id}/activate
///
/// Activate a driver after KYC document verification.
pub async fn activate_driver(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Agent, UserRole::Admin])?;

    let user_id = path.into_inner();
    let user = service::activate_driver(&pool, user_id, auth.user_id).await?;

    let response = ApiResponse::new(serde_json::json!({ "user": user }));
    Ok(HttpResponse::Ok().json(response))
}
