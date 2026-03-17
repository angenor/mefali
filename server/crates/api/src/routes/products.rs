use actix_multipart::Multipart;
use actix_web::{web, HttpResponse};
use aws_sdk_s3::Client;
use common::config::AppConfig;
use common::error::AppError;
use common::response::ApiResponse;
use domain::products::model::{CreateProductPayload, UpdateProductPayload};
use domain::products::service;
use domain::users::model::UserRole;
use futures_util::StreamExt;
use sqlx::PgPool;
use uuid::Uuid;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

/// GET /api/v1/products
///
/// List all available products for the authenticated merchant.
pub async fn list_products(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let merchant_id = service::resolve_merchant_id(&pool, auth.user_id).await?;
    let products = service::get_products(&pool, merchant_id).await?;

    let response = ApiResponse::new(serde_json::json!({ "products": products }));
    Ok(HttpResponse::Ok().json(response))
}

/// POST /api/v1/products
///
/// Create a product with optional photo (multipart).
pub async fn create_product(
    auth: AuthenticatedUser,
    mut payload: Multipart,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    s3_client: web::Data<Client>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let merchant_id = service::resolve_merchant_id(&pool, auth.user_id).await?;

    // Parse multipart fields
    let mut name: Option<String> = None;
    let mut price: Option<i64> = None;
    let mut description: Option<String> = None;
    let mut stock: Option<i32> = None;
    let mut file_bytes: Vec<u8> = Vec::new();
    let mut content_type: Option<String> = None;

    while let Some(item) = payload.next().await {
        let mut field = item.map_err(|e| AppError::BadRequest(e.to_string()))?;
        let field_name = field.name().unwrap_or("").to_string();

        match field_name.as_str() {
            "name" => {
                name = Some(read_text_field(&mut field).await?);
            }
            "price" => {
                let val = read_text_field(&mut field).await?;
                price = Some(
                    val.parse::<i64>()
                        .map_err(|_| AppError::BadRequest("Invalid price value".into()))?,
                );
            }
            "description" => {
                description = Some(read_text_field(&mut field).await?);
            }
            "stock" => {
                let val = read_text_field(&mut field).await?;
                stock = Some(
                    val.parse::<i32>()
                        .map_err(|_| AppError::BadRequest("Invalid stock value".into()))?,
                );
            }
            "file" => {
                content_type = field.content_type().map(|ct| ct.to_string());
                while let Some(chunk) = field.next().await {
                    file_bytes
                        .extend_from_slice(&chunk.map_err(|e| AppError::BadRequest(e.to_string()))?);
                }
            }
            _ => {}
        }
    }

    let product_name =
        name.ok_or_else(|| AppError::BadRequest("Missing 'name' field".into()))?;
    let product_price =
        price.ok_or_else(|| AppError::BadRequest("Missing 'price' field".into()))?;

    // Upload photo if provided
    let photo_url = if !file_bytes.is_empty() {
        let ct = content_type
            .ok_or_else(|| AppError::BadRequest("Missing file content type".into()))?;
        let key = format!(
            "merchants/{}/products/{}.webp",
            merchant_id,
            Uuid::new_v4()
        );
        infrastructure::storage::upload::upload_image(
            s3_client.get_ref(),
            &config.minio_bucket,
            &key,
            file_bytes,
            &ct,
        )
        .await?;
        Some(key)
    } else {
        None
    };

    let create_payload = CreateProductPayload {
        name: product_name,
        price: product_price,
        description,
        photo_url,
        stock,
    };

    let product = service::create_product_for_merchant(&pool, merchant_id, &create_payload).await?;

    let response = ApiResponse::new(serde_json::json!({ "product": product }));
    Ok(HttpResponse::Created().json(response))
}

/// PUT /api/v1/products/{id}
///
/// Update a product with optional new photo (multipart).
pub async fn update_product(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    mut payload: Multipart,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    s3_client: web::Data<Client>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let merchant_id = service::resolve_merchant_id(&pool, auth.user_id).await?;
    let product_id = path.into_inner();

    // Parse multipart fields
    let mut name: Option<String> = None;
    let mut price: Option<i64> = None;
    let mut description: Option<String> = None;
    let mut stock: Option<i32> = None;
    let mut file_bytes: Vec<u8> = Vec::new();
    let mut content_type: Option<String> = None;

    while let Some(item) = payload.next().await {
        let mut field = item.map_err(|e| AppError::BadRequest(e.to_string()))?;
        let field_name = field.name().unwrap_or("").to_string();

        match field_name.as_str() {
            "name" => {
                name = Some(read_text_field(&mut field).await?);
            }
            "price" => {
                let val = read_text_field(&mut field).await?;
                price = Some(
                    val.parse::<i64>()
                        .map_err(|_| AppError::BadRequest("Invalid price value".into()))?,
                );
            }
            "description" => {
                description = Some(read_text_field(&mut field).await?);
            }
            "stock" => {
                let val = read_text_field(&mut field).await?;
                stock = Some(
                    val.parse::<i32>()
                        .map_err(|_| AppError::BadRequest("Invalid stock value".into()))?,
                );
            }
            "file" => {
                content_type = field.content_type().map(|ct| ct.to_string());
                while let Some(chunk) = field.next().await {
                    file_bytes
                        .extend_from_slice(&chunk.map_err(|e| AppError::BadRequest(e.to_string()))?);
                }
            }
            _ => {}
        }
    }

    // Upload new photo if provided
    let photo_url = if !file_bytes.is_empty() {
        let ct = content_type
            .ok_or_else(|| AppError::BadRequest("Missing file content type".into()))?;
        let key = format!(
            "merchants/{}/products/{}.webp",
            merchant_id,
            Uuid::new_v4()
        );
        infrastructure::storage::upload::upload_image(
            s3_client.get_ref(),
            &config.minio_bucket,
            &key,
            file_bytes,
            &ct,
        )
        .await?;
        Some(key)
    } else {
        None
    };

    let update_payload = UpdateProductPayload {
        name,
        price,
        description,
        stock,
        photo_url,
    };

    let product = service::update_product(&pool, merchant_id, product_id, &update_payload).await?;

    let response = ApiResponse::new(serde_json::json!({ "product": product }));
    Ok(HttpResponse::Ok().json(response))
}

/// DELETE /api/v1/products/{id}
///
/// Soft-delete a product (set is_available = false).
pub async fn delete_product(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let merchant_id = service::resolve_merchant_id(&pool, auth.user_id).await?;
    let product_id = path.into_inner();

    service::soft_delete_product(&pool, merchant_id, product_id).await?;

    let response = ApiResponse::new(serde_json::json!({ "message": "Product deleted" }));
    Ok(HttpResponse::Ok().json(response))
}

/// Helper: read a text field from multipart.
async fn read_text_field(field: &mut actix_multipart::Field) -> Result<String, AppError> {
    let mut data = Vec::new();
    while let Some(chunk) = field.next().await {
        data.extend_from_slice(&chunk.map_err(|e| AppError::BadRequest(e.to_string()))?);
    }
    String::from_utf8(data).map_err(|_| AppError::BadRequest("Invalid UTF-8".into()))
}
