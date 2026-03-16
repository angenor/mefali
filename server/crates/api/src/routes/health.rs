use actix_web::HttpResponse;
use common::response::ApiResponse;

/// Health check endpoint — returns 200 with service status.
pub async fn health_check() -> HttpResponse {
    let response = ApiResponse::new(serde_json::json!({
        "status": "ok",
        "service": "mefali-api",
        "version": env!("CARGO_PKG_VERSION"),
    }));
    HttpResponse::Ok().json(response)
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{test, web, App};

    #[actix_web::test]
    async fn test_health_check_returns_200() {
        let app =
            test::init_service(App::new().route("/api/v1/health", web::get().to(health_check)))
                .await;

        let req = test::TestRequest::get().uri("/api/v1/health").to_request();
        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["status"], "ok");
        assert_eq!(body["data"]["service"], "mefali-api");
    }
}
