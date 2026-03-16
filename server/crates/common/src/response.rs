use serde::Serialize;

/// Standard API success response wrapper
#[derive(Debug, Serialize)]
pub struct ApiResponse<T: Serialize> {
    pub data: T,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub meta: Option<PaginationMeta>,
}

impl<T: Serialize> ApiResponse<T> {
    pub fn new(data: T) -> Self {
        Self { data, meta: None }
    }

    pub fn with_pagination(data: T, page: i64, per_page: i64, total: i64) -> Self {
        Self {
            data,
            meta: Some(PaginationMeta {
                page,
                per_page,
                total,
            }),
        }
    }
}

/// Pagination metadata
#[derive(Debug, Serialize)]
pub struct PaginationMeta {
    pub page: i64,
    pub per_page: i64,
    pub total: i64,
}

/// Standard API error response wrapper
#[derive(Debug, Serialize)]
pub struct ApiErrorResponse {
    pub error: ApiErrorDetail,
}

/// Error detail structure
#[derive(Debug, Serialize)]
pub struct ApiErrorDetail {
    pub code: String,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<serde_json::Value>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_api_response_serialization() {
        let response = ApiResponse::new("hello");
        let json = serde_json::to_value(&response).unwrap();
        assert_eq!(json["data"], "hello");
        assert!(json.get("meta").is_none());
    }

    #[test]
    fn test_api_response_with_pagination() {
        let response = ApiResponse::with_pagination(vec![1, 2, 3], 1, 20, 42);
        let json = serde_json::to_value(&response).unwrap();
        assert_eq!(json["meta"]["page"], 1);
        assert_eq!(json["meta"]["per_page"], 20);
        assert_eq!(json["meta"]["total"], 42);
    }

    #[test]
    fn test_api_error_response_serialization() {
        let error = ApiErrorResponse {
            error: ApiErrorDetail {
                code: "NOT_FOUND".into(),
                message: "Resource not found".into(),
                details: None,
            },
        };
        let json = serde_json::to_value(&error).unwrap();
        assert_eq!(json["error"]["code"], "NOT_FOUND");
        assert!(json["error"].get("details").is_none());
    }

    #[test]
    fn test_api_error_with_details() {
        let error = ApiErrorResponse {
            error: ApiErrorDetail {
                code: "VALIDATION_ERROR".into(),
                message: "Invalid input".into(),
                details: Some(serde_json::json!({"field": "email"})),
            },
        };
        let json = serde_json::to_value(&error).unwrap();
        assert_eq!(json["error"]["details"]["field"], "email");
    }
}
