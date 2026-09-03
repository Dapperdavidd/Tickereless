#![forbid(unsafe_code)]

pub mod catalog;
pub mod database;
mod lens;
mod link;
mod models;

use actix_web::{HttpResponse, Responder, web};
use catalog::CompanyCatalog;
use models::{
    ApiError, CreateDiscoveryRequest, DiscoveryHistoryQuery, HealthResponse, LensRequest,
    LinkRequest, OwnershipQuote, OwnershipQuoteQuery, SearchRequest,
};
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

async fn resolve_link(state: web::Data<AppState>, body: web::Json<LinkRequest>) -> impl Responder {
    match link::resolve(&state.catalog, &body.url).await {
        Ok(resolution) => HttpResponse::Ok().json(resolution),
        Err(link::LinkError::InvalidUrl) => HttpResponse::BadRequest().json(ApiError::new(
            "invalid_url",
            "a valid HTTP or HTTPS URL is required",
        )),
        Err(link::LinkError::UnsafeTarget) => HttpResponse::BadRequest().json(ApiError::new(
            "unsafe_url",
            "local and private-network URLs are not allowed",
        )),
        Err(link::LinkError::RedirectNotAllowed) => HttpResponse::UnprocessableEntity().json(
            ApiError::new("redirect_not_allowed", "redirecting URLs are not supported"),
        ),
        Err(link::LinkError::UnsupportedContent) => HttpResponse::UnsupportedMediaType().json(
            ApiError::new("unsupported_content", "URL must return HTML or plain text"),
        ),
        Err(link::LinkError::PageTooLarge) => HttpResponse::PayloadTooLarge().json(ApiError::new(
            "page_too_large",
            "page exceeds the one megabyte limit",
        )),
        Err(link::LinkError::FetchFailed) => HttpResponse::BadGateway()
            .json(ApiError::new("fetch_failed", "could not retrieve the URL")),
    }
}

