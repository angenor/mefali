use async_trait::async_trait;
use thiserror::Error;
use tracing::{info, warn};

#[derive(Debug, Error)]
pub enum SmsError {
    #[error("SMS send failed: {0}")]
    SendFailed(String),

    #[error("Invalid phone number: {0}")]
    InvalidPhone(String),

    #[error("All providers failed")]
    AllProvidersFailed,
}

#[derive(Debug, Clone)]
pub struct SmsResult {
    pub message_id: String,
    pub provider_used: String,
}

/// Abstract SMS provider trait — dual-provider with fallback.
#[async_trait]
pub trait SmsProvider: Send + Sync {
    fn provider_name(&self) -> &str;
    async fn send_sms(&self, to: &str, message: &str) -> Result<SmsResult, SmsError>;
}

/// SMS router that tries the primary provider first, then falls back to secondary.
pub struct SmsRouter {
    primary: Box<dyn SmsProvider>,
    fallback: Box<dyn SmsProvider>,
}

impl SmsRouter {
    pub fn new(primary: Box<dyn SmsProvider>, fallback: Box<dyn SmsProvider>) -> Self {
        Self { primary, fallback }
    }

    pub async fn send(&self, to: &str, message: &str) -> Result<SmsResult, SmsError> {
        match self.primary.send_sms(to, message).await {
            Ok(result) => {
                info!(
                    provider = self.primary.provider_name(),
                    to = to,
                    "SMS sent successfully via primary provider"
                );
                Ok(result)
            }
            Err(primary_err) => {
                warn!(
                    provider = self.primary.provider_name(),
                    error = %primary_err,
                    "Primary SMS provider failed, trying fallback"
                );
                match self.fallback.send_sms(to, message).await {
                    Ok(result) => {
                        info!(
                            provider = self.fallback.provider_name(),
                            to = to,
                            "SMS sent successfully via fallback provider"
                        );
                        Ok(result)
                    }
                    Err(fallback_err) => {
                        warn!(
                            fallback_provider = self.fallback.provider_name(),
                            error = %fallback_err,
                            "Fallback SMS provider also failed"
                        );
                        Err(SmsError::AllProvidersFailed)
                    }
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    struct MockSmsProvider {
        name: String,
        should_fail: bool,
    }

    #[async_trait]
    impl SmsProvider for MockSmsProvider {
        fn provider_name(&self) -> &str {
            &self.name
        }

        async fn send_sms(&self, _to: &str, _message: &str) -> Result<SmsResult, SmsError> {
            if self.should_fail {
                return Err(SmsError::SendFailed(format!("{} failed", self.name)));
            }
            Ok(SmsResult {
                message_id: format!("{}_msg_001", self.name),
                provider_used: self.name.clone(),
            })
        }
    }

    #[tokio::test]
    async fn test_sms_router_primary_success() {
        let router = SmsRouter::new(
            Box::new(MockSmsProvider {
                name: "primary".into(),
                should_fail: false,
            }),
            Box::new(MockSmsProvider {
                name: "fallback".into(),
                should_fail: false,
            }),
        );
        let result = router.send("+2250700000000", "Test").await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap().provider_used, "primary");
    }

    #[tokio::test]
    async fn test_sms_router_fallback_on_primary_failure() {
        let router = SmsRouter::new(
            Box::new(MockSmsProvider {
                name: "primary".into(),
                should_fail: true,
            }),
            Box::new(MockSmsProvider {
                name: "fallback".into(),
                should_fail: false,
            }),
        );
        let result = router.send("+2250700000000", "Test").await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap().provider_used, "fallback");
    }

    #[tokio::test]
    async fn test_sms_router_all_fail() {
        let router = SmsRouter::new(
            Box::new(MockSmsProvider {
                name: "primary".into(),
                should_fail: true,
            }),
            Box::new(MockSmsProvider {
                name: "fallback".into(),
                should_fail: true,
            }),
        );
        let result = router.send("+2250700000000", "Test").await;
        assert!(result.is_err());
    }
}
