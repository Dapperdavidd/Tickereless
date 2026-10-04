#![forbid(unsafe_code)]

mod auth;
pub mod catalog;
pub mod chain;
pub mod database;
pub mod google;
mod lens;
mod link;
mod models;
pub mod xstocks;

use actix_web::{HttpRequest, HttpResponse, Responder, error, error::JsonPayloadError, web};
use catalog::CompanyCatalog;
use models::{
    ApiError, AuthResponse, BindWalletRequest, CreateDiscoveryRequest, DiscoveryHistoryQuery,
    EmailCredentials, GoogleCredential, HealthResponse, LensRequest, LinkRequest, OwnershipQuote,
    OwnershipQuoteQuery, SearchRequest, SubmitTransactionRequest, WorldQuery,
};
use sqlx::PgPool;

const JSON_BODY_LIMIT: usize = 64 * 1024;

async fn issue_session(
    state: &AppState,
    user: models::AuthUser,
) -> Result<AuthResponse, HttpResponse> {
    let (token, token_hash) = auth::new_session_token();
    database::create_session(&state.pool, user.id, &token_hash)
        .await
        .map_err(|error| {
            tracing::error!(%error, "failed to create auth session");
            HttpResponse::InternalServerError()
                .json(ApiError::new("database_error", "could not create session"))
        })?;
    Ok(AuthResponse {
        access_token: token,
        token_type: "Bearer",
        expires_in: auth::SESSION_TTL_DAYS * 24 * 60 * 60,
        user,
    })
}

async fn register_email(
    state: web::Data<AppState>,
    body: web::Json<EmailCredentials>,
) -> impl Responder {
    let Some(email) = auth::normalize_email(&body.email) else {
        return HttpResponse::BadRequest().json(ApiError::new(
            "invalid_email",
            "a valid email address is required",
        ));
    };
    if !auth::valid_password(&body.password) {
        return HttpResponse::BadRequest().json(ApiError::new(
            "invalid_password",
            "password must be between 10 and 128 characters",
        ));
    }
    let password = body.password.clone();
    let password_hash = match web::block(move || auth::hash_password(&password)).await {
        Ok(hash) => hash,
        Err(error) => {
            tracing::error!(%error, "password hashing worker failed");
            return HttpResponse::InternalServerError()
                .json(ApiError::new("auth_error", "could not create account"));
        }
    };
    let user = match database::register_email_user(&state.pool, &email, &password_hash).await {
        Ok(user) => user,
        Err(database::RegisterUserError::EmailExists) => {
            return HttpResponse::Conflict().json(ApiError::new(
                "email_exists",
                "an account already exists for this email",
            ));
        }
        Err(database::RegisterUserError::Database(error)) => {
            tracing::error!(%error, "failed to register user");
            return HttpResponse::InternalServerError()
                .json(ApiError::new("database_error", "could not create account"));
        }
    };
    match issue_session(&state, user).await {
        Ok(response) => HttpResponse::Created().json(response),
        Err(response) => response,
    }
}

async fn login_email(
    state: web::Data<AppState>,
    body: web::Json<EmailCredentials>,
) -> impl Responder {
    let Some(email) = auth::normalize_email(&body.email) else {
        return HttpResponse::Unauthorized().json(ApiError::new(
            "invalid_credentials",
            "email or password is incorrect",
        ));
    };
    let credentials = match database::email_user_credentials(&state.pool, &email).await {
        Ok(value) => value,
        Err(error) => {
            tracing::error!(%error, "failed to load auth user");
            return HttpResponse::InternalServerError()
                .json(ApiError::new("database_error", "could not sign in"));
        }
    };
    let password = body.password.clone();
    let verification_hash = credentials.as_ref().map_or_else(
        || auth::dummy_password_hash().to_owned(),
        |(_, hash)| hash.clone(),
    );
    let verified =
        match web::block(move || auth::verify_password(&password, &verification_hash)).await {
            Ok(verified) => verified,
            Err(error) => {
                tracing::error!(%error, "password verification worker failed");
                return HttpResponse::InternalServerError()
                    .json(ApiError::new("auth_error", "could not sign in"));
            }
        };
    let Some((user, _)) = credentials else {
        return HttpResponse::Unauthorized().json(ApiError::new(
            "invalid_credentials",
            "email or password is incorrect",
        ));
    };
    if !verified {
        return HttpResponse::Unauthorized().json(ApiError::new(
            "invalid_credentials",
            "email or password is incorrect",
        ));
    }
    match issue_session(&state, user).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(response) => response,
    }
}