async fn resolve_lens(state: web::Data<AppState>, body: web::Json<LensRequest>) -> impl Responder {
    match lens::resolve(&state.catalog, body.into_inner()) {
        Ok(resolution) => HttpResponse::Ok().json(resolution),
        Err(lens::LensError::EmptyInput) => HttpResponse::BadRequest().json(ApiError::new(
            "empty_lens_input",
            "OCR text or at least one recognition label is required",
        )),
        Err(lens::LensError::InputTooLarge) => HttpResponse::PayloadTooLarge().json(ApiError::new(
            "lens_input_too_large",
            "recognition input exceeds the supported limit",
        )),
    }
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

async fn ownership_quote(
    state: web::Data<AppState>,
    slug: web::Path<String>,
    query: web::Query<OwnershipQuoteQuery>,
) -> impl Responder {
    let amount = query.amount_usdc;
    if amount <= rust_decimal::Decimal::ZERO || amount > rust_decimal::Decimal::new(10_000, 0) {
        return HttpResponse::BadRequest().json(ApiError::new(
            "invalid_amount",
            "amount_usdc must be greater than zero and no more than 10000",
        ));
    }
    let Some(company) = state.catalog.find_by_slug(&slug) else {
        return HttpResponse::NotFound().json(ApiError::new(
            "company_not_found",
            "company does not exist in the registry",
        ));
    };
    let Some(asset) = company.asset.as_ref() else {
        return HttpResponse::Conflict().json(ApiError::new(
            "asset_unavailable",
            "company does not have a supported tokenized asset",
        ));
    };
    let quote = OwnershipQuote {
        company_slug: &company.slug,
        company_name: &company.name,
        asset_symbol: &asset.symbol,
        network: &asset.network,
        amount_usdc: amount,
        estimated_token_amount: (amount / asset.price_usdc).round_dp(18),
        contract_address: asset.contract_address.as_deref(),
        market_address: asset.market_address.as_deref(),
        executable: asset.contract_address.is_some() && asset.market_address.is_some(),
    };
    HttpResponse::Ok().json(quote)
}

async fn create_discovery(
    state: web::Data<AppState>,
    body: web::Json<CreateDiscoveryRequest>,
) -> impl Responder {
    let mut input = body.into_inner();
    input.company_slug = input.company_slug.trim().to_ascii_lowercase();
    input.source = input.source.trim().to_owned();
    input.explanation = input.explanation.trim().to_owned();
    input.wallet_address = input
        .wallet_address
        .map(|wallet| wallet.trim().to_ascii_lowercase());
    if input.company_slug.is_empty() || input.source.is_empty() || input.explanation.is_empty() {
        return HttpResponse::BadRequest().json(ApiError::new(
            "invalid_discovery",
            "company_slug, source, and explanation must not be empty",
        ));
    }
    if input
        .wallet_address
        .as_deref()
        .is_some_and(|wallet| !valid_wallet(wallet))
    {
        return HttpResponse::BadRequest().json(ApiError::new(
            "invalid_wallet",
            "wallet_address must be a 20-byte hexadecimal address",
        ));
    }
    match database::create_discovery(&state.pool, &input).await {
        Ok(discovery) => HttpResponse::Created().json(discovery),
        Err(database::CreateDiscoveryError::CompanyNotFound) => {
            HttpResponse::NotFound().json(ApiError::new(
                "company_not_found",
                "company does not exist in the registry",
            ))
        }
        Err(database::CreateDiscoveryError::Database(error)) => {
            tracing::error!(%error, "failed to create discovery");
            HttpResponse::InternalServerError()
                .json(ApiError::new("database_error", "could not save discovery"))
        }
    }
}

async fn discovery_history(
    state: web::Data<AppState>,
    query: web::Query<DiscoveryHistoryQuery>,
) -> impl Responder {
    let wallet = query.wallet_address.trim().to_ascii_lowercase();
    if !valid_wallet(&wallet) {
        return HttpResponse::BadRequest().json(ApiError::new(
            "invalid_wallet",
            "wallet_address must be a 20-byte hexadecimal address",
        ));
    }
    let limit = query.limit.unwrap_or(50).clamp(1, 100);
    match database::discovery_history(&state.pool, &wallet, limit).await {
        Ok(discoveries) => HttpResponse::Ok().json(discoveries),
        Err(error) => {
            tracing::error!(%error, "failed to load discovery history");
            HttpResponse::InternalServerError().json(ApiError::new(
                "database_error",
                "could not load discoveries",
            ))
        }
    }
}

fn valid_wallet(value: &str) -> bool {
    value.len() == 42
        && value.starts_with("0x")
        && value[2..].bytes().all(|byte| byte.is_ascii_hexdigit())
}

pub fn configure_app(config: &mut web::ServiceConfig) {
    config
        .route("/health", web::get().to(health))
        .route("/ready", web::get().to(readiness))
        .service(
            web::scope("/v1")
                .route("/resolve/search", web::post().to(resolve_search))
                .route("/resolve/link", web::post().to(resolve_link))
                .route("/resolve/image", web::post().to(resolve_lens))
                .route("/companies/{slug}", web::get().to(get_company))
                .route("/companies/{slug}/quote", web::get().to(ownership_quote))
                .route("/discoveries", web::post().to(create_discovery))
                .route("/discoveries", web::get().to(discovery_history)),
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

    #[actix_web::test]
    async fn link_resolver_rejects_local_targets() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(test_state()))
                .configure(configure_app),
        )
        .await;
        let request = test::TestRequest::post()
            .uri("/v1/resolve/link")
            .set_json(serde_json::json!({"url": "http://localhost/private"}))
            .to_request();
        let response = test::call_service(&app, request).await;
        assert_eq!(response.status(), 400);
        let body: serde_json::Value = test::read_body_json(response).await;
        assert_eq!(body["code"], "unsafe_url");
    }

    #[actix_web::test]
    async fn lens_endpoint_resolves_product_text() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(test_state()))
                .configure(configure_app),
        )
        .await;
        let request = test::TestRequest::post()
            .uri("/v1/resolve/image")
            .set_json(serde_json::json!({"text": "GeForce RTX", "labels": ["GPU"]}))
            .to_request();
        let response = test::call_service(&app, request).await;
        assert_eq!(response.status(), 200);
        let body: serde_json::Value = test::read_body_json(response).await;
        assert_eq!(body["matches"][0]["company"]["slug"], "nvidia");
        assert_eq!(body["matches"][0]["role"], "primary");
    }

    #[actix_web::test]
    async fn quote_uses_exact_decimal_pricing() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(test_state()))
                .configure(configure_app),
        )
        .await;
        let request = test::TestRequest::get()
            .uri("/v1/companies/nvidia/quote?amount_usdc=9")
            .to_request();
        let response = test::call_service(&app, request).await;
        assert_eq!(response.status(), 200);
        let body: serde_json::Value = test::read_body_json(response).await;
        assert_eq!(body["estimated_token_amount"], "0.05");
        assert_eq!(body["executable"], false);
    }

    #[actix_web::test]
    async fn invalid_discovery_is_rejected_before_database_access() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(test_state()))
                .configure(configure_app),
        )
        .await;
        let request = test::TestRequest::post()
            .uri("/v1/discoveries")
            .set_json(serde_json::json!({
                "company_slug": "meta", "method": "search", "source": "",
                "explanation": "resolved from Instagram", "wallet_address": "0x1234"
            }))
            .to_request();
        assert_eq!(test::call_service(&app, request).await.status(), 400);
    }

    #[actix_web::test]
    async fn validates_ethereum_wallet_shape() {
        assert!(super::valid_wallet(
            "0x0000000000000000000000000000000000000001"
        ));
        assert!(!super::valid_wallet("0x1234"));
        assert!(!super::valid_wallet(
            "0xzz00000000000000000000000000000000000000"
        ));
    }
}
