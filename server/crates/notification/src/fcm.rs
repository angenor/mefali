use serde::Serialize;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum FcmError {
    #[error("FCM send failed: {0}")]
    SendFailed(String),

    #[error("Invalid device token: {0}")]
    InvalidToken(String),
}

/// Push notification payload
#[derive(Debug, Clone, Serialize)]
pub struct PushNotification {
    pub device_token: String,
    pub title: String,
    pub body: String,
    pub data: Option<serde_json::Value>,
}

/// Send a push notification via FCM.
/// Implementation will be added in Epic 5.
pub async fn send_push(_notification: &PushNotification) -> Result<(), FcmError> {
    // FCM integration will be implemented in Story 5-1
    Err(FcmError::SendFailed(
        "FCM integration not yet implemented".into(),
    ))
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
    }
}
