use actix_multipart::Multipart;
use actix_web::{web, HttpResponse};
use aws_sdk_s3::Client;
use common::config::AppConfig;
use common::error::AppError;
use common::response::ApiResponse;
use domain::products::model::{
    CreateProductPayload, DecrementStockPayload, Product, UpdateProductPayload, UpdateStockPayload,
};
use domain::products::service;
use domain::users::model::UserRole;
use futures_util::StreamExt;
use sqlx::PgPool;
use uuid::Uuid;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

// --- Helpers ---

struct ProductMultipartData {
    name: Option<String>,
    price: Option<i64>,
    description: Option<String>,
    stock: Option<i32>,
    file_bytes: Vec<u8>,
    content_type: Option<String>,
}

async fn parse_product_multipart(mut payload: Multipart) -> Result<ProductMultipartData, AppError> {
    let mut data = ProductMultipartData {
        name: None,
        price: None,
        description: None,
        stock: None,
        file_bytes: Vec::new(),
        content_type: None,
    };

    while let Some(item) = payload.next().await {
        let mut field = item.map_err(|e| AppError::BadRequest(e.to_string()))?;
        let field_name = field.name().unwrap_or("").to_string();

        match field_name.as_str() {
            "name" => data.name = Some(read_text_field(&mut field).await?),
            "price" => {
                let val = read_text_field(&mut field).await?;
                data.price = Some(
                    val.parse::<i64>()
                        .map_err(|_| AppError::BadRequest("Invalid price value".into()))?,
                );
            }
            "description" => data.description = Some(read_text_field(&mut field).await?),
            "stock" => {
                let val = read_text_field(&mut field).await?;
                data.stock = Some(
                    val.parse::<i32>()
                        .map_err(|_| AppError::BadRequest("Invalid stock value".into()))?,
                );
            }
            "file" => {
                data.content_type = field.content_type().map(|ct| ct.to_string());
                while let Some(chunk) = field.next().await {
                    data.file_bytes
                        .extend_from_slice(&chunk.map_err(|e| AppError::BadRequest(e.to_string()))?);
                }
            }
            _ => {}
        }
    }

    Ok(data)
}

async fn read_text_field(field: &mut actix_multipart::Field) -> Result<String, AppError> {
    let mut bytes = Vec::new();
    while let Some(chunk) = field.next().await {
        bytes.extend_from_slice(&chunk.map_err(|e| AppError::BadRequest(e.to_string()))?);
    }
    String::from_utf8(bytes).map_err(|_| AppError::BadRequest("Invalid UTF-8".into()))
}

/// Upload image to MinIO, returning the object key.
async fn upload_photo(
    s3_client: &Client,
    config: &AppConfig,
    merchant_id: Uuid,
    file_bytes: Vec<u8>,
    content_type: &str,
) -> Result<String, AppError> {
    let key = format!(
        "merchants/{}/products/{}.webp",
        merchant_id,
        Uuid::new_v4()
    );
    infrastructure::storage::upload::upload_image(
        s3_client,
        &config.minio_bucket,
        &key,
        file_bytes,
        content_type,
    )
    .await?;
    Ok(key)
}

/// Prepend MinIO base URL to product photo_url key.
fn with_photo_url(mut product: Product, config: &AppConfig) -> Product {
    if let Some(ref key) = product.photo_url {
        product.photo_url = Some(format!(
            "{}/{}/{}",
            config.minio_endpoint, config.minio_bucket, key
        ));
    }
    product
}

// --- Route handlers ---

/// GET /api/v1/products
///
/// List all available products for the authenticated merchant.
pub async fn list_products(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let merchant_id = service::resolve_merchant_id(&pool, auth.user_id).await?;
    let products = service::get_products(&pool, merchant_id).await?;
    let products: Vec<Product> = products
        .into_iter()
        .map(|p| with_photo_url(p, &config))
        .collect();

    let response = ApiResponse::new(serde_json::json!({ "products": products }));
    Ok(HttpResponse::Ok().json(response))
}

