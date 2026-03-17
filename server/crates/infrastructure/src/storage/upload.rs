use aws_sdk_s3::primitives::ByteStream;
use aws_sdk_s3::types::ServerSideEncryption;
use aws_sdk_s3::Client;
use common::error::AppError;

const MAX_IMAGE_SIZE: usize = 400 * 1024; // 400KB max
const ALLOWED_CONTENT_TYPES: &[&str] = &["image/webp", "image/jpeg", "image/png"];

const MAX_KYC_IMAGE_SIZE: usize = 2 * 1024 * 1024; // 2MB max for KYC documents
const ALLOWED_KYC_CONTENT_TYPES: &[&str] = &["image/jpeg", "image/png"];

/// Upload an image to MinIO/S3 and return the object key.
///
/// # Arguments
/// * `client` - S3-compatible client (MinIO)
/// * `bucket` - Target bucket name
/// * `key` - Object key (e.g., "merchants/{id}/products/{uuid}.webp")
/// * `bytes` - Image bytes
/// * `content_type` - MIME type of the image
pub async fn upload_image(
    client: &Client,
    bucket: &str,
    key: &str,
    bytes: Vec<u8>,
    content_type: &str,
) -> Result<String, AppError> {
    // Validate content type
    if !ALLOWED_CONTENT_TYPES.contains(&content_type) {
        return Err(AppError::BadRequest(format!(
            "Invalid content type '{}'. Allowed: {:?}",
            content_type, ALLOWED_CONTENT_TYPES
        )));
    }

    // Validate size
    if bytes.len() > MAX_IMAGE_SIZE {
        return Err(AppError::BadRequest(format!(
            "Image too large ({} bytes). Maximum: {} bytes",
            bytes.len(),
            MAX_IMAGE_SIZE
        )));
    }

    if bytes.is_empty() {
        return Err(AppError::BadRequest("Image file is empty".into()));
    }

    let body = ByteStream::from(bytes);

    client
        .put_object()
        .bucket(bucket)
        .key(key)
        .body(body)
        .content_type(content_type)
        .send()
        .await
        .map_err(|e| AppError::ExternalServiceError(format!("MinIO upload failed: {}", e)))?;

    Ok(key.to_string())
}

/// Upload an image to MinIO/S3 with server-side AES-256 encryption (SSE-S3).
///
/// Used for sensitive documents (KYC identity documents).
/// Accepts JPEG/PNG only, up to 2MB.
pub async fn upload_encrypted_image(
    client: &Client,
    bucket: &str,
    key: &str,
    bytes: Vec<u8>,
    content_type: &str,
) -> Result<String, AppError> {
    // Validate content type (JPEG/PNG only for KYC)
    if !ALLOWED_KYC_CONTENT_TYPES.contains(&content_type) {
        return Err(AppError::BadRequest(format!(
            "Invalid content type '{}'. Allowed for KYC: {:?}",
            content_type, ALLOWED_KYC_CONTENT_TYPES
        )));
    }

    // Validate size (2MB for KYC documents)
    if bytes.len() > MAX_KYC_IMAGE_SIZE {
        return Err(AppError::BadRequest(format!(
            "Image too large ({} bytes). Maximum for KYC: {} bytes",
            bytes.len(),
            MAX_KYC_IMAGE_SIZE
        )));
    }

    if bytes.is_empty() {
        return Err(AppError::BadRequest("Image file is empty".into()));
    }

    let body = ByteStream::from(bytes);

    client
        .put_object()
        .bucket(bucket)
        .key(key)
        .body(body)
        .content_type(content_type)
        .server_side_encryption(ServerSideEncryption::Aes256)
        .send()
        .await
        .map_err(|e| AppError::ExternalServiceError(format!("MinIO upload failed: {}", e)))?;

    Ok(key.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_allowed_content_types() {
        assert!(ALLOWED_CONTENT_TYPES.contains(&"image/webp"));
        assert!(ALLOWED_CONTENT_TYPES.contains(&"image/jpeg"));
        assert!(ALLOWED_CONTENT_TYPES.contains(&"image/png"));
        assert!(!ALLOWED_CONTENT_TYPES.contains(&"application/pdf"));
    }

    #[test]
    fn test_max_image_size() {
        assert_eq!(MAX_IMAGE_SIZE, 400 * 1024);
    }

    #[test]
    fn test_allowed_kyc_content_types() {
        assert!(ALLOWED_KYC_CONTENT_TYPES.contains(&"image/jpeg"));
        assert!(ALLOWED_KYC_CONTENT_TYPES.contains(&"image/png"));
        assert!(!ALLOWED_KYC_CONTENT_TYPES.contains(&"image/webp"));
    }

    #[test]
    fn test_max_kyc_image_size() {
        assert_eq!(MAX_KYC_IMAGE_SIZE, 2 * 1024 * 1024);
    }
}
