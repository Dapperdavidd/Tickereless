#![forbid(unsafe_code)]

use actix_web::{HttpResponse, Responder, web};
use serde::Serialize;

#[derive(Debug, Serialize)]
struct HealthResponse {
    status: &'static str,
    service: &'static str,
}

async fn health() -> impl Responder {
    HttpResponse::Ok().json(HealthResponse {
        status: "ok",
        service: "tickerless-api",
    })
}

pub fn configure_app(config: &mut web::ServiceConfig) {
    config.route("/health", web::get().to(health));
}

#[cfg(test)]
mod tests {
    use actix_web::{App, http::StatusCode, test};

    use super::configure_app;

    #[actix_web::test]
    async fn health_endpoint_reports_service_status() {
        let app = test::init_service(App::new().configure(configure_app)).await;
        let request = test::TestRequest::get().uri("/health").to_request();
        let response = test::call_service(&app, request).await;

        assert_eq!(response.status(), StatusCode::OK);
        assert_eq!(
            test::read_body(response).await.as_ref(),
            br#"{"status":"ok","service":"tickerless-api"}"#
        );
    }
}
