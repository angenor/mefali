use actix_web::{http::StatusCode, HttpResponse, ResponseError};
use serde_json::json;

#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Bad request: {0}")]
    BadRequest(String),

    #[error("Bad request: {1}")]
    BadRequestWithCode(&'static str, String),

    #[error("Unauthorized: {0}")]
    Unauthorized(String),

    #[error("Forbidden: {0}")]
    Forbidden(String),

    #[error("Internal error: {0}")]
    InternalError(String),

    #[error("Database error: {0}")]
    DatabaseError(String),

    #[error("External service error: {0}")]
    ExternalServiceError(String),

    #[error("Too many requests: {0}")]
    TooManyRequests(String),

    #[error("Conflict: {0}")]
    Conflict(String),
}

impl AppError {
    fn error_code(&self) -> &'static str {
        match self {
            AppError::NotFound(_) => "NOT_FOUND",
            AppError::BadRequest(_) => "BAD_REQUEST",
            AppError::BadRequestWithCode(code, _) => code,
            AppError::Unauthorized(_) => "UNAUTHORIZED",
            AppError::Forbidden(_) => "FORBIDDEN",
            AppError::InternalError(_) => "INTERNAL_ERROR",
            AppError::DatabaseError(_) => "DATABASE_ERROR",
            AppError::ExternalServiceError(_) => "EXTERNAL_SERVICE_ERROR",
            AppError::TooManyRequests(_) => "TOO_MANY_REQUESTS",
            AppError::Conflict(_) => "CONFLICT",
        }
    }

    fn status_code_value(&self) -> StatusCode {
        match self {
            AppError::NotFound(_) => StatusCode::NOT_FOUND,
            AppError::BadRequest(_) => StatusCode::BAD_REQUEST,
            AppError::BadRequestWithCode(_, _) => StatusCode::BAD_REQUEST,
            AppError::Unauthorized(_) => StatusCode::UNAUTHORIZED,
            AppError::Forbidden(_) => StatusCode::FORBIDDEN,
            AppError::InternalError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::DatabaseError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::ExternalServiceError(_) => StatusCode::BAD_GATEWAY,
            AppError::TooManyRequests(_) => StatusCode::TOO_MANY_REQUESTS,
            AppError::Conflict(_) => StatusCode::CONFLICT,
        }
    }
}

impl ResponseError for AppError {
    fn status_code(&self) -> StatusCode {
        self.status_code_value()
    }

    fn error_response(&self) -> HttpResponse {
        let user_message = match self {
            AppError::InternalError(_)
            | AppError::DatabaseError(_)
            | AppError::ExternalServiceError(_) => "An internal error occurred".to_string(),
            _ => self.to_string(),
        };
        HttpResponse::build(self.status_code_value()).json(json!({
            "error": {
                "code": self.error_code(),
                "message": user_message,
                "details": null
            }
        }))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::body::MessageBody;

    #[test]
    fn test_app_error_status_codes() {
        assert_eq!(
            AppError::NotFound("x".into()).status_code_value(),
            StatusCode::NOT_FOUND
        );
        assert_eq!(
            AppError::BadRequest("x".into()).status_code_value(),
            StatusCode::BAD_REQUEST
        );
        assert_eq!(
            AppError::Unauthorized("x".into()).status_code_value(),
            StatusCode::UNAUTHORIZED
        );
        assert_eq!(
            AppError::Forbidden("x".into()).status_code_value(),
            StatusCode::FORBIDDEN
        );
        assert_eq!(
            AppError::InternalError("x".into()).status_code_value(),
            StatusCode::INTERNAL_SERVER_ERROR
        );
        assert_eq!(
            AppError::DatabaseError("x".into()).status_code_value(),
            StatusCode::INTERNAL_SERVER_ERROR
        );
        assert_eq!(
            AppError::ExternalServiceError("x".into()).status_code_value(),
            StatusCode::BAD_GATEWAY
        );
        assert_eq!(
            AppError::TooManyRequests("x".into()).status_code_value(),
            StatusCode::TOO_MANY_REQUESTS
        );
        assert_eq!(
            AppError::Conflict("x".into()).status_code_value(),
            StatusCode::CONFLICT
        );
    }

    #[test]
    fn test_app_error_response_format() {
        let error = AppError::NotFound("Resource not found".into());
        let response = error.error_response();
        assert_eq!(response.status(), StatusCode::NOT_FOUND);

        let body = response.into_body().try_into_bytes().unwrap();
        let json: serde_json::Value = serde_json::from_slice(&body).unwrap();
        assert_eq!(json["error"]["code"], "NOT_FOUND");
        assert!(json["error"]["message"]
            .as_str()
            .unwrap()
            .contains("Resource not found"));
        assert!(json["error"]["details"].is_null());
    }

    #[test]
    fn test_app_error_display() {
        let error = AppError::BadRequest("invalid input".into());
        assert_eq!(error.to_string(), "Bad request: invalid input");
    }
}