async fn login_google(
    state: web::Data<AppState>,
    body: web::Json<GoogleCredential>,
) -> impl Responder {
    let Some(verifier) = state.google.as_ref() else {
        return HttpResponse::ServiceUnavailable().json(ApiError::new(
            "google_auth_unconfigured",
            "Google authentication is not configured",
        ));
    };
    let identity = match verifier.verify(body.id_token.trim()).await {
        Ok(identity) => identity,
        Err(google::VerifyError::Invalid) => {
            return HttpResponse::Unauthorized().json(ApiError::new(
                "invalid_google_token",
                "Google identity token is invalid",
            ));
        }
        Err(google::VerifyError::Unavailable) => {
            return HttpResponse::BadGateway().json(ApiError::new(
                "google_unavailable",
                "Google identity verification is temporarily unavailable",
            ));
        }
    };
    let user = match database::google_user(&state.pool, &identity.subject, &identity.email).await {
        Ok(user) => user,
        Err(database::GoogleUserError::EmailExists) => {
            return HttpResponse::Conflict().json(ApiError::new(
                "email_exists",
                "sign in with email before linking this Google account",
            ));
        }
        Err(database::GoogleUserError::Database(error)) => {
            tracing::error!(%error, "failed to save Google identity");
            return HttpResponse::InternalServerError().json(ApiError::new(
                "database_error",
                "could not sign in with Google",
            ));
        }
    };
    match issue_session(&state, user).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(response) => response,
    }
}

fn request_token(request: &HttpRequest) -> Option<&str> {
    request
        .headers()
        .get("authorization")
        .and_then(|value| value.to_str().ok())
        .and_then(|value| auth::bearer_token(Some(value)))
}

async fn current_user(state: web::Data<AppState>, request: HttpRequest) -> impl Responder {
    let Some(token) = request_token(&request) else {
        return HttpResponse::Unauthorized().json(ApiError::new(
            "unauthorized",
            "a valid bearer token is required",
        ));
    };
    match database::authenticated_user(&state.pool, &auth::hash_session_token(token)).await {
        Ok(Some(user)) => HttpResponse::Ok().json(user),
        Ok(None) => HttpResponse::Unauthorized().json(ApiError::new(
            "unauthorized",
            "session is invalid or expired",
        )),
        Err(error) => {
            tracing::error!(%error, "failed to authenticate session");
            HttpResponse::InternalServerError().json(ApiError::new(
                "database_error",
                "could not authenticate session",
            ))
        }
    }
}

async fn bind_wallet(
    state: web::Data<AppState>,
    request: HttpRequest,
    body: web::Json<BindWalletRequest>,
) -> impl Responder {
    let Some(token) = request_token(&request) else {
        return HttpResponse::Unauthorized().json(ApiError::new(
            "unauthorized",
            "a valid bearer token is required",
        ));
    };
    let user =
        match database::authenticated_user(&state.pool, &auth::hash_session_token(token)).await {
            Ok(Some(user)) => user,
            Ok(None) => {
                return HttpResponse::Unauthorized().json(ApiError::new(
                    "unauthorized",
                    "session is invalid or expired",
                ));
            }
            Err(error) => {
                tracing::error!(%error, "failed to authenticate wallet binding");
                return HttpResponse::InternalServerError().json(ApiError::new(
                    "database_error",
                    "could not authenticate session",
                ));
            }
        };
    let wallet_address = body.wallet_address.trim();
    if !valid_wallet(wallet_address) {
        return HttpResponse::BadRequest().json(ApiError::new(
            "invalid_wallet",
            "wallet_address must be a valid Solana public key",
        ));
    }
    match database::bind_wallet(&state.pool, user.id, wallet_address).await {
        Ok(user) => HttpResponse::Ok().json(user),
        Err(database::BindWalletError::AddressInUse) => {
            HttpResponse::Conflict().json(ApiError::new(
                "wallet_in_use",
                "wallet is already linked to another account",
            ))
        }
        Err(database::BindWalletError::WalletMismatch) => {
            HttpResponse::Conflict().json(ApiError::new(
                "wallet_mismatch",
                "account is already linked to a different wallet",
            ))
        }
        Err(database::BindWalletError::Database(error)) => {
            tracing::error!(%error, "failed to bind wallet");
            HttpResponse::InternalServerError()
                .json(ApiError::new("database_error", "could not link wallet"))
        }
    }
}

