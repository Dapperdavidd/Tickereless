#![forbid(unsafe_code)]

pub mod catalog;
pub mod database;
mod models;

use actix_web::{HttpResponse, Responder, web};
use catalog::CompanyCatalog;
use models::{ApiError, HealthResponse, SearchRequest};
use sqlx::PgPool;

pub struct AppState {
    catalog: CompanyCatalog,
    pool: PgPool,
}

impl AppState {
    pub fn new(catalog: CompanyCatalog, pool: PgPool) -> Self {
        Self { catalog, pool }
    }
}

async fn health() -> impl Responder {
    HttpResponse::Ok().json(HealthResponse {
        status: "ok",
        service: "tickerless-api",
    })
}

async fn readiness(state: web::Data<AppState>) -> impl Responder {
    match sqlx::query_scalar::<_, i32>("SELECT 1")
        .fetch_one(&state.pool)
        .await
    {
        Ok(_) => HttpResponse::Ok().json(HealthResponse {
            status: "ready",
            service: "tickerless-api",
        }),
        Err(_) => HttpResponse::ServiceUnavailable().json(ApiError::new(
            "database_unavailable",
            "database is unavailable",
        )),
    }
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
    config
        .route("/health", web::get().to(health))
        .route("/ready", web::get().to(readiness))
        .service(
            web::scope("/v1")
                .route("/resolve/search", web::post().to(resolve_search))
                .route("/companies/{slug}", web::get().to(get_company)),
        );
}

#[cfg(test)]
mod tests {
    use super::{AppState, configure_app};
    use actix_web::{App, http::StatusCode, test, web};
    use sqlx::postgres::PgPoolOptions;

    fn test_state() -> AppState {
        let pool = PgPoolOptions::new()
            .connect_lazy("postgres://tickerless:tickerless@127.0.0.1/tickerless")
            .expect("test database URL must be valid");
        AppState::new(crate::catalog::CompanyCatalog::seeded(), pool)
    }

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
                .app_data(web::Data::new(test_state()))
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
                .app_data(web::Data::new(test_state()))
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
