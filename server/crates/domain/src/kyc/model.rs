use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

use crate::users::model::User;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct KycDocument {
    pub id: Id,
    pub user_id: Id,
    pub document_type: KycDocumentType,
    pub encrypted_path: String,
    pub verified_by: Option<Id>,
    pub status: KycStatus,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "kyc_document_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum KycDocumentType {
    Cni,
    Permis,
}

impl std::fmt::Display for KycDocumentType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            KycDocumentType::Cni => write!(f, "cni"),
            KycDocumentType::Permis => write!(f, "permis"),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "kyc_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum KycStatus {
    Pending,
    Verified,
    Rejected,
}

impl std::fmt::Display for KycStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            KycStatus::Pending => write!(f, "pending"),
            KycStatus::Verified => write!(f, "verified"),
            KycStatus::Rejected => write!(f, "rejected"),
        }
    }
}

#[derive(Debug, Deserialize)]
pub struct UploadKycPayload {
    pub document_type: KycDocumentType,
}

#[derive(Debug, Serialize)]
pub struct KycSummary {
    pub user: User,
    pub documents: Vec<KycDocument>,
    pub sponsor: Option<User>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_kyc_document_type_display() {
        assert_eq!(KycDocumentType::Cni.to_string(), "cni");
        assert_eq!(KycDocumentType::Permis.to_string(), "permis");
    }

    #[test]
    fn test_kyc_document_type_serde() {
        let json = serde_json::to_string(&KycDocumentType::Cni).unwrap();
        assert_eq!(json, "\"cni\"");
        let parsed: KycDocumentType = serde_json::from_str("\"permis\"").unwrap();
        assert_eq!(parsed, KycDocumentType::Permis);
    }

    #[test]
    fn test_kyc_status_display() {
        assert_eq!(KycStatus::Pending.to_string(), "pending");
        assert_eq!(KycStatus::Verified.to_string(), "verified");
        assert_eq!(KycStatus::Rejected.to_string(), "rejected");
    }

    #[test]
    fn test_kyc_status_serde() {
        let json = serde_json::to_string(&KycStatus::Pending).unwrap();
        assert_eq!(json, "\"pending\"");
        let parsed: KycStatus = serde_json::from_str("\"verified\"").unwrap();
        assert_eq!(parsed, KycStatus::Verified);
    }

    #[test]
    fn test_upload_kyc_payload_deserialize() {
        let json = r#"{"document_type": "cni"}"#;
        let payload: UploadKycPayload = serde_json::from_str(json).unwrap();
        assert_eq!(payload.document_type, KycDocumentType::Cni);
    }

    #[test]
    fn test_upload_kyc_payload_permis() {
        let json = r#"{"document_type": "permis"}"#;
        let payload: UploadKycPayload = serde_json::from_str(json).unwrap();
        assert_eq!(payload.document_type, KycDocumentType::Permis);
    }

    #[test]
    fn test_upload_kyc_payload_invalid() {
        let json = r#"{"document_type": "passport"}"#;
        let result = serde_json::from_str::<UploadKycPayload>(json);
        assert!(result.is_err());
    }
}
