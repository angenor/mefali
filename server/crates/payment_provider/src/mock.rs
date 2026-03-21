use async_trait::async_trait;

use crate::provider::{
    PaymentError, PaymentProvider, PaymentRequest, PaymentResponse, PaymentStatus,
    WithdrawalRequest, WithdrawalResponse,
};

/// Mock behavior for testing different payment scenarios.
#[derive(Debug, Clone, PartialEq)]
pub enum MockBehavior {
    Success,
    Failure,
    Timeout,
}

/// Mock payment provider for testing.
pub struct MockPaymentProvider {
    pub should_fail: bool,
    pub behavior: MockBehavior,
    pub verify_status: PaymentStatus,
}

impl MockPaymentProvider {
    pub fn new() -> Self {
        Self {
            should_fail: false,
            behavior: MockBehavior::Success,
            verify_status: PaymentStatus::Completed,
        }
    }

    pub fn failing() -> Self {
        Self {
            should_fail: true,
            behavior: MockBehavior::Failure,
            verify_status: PaymentStatus::Failed,
        }
    }

    pub fn with_timeout() -> Self {
        Self {
            should_fail: true,
            behavior: MockBehavior::Timeout,
            verify_status: PaymentStatus::Pending,
        }
    }

    pub fn with_verify_status(mut self, status: PaymentStatus) -> Self {
        self.verify_status = status;
        self
    }
}

impl Default for MockPaymentProvider {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl PaymentProvider for MockPaymentProvider {
    async fn initiate_payment(
        &self,
        request: PaymentRequest,
    ) -> Result<PaymentResponse, PaymentError> {
        match self.behavior {
            MockBehavior::Success => Ok(PaymentResponse {
                transaction_id: request.order_id.to_string(),
                payment_url: Some("https://mock-payment.test/pay".into()),
                status: PaymentStatus::Pending,
            }),
            MockBehavior::Failure => Err(PaymentError::InitiationFailed("Mock failure".into())),
            MockBehavior::Timeout => Err(PaymentError::NetworkError("Mock timeout (>3s)".into())),
        }
    }

    async fn verify_payment(&self, _transaction_id: &str) -> Result<PaymentStatus, PaymentError> {
        if self.should_fail && self.behavior == MockBehavior::Timeout {
            return Err(PaymentError::NetworkError("Mock timeout".into()));
        }
        if self.should_fail {
            return Err(PaymentError::VerificationFailed("Mock failure".into()));
        }
        Ok(self.verify_status.clone())
    }

    async fn initiate_withdrawal(
        &self,
        _request: WithdrawalRequest,
    ) -> Result<WithdrawalResponse, PaymentError> {
        if self.should_fail {
            return Err(PaymentError::WithdrawalFailed("Mock failure".into()));
        }
        Ok(WithdrawalResponse {
            transaction_id: "mock_withdraw_001".into(),
            status: PaymentStatus::Completed,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use common::types::Id;

    #[tokio::test]
    async fn test_mock_payment_success() {
        let provider = MockPaymentProvider::new();
        let order_id = Id::new_v4();
        let request = PaymentRequest {
            order_id,
            amount: 5000,
            currency: "XOF".into(),
            customer_phone: "+2250700000000".into(),
            description: "Test payment".into(),
        };
        let result = provider.initiate_payment(request).await;
        assert!(result.is_ok());
        let response = result.unwrap();
        assert_eq!(response.status, PaymentStatus::Pending);
        assert_eq!(response.transaction_id, order_id.to_string());
        assert!(response.payment_url.is_some());
    }

    #[tokio::test]
    async fn test_mock_payment_failure() {
        let provider = MockPaymentProvider::failing();
        let request = PaymentRequest {
            order_id: Id::new_v4(),
            amount: 5000,
            currency: "XOF".into(),
            customer_phone: "+2250700000000".into(),
            description: "Test payment".into(),
        };
        let result = provider.initiate_payment(request).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            PaymentError::InitiationFailed(_) => {}
            other => panic!("Expected InitiationFailed, got: {other:?}"),
        }
    }

    #[tokio::test]
    async fn test_mock_payment_timeout() {
        let provider = MockPaymentProvider::with_timeout();
        let request = PaymentRequest {
            order_id: Id::new_v4(),
            amount: 5000,
            currency: "XOF".into(),
            customer_phone: "+2250700000000".into(),
            description: "Test payment".into(),
        };
        let result = provider.initiate_payment(request).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            PaymentError::NetworkError(_) => {}
            other => panic!("Expected NetworkError, got: {other:?}"),
        }
    }

    #[tokio::test]
    async fn test_mock_verify_payment_completed() {
        let provider = MockPaymentProvider::new();
        let result = provider.verify_payment("txn_001").await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), PaymentStatus::Completed);
    }

    #[tokio::test]
    async fn test_mock_verify_payment_custom_status() {
        let provider = MockPaymentProvider::new().with_verify_status(PaymentStatus::Pending);
        let result = provider.verify_payment("txn_001").await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), PaymentStatus::Pending);
    }

    #[tokio::test]
    async fn test_mock_withdrawal_success() {
        let provider = MockPaymentProvider::new();
        let request = WithdrawalRequest {
            user_id: Id::new_v4(),
            amount: 10000,
            currency: "XOF".into(),
            destination_phone: "+2250700000000".into(),
        };
        let result = provider.initiate_withdrawal(request).await;
        assert!(result.is_ok());
        let resp = result.unwrap();
        assert_eq!(resp.status, PaymentStatus::Completed);
    }

    #[tokio::test]
    async fn test_verify_payment_batch_success() {
        let provider = MockPaymentProvider::new();
        let ids = vec!["txn_001".into(), "txn_002".into(), "txn_003".into()];
        let results = provider.verify_payment_batch(&ids).await.unwrap();
        assert_eq!(results.len(), 3);
        for (id, status) in &results {
            assert_eq!(*status, PaymentStatus::Completed);
            assert!(ids.contains(id));
        }
    }

    #[tokio::test]
    async fn test_verify_payment_batch_with_failure() {
        let provider = MockPaymentProvider::failing();
        let ids = vec!["txn_001".into()];
        let result = provider.verify_payment_batch(&ids).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_verify_payment_batch_empty() {
        let provider = MockPaymentProvider::new();
        let ids: Vec<String> = vec![];
        let results = provider.verify_payment_batch(&ids).await.unwrap();
        assert!(results.is_empty());
    }

    #[tokio::test]
    async fn test_mock_withdrawal_failure() {
        let provider = MockPaymentProvider::failing();
        let request = WithdrawalRequest {
            user_id: Id::new_v4(),
            amount: 10000,
            currency: "XOF".into(),
            destination_phone: "+2250700000000".into(),
        };
        let result = provider.initiate_withdrawal(request).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            PaymentError::WithdrawalFailed(_) => {}
            other => panic!("Expected WithdrawalFailed, got: {other:?}"),
        }
    }
}
