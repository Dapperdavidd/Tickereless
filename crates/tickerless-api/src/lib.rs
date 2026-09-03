#![forbid(unsafe_code)]

mod catalog;
mod models;

use actix_web::{HttpResponse, Responder, web};
use catalog::CompanyCatalog;
use models::{ApiError, HealthResponse, SearchRequest};

pub struct AppState {
    catalog: CompanyCatalog,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            catalog: CompanyCatalog::seeded(),
        }
    }
}

async fn health() -> impl Responder {
    HttpResponse::Ok().json(HealthResponse {
        status: "ok",
        service: "tickerless-api",
    })
}

async fn resolve_search(
    state: web::Data<AppState>,
    body: web::Json<SearchRequest>,
) -> impl Responder {
    let query = body.query.trim();
    if query.is_empty() {
        return HttpResponse::BadRequest()
            .json(ApiError::new("invalid_query", "query must not be empty"));
    }
    HttpResponse::Ok().json(state.catalog.search(query))
}

async fn get_company(state: web::Data<AppState>, slug: web::Path<String>) -> impl Responder {
    match state.catalog.find_by_slug(&slug) {
        Some(company) => HttpResponse::Ok().json(company),
        None => HttpResponse::NotFound().json(ApiError::new(
            "company_not_found",
            "company does not exist in the registry",
        )),
    }
}

pub fn configure_app(config: &mut web::ServiceConfig) {
    config.route("/health", web::get().to(health)).service(
        web::scope("/v1")
            .route("/resolve/search", web::post().to(resolve_search))
            .route("/companies/{slug}", web::get().to(get_company)),
    );
}

#[cfg(test)]
mod tests {
    use super::{AppState, configure_app};
    use actix_web::{App, http::StatusCode, test, web};

    #[actix_web::test]
    async fn health_works() {
        let app = test::init_service(App::new().configure(configure_app)).await;
        let response =
            test::call_service(&app, test::TestRequest::get().uri("/health").to_request()).await;
        assert_eq!(response.status(), StatusCode::OK);
    }

    #[actix_web::test]
    async fn search_resolves_instagram() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(AppState::default()))
                .configure(configure_app),
        )
        .await;
        let request = test::TestRequest::post()
            .uri("/v1/resolve/search")
            .set_json(serde_json::json!({"query": "who owns Instagram?"}))
            .to_request();
        let response = test::call_service(&app, request).await;
        assert_eq!(response.status(), StatusCode::OK);
        let body: serde_json::Value = test::read_body_json(response).await;
        assert_eq!(body["matches"][0]["company"]["slug"], "meta");
        assert_eq!(body["matches"][0]["asset"]["symbol"], "tMETAc");
    }

    #[actix_web::test]
    async fn blank_search_is_rejected() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(AppState::default()))
                .configure(configure_app),
        )
        .await;
        let request = test::TestRequest::post()
            .uri("/v1/resolve/search")
            .set_json(serde_json::json!({"query": "  "}))
            .to_request();
        assert_eq!(test::call_service(&app, request).await.status(), 400);
    }
}
