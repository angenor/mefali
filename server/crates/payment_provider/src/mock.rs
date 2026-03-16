use async_trait::async_trait;

use crate::provider::{
    PaymentError, PaymentProvider, PaymentRequest, PaymentResponse, PaymentStatus,
    WithdrawalRequest, WithdrawalResponse,
};

/// Mock payment provider for testing.
pub struct MockPaymentProvider {
    pub should_fail: bool,
}

impl MockPaymentProvider {
    pub fn new() -> Self {
        Self { should_fail: false }
    }

    pub fn failing() -> Self {
        Self { should_fail: true }
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
        _request: PaymentRequest,
    ) -> Result<PaymentResponse, PaymentError> {
        if self.should_fail {
            return Err(PaymentError::InitiationFailed("Mock failure".into()));
        }
        Ok(PaymentResponse {
            transaction_id: "mock_txn_001".into(),
            payment_url: Some("https://mock-payment.test/pay".into()),
            status: PaymentStatus::Pending,
        })
    }

    async fn verify_payment(&self, _transaction_id: &str) -> Result<PaymentStatus, PaymentError> {
        if self.should_fail {
            return Err(PaymentError::VerificationFailed("Mock failure".into()));
        }
        Ok(PaymentStatus::Completed)
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
        let request = PaymentRequest {
            order_id: Id::new_v4(),
            amount: 5000,
            currency: "XOF".into(),
            customer_phone: "+2250700000000".into(),
            description: "Test payment".into(),
        };
        let result = provider.initiate_payment(request).await;
        assert!(result.is_ok());
        let response = result.unwrap();
        assert_eq!(response.status, PaymentStatus::Pending);
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
    }

    #[tokio::test]
    async fn test_mock_verify_payment() {
        let provider = MockPaymentProvider::new();
        let result = provider.verify_payment("txn_001").await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), PaymentStatus::Completed);
    }

    #[tokio::test]
    async fn test_mock_withdrawal() {
        let provider = MockPaymentProvider::new();
        let request = WithdrawalRequest {
            user_id: Id::new_v4(),
            amount: 10000,
            currency: "XOF".into(),
            destination_phone: "+2250700000000".into(),
        };
        let result = provider.initiate_withdrawal(request).await;
        assert!(result.is_ok());
    }
}
