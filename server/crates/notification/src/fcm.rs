use serde::{Deserialize, Serialize};
use thiserror::Error;
use tokio::sync::Mutex;
use tracing::{info, warn};

#[derive(Debug, Error)]
pub enum FcmError {
    #[error("FCM send failed: {0}")]
    SendFailed(String),

    #[error("Invalid device token: {0}")]
    InvalidToken(String),

    #[error("OAuth2 token error: {0}")]
    TokenError(String),
}

/// Push notification payload
#[derive(Debug, Clone, Serialize)]
pub struct PushNotification {
    pub device_token: String,
    pub title: String,
    pub body: String,
    pub data: Option<serde_json::Value>,
}

struct CachedToken {
    access_token: String,
    expires_at: chrono::DateTime<chrono::Utc>,
}

/// FCM HTTP v1 API client with OAuth2 token caching.
pub struct FcmClient {
    project_id: String,
    client_email: String,
    private_key: String,
    http_client: reqwest::Client,
    token_cache: Mutex<Option<CachedToken>>,
}

impl FcmClient {
    pub fn new(project_id: String, client_email: String, private_key: String) -> Self {
        info!(project_id = %project_id, "FCM client initialized");
        Self {
            project_id,
            client_email,
            private_key,
            http_client: reqwest::Client::new(),
            token_cache: Mutex::new(None),
        }
    }

    /// Create from environment variables. Returns None if FIREBASE_PROJECT_ID is not set.
    pub fn from_env() -> Option<Self> {
        let project_id = std::env::var("FIREBASE_PROJECT_ID").ok()?;
        let sa_json = std::env::var("FIREBASE_SERVICE_ACCOUNT_JSON").ok()?;

        let sa: serde_json::Value = match serde_json::from_str(&sa_json) {
            Ok(v) => v,
            Err(e) => {
                warn!("Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON: {e}");
                return None;
            }
        };

        let client_email = sa["client_email"].as_str()?.to_string();
        let private_key = sa["private_key"].as_str()?.to_string();

        Some(Self::new(project_id, client_email, private_key))
    }

    async fn get_access_token(&self) -> Result<String, FcmError> {
        {
            let cache = self.token_cache.lock().await;
            if let Some(ref cached) = *cache {
                if cached.expires_at > chrono::Utc::now() + chrono::Duration::minutes(5) {
                    return Ok(cached.access_token.clone());
                }
            }
        }

        let now = chrono::Utc::now();
        let claims = serde_json::json!({
            "iss": self.client_email,
            "scope": "https://www.googleapis.com/auth/firebase.messaging",
            "aud": "https://oauth2.googleapis.com/token",
            "iat": now.timestamp(),
            "exp": (now + chrono::Duration::hours(1)).timestamp(),
        });

        let key = jsonwebtoken::EncodingKey::from_rsa_pem(self.private_key.as_bytes())
            .map_err(|e| FcmError::TokenError(format!("Invalid private key: {e}")))?;

        let header = jsonwebtoken::Header::new(jsonwebtoken::Algorithm::RS256);
        let jwt = jsonwebtoken::encode(&header, &claims, &key)
            .map_err(|e| FcmError::TokenError(format!("JWT encoding failed: {e}")))?;

        let resp = self
            .http_client
            .post("https://oauth2.googleapis.com/token")
            .form(&[
                ("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
                ("assertion", jwt.as_str()),
            ])
            .send()
            .await
            .map_err(|e| FcmError::TokenError(format!("Token exchange failed: {e}")))?;

        if !resp.status().is_success() {
            let body = resp.text().await.unwrap_or_default();
            return Err(FcmError::TokenError(format!(
                "Token exchange error: {body}"
            )));
        }

        let token_resp: TokenResponse = resp
            .json()
            .await
            .map_err(|e| FcmError::TokenError(format!("Token parse failed: {e}")))?;

        let expires_at = now + chrono::Duration::seconds(token_resp.expires_in as i64);

        {
            let mut cache = self.token_cache.lock().await;
            *cache = Some(CachedToken {
                access_token: token_resp.access_token.clone(),
                expires_at,
            });
        }

        Ok(token_resp.access_token)
    }

    /// Send a push notification via FCM HTTP v1 API.
    pub async fn send_push(&self, notification: &PushNotification) -> Result<(), FcmError> {
        if notification.device_token.is_empty() {
            return Err(FcmError::InvalidToken("Empty device token".into()));
        }

        let access_token = self.get_access_token().await?;

        let mut message = serde_json::json!({
            "message": {
                "token": notification.device_token,
                "notification": {
                    "title": notification.title,
                    "body": notification.body,
                },
            }
        });

        if let Some(ref data) = notification.data {
            if let Some(obj) = data.as_object() {
                let string_data: serde_json::Map<String, serde_json::Value> = obj
                    .iter()
                    .map(|(k, v)| {
                        let s = match v {
                            serde_json::Value::String(s) => s.clone(),
                            other => other.to_string(),
                        };
                        (k.clone(), serde_json::Value::String(s))
                    })
                    .collect();
                message["message"]["data"] = serde_json::Value::Object(string_data);
            }
        }

        let url = format!(
            "https://fcm.googleapis.com/v1/projects/{}/messages:send",
            self.project_id
        );

        let resp = self
            .http_client
            .post(&url)
            .bearer_auth(&access_token)
            .json(&message)
            .send()
            .await
            .map_err(|e| FcmError::SendFailed(format!("HTTP error: {e}")))?;

        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            return Err(FcmError::SendFailed(format!(
                "FCM error ({status}): {body}"
            )));
        }

        info!(
            token_prefix = &notification.device_token[..8.min(notification.device_token.len())],
            "Push notification sent"
        );
        Ok(())
    }
}

#[derive(Deserialize)]
struct TokenResponse {
    access_token: String,
    expires_in: u64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_push_notification_creation() {
        let notif = PushNotification {
            device_token: "test_token".into(),
            title: "New order".into(),
            body: "You have a new delivery mission".into(),
            data: None,
        };
        assert_eq!(notif.title, "New order");
        assert_eq!(notif.device_token, "test_token");
    }

    #[test]
    fn test_push_notification_with_data() {
        let data = serde_json::json!({
            "order_id": "abc-123",
            "merchant_name": "Maman Adjoua",
        });
        let notif = PushNotification {
            device_token: "token".into(),
            title: "title".into(),
            body: "body".into(),
            data: Some(data),
        };
        assert_eq!(notif.data.unwrap()["order_id"], "abc-123");
    }

    #[test]
    fn test_fcm_client_creation() {
        let client = FcmClient::new(
            "test-project".into(),
            "test@test.iam.gserviceaccount.com".into(),
            "fake-key".into(),
        );
        assert_eq!(client.project_id, "test-project");
    }

    #[test]
    fn test_fcm_error_display() {
        let err = FcmError::SendFailed("test".into());
        assert_eq!(err.to_string(), "FCM send failed: test");
        let err = FcmError::InvalidToken("bad".into());
        assert_eq!(err.to_string(), "Invalid device token: bad");
    }
}