/// POST /api/v1/products
///
/// Create a product with optional photo (multipart).
pub async fn create_product(
    auth: AuthenticatedUser,
    payload: Multipart,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    s3_client: web::Data<Client>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let merchant_id = service::resolve_merchant_id(&pool, auth.user_id).await?;
    let data = parse_product_multipart(payload).await?;

    let product_name =
        data.name.ok_or_else(|| AppError::BadRequest("Missing 'name' field".into()))?;
    let product_price =
        data.price.ok_or_else(|| AppError::BadRequest("Missing 'price' field".into()))?;

    let photo_url = if !data.file_bytes.is_empty() {
        let ct = data
            .content_type
            .ok_or_else(|| AppError::BadRequest("Missing file content type".into()))?;
        Some(upload_photo(s3_client.get_ref(), &config, merchant_id, data.file_bytes, &ct).await?)
    } else {
        None
    };

    let create_payload = CreateProductPayload {
        name: product_name,
        price: product_price,
        description: data.description,
        photo_url,
        stock: data.stock,
    };

    let product = service::create_product_for_merchant(&pool, merchant_id, &create_payload).await?;
    let product = with_photo_url(product, &config);

    let response = ApiResponse::new(serde_json::json!({ "product": product }));
    Ok(HttpResponse::Created().json(response))
}

/// PUT /api/v1/products/{id}
///
/// Update a product with optional new photo (multipart).
pub async fn update_product(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    payload: Multipart,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    s3_client: web::Data<Client>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let merchant_id = service::resolve_merchant_id(&pool, auth.user_id).await?;
    let product_id = path.into_inner();
    let data = parse_product_multipart(payload).await?;

    let photo_url = if !data.file_bytes.is_empty() {
        let ct = data
            .content_type
            .ok_or_else(|| AppError::BadRequest("Missing file content type".into()))?;
        Some(upload_photo(s3_client.get_ref(), &config, merchant_id, data.file_bytes, &ct).await?)
    } else {
        None
    };

    let update_payload = UpdateProductPayload {
        name: data.name,
        price: data.price,
        description: data.description,
        stock: data.stock,
        photo_url,
    };

    let (product, old_photo_key) =
        service::update_product(&pool, merchant_id, product_id, &update_payload).await?;

    // Clean up old photo in MinIO if replaced (best effort)
    if update_payload.photo_url.is_some() {
        if let Some(old_key) = old_photo_key {
            let _ = s3_client
                .delete_object()
                .bucket(&config.minio_bucket)
                .key(&old_key)
                .send()
                .await;
        }
    }

    let product = with_photo_url(product, &config);

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

// --- Stock management handlers (story 3.4) ---

/// PUT /api/v1/products/{id}/stock
///
/// Update stock level for a product (JSON body, not multipart).
pub async fn update_stock(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    payload: web::Json<UpdateStockPayload>,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let merchant_id = service::resolve_merchant_id(&pool, auth.user_id).await?;
    let product_id = path.into_inner();

    let product =
        service::update_stock(&pool, merchant_id, product_id, &payload.into_inner()).await?;
    let product = with_photo_url(product, &config);

    let response = ApiResponse::new(serde_json::json!({ "product": product }));
    Ok(HttpResponse::Ok().json(response))
}

/// POST /api/v1/products/{id}/decrement-stock
///
/// Atomically decrement stock. Returns 409 if insufficient.
pub async fn decrement_stock(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    payload: web::Json<DecrementStockPayload>,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let merchant_id = service::resolve_merchant_id(&pool, auth.user_id).await?;
    let product_id = path.into_inner();

    let product =
        service::decrement_stock(&pool, merchant_id, product_id, &payload.into_inner()).await?;
    let product = with_photo_url(product, &config);

    let response = ApiResponse::new(serde_json::json!({ "product": product }));
    Ok(HttpResponse::Ok().json(response))
}

/// GET /api/v1/merchants/me/stock-alerts
///
/// List unacknowledged stock alerts for the authenticated merchant.
pub async fn list_stock_alerts(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let merchant_id = service::resolve_merchant_id(&pool, auth.user_id).await?;
    let alerts = service::get_stock_alerts(&pool, merchant_id).await?;

    let response = ApiResponse::new(serde_json::json!({ "alerts": alerts }));
    Ok(HttpResponse::Ok().json(response))
}

/// POST /api/v1/stock-alerts/{id}/acknowledge
///
/// Acknowledge a stock alert.
pub async fn acknowledge_alert(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let merchant_id = service::resolve_merchant_id(&pool, auth.user_id).await?;
    let alert_id = path.into_inner();
    let alert = service::acknowledge_alert(&pool, merchant_id, alert_id).await?;

    let response = ApiResponse::new(serde_json::json!({ "alert": alert }));
    Ok(HttpResponse::Ok().json(response))
}
