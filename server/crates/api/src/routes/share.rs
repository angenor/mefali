use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use domain::merchants;
use sqlx::PgPool;

use crate::extractors::AuthenticatedUser;

/// Escape HTML special characters to prevent XSS.
fn escape_html(input: &str) -> String {
    input
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#x27;")
}

/// Validate referral code format: 1-8 alphanumeric uppercase chars.
fn validate_ref_param(code: &str) -> bool {
    !code.is_empty() && code.len() <= 8 && code.chars().all(|c| c.is_ascii_alphanumeric())
}

/// GET /api/v1/share/restaurant/{merchant_id}
///
/// Returns share metadata for a merchant (name, description, share URL).
/// Auth: JWT required (any role).
pub async fn get_share_metadata(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    share_base_url: web::Data<String>,
) -> Result<HttpResponse, AppError> {
    let _ = auth; // authenticated but no role restriction
    let merchant_id = path.into_inner();

    let merchant = merchants::repository::find_by_id(&pool, merchant_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Merchant not found".into()))?;

    let referral_code =
        domain::users::repository::get_referral_code(&pool, auth.user_id).await?;

    let share_url = format!(
        "{}/share/r/{}?ref={}",
        share_base_url.get_ref(),
        merchant_id,
        referral_code
    );

    let whatsapp_message = format!(
        "Decouvre {} sur mefali ! Commande facilement depuis ton telephone.\n{}",
        merchant.name, share_url
    );

    let response = ApiResponse::new(serde_json::json!({
        "merchant_name": merchant.name,
        "merchant_description": merchant.category.unwrap_or_default(),
        "share_url": share_url,
        "whatsapp_message": whatsapp_message,
    }));
    Ok(HttpResponse::Ok().json(response))
}

/// GET /share/r/{merchant_id}
///
/// Public endpoint (no auth). Returns minimal HTML page with Open Graph meta tags
/// for WhatsApp link preview, then redirects to app or Play Store.
pub async fn share_redirect_page(
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    query: web::Query<ShareRedirectQuery>,
) -> Result<HttpResponse, AppError> {
    let merchant_id = path.into_inner();

    let merchant = merchants::repository::find_by_id(&pool, merchant_id).await?;
    let (title, description) = match merchant {
        Some(m) => (
            format!("{} sur mefali", m.name),
            format!(
                "Commande {} chez {} a Bouake !",
                m.category.unwrap_or_else(|| "a manger".into()),
                m.name
            ),
        ),
        None => (
            "mefali - Commande a manger".into(),
            "Decouvre mefali, l'app pour commander a manger a Bouake !".into(),
        ),
    };

    let ref_param = query
        .r#ref
        .as_deref()
        .filter(|r| validate_ref_param(r))
        .map(|r| format!("?ref={}", r))
        .unwrap_or_default();

    let safe_title = escape_html(&title);
    let safe_description = escape_html(&description);

    let html = format!(
        r#"<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<meta property="og:title" content="{safe_title}"/>
<meta property="og:description" content="{safe_description}"/>
<meta property="og:type" content="website"/>
<title>{safe_title}</title>
</head>
<body>
<p style="text-align:center;margin-top:40vh;font-family:sans-serif">Redirection en cours...</p>
<script>
var appUrl='mefali://restaurant/{merchant_id}{ref_param}';
var storeUrl='https://play.google.com/store/apps/details?id=ci.mefali.b2c';
window.location=appUrl;
setTimeout(function(){{window.location=storeUrl}},2000);
</script>
</body>
</html>"#
    );

    Ok(HttpResponse::Ok()
        .content_type("text/html; charset=utf-8")
        .body(html))
}

#[derive(Debug, serde::Deserialize)]
pub struct ShareRedirectQuery {
    pub r#ref: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_share_redirect_query_deserialize() {
        let q: ShareRedirectQuery = serde_json::from_str(r#"{"ref": "ABC123"}"#).unwrap();
        assert_eq!(q.r#ref.unwrap(), "ABC123");
    }

    #[test]
    fn test_share_redirect_query_empty() {
        let q: ShareRedirectQuery = serde_json::from_str(r#"{}"#).unwrap();
        assert!(q.r#ref.is_none());
    }

    #[test]
    fn test_escape_html() {
        assert_eq!(escape_html("Chez Adjoua"), "Chez Adjoua");
        assert_eq!(
            escape_html(r#"Bad"Name<script>"#),
            "Bad&quot;Name&lt;script&gt;"
        );
    }

    #[test]
    fn test_validate_ref_param() {
        assert!(validate_ref_param("ABC123"));
        assert!(validate_ref_param("XY9Z"));
        assert!(!validate_ref_param(""));
        assert!(!validate_ref_param("ABC123456")); // > 8 chars
        assert!(!validate_ref_param("abc!@#"));
    }
}