async fn logout(state: web::Data<AppState>, request: HttpRequest) -> impl Responder {
    let Some(token) = request_token(&request) else {
        return HttpResponse::Unauthorized().json(ApiError::new(
            "unauthorized",
            "a valid bearer token is required",
        ));
    };
    match database::revoke_session(&state.pool, &auth::hash_session_token(token)).await {
        Ok(true) => HttpResponse::NoContent().finish(),
        Ok(false) => HttpResponse::Unauthorized().json(ApiError::new(
            "unauthorized",
            "session is invalid or expired",
        )),
        Err(error) => {
            tracing::error!(%error, "failed to revoke session");
            HttpResponse::InternalServerError()
                .json(ApiError::new("database_error", "could not end session"))
        }
    }
}

pub struct AppState {
    catalog: CompanyCatalog,
    pool: PgPool,
    xstocks: xstocks::XStocksClient,
    google: Option<google::GoogleVerifier>,
}

impl AppState {
    pub fn new(catalog: CompanyCatalog, pool: PgPool) -> Self {
        Self {
            catalog,
            pool,
            xstocks: xstocks::XStocksClient::production(),
            google: None,
        }
    }

    pub fn with_google(mut self, google: Option<google::GoogleVerifier>) -> Self {
        self.google = google;
        self
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
        Err(link::LinkError::RedirectNotAllowed) => {
            HttpResponse::UnprocessableEntity().json(ApiError::new(
                "redirect_not_allowed",
                "the URL redirected too many times or without a valid destination",
            ))
        }
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
    let price = match state.xstocks.price(&asset.symbol).await {
        Ok(price) => price,
        Err(_) => {
            tracing::warn!(
                symbol = asset.symbol,
                "issuer price unavailable; using cached price"
            );
            asset.price_usdc
        }
    };
    let quote = OwnershipQuote {
        company_slug: &company.slug,
        company_name: &company.name,
        asset_symbol: &asset.symbol,
        network: &asset.network,
        amount_usdc: amount,
        estimated_token_amount: (amount / price).round_dp(8),
        contract_address: asset.contract_address.as_deref(),
        market_address: asset.market_address.as_deref(),
        payment_token_address: asset.payment_token_address.as_deref(),
        chain_id: asset.chain_id,
        explorer_url: asset.explorer_url.as_deref(),
        executable: false,
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
    if input.company_slug.is_empty() || input.source.is_empty() || input.explanation.is_empty() {
        return HttpResponse::BadRequest().json(ApiError::new(
            "invalid_discovery",
            "company_slug, source, and explanation must not be empty",
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
    let wallet = query.wallet_address.trim().to_owned();
    if !valid_wallet(&wallet) {
        return HttpResponse::BadRequest().json(ApiError::new(
            "invalid_wallet",
            "wallet_address must be a valid Solana public key",
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

async fn submit_transaction(
    state: web::Data<AppState>,
    body: web::Json<SubmitTransactionRequest>,
) -> impl Responder {
    let mut input = body.into_inner();
    input.wallet_address = input.wallet_address.trim().to_owned();
    input.company_slug = input.company_slug.trim().to_ascii_lowercase();
    input.tx_hash = input.tx_hash.trim().to_owned();
    if !valid_wallet(&input.wallet_address) {
        return HttpResponse::BadRequest().json(ApiError::new(
            "invalid_wallet",
            "wallet_address must be a valid Solana public key",
        ));
    }
    let Some(company) = state.catalog.find_by_slug(&input.company_slug) else {
        return HttpResponse::NotFound().json(ApiError::new(
            "company_not_found",
            "company does not exist in the registry",
        ));
    };
    if company.asset.is_none() {
        return HttpResponse::Conflict().json(ApiError::new(
            "asset_unavailable",
            "company does not have a supported tokenized asset",
        ));
    }
    HttpResponse::ServiceUnavailable().json(ApiError::new(
        "execution_unavailable",
        "Solana transaction verification is not enabled yet",
    ))
}

async fn get_world(state: web::Data<AppState>, query: web::Query<WorldQuery>) -> impl Responder {
    let wallet = query.wallet_address.trim().to_owned();
    if !valid_wallet(&wallet) {
        return HttpResponse::BadRequest().json(ApiError::new(
            "invalid_wallet",
            "wallet_address must be a valid Solana public key",
        ));
    }
    match database::world(&state.pool, &wallet).await {
        Ok(world) => HttpResponse::Ok().json(world),
        Err(error) => {
            tracing::error!(%error, "failed to load world");
            HttpResponse::InternalServerError()
                .json(ApiError::new("database_error", "could not load world"))
        }
    }
}

fn valid_wallet(value: &str) -> bool {
    bs58::decode(value)
        .into_vec()
        .is_ok_and(|decoded| decoded.len() == 32)
}

pub fn configure_app(config: &mut web::ServiceConfig) {
    config
        .app_data(
            web::JsonConfig::default()
                .limit(JSON_BODY_LIMIT)
                .content_type_required(true)
                .error_handler(|json_error, _request| {
                    let response = match &json_error {
                        JsonPayloadError::OverflowKnownLength { .. }
                        | JsonPayloadError::Overflow { .. } => HttpResponse::PayloadTooLarge()
                            .json(ApiError::new(
                                "json_payload_too_large",
                                "JSON request body exceeds the 64 KiB limit",
                            )),
                        JsonPayloadError::ContentType => {
                            HttpResponse::UnsupportedMediaType().json(ApiError::new(
                                "unsupported_media_type",
                                "content-type must be application/json",
                            ))
                        }
                        _ => HttpResponse::BadRequest().json(ApiError::new(
                            "invalid_json",
                            "request body must be valid JSON with the expected fields",
                        )),
                    };
                    error::InternalError::from_response(json_error, response).into()
                }),
        )
        .route("/health", web::get().to(health))
        .route("/ready", web::get().to(readiness))
        .service(
            web::scope("/v1")
                .route("/auth/email/register", web::post().to(register_email))
                .route("/auth/email/login", web::post().to(login_email))
                .route("/auth/google", web::post().to(login_google))
                .route("/auth/me", web::get().to(current_user))
                .route("/auth/wallet", web::post().to(bind_wallet))
                .route("/auth/logout", web::post().to(logout))
                .route("/resolve/search", web::post().to(resolve_search))
                .route("/resolve/link", web::post().to(resolve_link))
                .route("/resolve/image", web::post().to(resolve_lens))
                .route("/companies/{slug}", web::get().to(get_company))
                .route("/companies/{slug}/quote", web::get().to(ownership_quote))
                .route("/discoveries", web::post().to(create_discovery))
                .route("/discoveries", web::get().to(discovery_history))
                .route("/transactions", web::post().to(submit_transaction))
                .route("/world", web::get().to(get_world)),
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
        let mut state = AppState::new(crate::catalog::CompanyCatalog::seeded(), pool);
        state.xstocks = crate::xstocks::XStocksClient::new("http://127.0.0.1:1");
        state
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
        assert_eq!(body["matches"][0]["asset"]["symbol"], "METAx");
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
    async fn google_auth_fails_closed_when_unconfigured() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(test_state()))
                .configure(configure_app),
        )
        .await;
        let request = test::TestRequest::post()
            .uri("/v1/auth/google")
            .set_json(serde_json::json!({"id_token": "not-a-token"}))
            .to_request();
        let response = test::call_service(&app, request).await;
        assert_eq!(response.status(), StatusCode::SERVICE_UNAVAILABLE);
        let body: serde_json::Value = test::read_body_json(response).await;
        assert_eq!(body["code"], "google_auth_unconfigured");
    }

    #[actix_web::test]
    async fn wallet_binding_requires_authentication() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(test_state()))
                .configure(configure_app),
        )
        .await;
        let request = test::TestRequest::post()
            .uri("/v1/auth/wallet")
            .set_json(serde_json::json!({
                "wallet_address": "XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp"
            }))
            .to_request();
        assert_eq!(
            test::call_service(&app, request).await.status(),
            StatusCode::UNAUTHORIZED
        );
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
        assert_eq!(body["estimated_token_amount"], "0.03864568");
        assert_eq!(body["executable"], false);
    }

    #[actix_web::test]
    async fn world_rejects_invalid_wallet() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(test_state()))
                .configure(configure_app),
        )
        .await;
        let request = test::TestRequest::get()
            .uri("/v1/world?wallet_address=0x1234")
            .to_request();
        assert_eq!(test::call_service(&app, request).await.status(), 400);
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
                "explanation": "resolved from Instagram"
            }))
            .to_request();
        assert_eq!(test::call_service(&app, request).await.status(), 400);
    }

    #[actix_web::test]
    async fn discovery_rejects_unverified_wallet_attribution() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(test_state()))
                .configure(configure_app),
        )
        .await;
        let request = test::TestRequest::post()
            .uri("/v1/discoveries")
            .set_json(serde_json::json!({
                "company_slug": "meta",
                "method": "search",
                "source": "company behind Instagram",
                "explanation": "Instagram is associated with Meta Platforms.",
                "wallet_address": "0x0000000000000000000000000000000000000001"
            }))
            .to_request();
        assert_eq!(test::call_service(&app, request).await.status(), 400);
    }

    #[actix_web::test]
    async fn malformed_json_returns_a_structured_error() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(test_state()))
                .configure(configure_app),
        )
        .await;
        let request = test::TestRequest::post()
            .uri("/v1/resolve/search")
            .insert_header(("content-type", "application/json"))
            .set_payload(r#"{"query":"meta"#)
            .to_request();
        let response = test::call_service(&app, request).await;
        assert_eq!(response.status(), 400);
        let body: serde_json::Value = test::read_body_json(response).await;
        assert_eq!(body["code"], "invalid_json");
    }

    #[actix_web::test]
    async fn json_content_type_is_required() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(test_state()))
                .configure(configure_app),
        )
        .await;
        let request = test::TestRequest::post()
            .uri("/v1/resolve/search")
            .set_payload(r#"{"query":"meta"}"#)
            .to_request();
        let response = test::call_service(&app, request).await;
        assert_eq!(response.status(), 415);
        let body: serde_json::Value = test::read_body_json(response).await;
        assert_eq!(body["code"], "unsupported_media_type");
    }

    #[actix_web::test]
    async fn oversized_json_is_rejected() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(test_state()))
                .configure(configure_app),
        )
        .await;
        let request = test::TestRequest::post()
            .uri("/v1/resolve/search")
            .insert_header(("content-type", "application/json"))
            .set_payload(format!(r#"{{"query":"{}"}}"#, "x".repeat(65 * 1024)))
            .to_request();
        let response = test::call_service(&app, request).await;
        assert_eq!(response.status(), 413);
        let body: serde_json::Value = test::read_body_json(response).await;
        assert_eq!(body["code"], "json_payload_too_large");
    }

    #[actix_web::test]
    async fn validates_solana_wallet_shape() {
        assert!(super::valid_wallet("11111111111111111111111111111111"));
        assert!(super::valid_wallet(
            "XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp"
        ));
        assert!(!super::valid_wallet("0x1234"));
        assert!(!super::valid_wallet("not-a-solana-address"));
    }
}
