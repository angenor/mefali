use async_trait::async_trait;
use tracing::info;

use super::{SmsProvider, SmsResult};

/// Development SMS provider that logs OTP codes instead of sending real SMS.
pub struct DevSmsProvider;

#[async_trait]
impl SmsProvider for DevSmsProvider {
    fn provider_name(&self) -> &str {
        "dev-console"
    }

    async fn send_sms(&self, to: &str, message: &str) -> Result<SmsResult, super::SmsError> {
        info!(
            provider = "dev-console",
            to = to,
            message = message,
            "DEV SMS (not actually sent)"
        );
        Ok(SmsResult {
            message_id: format!("dev_{}", uuid::Uuid::new_v4()),
            provider_used: "dev-console".into(),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_dev_sms_provider_sends_successfully() {
        let provider = DevSmsProvider;
        let result = provider
            .send_sms("+2250700000000", "Your OTP is 123456")
            .await;
        assert!(result.is_ok());
        let result = result.unwrap();
        assert_eq!(result.provider_used, "dev-console");
        assert!(result.message_id.starts_with("dev_"));
    }
}
