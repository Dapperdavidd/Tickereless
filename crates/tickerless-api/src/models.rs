use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct EmailCredentials {
    pub email: String,
    pub password: String,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct GoogleCredential {
    pub id_token: String,
}

#[derive(Serialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub token_type: &'static str,
    pub expires_in: i64,
    pub user: AuthUser,
}

#[derive(Serialize, FromRow)]
pub struct AuthUser {
    pub id: Uuid,
    pub email: String,
    pub wallet_address: Option<String>,
}

#[derive(Serialize)]
pub struct HealthResponse {
    pub status: &'static str,
    pub service: &'static str,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct SearchRequest {
    pub query: String,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct LinkRequest {
    pub url: String,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct LensRequest {
    pub text: Option<String>,
    #[serde(default)]
    pub labels: Vec<String>,
}

#[derive(Serialize)]
pub struct SearchResponse<'a> {
    pub query: String,
    pub matches: Vec<SearchMatch<'a>>,
}

#[derive(Serialize)]
pub struct SearchMatch<'a> {
    pub company: &'a Company,
    pub asset: Option<&'a TokenizedAsset>,
    pub reason: String,
    pub confidence: f32,
    pub actionable: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub role: Option<&'static str>,
}

#[derive(Serialize)]
pub struct LinkResolution<'a> {
    pub url: String,
    pub title: Option<String>,
    pub matches: Vec<SearchMatch<'a>>,
}

#[derive(Serialize)]
pub struct LensResolution<'a> {
    pub signals: Vec<String>,
    pub matches: Vec<SearchMatch<'a>>,
}

#[derive(Serialize)]
pub struct Company {
    pub slug: String,
    pub name: String,
    pub ticker: String,
    pub description: String,
    pub aliases: Vec<String>,
    pub themes: Vec<String>,
    pub asset: Option<TokenizedAsset>,
}

#[derive(Serialize)]
pub struct TokenizedAsset {
    pub symbol: String,
    pub network: String,
    pub environment: String,
    pub contract_address: Option<String>,
    pub market_address: Option<String>,
    pub payment_token_address: Option<String>,
    pub chain_id: Option<i64>,
    pub explorer_url: Option<String>,
    #[serde(with = "rust_decimal::serde::str")]
    pub price_usdc: Decimal,
}

#[derive(Deserialize)]
pub struct OwnershipQuoteQuery {
    #[serde(with = "rust_decimal::serde::str")]
    pub amount_usdc: Decimal,
}

#[derive(Serialize)]
pub struct OwnershipQuote<'a> {
    pub company_slug: &'a str,
    pub company_name: &'a str,
    pub asset_symbol: &'a str,
    pub network: &'a str,
    #[serde(with = "rust_decimal::serde::str")]
    pub amount_usdc: Decimal,
    #[serde(with = "rust_decimal::serde::str")]
    pub estimated_token_amount: Decimal,
    pub contract_address: Option<&'a str>,
    pub market_address: Option<&'a str>,
    pub payment_token_address: Option<&'a str>,
    pub chain_id: Option<i64>,
    pub explorer_url: Option<&'a str>,
    pub executable: bool,
}

#[derive(Serialize)]
pub struct ApiError {
    pub code: &'static str,
    pub message: &'static str,
}
impl ApiError {
    pub const fn new(code: &'static str, message: &'static str) -> Self {
        Self { code, message }
    }
}

#[derive(Debug, Clone, Copy, Deserialize, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum DiscoveryMethod {
    Search,
    Lens,
    Link,
}

impl DiscoveryMethod {
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Search => "search",
            Self::Lens => "lens",
            Self::Link => "link",
        }
    }
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CreateDiscoveryRequest {
    pub company_slug: String,
    pub method: DiscoveryMethod,
    pub source: String,
    pub explanation: String,
}

#[derive(Deserialize)]
pub struct DiscoveryHistoryQuery {
    pub wallet_address: String,
    pub limit: Option<i64>,
}

#[derive(Serialize, FromRow)]
pub struct Discovery {
    pub id: Uuid,
    pub company_slug: String,
    pub company_name: String,
    pub ticker: String,
    pub method: String,
    pub source: String,
    pub explanation: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct SubmitTransactionRequest {
    pub wallet_address: String,
    pub company_slug: String,
    pub discovery_id: Option<Uuid>,
    pub tx_hash: String,
}

#[derive(Serialize, FromRow)]
pub struct TransactionRecord {
    pub id: Uuid,
    pub company_slug: String,
    pub company_name: String,
    pub ticker: String,
    pub asset_symbol: String,
    pub tx_hash: String,
    #[serde(with = "rust_decimal::serde::str")]
    pub amount_usdc: Decimal,
    #[serde(with = "rust_decimal::serde::str")]
    pub token_amount: Decimal,
    pub status: String,
    pub network: String,
    pub created_at: DateTime<Utc>,
    pub confirmed_at: Option<DateTime<Utc>>,
}

#[derive(Deserialize)]
pub struct WorldQuery {
    pub wallet_address: String,
}

#[derive(Serialize)]
pub struct WorldSummary {
    #[serde(with = "rust_decimal::serde::str")]
    pub total_owned_usdc: Decimal,
    pub company_count: usize,
    pub discovery_count: usize,
    pub companies: Vec<WorldPosition>,
}

#[derive(Serialize)]
pub struct WorldPosition {
    pub company_slug: String,
    pub company_name: String,
    pub ticker: String,
    pub asset_symbol: String,
    #[serde(with = "rust_decimal::serde::str")]
    pub invested_usdc: Decimal,
    #[serde(with = "rust_decimal::serde::str")]
    pub token_amount: Decimal,
    pub discoveries: Vec<WorldDiscoveryContext>,
}

#[derive(Serialize)]
pub struct WorldDiscoveryContext {
    pub method: String,
    pub source: String,
}
